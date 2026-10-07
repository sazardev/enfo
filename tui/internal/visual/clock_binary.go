package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// ClockBinary is a binary-coded-decimal dot clock: one column per digit, one
// disc per bit. Discs glow in and fade out instead of snapping.
type ClockBinary struct {
	level  [6][4]float64
	target [6][4]float64
	primed bool
}

func (*ClockBinary) Name() string { return "binary" }

var clockBinBits = [6]int{2, 4, 3, 4, 3, 4}

func (b *ClockBinary) digits(f *ClockFrame) [6]int {
	h := f.Now.Hour()
	if !f.H24 {
		h %= 12
		if h == 0 {
			h = 12
		}
	}
	m, s := f.Now.Minute(), f.Now.Second()
	return [6]int{h / 10, h % 10, m / 10, m % 10, s / 10, s % 10}
}

func (b *ClockBinary) Step(f *ClockFrame) {
	d := b.digits(f)
	for col := 0; col < 6; col++ {
		for bit := 0; bit < 4; bit++ {
			t := 0.0
			if d[col]>>(3-bit)&1 == 1 {
				t = 1
			}
			b.target[col][bit] = t
			if !b.primed || f.Still {
				b.level[col][bit] = t
				continue
			}
			k := 1 - math.Exp(-f.Dt*11)
			b.level[col][bit] += (t - b.level[col][bit]) * k
		}
	}
	b.primed = true
}

func (b *ClockBinary) Animated(f *ClockFrame) bool {
	if f.Still {
		return false
	}
	for col := range b.level {
		for bit := range b.level[col] {
			if math.Abs(b.level[col][bit]-b.target[col][bit]) > 0.02 {
				return true
			}
		}
	}
	return false
}

func (b *ClockBinary) Draw(c *braille.Canvas, f *ClockFrame) []Label {
	W, H := float64(c.W), float64(c.H)
	pal := f.Pal
	if !b.primed {
		b.Step(f)
	}
	ncols := 6
	if !f.Seconds {
		ncols = 4
	}
	// layout: pairs of columns with a wider gap between pairs
	pairs := ncols / 2
	units := float64(ncols) + 0.7*float64(pairs-1) // in pitches
	showText := c.Rows >= 10
	gridH := H * 0.9
	if showText {
		gridH = H * 0.62
	}
	pitch := math.Min((W-8)/units, gridH/4)
	if pitch < 4 {
		pitch = math.Max(2.5, math.Min((W-2)/units, H/4.4))
	}
	gridW := pitch * units
	left := (W - gridW) / 2
	blockH := pitch * 4
	textH := 0
	if showText {
		textH = int(clamp(H*0.2, 8, 40))
	}
	total := blockH + float64(textH) + 8
	top := (H - total) / 2
	if top < 1 {
		top = 1
	}

	groupCol := [3]braille.RGB{pal.Accent, pal.Bright, pal.RestHi}
	var labels []Label
	for col := 0; col < ncols; col++ {
		pair := col / 2
		x := left + pitch*(float64(col)+0.5) + 0.7*pitch*float64(pair)
		gc := groupCol[pair]
		for bit := 0; bit < 4; bit++ {
			// only the bits a digit can use are shown (tens digits are shorter)
			if bit < 4-clockBinBits[col] {
				continue
			}
			y := top + pitch*(float64(bit)+0.5)
			v := b.level[col][bit]
			r := pitch * 0.34
			if pitch < 5 {
				r = math.Max(1, pitch*0.36)
			}
			// the unlit socket
			c.Disc(x, y, math.Max(0.8, r*0.28), braille.Solid(pal.Faint.Mix(pal.Bg, 0.1)))
			if v > 0.03 {
				if v > 0.4 && pitch >= 6 {
					// halo
					for a := 0; a < 14; a++ {
						ang := float64(a) / 14 * 2 * math.Pi
						hx, hy := braille.Polar(x, y, r*1.45, ang)
						if a%2 == 0 {
							c.Dot(hx, hy, pal.Bg.Mix(gc, 0.22*v))
						}
					}
				}
				c.Disc(x, y, r*(0.35+0.65*v), braille.Solid(pal.Bg.Mix(gc, 0.25+0.75*v)))
			}
		}
	}
	// bit weights on the left edge
	if c.Rows >= 12 && left >= 8 {
		for bit := 0; bit < 4; bit++ {
			y := top + pitch*(float64(bit)+0.5)
			labels = append(labels, Label{Col: int(left)/2 - 2, Row: int(y) / 4, Text: clockItoaBin(8 >> bit), Color: pal.Faint.Mix(pal.Muted, 0.4)})
		}
	}
	if showText {
		ty := top + blockH + 8 + float64(textH)/2
		text := f.TimeText(f.Seconds)
		h := clockFitDigits(f.Font, text, int(gridW), textH)
		clockDrawDigits(c, f.Font, text, W/2, ty, h, braille.Solid(pal.Text.Mix(pal.Bg, 0.1)))
		if ap := f.AMPM(); ap != "" {
			labels = append(labels, Label{Col: (int(W/2)+clockDigitsWidth(f.Font, text, h)/2)/2 + 1, Row: int(ty-float64(h)/2) / 4, Text: ap, Color: pal.Accent, Bold: true})
		}
	}
	return labels
}

func clockItoaBin(n int) string { return string([]byte{byte('0' + n)}) }
