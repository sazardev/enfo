package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// BreatheFrame is what a breathing visual needs to draw one frame.
type BreatheFrame struct {
	Fill      float64 // lungs, 0 empty .. 1 full (already eased)
	Phase     engine.BreathePhase
	PhaseProg float64 // progress through the current beat, 0..1
	Cycle     float64 // progress through the whole breath, 0..1
	Running   bool
	Time      float64 // continuous seconds, for ambient motion
	Dt        float64
	Pal       theme.Palette
	Still     bool // reduced motion: no ambient animation
}

// col is the color of the moment: calm rest hue when empty, accent when full.
func (f *BreatheFrame) col() braille.RGB { return f.Pal.Rest.Mix(f.Pal.Accent, f.Fill) }

func (f *BreatheFrame) hi() braille.RGB { return f.Pal.RestHi.Mix(f.Pal.Bright, f.Fill) }

// ambient is the clock ambient motion runs on (frozen when motion is reduced).
func (f *BreatheFrame) ambient() float64 {
	if f.Still {
		return 0
	}
	return f.Time
}

// BreatheVisual is one breathing face.
type BreatheVisual interface {
	Name() string
	Draw(c *braille.Canvas, f *BreatheFrame)
}

// BreatheVisuals is the registry, in the order the user cycles through.
var BreatheVisuals = []func() BreatheVisual{
	func() BreatheVisual { return &breatheOrb{} },
	func() BreatheVisual { return &breatheFlower{} },
	func() BreatheVisual { return &breatheWaves{} },
	func() BreatheVisual { return &breatheBox{} },
}

// BreatheVisualNames lists the faces in order.
func BreatheVisualNames() []string {
	out := make([]string, len(BreatheVisuals))
	for i, v := range BreatheVisuals {
		out[i] = v().Name()
	}
	return out
}

// NewBreatheVisual builds a face by name (the first one if unknown).
func NewBreatheVisual(name string) BreatheVisual {
	for _, v := range BreatheVisuals {
		if b := v(); b.Name() == name {
			return b
		}
	}
	return BreatheVisuals[0]()
}

// BreatheWantsFill says whether a face wants the whole area (wide) rather than
// a centered square.
func BreatheWantsFill(v BreatheVisual) bool { return v.Name() == "waves" }

// breatheDither lights dots of an annulus with the given density (0..1).
func breatheDither(c *braille.Canvas, cx, cy, r, thick, dens float64, col braille.RGB) {
	if dens <= 0 {
		return
	}
	out := r + thick/2 + 1
	x0, x1 := breatheClampi(int(cx-out), 0, c.W-1), breatheClampi(int(cx+out), 0, c.W-1)
	y0, y1 := breatheClampi(int(cy-out), 0, c.H-1), breatheClampi(int(cy+out), 0, c.H-1)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			d := math.Hypot(float64(x)-cx, float64(y)-cy)
			if math.Abs(d-r) <= thick/2 && hash(x*7919+y*104729) < dens {
				c.Set(x, y, col)
			}
		}
	}
}

func breatheClampi(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}
