package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Ring is the signature face: a track, a gradient arc that grows, a glowing
// comet at its head, a halo of ticks and a breathing inner ring.
type Ring struct{}

func (Ring) Name() string { return "ring" }

func (Ring) Draw(c *braille.Canvas, f *Frame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 2)
	if R < 6 {
		return nil
	}
	thick := clamp(R*0.075, 2, 7)
	// leave room for ticks outside the ring on bigger dials
	ticks := R > 22
	if ticks {
		R -= thick*0.5 + 5
	}
	prog := clamp(f.Progress, 0, 1)
	grad := f.grad()
	track := f.track()

	if ticks {
		out0, out1 := R+thick/2+2.5, R+thick/2+4.5
		c.Ticks(cx, cy, out0, out1, 60, 1, func(i int) (braille.RGB, bool) {
			frac := float64(i) / 60
			long := i%5 == 0
			switch {
			case frac < prog:
				if long {
					return f.hi(), true
				}
				return f.main().Mix(f.Pal.Bg, 0.35), true
			case long:
				return f.Pal.Muted.Mix(f.Pal.Bg, 0.35), true
			default:
				return f.Pal.Faint.Mix(f.Pal.Bg, 0.25), true
			}
		})
	}

	c.Ring(cx, cy, R, thick, braille.Solid(track))

	if prog > 0 {
		end := prog * 2 * math.Pi
		glowLen := 0.55 // radians of bright tail behind the head
		c.Arc(cx, cy, R, thick, 0, end, true, func(x, y float64) braille.RGB {
			a := braille.Angle(cx, cy, x, y)
			if a > end+0.3 { // cap near 12 o'clock wraps
				a = 0
			}
			col := grad.At(a / (2 * math.Pi) * 1.0)
			// brighten toward the head
			d := end - a
			if d >= 0 && d < glowLen {
				col = col.Mix(f.hi().Lighten(0.35), math.Pow(1-d/glowLen, 1.6))
			}
			return col
		})
		// comet head
		hx, hy := braille.Polar(cx, cy, R, end)
		halo := thick * (1.9 + 0.5*f.breath())
		if f.Running || f.Pulse > 0 {
			for dy := -halo; dy <= halo; dy++ {
				for dx := -halo; dx <= halo; dx++ {
					d := math.Hypot(dx, dy)
					if d > halo || d < thick*0.7 {
						continue
					}
					if (int(hx+dx)+int(hy+dy))&1 == 0 {
						k := 1 - d/halo
						c.Dot(hx+dx, hy+dy, f.Pal.Bg.Mix(f.hi(), 0.18+0.45*k+0.3*f.Pulse))
					}
				}
			}
		}
		c.Disc(hx, hy, thick*0.62, braille.Solid(f.hi().Lighten(0.55)))
	}

	// the inner ring breathes while running
	innerR := R - thick/2 - 4
	if innerR > 14 {
		sway := 0.0
		if f.Running && !f.Still {
			sway = 1.6 * math.Sin(f.Time*2*math.Pi/4)
		}
		col := f.Pal.Faint.Mix(f.main(), 0.18+0.25*f.breath())
		if f.Running {
			c.Arc(cx, cy, innerR+sway, 1, 0, 2*math.Pi, false, braille.Solid(col))
		} else {
			// dashed when stopped
			for i := 0; i < 48; i += 2 {
				a0 := 2 * math.Pi * float64(i) / 48
				a1 := 2 * math.Pi * float64(i+1) / 48
				c.Arc(cx, cy, innerR, 1, a0, a1, false, braille.Solid(col))
			}
		}
		innerR -= 6
	}

	bottom := f.drawTime(c, cx, cy-float64(c.H)*0.02, int(innerR*1.75), int(innerR*0.9))
	return f.subLabel(c, cx, bottom)
}
