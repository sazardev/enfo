package engine

import "time"

type Phase string

const (
	Focus Phase = "focus"
	Rest  Phase = "rest"
	Long  Phase = "long"
)

func (p Phase) IsRest() bool { return p != Focus }

func (p Phase) Kind() Kind {
	switch p {
	case Rest:
		return KindRest
	case Long:
		return KindLong
	}
	return KindFocus
}

type Run string

const (
	Idle    Run = "idle"
	Running Run = "running"
	Paused  Run = "paused"
)

// PomodoroConfig is the rhythm.
type PomodoroConfig struct {
	Work     time.Duration `json:"work"`
	Rest     time.Duration `json:"rest"`
	Long     time.Duration `json:"long"`
	Cycles   int           `json:"cycles"` // focus sessions before a long rest, 0 = none
	AutoNext bool          `json:"auto"`   // start the next phase by itself
}

func DefaultPomodoro() PomodoroConfig {
	return PomodoroConfig{Work: 25 * time.Minute, Rest: 5 * time.Minute, Long: 15 * time.Minute, Cycles: 4}
}

func (c PomodoroConfig) Length(p Phase) time.Duration {
	switch p {
	case Rest:
		return c.Rest
	case Long:
		return c.Long
	}
	return c.Work
}

// Pomodoro is the focus/rest cycle. It survives a restart because a running
// phase stores the instant it ends, and a paused one the time it had left.
type Pomodoro struct {
	Cfg    PomodoroConfig `json:"cfg"`
	Phase  Phase          `json:"phase"`
	Run    Run            `json:"run"`
	Total  time.Duration  `json:"total"`            // length of this phase, including added time
	EndsAt time.Time      `json:"endsAt,omitempty"` // running
	Left   time.Duration  `json:"left"`             // paused or idle
	Done   int            `json:"done"`             // focus sessions finished in this set

	SessionStart time.Time     `json:"start,omitempty"`
	Pauses       int           `json:"pauses,omitempty"`
	PauseStart   time.Time     `json:"pauseStart,omitempty"`
	PausedFor    time.Duration `json:"pausedFor,omitempty"`
}

func NewPomodoro(cfg PomodoroConfig) *Pomodoro {
	p := &Pomodoro{Cfg: cfg, Phase: Focus, Run: Idle}
	p.Total = cfg.Work
	p.Left = cfg.Work
	return p
}

// SetConfig applies new durations. An idle phase takes the new length at once;
// a phase in progress is left alone.
func (p *Pomodoro) SetConfig(cfg PomodoroConfig) {
	p.Cfg = cfg
	if p.Run == Idle {
		p.Total = cfg.Length(p.Phase)
		p.Left = p.Total
	}
}

// Remaining is the time left in the current phase at now.
func (p *Pomodoro) Remaining(now time.Time) time.Duration {
	switch p.Run {
	case Running:
		if d := p.EndsAt.Sub(now); d > 0 {
			return d
		}
		return 0
	default:
		return p.Left
	}
}

// Progress is how much of the phase has elapsed, 0..1.
func (p *Pomodoro) Progress(now time.Time) float64 {
	if p.Total <= 0 {
		return 0
	}
	v := 1 - float64(p.Remaining(now))/float64(p.Total)
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

func (p *Pomodoro) Active() bool { return p.Run != Idle }

// Start begins the phase (from idle) or resumes it (from paused).
func (p *Pomodoro) Start(now time.Time) {
	switch p.Run {
	case Idle:
		p.Run = Running
		p.EndsAt = now.Add(p.Left)
		p.SessionStart = now
		p.Pauses, p.PausedFor, p.PauseStart = 0, 0, time.Time{}
	case Paused:
		p.Run = Running
		p.EndsAt = now.Add(p.Left)
		if !p.PauseStart.IsZero() {
			p.PausedFor += now.Sub(p.PauseStart)
			p.PauseStart = time.Time{}
		}
	}
}

func (p *Pomodoro) Pause(now time.Time) {
	if p.Run != Running {
		return
	}
	p.Left = clampDur(p.EndsAt.Sub(now), 0)
	p.Run = Paused
	p.Pauses++
	p.PauseStart = now
}

func (p *Pomodoro) Toggle(now time.Time) {
	if p.Run == Running {
		p.Pause(now)
	} else {
		p.Start(now)
	}
}

// Reset abandons the phase and puts it back to its full length. It reports the
// abandoned phase (if enough of it had passed to be worth logging).
func (p *Pomodoro) Reset(now time.Time) []Event {
	ev := p.abandoned(now)
	p.Run = Idle
	p.Total = p.Cfg.Length(p.Phase)
	p.Left = p.Total
	p.EndsAt = time.Time{}
	return ev
}

// Skip jumps to the next phase without finishing this one.
func (p *Pomodoro) Skip(now time.Time) []Event {
	ev := p.abandoned(now)
	p.enter(p.next(), now, false)
	return ev
}

// Add changes the time left by d (negative shortens). It never leaves less than
// ten seconds, and the phase's total grows or shrinks with it.
func (p *Pomodoro) Add(d time.Duration, now time.Time) {
	left := p.Remaining(now) + d
	if left < 10*time.Second {
		d += 10*time.Second - left
		left = 10 * time.Second
	}
	p.Total += d
	if p.Total < left {
		p.Total = left
	}
	if p.Run == Running {
		p.EndsAt = now.Add(left)
	} else {
		p.Left = left
	}
}

// SetPhase jumps to a phase while idle (switching focus <-> rest by hand).
func (p *Pomodoro) SetPhase(ph Phase, now time.Time) []Event {
	ev := p.abandoned(now)
	p.enter(ph, now, false)
	return ev
}

func (p *Pomodoro) abandoned(now time.Time) []Event {
	if p.Run == Idle || p.SessionStart.IsZero() {
		return nil
	}
	actual := p.elapsedActive(now)
	if actual < 20*time.Second {
		return nil
	}
	return []Event{{
		Kind: p.Phase.Kind(), Start: p.SessionStart, Planned: p.Total, Actual: actual,
	}}
}

// elapsedActive is the focused time of the phase so far (pauses excluded).
func (p *Pomodoro) elapsedActive(now time.Time) time.Duration {
	return clampDur(p.Total-p.Remaining(now), 0)
}

func (p *Pomodoro) next() Phase {
	switch p.Phase {
	case Focus:
		if p.Cfg.Cycles > 0 && p.Done+1 >= p.Cfg.Cycles {
			return Long
		}
		return Rest
	default:
		return Focus
	}
}

func (p *Pomodoro) enter(ph Phase, at time.Time, run bool) {
	p.Phase = ph
	p.Total = p.Cfg.Length(ph)
	p.Left = p.Total
	p.Pauses, p.PausedFor, p.PauseStart = 0, 0, time.Time{}
	if run {
		p.Run = Running
		p.EndsAt = at.Add(p.Total)
		p.SessionStart = at
	} else {
		p.Run = Idle
		p.EndsAt = time.Time{}
		p.SessionStart = time.Time{}
	}
}

// Tick finishes phases that are due and returns what completed. When the
// program was away several auto-chained phases may have passed; each is
// reported, marked Late.
func (p *Pomodoro) Tick(now time.Time) []Event {
	var out []Event
	for guard := 0; guard < 64 && p.Run == Running && !now.Before(p.EndsAt); guard++ {
		end := p.EndsAt
		out = append(out, Event{
			Kind: p.Phase.Kind(), Start: p.SessionStart, Planned: p.Total,
			Actual: p.Total, Completed: true,
			Late: now.Sub(end) > lateAfter,
		})
		next := p.next()
		if p.Phase == Focus {
			p.Done++
		}
		if p.Phase == Long {
			p.Done = 0
		}
		// An auto-chained phase starts exactly when the last one ended, so the
		// time is continuous even after a long absence.
		p.enter(next, end, p.Cfg.AutoNext)
	}
	return out
}

// CycleDots describes the set for display: how many focus sessions are done,
// and the set length (0 when long rests are off).
func (p *Pomodoro) CycleDots() (done, total int) { return p.Done, p.Cfg.Cycles }
