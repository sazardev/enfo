package engine

import (
	"math"
	"time"
)

type BreathePhase int

const (
	Inhale BreathePhase = iota
	HoldFull
	Exhale
	HoldEmpty
)

// Pattern is a breathing rhythm in seconds.
type Pattern struct {
	ID                                  string
	Inhale, HoldFull, Exhale, HoldEmpty int
}

var Patterns = []Pattern{
	{"box", 4, 4, 4, 4},
	{"478", 4, 7, 8, 0},
	{"coherent", 5, 0, 5, 0},
	{"calm", 4, 0, 6, 0},
}

func PatternByID(id string) Pattern {
	for _, p := range Patterns {
		if p.ID == id {
			return p
		}
	}
	return Patterns[0]
}

func (p Pattern) Cycle() time.Duration {
	return time.Duration(p.Inhale+p.HoldFull+p.Exhale+p.HoldEmpty) * time.Second
}

func (p Pattern) Timings() string {
	s := ""
	for _, n := range []int{p.Inhale, p.HoldFull, p.Exhale, p.HoldEmpty} {
		if n > 0 {
			if s != "" {
				s += "-"
			}
			s += itoa(n)
		}
	}
	return s
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b [8]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	return string(b[i:])
}

// BreathePoint is where a session is at one instant.
type BreathePoint struct {
	Phase    BreathePhase
	Breath   int           // breaths completed
	Fill     float64       // lungs, 0 empty .. 1 full
	PhaseLen time.Duration // length of the current beat
	Into     time.Duration // time into the current beat
}

func (b BreathePoint) Left() time.Duration { return b.PhaseLen - b.Into }

// At returns the point after elapsed time. Inhale and exhale ease like real
// breath; holds stay put.
func (p Pattern) At(elapsed time.Duration) BreathePoint {
	cyc := p.Cycle()
	if cyc <= 0 || elapsed < 0 {
		return BreathePoint{}
	}
	breath := int(elapsed / cyc)
	t := elapsed % cyc
	beats := [4]struct {
		ph BreathePhase
		d  time.Duration
	}{
		{Inhale, time.Duration(p.Inhale) * time.Second},
		{HoldFull, time.Duration(p.HoldFull) * time.Second},
		{Exhale, time.Duration(p.Exhale) * time.Second},
		{HoldEmpty, time.Duration(p.HoldEmpty) * time.Second},
	}
	for _, b := range beats {
		if b.d == 0 {
			continue
		}
		if t < b.d {
			f := 0.0
			x := float64(t) / float64(b.d)
			ease := (1 - math.Cos(math.Pi*x)) / 2
			switch b.ph {
			case Inhale:
				f = ease
			case HoldFull:
				f = 1
			case Exhale:
				f = 1 - ease
			}
			return BreathePoint{Phase: b.ph, Breath: breath, Fill: f, PhaseLen: b.d, Into: t}
		}
		t -= b.d
	}
	return BreathePoint{Breath: breath}
}
