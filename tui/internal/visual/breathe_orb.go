package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// breatheOrb is a glowing disc that swells with the inhale, ringed by halos
// that spread on the exhale and gather on the inhale, with dust drifting round.
type breatheOrb struct {
	dust []breatheDust
}

type breatheDust struct{ a, v, frac, ph float64 }

func (*breatheOrb) Name() string { return "orb" }

func (o *breatheOrb) Draw(c *braille.Canvas, f *BreatheFrame) {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 1.5)
	if R < 3 {
		return
	}
	col, hi := f.col(), f.hi()
	bg := f.Pal.Bg
	minR := R * 0.24
	r := minR + (R*0.62-minR)*f.Fill

	// halos: far apart when the lungs are empty, hugging the orb when full
	if R > 9 {
		gap := R * 0.075 * (0.55 + 1.0*(1-f.Fill))
		for i := 1; i <= 4; i++ {
			rr := r*1.18 + float64(i)*gap
			if rr > R {
				break
			}
			dens := 0.9 - 0.17*float64(i)
			breatheDither(c, cx, cy, rr, 1.3, dens, bg.Mix(col, 0.62-0.1*float64(i)))
		}
	}

	// dust
	if len(o.dust) == 0 {
		n := 14
		for i := 0; i < n; i++ {
			o.dust = append(o.dust, breatheDust{
				a: hash(i*31+1) * 2 * math.Pi, v: (hash(i*17+5) - 0.5) * 0.18,
				frac: hash(i*13 + 9), ph: hash(i*7+3) * 6.3,
			})
		}
	}
	for i := range o.dust {
		d := &o.dust[i]
		if !f.Still {
			d.a += d.v * f.Dt
		}
		rad := r*1.25 + (R*0.98-r*1.25)*d.frac
		if rad < r*1.1 {
			continue
		}
		x, y := braille.Polar(cx, cy, rad, d.a)
		tw := 0.5 + 0.5*math.Sin(f.ambient()*1.3+d.ph)
		if f.Still {
			tw = 0.6
		}
		c.Dot(x, y, bg.Mix(hi, 0.25+0.6*tw))
	}

	// the orb: bright core fading to a dithered soft edge
	soft := r * 1.28
	x0, x1 := breatheClampi(int(cx-soft), 0, c.W-1), breatheClampi(int(cx+soft), 0, c.W-1)
	y0, y1 := breatheClampi(int(cy-soft), 0, c.H-1), breatheClampi(int(cy+soft), 0, c.H-1)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			d := math.Hypot(dx, dy) / r
			switch {
			case d <= 1:
				// light falls from a point up-left of centre
				lx, ly := dx+r*0.28, dy+r*0.28
				t := math.Min(1, math.Hypot(lx, ly)/(r*1.15))
				c.Set(x, y, hi.Mix(col, math.Pow(t, 0.9)).Mix(bg, 0.12*t*t))
			case d <= 1.28:
				k := 1 - (d-1)/0.28
				if hash(x*7919+y*104729) < k*k*0.85 {
					c.Set(x, y, bg.Mix(col, 0.25+0.5*k))
				}
			}
		}
	}
}
