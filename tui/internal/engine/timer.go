package engine

import "time"

// Timer is a plain countdown.
type Timer struct {
	Run    Run           `json:"run"`
	Total  time.Duration `json:"total"`
	EndsAt time.Time     `json:"endsAt,omitempty"`
	Left   time.Duration `json:"left"`
	Label  string        `json:"label,omitempty"`
	Start  time.Time     `json:"start,omitempty"`
}

func NewTimer(d time.Duration) *Timer { return &Timer{Run: Idle, Total: d, Left: d} }

// Set picks a new duration (only while idle).
func (t *Timer) Set(d time.Duration, label string) {
	if t.Run != Idle {
		return
	}
	t.Total, t.Left, t.Label = d, d, label
}

func (t *Timer) Remaining(now time.Time) time.Duration {
	if t.Run == Running {
		return clampDur(t.EndsAt.Sub(now), 0)
	}
	return t.Left
}

func (t *Timer) Progress(now time.Time) float64 {
	if t.Total <= 0 {
		return 0
	}
	v := 1 - float64(t.Remaining(now))/float64(t.Total)
	return min(max(v, 0), 1)
}

func (t *Timer) Active() bool { return t.Run != Idle }

func (t *Timer) Begin(now time.Time) {
	switch t.Run {
	case Idle:
		if t.Left <= 0 {
			return
		}
		t.Run, t.EndsAt, t.Start = Running, now.Add(t.Left), now
	case Paused:
		t.Run, t.EndsAt = Running, now.Add(t.Left)
	}
}

func (t *Timer) Pause(now time.Time) {
	if t.Run == Running {
		t.Left = clampDur(t.EndsAt.Sub(now), 0)
		t.Run = Paused
	}
}

func (t *Timer) Toggle(now time.Time) {
	if t.Run == Running {
		t.Pause(now)
	} else {
		t.Begin(now)
	}
}

// Reset stops and restores the full length; reports the abandoned run.
func (t *Timer) Reset(now time.Time) []Event {
	var ev []Event
	if t.Run != Idle && !t.Start.IsZero() {
		if a := clampDur(t.Total-t.Remaining(now), 0); a >= 5*time.Second {
			ev = []Event{{Kind: KindTimer, Label: t.Label, Start: t.Start, Planned: t.Total, Actual: a}}
		}
	}
	t.Run, t.Left, t.EndsAt, t.Start = Idle, t.Total, time.Time{}, time.Time{}
	return ev
}

// Add extends a running or paused timer (a quick "+1 min").
func (t *Timer) Add(d time.Duration, now time.Time) {
	left := t.Remaining(now) + d
	if left < time.Second {
		left = time.Second
	}
	if t.Run == Idle {
		t.Total, t.Left = max(left, time.Second), max(left, time.Second)
		return
	}
	t.Total += left - t.Remaining(now)
	if t.Total < left {
		t.Total = left
	}
	if t.Run == Running {
		t.EndsAt = now.Add(left)
	} else {
		t.Left = left
	}
}

// Tick reports the timer finishing.
func (t *Timer) Tick(now time.Time) []Event {
	if t.Run != Running || now.Before(t.EndsAt) {
		return nil
	}
	ev := Event{Kind: KindTimer, Label: t.Label, Start: t.Start, Planned: t.Total, Actual: t.Total,
		Completed: true, Late: now.Sub(t.EndsAt) > lateAfter}
	t.Run, t.Left, t.EndsAt, t.Start = Idle, t.Total, time.Time{}, time.Time{}
	return []Event{ev}
}
