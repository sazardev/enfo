// Package theme holds Enfo's palette: one accent color picked by the user, and
// every other color derived from it so the whole interface stays coherent.
package theme

import (
	"strings"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Accent is a named accent color. Names match the Flutter app's palette.
type Accent struct {
	Name string
	RGB  braille.RGB
}

// Accents is the palette the user can pick from (same set as the mobile app).
var Accents = []Accent{
	{"lime", braille.Hex("cddc39")},
	{"lightgreen", braille.Hex("8bc34a")},
	{"green", braille.Hex("4caf50")},
	{"emerald", braille.Hex("10b981")},
	{"teal", braille.Hex("14b8a6")},
	{"cyan", braille.Hex("00bcd4")},
	{"sky", braille.Hex("0ea5e9")},
	{"lightblue", braille.Hex("03a9f4")},
	{"royal", braille.Hex("2563eb")},
	{"indigo", braille.Hex("6366f1")},
	{"violet", braille.Hex("7c3aed")},
	{"purple", braille.Hex("b04bd0")},
	{"fuchsia", braille.Hex("d946ef")},
	{"pink", braille.Hex("ec4899")},
	{"rose", braille.Hex("f43f5e")},
	{"red", braille.Hex("f44336")},
	{"deeporange", braille.Hex("ff5722")},
	{"tangerine", braille.Hex("ea580c")},
	{"orange", braille.Hex("ff9800")},
	{"honey", braille.Hex("f59e0b")},
	{"amber", braille.Hex("ffc107")},
	{"cocoa", braille.Hex("b07a52")},
	{"slate", braille.Hex("94a3b8")},
	{"white", braille.Hex("e5e7eb")},
}

// DefaultAccent is lime, like the app.
const DefaultAccent = "lime"

// Resolve turns a stored accent (a name or "#rrggbb") into a color.
func Resolve(s string) braille.RGB {
	s = strings.ToLower(strings.TrimSpace(s))
	for _, a := range Accents {
		if a.Name == s {
			return a.RGB
		}
	}
	if strings.HasPrefix(s, "#") && len(s) == 7 {
		return braille.Hex(s)
	}
	return Accents[0].RGB
}

// Index returns the position of an accent name (or 0).
func Index(name string) int {
	for i, a := range Accents {
		if a.Name == strings.ToLower(name) {
			return i
		}
	}
	return 0
}

// Palette is every color the UI uses.
type Palette struct {
	Dark bool
	Bg   braille.RGB // the terminal background (a guess until it is queried)

	Accent   braille.RGB // focus, the main color
	Bright   braille.RGB // lighter tone of the accent (glints, hands, pivots)
	Soft     braille.RGB // accent washed toward the background (tracks, fills)
	Rest     braille.RGB // rest phases: a calmer hue
	RestHi   braille.RGB
	Text     braille.RGB
	Muted    braille.RGB
	Faint    braille.RGB
	Good     braille.RGB
	Warn     braille.RGB
	Bad      braille.RGB
	Sun      braille.RGB
	Moon     braille.RGB
	Gradient braille.Gradient // accent sweep for rings
}

// New derives the palette from an accent for a dark or light terminal.
func New(accent braille.RGB, bg braille.RGB, dark bool) Palette {
	p := Palette{Dark: dark, Bg: bg, Accent: accent}
	if dark {
		p.Text = braille.Hex("ececf1")
		p.Bright = accent.Lighten(0.45)
		p.Muted = bg.Mix(p.Text, 0.55)
		p.Faint = bg.Mix(p.Text, 0.22)
		p.Soft = bg.Mix(accent, 0.2)
	} else {
		p.Text = braille.Hex("1b1b22")
		p.Bright = accent.Darken(0.25)
		p.Muted = bg.Mix(p.Text, 0.55)
		p.Faint = bg.Mix(p.Text, 0.16)
		p.Soft = bg.Mix(accent, 0.22)
	}
	p.Rest = accent.Shift(150)
	// keep rest as vivid as the accent but never muddy
	if h, s, v := p.Rest.HSV(); s < 0.45 || v < 0.6 {
		p.Rest = braille.FromHSV(h, maxf(s, 0.55), maxf(v, 0.85))
	}
	p.RestHi = p.Rest.Lighten(0.4)
	p.Good = braille.Hex("34d399")
	p.Warn = braille.Hex("fbbf24")
	p.Bad = braille.Hex("fb7185")
	p.Sun = braille.Hex("ffd166")
	p.Moon = braille.Hex("aab8ff")
	p.Gradient = braille.Gradient{accent.Shift(-28), accent, p.Bright}
	return p
}

// Phase color helper: focus uses the accent, rest the calmer hue.
func (p Palette) Phase(rest bool) braille.RGB {
	if rest {
		return p.Rest
	}
	return p.Accent
}

func (p Palette) PhaseHi(rest bool) braille.RGB {
	if rest {
		return p.RestHi
	}
	return p.Bright
}

func maxf(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}
