package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// StopwatchMark is a lap dot on the minute ring. Frac is where on the ring
// (0..1 of a minute); Kind 0 is a normal lap, 1 the fastest, 2 the slowest.
type StopwatchMark struct {
	Frac float64
	Kind int
}

// StopwatchFace is a minute sweep: a comet circles the ring once a minute,
// leaving a fading trail; laps stay behind as dots and a tiny centisecond
// bead spins inside. Frame.Progress is the share of the current minute.
type StopwatchFace struct {
	Marks []StopwatchMark
}

func (*StopwatchFace) Name() string { return "stopwatch" }

func (s *StopwatchFace) Draw(c *braille.Canvas, f *Frame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 2)
	if R < 6 {
		return nil
	}
	thick := clamp(R*0.07, 2, 6)
	if R > 22 {
		R -= thick*0.5 + 5
	}
	prog := clamp(f.Progress, 0, 0.99999)
	end := prog * 2 * math.Pi
	main, hi := f.main(), f.hi()

	// ticks: one per second, the passed ones lit
	if R > 18 {
		c.Ticks(cx, cy, R+thick/2+2.5, R+thick/2+4.5, 60, 1, func(i int) (braille.RGB, bool) {
			passed := float64(i)/60 <= prog
			long := i%5 == 0
			switch {
			case passed && long:
				return hi, true
			case passed:
				return main.Mix(f.Pal.Bg, 0.4), true
			case long:
				return f.Pal.Muted.Mix(f.Pal.Bg, 0.35), true
			}
			return f.Pal.Faint.Mix(f.Pal.Bg, 0.25), true
		})
	}

	c.Ring(cx, cy, R, thick, braille.Solid(f.track()))

	// the trail behind the head fades from bright to nothing
	const trail = 1.9
	if f.Running || prog > 0 {
		c.Arc(cx, cy, R, thick, 0, 2*math.Pi, false, func(x, y float64) braille.RGB {
			a := braille.Angle(cx, cy, x, y)
			d := end - a
			if d < 0 {
				d += 2 * math.Pi
			}
			if d > trail {
				return f.track()
			}
			k := 1 - d/trail
			col := f.track().Mix(main, math.Pow(k, 0.8))
			return col.Mix(hi.Lighten(0.3), math.Pow(k, 6))
		})
	}
	// comet head
	hx, hy := braille.Polar(cx, cy, R, end)
	if f.Running || f.Pulse > 0 {
		halo := thick * (1.8 + 0.5*f.breath())
		for dy := -halo; dy <= halo; dy++ {
			for dx := -halo; dx <= halo; dx++ {
				d := math.Hypot(dx, dy)
				if d > halo || d < thick*0.7 || (int(hx+dx)+int(hy+dy))&1 != 0 {
					continue
				}
				c.Dot(hx+dx, hy+dy, f.Pal.Bg.Mix(hi, 0.15+0.4*(1-d/halo)+0.3*f.Pulse))
			}
		}
	}
	c.Disc(hx, hy, thick*0.62, braille.Solid(hi.Lighten(0.55)))

	// lap dots sit on the ring
	for _, m := range s.Marks {
		col := f.Pal.Text
		switch m.Kind {
		case 1:
			col = f.Pal.Good
		case 2:
			col = f.Pal.Bad
		}
		x, y := braille.Polar(cx, cy, R, m.Frac*2*math.Pi)
		c.Disc(x, y, math.Max(1.2, thick*0.5), braille.Solid(col))
	}

	// the centisecond bead: once around per second on an inner ring
	innerR := R - thick/2 - 4
	if innerR > 14 {
		for i := 0; i < 40; i++ {
			a := 2 * math.Pi * float64(i) / 40
			x, y := braille.Polar(cx, cy, innerR, a)
			c.Dot(x, y, f.Pal.Faint.Mix(main, 0.12))
		}
		if !f.Still {
			cs := math.Mod(prog*60, 1)
			bx, by := braille.Polar(cx, cy, innerR, cs*2*math.Pi)
			c.Disc(bx, by, 1.4, braille.Solid(main.Mix(hi, 0.4)))
		}
		innerR -= 6
	}

	bottom := f.drawTime(c, cx, cy-float64(c.H)*0.02, int(innerR*1.85), int(innerR*0.8))
	return f.subLabel(c, cx, bottom)
}
