package engine

import "time"

// KindTracker labels time-tracker spans in the history.
const KindTracker Kind = "tracker"

// TrackerActivity is something you track time on.
type TrackerActivity struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Color int    `json:"color"` // index into the app's hue wheel
}

// TrackerSpan is a finished stretch of time on an activity.
type TrackerSpan struct {
	Act   int       `json:"a"`
	Start time.Time `json:"s"`
	End   time.Time `json:"e"`
}

// TrackerSeg is a piece of a day (clipped to it) for the timeline.
type TrackerSeg struct {
	Act      int
	From, To time.Duration // offsets from the start of the day
	Live     bool
}

// Tracker is the activity list, the spans and the one running activity. Time
// is absolute (RunStart), so it keeps counting while hidden or closed.
type Tracker struct {
	Acts     []*TrackerActivity `json:"acts"`
	Spans    []TrackerSpan      `json:"spans,omitempty"`
	NextID   int                `json:"nextId"`
	Running  int                `json:"running,omitempty"` // activity id, 0 = none
	RunStart time.Time          `json:"runStart,omitempty"`
}

// TrackerColors is how many hues the color wheel offers.
const TrackerColors = 8

// NewTracker seeds a few starter activities with the given names.
func NewTracker(names ...string) *Tracker {
	t := &Tracker{}
	for _, n := range names {
		t.Add(n)
	}
	return t
}

func (t *Tracker) Get(id int) *TrackerActivity {
	for _, a := range t.Acts {
		if a.ID == id {
			return a
		}
	}
	return nil
}

// Add creates an activity with the next free color.
func (t *Tracker) Add(name string) *TrackerActivity {
	t.NextID++
	a := &TrackerActivity{ID: t.NextID, Name: name, Color: (len(t.Acts)) % TrackerColors}
	t.Acts = append(t.Acts, a)
	return a
}

// Delete removes an activity and its spans (stopping it first, unlogged).
func (t *Tracker) Delete(id int) {
	if t.Running == id {
		t.Running, t.RunStart = 0, time.Time{}
	}
	for i, a := range t.Acts {
		if a.ID == id {
			t.Acts = append(t.Acts[:i], t.Acts[i+1:]...)
			break
		}
	}
	keep := t.Spans[:0]
	for _, s := range t.Spans {
		if s.Act != id {
			keep = append(keep, s)
		}
	}
	t.Spans = keep
}

func (t *Tracker) Rename(id int, name string) {
	if a := t.Get(id); a != nil && name != "" {
		a.Name = name
	}
}

func (t *Tracker) CycleColor(id int) {
	if a := t.Get(id); a != nil {
		a.Color = (a.Color + 1) % TrackerColors
	}
}

// trackerMinSpan: shorter spans are accidental taps and are dropped.
const trackerMinSpan = 2 * time.Second

// Stop ends the running activity and returns the finished span (ok=false when
// nothing ran or it was too short to keep).
func (t *Tracker) Stop(now time.Time) (TrackerSpan, bool) {
	if t.Running == 0 {
		return TrackerSpan{}, false
	}
	s := TrackerSpan{Act: t.Running, Start: t.RunStart, End: now}
	t.Running, t.RunStart = 0, time.Time{}
	if s.End.Sub(s.Start) < trackerMinSpan {
		return s, false
	}
	t.Spans = append(t.Spans, s)
	t.prune(now)
	return s, true
}

// Start runs an activity, stopping the current one first. It returns the span
// that was finished by the switch, if any.
func (t *Tracker) Start(id int, now time.Time) (TrackerSpan, bool) {
	if t.Get(id) == nil {
		return TrackerSpan{}, false
	}
	var s TrackerSpan
	var ok bool
	if t.Running != 0 {
		s, ok = t.Stop(now)
	}
	t.Running, t.RunStart = id, now
	return s, ok
}

func (t *Tracker) prune(now time.Time) {
	cut := now.AddDate(0, 0, -45)
	keep := t.Spans[:0]
	for _, s := range t.Spans {
		if s.End.After(cut) {
			keep = append(keep, s)
		}
	}
	t.Spans = keep
}

// Elapsed is how long the running activity has been running.
func (t *Tracker) Elapsed(now time.Time) time.Duration {
	if t.Running == 0 {
		return 0
	}
	return clampDur(now.Sub(t.RunStart), 0)
}

func trackerDayStart(d time.Time) time.Time {
	y, m, dd := d.Date()
	return time.Date(y, m, dd, 0, 0, 0, 0, d.Location())
}

// overlap of [a0,a1) with [b0,b1).
func trackerOverlap(a0, a1, b0, b1 time.Time) time.Duration {
	if a0.Before(b0) {
		a0 = b0
	}
	if a1.After(b1) {
		a1 = b1
	}
	if !a1.After(a0) {
		return 0
	}
	return a1.Sub(a0)
}

// DayTotals sums time per activity on the calendar day of `day`, including the
// running activity up to now.
func (t *Tracker) DayTotals(day, now time.Time) map[int]time.Duration {
	d0 := trackerDayStart(day.In(now.Location()))
	d1 := d0.AddDate(0, 0, 1)
	out := map[int]time.Duration{}
	for _, s := range t.Spans {
		if o := trackerOverlap(s.Start, s.End, d0, d1); o > 0 {
			out[s.Act] += o
		}
	}
	if t.Running != 0 {
		if o := trackerOverlap(t.RunStart, now, d0, d1); o > 0 {
			out[t.Running] += o
		}
	}
	return out
}

// Segments lists the day's spans clipped to the day, oldest first.
func (t *Tracker) Segments(day, now time.Time) []TrackerSeg {
	d0 := trackerDayStart(day.In(now.Location()))
	d1 := d0.AddDate(0, 0, 1)
	var out []TrackerSeg
	clip := func(a int, s, e time.Time, live bool) {
		if trackerOverlap(s, e, d0, d1) <= 0 {
			return
		}
		if s.Before(d0) {
			s = d0
		}
		if e.After(d1) {
			e = d1
		}
		out = append(out, TrackerSeg{Act: a, From: s.Sub(d0), To: e.Sub(d0), Live: live})
	}
	for _, s := range t.Spans {
		clip(s.Act, s.Start, s.End, false)
	}
	if t.Running != 0 {
		clip(t.Running, t.RunStart, now, true)
	}
	return out
}

// Sum adds every value of a totals map.
func TrackerSum(m map[int]time.Duration) time.Duration {
	var d time.Duration
	for _, v := range m {
		d += v
	}
	return d
}
