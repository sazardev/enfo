package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Spiral winds the elapsed time outward along a spiral track.
type Spiral struct{}

func (Spiral) Name() string { return "spiral" }

func (Spiral) Draw(c *braille.Canvas, f *Frame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 3)
	if R < 12 {
		return nil
	}
	const turns = 3.0
	r0 := R * 0.4
	thick := clamp(R*0.05, 1.6, 4)
	total := turns * 2 * math.Pi
	prog := clamp(f.Progress, 0, 1)
	grad := f.grad()
	pt := func(th float64) (float64, float64) {
		r := r0 + (R-thick)*(th/total)
		return braille.Polar(cx, cy, r, th)
	}
	steps := int(R * 7)
	var prev [2]float64
	prev[0], prev[1] = pt(0)
	for i := 1; i <= steps; i++ {
		th := total * float64(i) / float64(steps)
		x, y := pt(th)
		var col braille.RGB
		if float64(i)/float64(steps) <= prog {
			col = grad.At(float64(i) / float64(steps))
			// glow near the head
			d := prog - float64(i)/float64(steps)
			if d < 0.05 {
				col = col.Mix(f.hi().Lighten(0.4), 1-d/0.05)
			}
		} else {
			col = f.track()
		}
		c.Line(prev[0], prev[1], x, y, thick, braille.Solid(col))
		prev = [2]float64{x, y}
	}
	if prog > 0 {
		hx, hy := pt(total * prog)
		c.Disc(hx, hy, thick*0.9, braille.Solid(f.hi().Lighten(0.5)))
		if f.Running && !f.Still {
			c.Arc(hx, hy, thick*(1.8+0.8*f.breath()), 1, 0, 2*math.Pi, false, braille.Solid(f.main().Mix(f.Pal.Bg, 0.4)))
		}
	}
	bottom := f.drawTime(c, cx, cy, int(r0*1.5), int(r0*0.8))
	return f.subLabel(c, cx, bottom)
}
