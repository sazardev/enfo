package engine

import "time"

// Lap is one recorded lap: its own duration and the running total.
type Lap struct {
	N     int           `json:"n"`
	Split time.Duration `json:"split"`
	Total time.Duration `json:"total"`
}

// Stopwatch counts up from a fixed start instant, so it keeps counting while
// another mode is open or Enfo is closed.
type Stopwatch struct {
	Run     Run           `json:"run"`
	Started time.Time     `json:"started,omitempty"` // when the current run began
	Accum   time.Duration `json:"accum"`             // time from earlier runs
	Laps    []Lap         `json:"laps,omitempty"`
	Since   time.Time     `json:"since,omitempty"` // first start of this session
}

func (s *Stopwatch) Elapsed(now time.Time) time.Duration {
	if s.Run == Running {
		return s.Accum + clampDur(now.Sub(s.Started), 0)
	}
	return s.Accum
}

func (s *Stopwatch) Active() bool { return s.Run == Running || s.Accum > 0 }

func (s *Stopwatch) Toggle(now time.Time) {
	if s.Run == Running {
		s.Accum += now.Sub(s.Started)
		s.Run = Paused
		return
	}
	if s.Since.IsZero() {
		s.Since = now
	}
	s.Run, s.Started = Running, now
}

// Lap records a lap and returns it (only while running).
func (s *Stopwatch) Lap(now time.Time) (Lap, bool) {
	if s.Run != Running {
		return Lap{}, false
	}
	total := s.Elapsed(now)
	var prev time.Duration
	if n := len(s.Laps); n > 0 {
		prev = s.Laps[n-1].Total
	}
	l := Lap{N: len(s.Laps) + 1, Split: total - prev, Total: total}
	s.Laps = append(s.Laps, l)
	return l, true
}

// Reset clears everything and reports the finished run for the history.
func (s *Stopwatch) Reset(now time.Time) []Event {
	var ev []Event
	if el := s.Elapsed(now); el >= 2*time.Second && !s.Since.IsZero() {
		ev = []Event{{Kind: KindStopwatch, Start: s.Since, Actual: el, Completed: true}}
	}
	*s = Stopwatch{}
	return ev
}

// Extremes returns the indexes of the fastest and slowest laps (-1 if fewer
// than two laps, since one lap is neither).
func (s *Stopwatch) Extremes() (best, worst int) {
	best, worst = -1, -1
	if len(s.Laps) < 2 {
		return
	}
	best, worst = 0, 0
	for i, l := range s.Laps {
		if l.Split < s.Laps[best].Split {
			best = i
		}
		if l.Split > s.Laps[worst].Split {
			worst = i
		}
	}
	return
}
