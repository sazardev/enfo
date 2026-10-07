package visual

import (
	"math"
	"time"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// ClockFrame is everything a clock design needs to draw one frame.
type ClockFrame struct {
	Now     time.Time // local time of the frame
	Sub     float64   // fraction of the current second, 0 when motion is still
	Dt      float64
	Time    float64 // continuous animation clock, seconds
	Pal     theme.Palette
	Font    braille.Font
	Seconds bool
	H24     bool
	Still   bool

	Date      string // "Wednesday, 7 October"
	DateShort string // "WED 7"
	Zone      string // "Mexico City" or "UTC-6"

	// Sun times for the sun design, in local hours (0..24). SunReal tells if
	// they are computed for a place; Polar is +1 (midnight sun) / -1.
	Sunrise, Sunset float64
	SunReal         bool
	Polar           int
	MoonPhase       float64
}

// ClockFace is one clock design.
type ClockFace interface {
	Name() string
	Draw(c *braille.Canvas, f *ClockFrame) []Label
	// Step advances any internal animation state by f.Dt.
	Step(f *ClockFrame)
	// Animated reports whether the design needs smooth frames right now.
	Animated(f *ClockFrame) bool
}

// ClockFaceNames lists the designs in the order the user cycles through them.
var ClockFaceNames = []string{"analog", "digital", "orbit", "binary", "sun"}

// NewClockFace builds a design by name (analog if unknown).
func NewClockFace(name string) ClockFace {
	switch name {
	case "digital":
		return &ClockDigital{}
	case "orbit":
		return &ClockOrbit{}
	case "binary":
		return &ClockBinary{}
	case "sun":
		return &ClockSun{}
	}
	return &ClockAnalog{}
}

// ClockFaceFills reports whether a design wants the whole area (landscape)
// instead of a square.
func ClockFaceFills(name string) bool {
	switch name {
	case "digital", "binary", "sun":
		return true
	}
	return false
}

// Hours is the local time of day as hours (0..24), with fractions.
func (f *ClockFrame) Hours() float64 {
	n := f.Now
	return float64(n.Hour()) + float64(n.Minute())/60 + (float64(n.Second())+f.Sub)/3600
}

// secFrac is the position of the second hand over a minute, 0..1.
func (f *ClockFrame) secFrac() float64 { return (float64(f.Now.Second()) + f.Sub) / 60 }

// minFrac is the position of the minute hand over an hour, 0..1.
func (f *ClockFrame) minFrac() float64 { return (float64(f.Now.Minute()) + f.secFrac()) / 60 }

// hourFrac is the position of the hour hand over twelve hours, 0..1.
func (f *ClockFrame) hourFrac() float64 {
	return (float64(f.Now.Hour()%12) + f.minFrac()) / 12
}

// TimeText formats the time: "15:04", "15:04:05" or 12-hour "3:04" (no AM/PM).
func (f *ClockFrame) TimeText(withSeconds bool) string {
	n := f.Now
	h := n.Hour()
	if !f.H24 {
		h %= 12
		if h == 0 {
			h = 12
		}
	}
	s := clockPad2(h)
	if !f.H24 {
		s = clockItoa2(h)
	}
	s += ":" + clockPad2(n.Minute())
	if withSeconds {
		s += ":" + clockPad2(n.Second())
	}
	return s
}

func (f *ClockFrame) AMPM() string {
	if f.H24 {
		return ""
	}
	if f.Now.Hour() >= 12 {
		return "PM"
	}
	return "AM"
}

func clockPad2(n int) string {
	return string([]byte{byte('0' + n/10%10), byte('0' + n%10)})
}

func clockItoa2(n int) string {
	if n >= 10 {
		return clockPad2(n)
	}
	return string([]byte{byte('0' + n)})
}

// clockDrawDigits draws a time string with fixed-width cells so a changing
// digit never shifts its neighbours. It returns the drawn width in dots.
func clockDrawDigits(c *braille.Canvas, f braille.Font, s string, cx, cy float64, h int, fn braille.ColorFn) int {
	adv0 := f.TextWidth("00", h) - f.TextWidth("0", h)
	advColon := f.TextWidth("0:0", h) - f.TextWidth("00", h)
	adv := func(r rune) int {
		if r == ':' || r == '.' {
			return advColon
		}
		return adv0
	}
	total := 0
	for _, r := range s {
		total += adv(r)
	}
	// the last glyph has no trailing gap
	total -= adv0 - f.TextWidth("0", h)
	if total < 0 {
		total = 0
	}
	x := cx - float64(total)/2
	for _, r := range s {
		c.Text(f, string(r), x, cy-float64(h)/2, h, fn)
		x += float64(adv(r))
	}
	return total
}

// clockDigitsWidth is the width clockDrawDigits would use.
func clockDigitsWidth(f braille.Font, s string, h int) int {
	adv0 := f.TextWidth("00", h) - f.TextWidth("0", h)
	advColon := f.TextWidth("0:0", h) - f.TextWidth("00", h)
	total := 0
	for _, r := range s {
		if r == ':' || r == '.' {
			total += advColon
		} else {
			total += adv0
		}
	}
	total -= adv0 - f.TextWidth("0", h)
	return total
}

// clockFitDigits is the tallest digit height whose text fits maxW x maxH.
func clockFitDigits(f braille.Font, s string, maxW, maxH int) int {
	h := maxH
	for h > 4 && clockDigitsWidth(f, s, h) > maxW {
		h--
	}
	if h < 4 {
		h = 4
	}
	return h
}

// clockTaper fills a tapered capsule hand: it starts `tail` dots behind
// (cx, cy), points at angle a (clockwise from 12) for `length` dots, and
// narrows from width w0 at the pivot to w1 at the tip.
func clockTaper(c *braille.Canvas, cx, cy, a, length, tail, w0, w1 float64, col braille.RGB) {
	dx, dy := math.Sin(a), -math.Cos(a)
	sx, sy := cx-dx*tail, cy-dy*tail
	ex, ey := cx+dx*length, cy+dy*length
	pad := math.Max(w0, w1)/2 + 1
	x0, x1 := clockClampi(int(math.Min(sx, ex)-pad), 0, c.W-1), clockClampi(int(math.Max(sx, ex)+pad), 0, c.W-1)
	y0, y1 := clockClampi(int(math.Min(sy, ey)-pad), 0, c.H-1), clockClampi(int(math.Max(sy, ey)+pad), 0, c.H-1)
	total := tail + length
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			vx, vy := float64(x)-sx, float64(y)-sy
			s := vx*dx + vy*dy
			d := math.Abs(vx*dy - vy*dx)
			if s < -w0*0.4 || s > total+w1/2 {
				continue
			}
			var hw float64
			switch {
			case s <= tail:
				hw = w0 * 0.42
			default:
				u := clamp((s-tail)/length, 0, 1)
				hw = (w0*(1-u) + w1*u) / 2
			}
			if s < 0 || s > total {
				// rounded ends
				ex2, ey2 := sx, sy
				r := w0 * 0.42
				if s > total {
					ex2, ey2, r = ex, ey, w1/2
				}
				if math.Hypot(float64(x)-ex2, float64(y)-ey2) > r {
					continue
				}
			} else if d > hw {
				continue
			}
			c.Set(x, y, col)
		}
	}
}

func clockClampi(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

// clockTrail dithers a fading band behind angle a, between radii r0 and r1.
func clockTrail(c *braille.Canvas, cx, cy, r0, r1, a, span float64, col, bg braille.RGB) {
	x0, x1 := clockClampi(int(cx-r1-1), 0, c.W-1), clockClampi(int(cx+r1+1), 0, c.W-1)
	y0, y1 := clockClampi(int(cy-r1-1), 0, c.H-1), clockClampi(int(cy+r1+1), 0, c.H-1)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			d := math.Hypot(dx, dy)
			if d < r0 || d > r1 {
				continue
			}
			ang := math.Atan2(dx, -dy)
			if ang < 0 {
				ang += 2 * math.Pi
			}
			diff := math.Mod(a-ang+4*math.Pi, 2*math.Pi)
			if diff > span {
				continue
			}
			k := 1 - diff/span
			if hash(x*7919+y*104729) < k*k {
				c.Set(x, y, bg.Mix(col, 0.2+0.7*k))
			}
		}
	}
}
