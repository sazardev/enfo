package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// ClockAnalog is a braille dial: sixty ticks, tapered hands, a sweeping second
// hand with a fading trail and a counterweight, a pivot cap, a date window.
type ClockAnalog struct{}

func (ClockAnalog) Name() string                { return "analog" }
func (ClockAnalog) Step(f *ClockFrame)          {}
func (ClockAnalog) Animated(f *ClockFrame) bool { return f.Seconds && !f.Still }

func (ClockAnalog) Draw(c *braille.Canvas, f *ClockFrame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := math.Min(float64(c.W), float64(c.H))/2 - 2
	if R < 6 {
		return nil
	}
	pal := f.Pal
	big := R > 18

	// the face: a faint rim, minute dots, hour bars, accented quarters
	if big {
		c.Ring(cx, cy, R, 1, braille.Solid(pal.Faint.Mix(pal.Bg, 0.3)))
	}
	for i := 0; i < 60; i++ {
		a := 2 * math.Pi * float64(i) / 60
		switch {
		case i%15 == 0:
			x0, y0 := braille.Polar(cx, cy, R*0.80, a)
			x1, y1 := braille.Polar(cx, cy, R*0.97, a)
			c.Line(x0, y0, x1, y1, clamp(R*0.045, 1.6, 4), braille.Solid(pal.Accent))
		case i%5 == 0:
			x0, y0 := braille.Polar(cx, cy, R*0.86, a)
			x1, y1 := braille.Polar(cx, cy, R*0.97, a)
			c.Line(x0, y0, x1, y1, clamp(R*0.03, 1.2, 3), braille.Solid(pal.Text.Mix(pal.Bg, 0.1)))
		case big:
			x, y := braille.Polar(cx, cy, R*0.955, a)
			c.Dot(x, y, pal.Muted.Mix(pal.Bg, 0.1))
		}
	}

	// the second hand's trail first, so the hands sit on top of it
	sa := f.secFrac() * 2 * math.Pi
	if f.Seconds && big {
		clockTrail(c, cx, cy, R*0.62, R*0.76, sa, 0.9, pal.Accent, pal.Bg)
	}

	// date window under the pivot is a label; hands are drawn over the dots
	hw := clamp(R*0.105, 2.4, 8)
	clockTaper(c, cx, cy, f.hourFrac()*2*math.Pi, R*0.5, R*0.1, hw, hw*0.55, pal.Text)
	mw := clamp(R*0.075, 2, 6)
	clockTaper(c, cx, cy, f.minFrac()*2*math.Pi, R*0.78, R*0.12, mw, mw*0.5, pal.Text.Mix(pal.Bg, 0.08))

	if f.Seconds {
		sw := clamp(R*0.018, 1, 2)
		x0, y0 := braille.Polar(cx, cy, -R*0.2, sa)
		x1, y1 := braille.Polar(cx, cy, R*0.92, sa)
		c.Line(x0, y0, x1, y1, sw, braille.Solid(pal.Bright))
		// counterweight
		tx, ty := braille.Polar(cx, cy, -R*0.2, sa)
		c.Disc(tx, ty, clamp(R*0.035, 1.2, 3.5), braille.Solid(pal.Bright))
	}
	// pivot cap
	pr := clamp(R*0.055, 1.6, 5)
	c.Disc(cx, cy, pr, braille.Solid(pal.Accent))
	if pr >= 3 {
		c.Disc(cx, cy, pr*0.45, braille.Solid(pal.Bright))
	}

	var labels []Label
	if big && c.Rows >= 12 && f.DateShort != "" {
		row := int(cy+R*0.46) / 4
		labels = append(labels, Label{Col: int(cx) / 2, Row: row, Text: f.DateShort, Color: pal.Muted, Center: true})
	}
	return labels
}
