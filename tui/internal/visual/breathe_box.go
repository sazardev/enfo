package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// breatheBox is box breathing: a dot runs round a square, one side per beat,
// leaving a comet tail; a square in the centre breathes with the lungs.
type breatheBox struct{}

func (*breatheBox) Name() string { return "box" }

func (*breatheBox) Draw(c *braille.Canvas, f *BreatheFrame) {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	s := math.Min(float64(c.W), float64(c.H)) * 0.84
	if s < 8 {
		return
	}
	h := s / 2
	l, r, t, b := cx-h, cx+h, cy-h, cy+h
	col, hi := f.col(), f.hi()
	bg := f.Pal.Bg
	th := math.Max(1.2, s*0.012)

	// perimeter, starting at the bottom-left corner going up (inhale), across
	// the top (hold), down (exhale), back along the bottom (hold)
	pts := [5][2]float64{{l, b}, {l, t}, {r, t}, {r, b}, {l, b}}
	at := func(pf float64) (float64, float64) {
		pf = math.Mod(pf+4, 1) * 4
		i := int(pf)
		if i > 3 {
			i = 3
		}
		u := pf - float64(i)
		return pts[i][0] + (pts[i+1][0]-pts[i][0])*u, pts[i][1] + (pts[i+1][1]-pts[i][1])*u
	}
	// the faint track
	for i := 0; i < 4; i++ {
		c.Line(pts[i][0], pts[i][1], pts[i+1][0], pts[i+1][1], th, braille.Solid(bg.Mix(col, 0.2)))
	}
	// the corners
	for i := 0; i < 4; i++ {
		c.Disc(pts[i][0], pts[i][1], math.Max(1.6, th*1.5), braille.Solid(bg.Mix(f.Pal.Muted, 0.6)))
	}
	pf := f.Cycle
	// tail
	const tail = 0.12
	steps := int(math.Max(16, s/2))
	for i := steps; i >= 1; i-- {
		k := float64(i) / float64(steps)
		x, y := at(pf - tail*k)
		cc := bg.Mix(col, 1-k*0.9)
		c.Disc(x, y, math.Max(0.6, th*(1-0.5*k)), braille.Solid(cc))
	}
	hx, hy := at(pf)
	pulse := 0.0
	if !f.Still {
		pulse = 0.5 + 0.5*math.Sin(f.Time*3)
	}
	c.Disc(hx, hy, th*2.4+pulse*0.8, braille.Solid(bg.Mix(col, 0.5)))
	c.Disc(hx, hy, th*1.7, braille.Solid(hi.Lighten(0.4)))

	// the breathing square
	cs := s * (0.14 + 0.46*f.Fill)
	if cs > 2 {
		rad := cs * 0.22
		c.RoundRect(cx-cs/2, cy-cs/2, cs, cs, rad, func(x, y float64) braille.RGB {
			d := math.Hypot(x-cx, y-cy) / (cs * 0.72)
			return hi.Mix(col, math.Min(1, d)).Mix(bg, 0.1*d*d)
		})
	}
}
