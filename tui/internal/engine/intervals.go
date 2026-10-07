package engine

import (
	"time"
)

// IntervalsKind labels the history events of interval workouts.
const IntervalsKind Kind = "intervals"

// IntervalsPhase is one kind of segment of a workout.
type IntervalsPhase string

const (
	IntervalsWarm  IntervalsPhase = "warm"
	IntervalsWork  IntervalsPhase = "work"
	IntervalsRest  IntervalsPhase = "rest"
	IntervalsCool  IntervalsPhase = "cool"
	IntervalsReady IntervalsPhase = "ready" // before the start / after the end
)

// IsRest reports whether the phase is a calm one.
func (p IntervalsPhase) IsRest() bool { return p == IntervalsRest || p == IntervalsCool }

// IntervalsPlan describes a workout: warm-up, N rounds of work/rest, cool-down.
// Ramp makes every round's work Ramp longer than the one before (a pyramid
// going up). The last round has no rest after it.
type IntervalsPlan struct {
	Warm   time.Duration `json:"warm"`
	Work   time.Duration `json:"work"`
	Rest   time.Duration `json:"rest"`
	Cool   time.Duration `json:"cool"`
	Rounds int           `json:"rounds"`
	Ramp   time.Duration `json:"ramp,omitempty"`
}

// IntervalsPresets are the built-in workouts.
var IntervalsPresets = []struct {
	ID   string
	Plan IntervalsPlan
}{
	{"tabata", IntervalsPlan{Work: 20 * time.Second, Rest: 10 * time.Second, Rounds: 8, Warm: 0, Cool: 0}},
	{"hiit", IntervalsPlan{Work: 40 * time.Second, Rest: 20 * time.Second, Rounds: 10, Warm: time.Minute}},
	{"emom", IntervalsPlan{Work: time.Minute, Rest: 0, Rounds: 10}},
	{"pyramid", IntervalsPlan{Work: 30 * time.Second, Rest: 15 * time.Second, Rounds: 6, Ramp: 10 * time.Second}},
}

// Normalize clamps the plan to sane values.
func (p *IntervalsPlan) Normalize() {
	clampD := func(d, lo, hi time.Duration) time.Duration {
		if d < lo {
			return lo
		}
		if d > hi {
			return hi
		}
		return d
	}
	p.Warm = clampD(p.Warm, 0, 10*time.Minute)
	p.Cool = clampD(p.Cool, 0, 10*time.Minute)
	p.Rest = clampD(p.Rest, 0, 10*time.Minute)
	p.Work = clampD(p.Work, 5*time.Second, 10*time.Minute)
	p.Ramp = clampD(p.Ramp, 0, time.Minute)
	if p.Rounds < 1 {
		p.Rounds = 1
	}
	if p.Rounds > 99 {
		p.Rounds = 99
	}
}

// WorkAt is the length of round r's work (1-based).
func (p IntervalsPlan) WorkAt(r int) time.Duration {
	if r < 1 {
		r = 1
	}
	return p.Work + time.Duration(r-1)*p.Ramp
}

// IntervalsSeg is one segment of the workout timeline.
type IntervalsSeg struct {
	Phase IntervalsPhase
	Round int // 1-based for work/rest, 0 otherwise
	Start time.Duration
	Len   time.Duration
}

func (s IntervalsSeg) End() time.Duration { return s.Start + s.Len }

// Segments lays the workout out on a timeline.
func (p IntervalsPlan) Segments() []IntervalsSeg {
	var out []IntervalsSeg
	var at time.Duration
	add := func(ph IntervalsPhase, r int, l time.Duration) {
		if l <= 0 {
			return
		}
		out = append(out, IntervalsSeg{Phase: ph, Round: r, Start: at, Len: l})
		at += l
	}
	add(IntervalsWarm, 0, p.Warm)
	for r := 1; r <= p.Rounds; r++ {
		add(IntervalsWork, r, p.WorkAt(r))
		if r < p.Rounds {
			add(IntervalsRest, r, p.Rest)
		}
	}
	add(IntervalsCool, 0, p.Cool)
	return out
}

// Total is the whole workout's length.
func (p IntervalsPlan) Total() time.Duration {
	segs := p.Segments()
	if len(segs) == 0 {
		return 0
	}
	return segs[len(segs)-1].End()
}

// IntervalsPoint is where a workout is at one instant.
type IntervalsPoint struct {
	Seg     IntervalsSeg
	Index   int // index in Segments, len(segs) when done
	Next    *IntervalsSeg
	Into    time.Duration // time into the segment
	Left    time.Duration // time left in the segment
	Elapsed time.Duration
	Total   time.Duration
	Rounds  int
	Done    bool
}

// Progress is the share of the current segment that has passed.
func (pt IntervalsPoint) Progress() float64 {
	if pt.Seg.Len <= 0 {
		return 0
	}
	return float64(pt.Into) / float64(pt.Seg.Len)
}

// At returns the point after elapsed workout time.
func (p IntervalsPlan) At(elapsed time.Duration) IntervalsPoint {
	segs := p.Segments()
	total := p.Total()
	pt := IntervalsPoint{Elapsed: elapsed, Total: total, Rounds: p.Rounds}
	if len(segs) == 0 {
		pt.Done = true
		pt.Seg = IntervalsSeg{Phase: IntervalsReady}
		return pt
	}
	if elapsed < 0 {
		elapsed = 0
	}
	if elapsed >= total {
		pt.Done, pt.Index, pt.Elapsed = true, len(segs), total
		pt.Seg = IntervalsSeg{Phase: IntervalsReady, Start: total}
		return pt
	}
	for i, s := range segs {
		if elapsed < s.End() {
			pt.Index, pt.Seg = i, s
			pt.Into = elapsed - s.Start
			pt.Left = s.End() - elapsed
			if i+1 < len(segs) {
				n := segs[i+1]
				pt.Next = &n
			}
			return pt
		}
	}
	return pt
}

// IntervalsRun is a workout in progress. It stores the instant it (virtually)
// started, so it stays exact while hidden and after a restart.
type IntervalsRun struct {
	Plan    IntervalsPlan `json:"plan"`
	Run     Run           `json:"run"`
	Started time.Time     `json:"started,omitempty"` // running: elapsed = now - Started
	Accum   time.Duration `json:"accum"`             // paused: elapsed so far
	Since   time.Time     `json:"since,omitempty"`   // first start of this workout
}

func (r *IntervalsRun) idle() bool { return r.Run != Running && r.Run != Paused }

func (r *IntervalsRun) Active() bool { return !r.idle() }

// Elapsed is the workout time at now.
func (r *IntervalsRun) Elapsed(now time.Time) time.Duration {
	switch r.Run {
	case Running:
		return clampDur(now.Sub(r.Started), 0)
	case Paused:
		return r.Accum
	}
	return 0
}

// Point is the workout's state at now (the first segment when idle).
func (r *IntervalsRun) Point(now time.Time) IntervalsPoint { return r.Plan.At(r.Elapsed(now)) }

func (r *IntervalsRun) Toggle(now time.Time) {
	switch {
	case r.idle():
		if r.Plan.Total() <= 0 {
			return
		}
		r.Run, r.Started, r.Accum, r.Since = Running, now, 0, now
	case r.Run == Running:
		r.Accum = now.Sub(r.Started)
		r.Run = Paused
	case r.Run == Paused:
		r.Run, r.Started = Running, now.Add(-r.Accum)
	}
}

// Skip jumps to the start of the next segment.
func (r *IntervalsRun) Skip(now time.Time) {
	if r.idle() {
		return
	}
	pt := r.Point(now)
	if pt.Done {
		return
	}
	delta := pt.Left
	if r.Run == Running {
		r.Started = r.Started.Add(-delta)
	} else {
		r.Accum += delta
	}
}

// Label describes the plan for history entries, "20s/10s x8".
func (p IntervalsPlan) Label() string {
	return fmtShort(p.Work) + "/" + fmtShort(p.Rest) + " x" + itoa(p.Rounds)
}

func fmtShort(d time.Duration) string {
	s := int(d / time.Second)
	if s%60 == 0 && s > 0 {
		return itoa(s/60) + "m"
	}
	return itoa(s) + "s"
}

// Reset stops the workout; it reports the abandoned run when long enough.
func (r *IntervalsRun) Reset(now time.Time) []Event {
	var ev []Event
	if !r.idle() && !r.Since.IsZero() {
		if a := r.Elapsed(now); a >= 20*time.Second {
			ev = []Event{{Kind: IntervalsKind, Label: r.Plan.Label(), Start: r.Since, Planned: r.Plan.Total(), Actual: a}}
		}
	}
	r.Run, r.Accum, r.Started, r.Since = Idle, 0, time.Time{}, time.Time{}
	return ev
}

// Tick finishes the workout when it is over and reports it.
func (r *IntervalsRun) Tick(now time.Time) []Event {
	if r.Run != Running {
		return nil
	}
	total := r.Plan.Total()
	end := r.Started.Add(total)
	if now.Before(end) {
		return nil
	}
	ev := Event{Kind: IntervalsKind, Label: r.Plan.Label(), Start: r.Since, Planned: total, Actual: total,
		Completed: true, Late: now.Sub(end) > lateAfter}
	r.Run, r.Accum, r.Started, r.Since = Idle, 0, time.Time{}, time.Time{}
	return []Event{ev}
}
