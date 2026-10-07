package engine

import (
	"sort"
	"strconv"
	"time"
)

// KindBreaks labels break-reminder events in the history.
const KindBreaks Kind = "breaks"

// BreaksSnooze is how long "snooze" quiets a due reminder.
const BreaksSnooze = 5 * time.Minute

// BreaksReminder is one healthy habit: every Min minutes it comes due.
type BreaksReminder struct {
	ID     string    `json:"id"`
	Label  string    `json:"label,omitempty"` // custom reminders only
	Custom bool      `json:"custom,omitempty"`
	Min    int       `json:"min"` // interval, minutes
	On     bool      `json:"on"`
	NextAt time.Time `json:"next,omitempty"`
	// Pending is true once the reminder came due and was announced; it stays
	// so until the user does it, snoozes it or switches it off.
	Pending bool   `json:"pending,omitempty"`
	Day     string `json:"day,omitempty"` // the day the counters below belong to
	Done    int    `json:"done,omitempty"`
	Skipped int    `json:"skipped,omitempty"`
}

// BreaksDuty is a reminder that just came due.
type BreaksDuty struct{ R *BreaksReminder }

// Breaks is the whole set, timestamp-driven so it keeps exact time while
// hidden and across restarts.
type Breaks struct {
	List     []*BreaksReminder `json:"list"`
	Paused   bool              `json:"paused,omitempty"`
	PausedAt time.Time         `json:"pausedAt,omitempty"`
	NextID   int               `json:"nextId,omitempty"`
	// DoneByDay counts completed breaks per local day ("2006-01-02"), for the
	// streak and the weekly sparkline. Pruned to 60 days.
	DoneByDay map[string]int `json:"days,omitempty"`
}

const breaksDayLayout = "2006-01-02"

// BreaksDefaults is the first-run set: 20-20-20, stretch, water, posture.
func BreaksDefaults(now time.Time) *Breaks {
	b := &Breaks{DoneByDay: map[string]int{}}
	for _, d := range []struct {
		id  string
		min int
		on  bool
	}{{"eyes", 20, true}, {"stretch", 45, true}, {"water", 60, true}, {"posture", 30, false}} {
		r := &BreaksReminder{ID: d.id, Min: d.min, On: d.on}
		r.arm(now)
		b.List = append(b.List, r)
	}
	return b
}

func (r *BreaksReminder) every() time.Duration { return time.Duration(r.Min) * time.Minute }

func (r *BreaksReminder) arm(now time.Time) {
	r.Pending = false
	if r.On {
		r.NextAt = now.Add(r.every())
	} else {
		r.NextAt = time.Time{}
	}
}

func breaksDay(t time.Time) string { return t.Format(breaksDayLayout) }

// roll resets the daily counters when the day changed.
func (r *BreaksReminder) roll(now time.Time) {
	if d := breaksDay(now); r.Day != d {
		r.Day, r.Done, r.Skipped = d, 0, 0
	}
}

// CatchUp reschedules whatever came due while Enfo was closed (nothing rings
// for the past) and rolls the day counters.
func (b *Breaks) CatchUp(now time.Time) {
	for _, r := range b.List {
		r.roll(now)
		if r.On && !b.Paused && !r.NextAt.IsZero() && !now.Before(r.NextAt) {
			r.arm(now)
		}
	}
	b.prune(now)
}

func (b *Breaks) prune(now time.Time) {
	if b.DoneByDay == nil {
		b.DoneByDay = map[string]int{}
	}
	cut := breaksDay(now.AddDate(0, 0, -60))
	for k := range b.DoneByDay {
		if k < cut {
			delete(b.DoneByDay, k)
		}
	}
}

// Tick returns the reminders that just came due (once each).
func (b *Breaks) Tick(now time.Time) []BreaksDuty {
	if b.Paused {
		return nil
	}
	var out []BreaksDuty
	for _, r := range b.List {
		r.roll(now)
		if r.On && !r.Pending && !r.NextAt.IsZero() && !now.Before(r.NextAt) {
			r.Pending = true
			out = append(out, BreaksDuty{r})
		}
	}
	return out
}

// Get finds a reminder by id.
func (b *Breaks) Get(id string) *BreaksReminder {
	for _, r := range b.List {
		if r.ID == id {
			return r
		}
	}
	return nil
}

// Complete records that the break was taken and restarts the interval.
func (b *Breaks) Complete(id string, now time.Time) {
	r := b.Get(id)
	if r == nil {
		return
	}
	r.roll(now)
	r.Done++
	if b.DoneByDay == nil {
		b.DoneByDay = map[string]int{}
	}
	b.DoneByDay[breaksDay(now)]++
	r.On = true
	r.arm(now)
}

// Snooze quiets a reminder for BreaksSnooze.
func (b *Breaks) Snooze(id string, now time.Time) {
	if r := b.Get(id); r != nil {
		r.Pending = false
		r.On = true
		r.NextAt = now.Add(BreaksSnooze)
	}
}

// Skip counts the break as skipped and restarts the interval.
func (b *Breaks) Skip(id string, now time.Time) {
	if r := b.Get(id); r != nil {
		r.roll(now)
		r.Skipped++
		r.arm(now)
	}
}

// Toggle switches a reminder on/off (on restarts its interval).
func (b *Breaks) Toggle(id string, now time.Time) {
	if r := b.Get(id); r != nil {
		r.On = !r.On
		r.arm(now)
		if b.Paused && r.On {
			r.NextAt = now.Add(r.every())
		}
	}
}

// SetEvery changes the interval (clamped 5..240 min); a waiting reminder is
// rescheduled from now.
func (b *Breaks) SetEvery(id string, min int, now time.Time) {
	if r := b.Get(id); r != nil {
		if min < 5 {
			min = 5
		}
		if min > 240 {
			min = 240
		}
		r.Min = min
		if r.On && !r.Pending {
			r.NextAt = now.Add(r.every())
		}
	}
}

// Add creates a custom reminder.
func (b *Breaks) Add(label string, min int, now time.Time) *BreaksReminder {
	b.NextID++
	r := &BreaksReminder{ID: "c" + strconv.Itoa(b.NextID), Label: label, Custom: true, Min: min, On: true}
	if r.Min < 5 {
		r.Min = 5
	}
	if r.Min > 240 {
		r.Min = 240
	}
	r.arm(now)
	b.List = append(b.List, r)
	return r
}

// Delete removes a custom reminder (built-in ones can only be switched off).
func (b *Breaks) Delete(id string) {
	for i, r := range b.List {
		if r.ID == id && r.Custom {
			b.List = append(b.List[:i], b.List[i+1:]...)
			return
		}
	}
}

// Rename changes a custom reminder's label and interval.
func (b *Breaks) Edit(id, label string, min int, now time.Time) {
	if r := b.Get(id); r != nil && r.Custom {
		r.Label = label
		b.SetEvery(id, min, now)
	}
}

// SetPaused pauses or resumes every reminder; resuming shifts the schedule by
// the time spent paused so nothing comes due the instant you return.
func (b *Breaks) SetPaused(p bool, now time.Time) {
	if p == b.Paused {
		return
	}
	if p {
		b.Paused, b.PausedAt = true, now
		return
	}
	d := now.Sub(b.PausedAt)
	for _, r := range b.List {
		if r.On && !r.NextAt.IsZero() {
			r.NextAt = r.NextAt.Add(d)
		}
	}
	b.Paused, b.PausedAt = false, time.Time{}
}

// Until is the time left to the reminder (negative when overdue); frozen while
// paused.
func (b *Breaks) Until(r *BreaksReminder, now time.Time) time.Duration {
	if b.Paused {
		now = b.PausedAt
	}
	return r.NextAt.Sub(now)
}

// Nearest returns the enabled reminder that comes due first.
func (b *Breaks) Nearest(now time.Time) *BreaksReminder {
	var best *BreaksReminder
	for _, r := range b.List {
		if !r.On || r.NextAt.IsZero() {
			continue
		}
		if best == nil || r.NextAt.Before(best.NextAt) {
			best = r
		}
	}
	return best
}

// Streak counts consecutive days with at least one break taken, ending today
// (a quiet today does not break yesterday's run).
func (b *Breaks) Streak(now time.Time) int {
	n := 0
	d := now
	if b.DoneByDay[breaksDay(d)] == 0 {
		d = d.AddDate(0, 0, -1)
	}
	for b.DoneByDay[breaksDay(d)] > 0 {
		n++
		d = d.AddDate(0, 0, -1)
	}
	return n
}

// DoneToday and SkippedToday sum the counters of every reminder.
func (b *Breaks) DoneToday(now time.Time) (done, skipped int) {
	d := breaksDay(now)
	for _, r := range b.List {
		if r.Day == d {
			done += r.Done
			skipped += r.Skipped
		}
	}
	return
}

// LastDays returns completed breaks for the last n days, oldest first.
func (b *Breaks) LastDays(now time.Time, n int) []int {
	out := make([]int, n)
	for i := 0; i < n; i++ {
		out[n-1-i] = b.DoneByDay[breaksDay(now.AddDate(0, 0, -i))]
	}
	return out
}

// SortedDue lists enabled reminders by due time (for display).
func (b *Breaks) SortedDue() []*BreaksReminder {
	out := append([]*BreaksReminder(nil), b.List...)
	sort.SliceStable(out, func(i, j int) bool { return out[i].NextAt.Before(out[j].NextAt) })
	return out
}
