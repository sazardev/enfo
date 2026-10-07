// Package visual draws Enfo's timer faces and clock designs in braille. A
// Visual owns whatever state its animation needs (sand grains, bubbles) and is
// asked for one frame at a time.
package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// Frame is everything a timer face needs to draw one frame.
type Frame struct {
	Progress float64 // elapsed share of the phase, 0..1
	Running  bool
	Rest     bool
	Idle     bool    // nothing started yet
	Time     float64 // seconds on a continuous animation clock
	Dt       float64 // seconds since the last frame
	Pulse    float64 // 0..1 one-off flash (start, finish), decays by itself
	Pal      theme.Palette
	Text     string // the time to show, "24:13"
	Sub      string // small caption under the time ("FOCUS", "PAUSED")
	Font     braille.Font
	Still    bool // reduced motion: no ambient animation
}

// Label is plain text placed on top of the braille, in cell coordinates.
type Label struct {
	Col, Row int
	Text     string
	Color    braille.RGB
	Bold     bool
	Center   bool // Col is the center, not the left edge
}

// Visual is one timer face.
type Visual interface {
	Name() string
	Draw(c *braille.Canvas, f *Frame) []Label
}

// Registry of timer faces, in the order the user cycles through them.
var Dials = []func() Visual{
	func() Visual { return &Ring{} },
	func() Visual { return &Orbit{} },
	func() Visual { return &Hourglass{} },
	func() Visual { return &Liquid{} },
	func() Visual { return &Radar{} },
	func() Visual { return &Spiral{} },
	func() Visual { return &Bars{} },
}

// DialNames lists the faces in order.
func DialNames() []string {
	out := make([]string, len(Dials))
	for i, d := range Dials {
		out[i] = d().Name()
	}
	return out
}

// NewDial builds a face by name (the first one if unknown).
func NewDial(name string) Visual {
	for _, d := range Dials {
		if v := d(); v.Name() == name {
			return v
		}
	}
	return Dials[0]()
}

// ----------------------------------------------------------------- shared bits

func (f *Frame) main() braille.RGB { return f.Pal.Phase(f.Rest) }
func (f *Frame) hi() braille.RGB   { return f.Pal.PhaseHi(f.Rest) }

// grad is the accent sweep for the current phase.
func (f *Frame) grad() braille.Gradient {
	m := f.main()
	return braille.Gradient{m.Darken(0.42), m, f.hi()}
}

// track is the dim color of an unfilled path.
func (f *Frame) track() braille.RGB { return f.Pal.Bg.Mix(f.main(), 0.22) }

// breath is a slow 0..1 swell (4 s period) used by ambient motion.
func (f *Frame) breath() float64 {
	if f.Still {
		return 0.5
	}
	return (math.Sin(f.Time*2*math.Pi/4) + 1) / 2
}

// blink is 1 half of the time, for "paused" cues.
func (f *Frame) blinkOn() bool {
	if f.Running || f.Idle || f.Still {
		return true
	}
	return math.Mod(f.Time, 1.4) < 0.9
}

// timeColor is the color digits are drawn in.
func (f *Frame) timeColor() braille.RGB {
	if !f.blinkOn() {
		return f.Pal.Muted
	}
	return f.Pal.Text
}

// drawTime centers the time on (cx, cy) as large as fits in maxW x maxH dots and
// returns the dot y of the digits' bottom edge.
func (f *Frame) drawTime(c *braille.Canvas, cx, cy float64, maxW, maxH int) (bottom float64) {
	return f.drawTimeOn(c, cx, cy, maxW, maxH, false)
}

// drawTimeOn is drawTime; with frost the digits sit on frosted glass (the
// layer behind stays faintly visible) instead of a clean hole.
func (f *Frame) drawTimeOn(c *braille.Canvas, cx, cy float64, maxW, maxH int, frost bool) (bottom float64) {
	h := f.Font.FitHeight(f.Text, maxW, maxH)
	if h < 5 {
		h = 5
	}
	w := f.Font.TextWidth(f.Text, h)
	// make a clean hole so whatever is behind never muddies the digits
	pad := 2
	if frost {
		c.Frost(int(cx)-w/2-pad, int(cy)-h/2-pad, w+2*pad, h+2*pad, 5)
	} else {
		c.Erase(int(cx)-w/2-pad, int(cy)-h/2-pad, w+2*pad, h+2*pad)
	}
	c.TextCentered(f.Font, f.Text, cx, cy, h, braille.Solid(f.timeColor()))
	return cy + float64(h)/2
}

// subLabel places the caption under the digits.
func (f *Frame) subLabel(c *braille.Canvas, cx, bottom float64) []Label {
	if f.Sub == "" {
		return nil
	}
	row := int(bottom)/4 + 1
	if row >= c.Rows {
		return nil
	}
	col := f.main()
	if !f.Running && !f.Idle {
		col = f.Pal.Muted
	}
	return []Label{{Col: int(cx) / 2, Row: row, Text: f.Sub, Color: col, Bold: true, Center: true}}
}

func min2(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

// radius picks the biggest circle that fits with a margin, in dots.
func radius(c *braille.Canvas, margin float64) float64 {
	return min2(float64(c.W), float64(c.H))/2 - margin
}

func clamp(v, lo, hi float64) float64 { return math.Max(lo, math.Min(hi, v)) }
