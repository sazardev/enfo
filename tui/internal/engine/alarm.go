package engine

import (
	"sort"
	"time"
)

// SnoozeFor is how long a snoozed alarm stays quiet.
const SnoozeFor = 5 * time.Minute

// missedAfter: an alarm more than this late is logged as missed, not rung.
const missedAfter = 10 * time.Minute

// Days is a weekday bitmask, bit 0 = Monday ... bit 6 = Sunday. Zero means the
// alarm fires once, at the next occurrence of its time.
type Days uint8

const (
	Weekdays Days = 0b0011111
	Weekend  Days = 0b1100000
	Everyday Days = 0b1111111
)

func (d Days) Has(wd time.Weekday) bool { return d&(1<<uint((int(wd)+6)%7)) != 0 }

func (d Days) Toggle(idx int) Days { return d ^ (1 << uint(idx)) }

// Alarm is one alarm clock.
type Alarm struct {
	ID       int       `json:"id"`
	Label    string    `json:"label,omitempty"`
	Hour     int       `json:"h"`
	Min      int       `json:"m"`
	Days     Days      `json:"days"`
	Enabled  bool      `json:"on"`
	NextAt   time.Time `json:"next,omitempty"`
	SnoozeAt time.Time `json:"snooze,omitempty"`
}

// NextOccurrence is the first moment strictly after from at which the alarm's
// time of day falls on one of its days (any day when Days is zero).
func (a *Alarm) NextOccurrence(from time.Time) time.Time {
	loc := from.Location()
	for i := 0; i < 8; i++ {
		d := from.AddDate(0, 0, i)
		t := time.Date(d.Year(), d.Month(), d.Day(), a.Hour, a.Min, 0, 0, loc)
		if !t.After(from) {
			continue
		}
		if a.Days == 0 || a.Days.Has(t.Weekday()) {
			return t
		}
	}
	return time.Time{}
}

// Arm recomputes the next ring from now. Enabling or editing an alarm never
// makes it ring for a time that already passed today.
func (a *Alarm) Arm(now time.Time) {
	if a.Enabled {
		a.NextAt = a.NextOccurrence(now)
	} else {
		a.NextAt = time.Time{}
	}
	a.SnoozeAt = time.Time{}
}

// Ring is an alarm going off.
type Ring struct {
	Alarm  Alarm
	Missed bool
	At     time.Time
}

// Alarms is the collection.
type Alarms struct {
	List   []*Alarm `json:"list"`
	NextID int      `json:"nextId"`
}

func (as *Alarms) Add(a Alarm, now time.Time) *Alarm {
	as.NextID++
	a.ID = as.NextID
	a.Arm(now)
	as.List = append(as.List, &a)
	as.sort()
	return as.find(a.ID)
}

func (as *Alarms) sort() {
	sort.SliceStable(as.List, func(i, j int) bool {
		x, y := as.List[i], as.List[j]
		return x.Hour*60+x.Min < y.Hour*60+y.Min
	})
}

func (as *Alarms) find(id int) *Alarm {
	for _, a := range as.List {
		if a.ID == id {
			return a
		}
	}
	return nil
}

func (as *Alarms) Get(id int) *Alarm { return as.find(id) }

// Update replaces the alarm with the same ID, re-arming it.
func (as *Alarms) Update(a Alarm, now time.Time) {
	if cur := as.find(a.ID); cur != nil {
		*cur = a
		cur.Arm(now)
		as.sort()
	}
}

func (as *Alarms) Delete(id int) {
	for i, a := range as.List {
		if a.ID == id {
			as.List = append(as.List[:i], as.List[i+1:]...)
			return
		}
	}
}

func (as *Alarms) Toggle(id int, now time.Time) {
	if a := as.find(id); a != nil {
		a.Enabled = !a.Enabled
		a.Arm(now)
	}
}

// Snooze quiets a ringing alarm for SnoozeFor.
func (as *Alarms) Snooze(id int, now time.Time) {
	if a := as.find(id); a != nil {
		a.SnoozeAt = now.Add(SnoozeFor)
	}
}

// Next returns the alarm that will ring first, and when.
func (as *Alarms) Next() (*Alarm, time.Time) {
	var best *Alarm
	var at time.Time
	for _, a := range as.List {
		for _, t := range []time.Time{a.NextAt, a.SnoozeAt} {
			if t.IsZero() || (a.NextAt == t && !a.Enabled) {
				continue
			}
			if best == nil || t.Before(at) {
				best, at = a, t
			}
		}
	}
	return best, at
}

// Tick returns the alarms that are due. A repeating alarm moves on to its next
// day; a one-shot alarm turns itself off.
func (as *Alarms) Tick(now time.Time) []Ring {
	var out []Ring
	for _, a := range as.List {
		if !a.SnoozeAt.IsZero() && !now.Before(a.SnoozeAt) {
			out = append(out, Ring{Alarm: *a, At: a.SnoozeAt, Missed: now.Sub(a.SnoozeAt) > missedAfter})
			a.SnoozeAt = time.Time{}
		}
		if a.Enabled && !a.NextAt.IsZero() && !now.Before(a.NextAt) {
			out = append(out, Ring{Alarm: *a, At: a.NextAt, Missed: now.Sub(a.NextAt) > missedAfter})
			if a.Days == 0 {
				a.Enabled = false
				a.NextAt = time.Time{}
			} else {
				a.NextAt = a.NextOccurrence(now)
			}
		}
	}
	return out
}
