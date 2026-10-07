package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Radar sweeps a fading dithered beam over a scope and lights blips as it
// passes; the elapsed time is a thin ring around the scope.
type Radar struct{}

func (Radar) Name() string { return "radar" }

type blip struct{ a, r float64 }

var blips = func() []blip {
	out := make([]blip, 9)
	for i := range out {
		out[i] = blip{a: hash(i*17+1) * 2 * math.Pi, r: 0.25 + 0.7*hash(i*29+7)}
	}
	return out
}()

func (Radar) Draw(c *braille.Canvas, f *Frame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 2)
	if R < 10 {
		return nil
	}
	prog := clamp(f.Progress, 0, 1)
	ringT := clamp(R*0.04, 1.4, 3)
	scope := R - ringT - 3

	// progress ring
	c.Ring(cx, cy, R-ringT/2, ringT, braille.Solid(f.track()))
	if prog > 0 {
		grad := f.grad()
		end := prog * 2 * math.Pi
		c.Arc(cx, cy, R-ringT/2, ringT, 0, end, true, func(x, y float64) braille.RGB {
			return grad.At(braille.Angle(cx, cy, x, y) / (2 * math.Pi))
		})
	}

	// scope rings and crosshair
	faint := f.Pal.Faint.Mix(f.Pal.Bg, 0.1)
	for _, k := range []float64{1, 0.66, 0.33} {
		n := int(2 * math.Pi * scope * k / 3)
		dottedRing(c, cx, cy, scope*k, n, 0, faint)
	}
	for i := 0; i < 4; i++ {
		a := float64(i) * math.Pi / 2
		x0, y0 := braille.Polar(cx, cy, scope*0.12, a)
		x1, y1 := braille.Polar(cx, cy, scope, a)
		for s := 0.0; s <= 1; s += 3 / math.Max(scope, 1) {
			c.Dot(x0+(x1-x0)*s, y0+(y1-y0)*s, faint)
		}
	}

	sweep := 0.0
	if !f.Still {
		sweep = math.Mod(f.Time*2*math.Pi/5, 2*math.Pi)
		if !f.Running {
			sweep = math.Mod(f.Time*2*math.Pi/14, 2*math.Pi)
		}
	} else {
		sweep = math.Pi / 3
	}
	// the beam: dither density falls off behind the leading edge
	const trail = 1.25
	x0, x1 := int(cx-scope), int(cx+scope)
	y0, y1 := int(cy-scope), int(cy+scope)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			d := math.Hypot(dx, dy)
			if d > scope || d < 2 {
				continue
			}
			a := math.Atan2(dx, -dy)
			if a < 0 {
				a += 2 * math.Pi
			}
			diff := math.Mod(sweep-a+4*math.Pi, 2*math.Pi)
			if diff > trail {
				continue
			}
			k := 1 - diff/trail
			if hash(x*7919+y*104729) < k*k*0.9 {
				c.Set(x, y, f.Pal.Bg.Mix(f.hi(), 0.25+0.7*k))
			}
		}
	}
	// the leading edge
	ex, ey := braille.Polar(cx, cy, scope, sweep)
	c.Line(cx, cy, ex, ey, 1, braille.Solid(f.hi()))

	// blips
	for _, b := range blips {
		diff := math.Mod(sweep-b.a+4*math.Pi, 2*math.Pi)
		k := 1 - diff/(2*math.Pi)
		if f.Still {
			k = 0.5
		}
		if k < 0.35 {
			continue
		}
		x, y := braille.Polar(cx, cy, scope*b.r, b.a)
		c.Disc(x, y, 1+1.3*k, braille.Solid(f.Pal.Bg.Mix(f.hi(), k)))
	}

	bottom := f.drawTime(c, cx, cy, int(scope*1.2), int(scope*0.65))
	return f.subLabel(c, cx, bottom)
}
