package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// ClockDigital is big digits, a ring (here a rail) of sixty dots that fill with
// the seconds, and the date and place underneath.
type ClockDigital struct{}

func (ClockDigital) Name() string                { return "digital" }
func (ClockDigital) Step(f *ClockFrame)          {}
func (ClockDigital) Animated(f *ClockFrame) bool { return false }

func (ClockDigital) Draw(c *braille.Canvas, f *ClockFrame) []Label {
	W, H := float64(c.W), float64(c.H)
	pal := f.Pal
	small := c.Rows < 9 || c.Cols < 46
	text := f.TimeText(f.Seconds && small)

	// rows reserved under the digits: date + zone
	labelRows := 0
	if c.Rows >= 12 {
		labelRows = 2
	} else if c.Rows >= 7 {
		labelRows = 1
	}
	bar := f.Seconds && !small
	barGap, barH := 0.0, 0.0
	if bar {
		barGap, barH = 7, 3
	}
	avail := H - float64(labelRows*4) - barGap - barH - 6
	maxH := int(math.Min(avail, H*0.62))
	if maxH < 5 {
		maxH = int(math.Max(5, H-2))
		labelRows = 0
		bar = false
		barGap, barH = 0, 0
	}
	h := clockFitDigits(f.Font, text, int(W*0.9), maxH)
	block := float64(h) + barGap + barH + float64(labelRows*4)
	top := (H - block) / 2
	cy := top + float64(h)/2

	// a vertical wash from text color to a hint of the accent
	wash := func(x, y float64) braille.RGB {
		k := clamp((y-top)/float64(h), 0, 1)
		return pal.Text.Mix(pal.Accent, 0.28*k)
	}
	w := clockDrawDigits(c, f.Font, text, W/2, cy, h, wash)

	var labels []Label
	if ap := f.AMPM(); ap != "" && c.Rows >= 7 {
		col := (int(W/2) + w/2) / 2
		labels = append(labels, Label{Col: col + 1, Row: int(top) / 4, Text: ap, Color: pal.Accent, Bold: true})
	}

	if bar {
		by := top + float64(h) + barGap
		span := float64(w)
		if span < 60 {
			span = 60
		}
		x0 := W/2 - span/2
		step := span / 59
		sec := f.Now.Second()
		for i := 0; i < 60; i++ {
			x := x0 + step*float64(i)
			var col braille.RGB
			switch {
			case i < sec:
				col = pal.Accent.Mix(pal.Bg, 0.25)
				if i%5 == 0 {
					col = pal.Accent
				}
			case i == sec:
				col = pal.Bright
			default:
				col = pal.Faint.Mix(pal.Bg, 0.2)
				if i%5 == 0 {
					col = pal.Muted.Mix(pal.Bg, 0.4)
				}
			}
			rad := 0.0
			if step >= 3 {
				rad = clamp(step*0.13, 1, 2.6)
			}
			if i == sec && step >= 3 {
				rad *= 1.5
			}
			if i%5 == 0 && step >= 3 && i != sec {
				rad *= 1.25
			}
			if rad > 0 {
				c.Disc(x, by+1, rad, braille.Solid(col))
			} else {
				c.Dot(x, by+1, col)
			}
		}
	}

	if labelRows > 0 {
		row := int(top+float64(h)+barGap+barH)/4 + 1
		if f.Date != "" {
			labels = append(labels, Label{Col: c.Cols / 2, Row: row, Text: f.Date, Color: pal.Muted, Center: true})
		}
		if labelRows > 1 && f.Zone != "" {
			labels = append(labels, Label{Col: c.Cols / 2, Row: row + 1, Text: f.Zone, Color: pal.Faint.Mix(pal.Muted, 0.5), Center: true})
		}
	}
	return labels
}
