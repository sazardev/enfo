package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Bars is an equalizer: one bar per slice of the phase. Spent slices shrink to
// a stub, the live slice glows and the remaining ones dance.
type Bars struct{}

func (Bars) Name() string { return "bars" }

func (Bars) Draw(c *braille.Canvas, f *Frame) []Label {
	W, H := float64(c.W), float64(c.H)
	if W < 24 || H < 16 {
		return nil
	}
	pitch := 3.0
	n := int((W - 4) / pitch)
	if n > 60 {
		n = 60
		pitch = (W - 4) / 60
	}
	if n < 10 {
		return nil
	}
	if pitch > 4.2 {
		// stretch bars on very wide canvases instead of leaving margins
		n = int((W - 4) / 4.2)
		pitch = (W - 4) / float64(n)
	}
	barW := math.Max(1.5, pitch*0.62)
	prog := clamp(f.Progress, 0, 1)
	base := H - 2
	zone := H * 0.55 // tallest bar
	left := (W - pitch*float64(n)) / 2
	grad := f.grad()
	cur := int(prog * float64(n))
	for i := 0; i < n; i++ {
		x := left + pitch*float64(i) + (pitch-barW)/2
		frac := float64(i) / float64(n)
		var h float64
		var col braille.RGB
		switch {
		case i < cur:
			h = 3
			col = f.main().Mix(f.Pal.Bg, 0.55)
		case i == cur:
			h = zone * (0.75 + 0.2*f.breath())
			col = f.hi().Lighten(0.2)
		default:
			wave := 0.5
			if !f.Still && f.Running {
				wave += 0.28*math.Sin(f.Time*3.1+float64(i)*0.55) + 0.14*math.Sin(f.Time*5.3-float64(i)*0.9)
			} else if !f.Still {
				wave += 0.1 * math.Sin(f.Time*1.2+float64(i)*0.5)
			}
			// taller toward the live bar, like a spotlight
			near := math.Exp(-math.Abs(float64(i-cur)) / (float64(n) * 0.35))
			h = zone * clamp(wave*(0.45+0.55*near), 0.08, 1)
			col = grad.At(frac)
		}
		c.RoundRect(x, base-h, barW, h, barW/2, braille.Solid(col))
	}
	// digits float above the bars
	room := base - zone - 6
	th := int(math.Min(room*0.9, H*0.36))
	if th < 8 {
		th = 8
	}
	cy := (H - zone) / 2
	bottom := f.drawTime(c, W/2, cy, int(W*0.7), th)
	return f.subLabel(c, W/2, bottom)
}
