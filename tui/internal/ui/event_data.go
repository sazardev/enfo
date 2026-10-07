package ui

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"time"
)

// eventItem is one thing to count down to. All instants are stored as absolute
// times; "yearly" events repeat on the same month/day/clock time every year.
type eventItem struct {
	ID       int       `json:"id"`
	Name     string    `json:"name"`
	At       time.Time `json:"at"`
	Yearly   bool      `json:"yearly,omitempty"`
	Created  time.Time `json:"created"`
	Accent   int       `json:"accent,omitempty"`   // index into the palette cycle, 0 = the theme accent
	Fired    time.Time `json:"fired,omitempty"`    // the occurrence already announced
	Reminded time.Time `json:"reminded,omitempty"` // the occurrence whose day-before reminder was sent
}

type eventFile struct {
	Next  int         `json:"next"`
	Items []eventItem `json:"items"`
}

// eventStore reads and writes event.json in the state directory.
type eventStore struct {
	path string
	data eventFile
}

func eventOpen(dir string) *eventStore {
	s := &eventStore{path: filepath.Join(dir, "event.json")}
	if b, err := os.ReadFile(s.path); err == nil {
		if json.Unmarshal(b, &s.data) != nil {
			s.data = eventFile{}
		}
	}
	return s
}

func (s *eventStore) save() {
	b, err := json.Marshal(s.data)
	if err != nil {
		return
	}
	tmp := s.path + ".tmp"
	if os.WriteFile(tmp, b, 0o644) == nil {
		_ = os.Rename(tmp, s.path)
	}
}

func (s *eventStore) add(it eventItem) int {
	s.data.Next++
	it.ID = s.data.Next
	s.data.Items = append(s.data.Items, it)
	return it.ID
}

func (s *eventStore) find(id int) *eventItem {
	for i := range s.data.Items {
		if s.data.Items[i].ID == id {
			return &s.data.Items[i]
		}
	}
	return nil
}

func (s *eventStore) remove(id int) {
	for i := range s.data.Items {
		if s.data.Items[i].ID == id {
			s.data.Items = append(s.data.Items[:i], s.data.Items[i+1:]...)
			return
		}
	}
}

// ---------------------------------------------------------------- occurrences

// eventAt is the instant of the item's occurrence in a given year (the same
// month, day and clock time, in the zone the event was made in).
func eventOccurrence(it *eventItem, year int) time.Time {
	loc := it.At.Location()
	return time.Date(year, it.At.Month(), it.At.Day(), it.At.Hour(), it.At.Minute(), it.At.Second(), 0, loc)
}

// eventNext is the occurrence the countdown points at: the first one strictly
// after now. A one-off event whose date has passed has none (ok=false).
func eventNext(it *eventItem, now time.Time) (time.Time, bool) {
	if !it.Yearly {
		if it.At.After(now) {
			return it.At, true
		}
		return time.Time{}, false
	}
	n := now.In(it.At.Location())
	for y := n.Year(); y <= n.Year()+2; y++ {
		if t := eventOccurrence(it, y); t.After(now) {
			return t, true
		}
	}
	return time.Time{}, false
}

// eventLast is the latest occurrence that is not after now (ok=false when the
// first one is still to come).
func eventLast(it *eventItem, now time.Time) (time.Time, bool) {
	if !it.Yearly {
		if !it.At.After(now) {
			return it.At, true
		}
		return time.Time{}, false
	}
	n := now.In(it.At.Location())
	for y := n.Year(); y >= it.At.Year(); y-- {
		if t := eventOccurrence(it, y); !t.After(now) {
			return t, true
		}
	}
	return time.Time{}, false
}

// eventView is an item resolved against the clock.
type eventView struct {
	Item     *eventItem
	Target   time.Time     // the occurrence being counted to/from
	Left     time.Duration // > 0 upcoming; <= 0 for events that already happened
	Prev     time.Time     // start of the progress span
	Past     bool          // one-off event that already happened
	Arrived  bool          // happened within the last arrival window
	Progress float64       // 0..1 from Prev to Target (1 for past events)
}

const eventArrivalWindow = 2 * time.Minute

func eventResolve(it *eventItem, now time.Time) eventView {
	v := eventView{Item: it}
	if t, ok := eventNext(it, now); ok {
		v.Target = t
		v.Left = t.Sub(now)
		if it.Yearly {
			v.Prev = eventOccurrence(it, t.In(it.At.Location()).Year()-1)
		} else {
			v.Prev = it.Created
			if !v.Prev.Before(t) {
				v.Prev = t.AddDate(0, 0, -30)
			}
		}
		span := t.Sub(v.Prev)
		if span > 0 {
			v.Progress = clamp01(float64(now.Sub(v.Prev)) / float64(span))
		}
	} else {
		v.Target = it.At
		v.Past = true
		v.Left = it.At.Sub(now)
		v.Progress = 1
	}
	if last, ok := eventLast(it, now); ok && now.Sub(last) < eventArrivalWindow {
		v.Arrived = true
	}
	return v
}

func clamp01(v float64) float64 {
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

// eventSorted orders views: upcoming by proximity, then past ones, newest first.
func eventSorted(items []eventItem, now time.Time) []eventView {
	out := make([]eventView, 0, len(items))
	for i := range items {
		out = append(out, eventResolve(&items[i], now))
	}
	sort.SliceStable(out, func(i, j int) bool {
		a, b := out[i], out[j]
		if a.Past != b.Past {
			return !a.Past
		}
		if !a.Past {
			return a.Left < b.Left
		}
		return a.Left > b.Left // closer to now first
	})
	return out
}

// eventParts splits a duration into days / hours / minutes / seconds (rounded
// up to the second like the other countdowns).
func eventParts(d time.Duration) (days, h, m, s int) {
	if d < 0 {
		d = -d
	}
	total := int((d + time.Second - 1) / time.Second)
	return total / 86400, total % 86400 / 3600, total % 3600 / 60, total % 60
}

// eventDaysInMonth is the length of a month.
func eventDaysInMonth(year int, month time.Month) int {
	return time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
}

// eventStep reports what the clock crossed since the last look: the arrival of
// an occurrence and the day-before reminder. It marks both as done so each is
// announced once. Anything that happened while Enfo was closed is marked
// without being reported (reported=false for those).
type eventNote struct {
	Item    eventItem
	Arrived bool // else: the day-before reminder
	Occurs  time.Time
}

func eventCheck(items []eventItem, now time.Time) (notes []eventNote, changed bool) {
	const grace = 10 * time.Second
	for i := range items {
		it := &items[i]
		if last, ok := eventLast(it, now); ok && last.After(it.Fired) {
			it.Fired = last
			changed = true
			if now.Sub(last) <= grace {
				notes = append(notes, eventNote{Item: *it, Arrived: true, Occurs: last})
			}
		}
		if next, ok := eventNext(it, now); ok && it.Reminded != next {
			remind := next.Add(-24 * time.Hour)
			if !now.Before(remind) {
				it.Reminded = next
				changed = true
				// only a real reminder if the event existed a day before and
				// the moment is fresh (not found stale after being away)
				if it.Created.Before(remind) && now.Sub(remind) <= 10*time.Minute {
					notes = append(notes, eventNote{Item: *it, Occurs: next})
				}
			}
		}
	}
	return
}
