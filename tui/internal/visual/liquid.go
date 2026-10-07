package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Liquid is a round tank that drains as time passes, with rolling waves and
// rising bubbles.
type Liquid struct {
	bub []bubble
	t   float64
}

type bubble struct{ x, y, v, ph, r float64 }

func (*Liquid) Name() string { return "liquid" }

func (l *Liquid) Draw(c *braille.Canvas, f *Frame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 2)
	if R < 8 {
		return nil
	}
	thick := clamp(R*0.05, 1.5, 4)
	inner := R - thick - 1
	prog := clamp(f.Progress, 0, 1)
	// amount of water left; a sliver always remains until the very end
	level := cy + inner - 2*inner*(1-prog)
	amp := inner * 0.045
	if f.Still {
		amp = 0
	}
	if f.Running {
		l.t += f.Dt
	} else {
		l.t += f.Dt * 0.25
	}
	t := l.t

	deep := f.main().Darken(0.55)
	for y := int(cy - inner); y <= int(cy+inner); y++ {
		for x := int(cx - inner); x <= int(cx+inner); x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			if dx*dx+dy*dy > inner*inner {
				continue
			}
			surf := level + amp*math.Sin(float64(x)*0.19+t*2.1) + amp*0.6*math.Sin(float64(x)*0.37-t*1.4)
			fy := float64(y)
			if fy < surf {
				continue
			}
			depth := clamp((fy-surf)/(2*inner), 0, 1)
			col := f.main().Mix(deep, depth*0.85)
			if fy < surf+2.2 {
				col = f.hi()
			}
			c.Set(x, y, col)
		}
	}

	// bubbles rise from the bottom to the surface
	if len(l.bub) == 0 {
		for i := 0; i < 7; i++ {
			l.bub = append(l.bub, bubble{
				x: cx + (hash(i*3+1)-0.5)*inner*1.2, y: cy + inner*hash(i*5+2),
				v: 7 + 9*hash(i*7+3), ph: hash(i*11+4) * 6, r: 0.8 + hash(i*13+5)*1.3,
			})
		}
	}
	if f.Running && !f.Still {
		for i := range l.bub {
			b := &l.bub[i]
			b.y -= b.v * f.Dt
			b.x += math.Sin(t*2+b.ph) * 4 * f.Dt
			if b.y < level+3 || b.y < cy-inner {
				b.y = cy + inner*0.9
				b.x = cx + (hash(int(t*10)+i)-0.5)*inner*1.1
			}
		}
	}
	for _, b := range l.bub {
		dx, dy := b.x-cx, b.y-cy
		if math.Hypot(dx, dy) < inner-3 && b.y > level+2 {
			c.Arc(b.x, b.y, b.r, 1, 0, 2*math.Pi, false, braille.Solid(f.hi().Lighten(0.3)))
		}
	}

	c.Ring(cx, cy, R-thick/2, thick, braille.Solid(f.Pal.Muted.Mix(f.Pal.Bg, 0.2)))
	// a glint on the glass
	c.Arc(cx, cy, R-thick/2-3, 1.2, -1.15, -0.55, true, braille.Solid(f.Pal.Text.Mix(f.Pal.Bg, 0.45)))

	bottom := f.drawTimeOn(c, cx, cy, int(inner*1.5), int(inner*0.8), true)
	return f.subLabel(c, cx, bottom)
}

func hash(k int) float64 {
	u := uint32(k)*2654435761 + 12345
	u ^= u >> 15
	u *= 2246822519
	u ^= u >> 13
	return float64(u&0xffff) / 65535
}
