// Package engine is the logic of every Enfo mode, free of any UI. Nothing here
// ticks: every machine stores absolute times (when it ends, when it started) and
// is asked what is true "now", so it keeps exact time while another mode is on
// screen and can be restored after the program was closed.
package engine

import "time"

// Kind labels a logged event.
type Kind string

const (
	KindFocus     Kind = "focus"
	KindRest      Kind = "rest"
	KindLong      Kind = "long"
	KindTimer     Kind = "timer"
	KindStopwatch Kind = "stopwatch"
	KindAlarm     Kind = "alarm"
	KindBreathe   Kind = "breathe"
)

// Event is one thing that happened, for the history and for ringing.
type Event struct {
	Kind      Kind          `json:"k"`
	Label     string        `json:"l,omitempty"`
	Start     time.Time     `json:"s"`
	Planned   time.Duration `json:"p,omitempty"`
	Actual    time.Duration `json:"a"`
	Completed bool          `json:"c"`
	// Late is true when the event finished while Enfo was not running; it is
	// logged but not announced.
	Late bool `json:"-"`
}

// lateAfter is how stale a finish may be before it counts as "while away".
const lateAfter = 5 * time.Second

func clampDur(d, lo time.Duration) time.Duration {
	if d < lo {
		return lo
	}
	return d
}
