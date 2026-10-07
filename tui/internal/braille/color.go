package braille

import (
	"image/color"
	"math"
)

// RGB is an opaque truecolor value. Bubble Tea downsamples it for terminals
// that cannot show 24-bit color, so everything here can stay in RGB.
type RGB struct{ R, G, B uint8 }

// FromColor converts any image/color value (lipgloss.Color included).
func FromColor(c color.Color) RGB {
	if c == nil {
		return RGB{}
	}
	r, g, b, _ := c.RGBA()
	return RGB{uint8(r >> 8), uint8(g >> 8), uint8(b >> 8)}
}

// Hex parses "#rrggbb" (the leading # is optional).
func Hex(s string) RGB {
	if len(s) > 0 && s[0] == '#' {
		s = s[1:]
	}
	if len(s) != 6 {
		return RGB{}
	}
	var v [3]uint8
	for i := 0; i < 3; i++ {
		v[i] = hexByte(s[i*2])<<4 | hexByte(s[i*2+1])
	}
	return RGB{v[0], v[1], v[2]}
}

func hexByte(c byte) uint8 {
	switch {
	case c >= '0' && c <= '9':
		return c - '0'
	case c >= 'a' && c <= 'f':
		return c - 'a' + 10
	case c >= 'A' && c <= 'F':
		return c - 'A' + 10
	}
	return 0
}

// Color implements color.Color so an RGB can be handed straight to lipgloss.
func (c RGB) RGBA() (r, g, b, a uint32) {
	return uint32(c.R) * 0x101, uint32(c.G) * 0x101, uint32(c.B) * 0x101, 0xffff
}

func (c RGB) Hex() string {
	const h = "0123456789abcdef"
	return string([]byte{'#', h[c.R>>4], h[c.R&15], h[c.G>>4], h[c.G&15], h[c.B>>4], h[c.B&15]})
}

// Mix blends c toward o by t (0 = c, 1 = o).
func (c RGB) Mix(o RGB, t float64) RGB {
	if t <= 0 {
		return c
	}
	if t >= 1 {
		return o
	}
	return RGB{
		uint8(float64(c.R) + (float64(o.R)-float64(c.R))*t + 0.5),
		uint8(float64(c.G) + (float64(o.G)-float64(c.G))*t + 0.5),
		uint8(float64(c.B) + (float64(o.B)-float64(c.B))*t + 0.5),
	}
}

// Scale multiplies the brightness (k < 1 darkens, k > 1 brightens, clamped).
func (c RGB) Scale(k float64) RGB {
	f := func(v uint8) uint8 {
		x := float64(v) * k
		if x > 255 {
			x = 255
		}
		if x < 0 {
			x = 0
		}
		return uint8(x + 0.5)
	}
	return RGB{f(c.R), f(c.G), f(c.B)}
}

// Lighten mixes toward white, Darken toward black.
func (c RGB) Lighten(t float64) RGB { return c.Mix(RGB{255, 255, 255}, t) }
func (c RGB) Darken(t float64) RGB  { return c.Mix(RGB{0, 0, 0}, t) }

// Luma is the perceived brightness in 0..1.
func (c RGB) Luma() float64 {
	return (0.2126*float64(c.R) + 0.7152*float64(c.G) + 0.0722*float64(c.B)) / 255
}

// HSV converts to hue (0..360), saturation and value (0..1).
func (c RGB) HSV() (h, s, v float64) {
	r, g, b := float64(c.R)/255, float64(c.G)/255, float64(c.B)/255
	mx := math.Max(r, math.Max(g, b))
	mn := math.Min(r, math.Min(g, b))
	v = mx
	d := mx - mn
	if mx == 0 {
		return 0, 0, 0
	}
	s = d / mx
	switch {
	case d == 0:
		h = 0
	case mx == r:
		h = math.Mod((g-b)/d, 6)
	case mx == g:
		h = (b-r)/d + 2
	default:
		h = (r-g)/d + 4
	}
	h *= 60
	if h < 0 {
		h += 360
	}
	return
}

// FromHSV is the inverse of HSV.
func FromHSV(h, s, v float64) RGB {
	h = math.Mod(h, 360)
	if h < 0 {
		h += 360
	}
	c := v * s
	x := c * (1 - math.Abs(math.Mod(h/60, 2)-1))
	m := v - c
	var r, g, b float64
	switch {
	case h < 60:
		r, g, b = c, x, 0
	case h < 120:
		r, g, b = x, c, 0
	case h < 180:
		r, g, b = 0, c, x
	case h < 240:
		r, g, b = 0, x, c
	case h < 300:
		r, g, b = x, 0, c
	default:
		r, g, b = c, 0, x
	}
	return RGB{uint8((r+m)*255 + 0.5), uint8((g+m)*255 + 0.5), uint8((b+m)*255 + 0.5)}
}

// Shift rotates the hue by deg degrees, keeping saturation and value.
func (c RGB) Shift(deg float64) RGB {
	h, s, v := c.HSV()
	return FromHSV(h+deg, s, v)
}

// Gradient maps t in 0..1 to a color across its stops.
type Gradient []RGB

func (g Gradient) At(t float64) RGB {
	switch len(g) {
	case 0:
		return RGB{}
	case 1:
		return g[0]
	}
	if t <= 0 {
		return g[0]
	}
	if t >= 1 {
		return g[len(g)-1]
	}
	p := t * float64(len(g)-1)
	i := int(p)
	return g[i].Mix(g[i+1], p-float64(i))
}

// ColorFn gives the color of the dot at (x, y), in dot coordinates.
type ColorFn func(x, y float64) RGB

// Solid is a ColorFn that ignores position.
func Solid(c RGB) ColorFn { return func(_, _ float64) RGB { return c } }
