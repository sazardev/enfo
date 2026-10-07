package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Orbit sends a planet (with a moon and a comet tail) around a dotted path;
// two gyroscope rings turn slowly inside.
type Orbit struct{}

func (Orbit) Name() string { return "orbit" }

func dottedRing(c *braille.Canvas, cx, cy, r float64, n int, rot float64, col braille.RGB) {
	for i := 0; i < n; i++ {
		a := rot + 2*math.Pi*float64(i)/float64(n)
		x, y := braille.Polar(cx, cy, r, a)
		c.Dot(x, y, col)
	}
}

func (Orbit) Draw(c *braille.Canvas, f *Frame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 3)
	if R < 8 {
		return nil
	}
	prog := clamp(f.Progress, 0, 1)
	end := prog * 2 * math.Pi
	pr := clamp(R*0.075, 2, 6) // planet radius
	R -= pr + 1
	grad := f.grad()

	// the path: a dotted ring, brighter where the planet already was
	n := int(2 * math.Pi * R / 2.2)
	for i := 0; i < n; i++ {
		a := 2 * math.Pi * float64(i) / float64(n)
		x, y := braille.Polar(cx, cy, R, a)
		if a <= end {
			c.Dot(x, y, f.main().Mix(f.Pal.Bg, 0.45))
		} else {
			c.Dot(x, y, f.track())
		}
	}
	// hour markers
	for i := 0; i < 12; i++ {
		a := 2 * math.Pi * float64(i) / 12
		x, y := braille.Polar(cx, cy, R, a)
		col := f.Pal.Muted
		if a <= end {
			col = f.hi()
		}
		c.Disc(x, y, 1.1, braille.Solid(col))
	}

	// gyroscope
	spin := 0.0
	if !f.Still {
		spin = f.Time * 0.35
		if !f.Running {
			spin = f.Time * 0.08
		}
	}
	if R > 20 {
		dottedRing(c, cx, cy, R*0.78, int(R*0.78*2*math.Pi/4), spin, f.Pal.Faint.Mix(f.main(), 0.2))
		dottedRing(c, cx, cy, R*0.62, int(R*0.62*2*math.Pi/5), -spin*1.6, f.Pal.Faint.Mix(f.main(), 0.12))
	}

	// comet tail
	if prog > 0 {
		const tail = 0.9
		steps := 46
		for i := steps; i >= 1; i-- {
			k := float64(i) / float64(steps)
			a := end - tail*k
			if a < 0 {
				continue
			}
			x, y := braille.Polar(cx, cy, R, a)
			col := f.Pal.Bg.Mix(grad.At(a/(2*math.Pi)), 1-k*0.85)
			c.Dot(x, y, col)
			if i < steps/2 {
				x2, y2 := braille.Polar(cx, cy, R-1, a)
				c.Dot(x2, y2, col)
			}
		}
		px, py := braille.Polar(cx, cy, R, end)
		c.Disc(px, py, pr+0.6, braille.Solid(f.main().Mix(f.Pal.Bg, 0.5)))
		c.Disc(px, py, pr, braille.Solid(f.hi()))
		c.Disc(px-pr*0.3, py-pr*0.3, pr*0.45, braille.Solid(f.hi().Lighten(0.7)))
		if !f.Still {
			ma := f.Time * 3.2
			mx, my := braille.Polar(px, py, pr*2.1+1, ma)
			c.Disc(mx, my, 1, braille.Solid(f.Pal.Text))
		}
	}

	inner := R * 0.62
	bottom := f.drawTime(c, cx, cy-float64(c.H)*0.02, int(inner*1.9), int(inner))
	return f.subLabel(c, cx, bottom)
}
