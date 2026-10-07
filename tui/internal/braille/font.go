package braille

import "math"

// Font draws big text out of dots. Three families ship: a smooth stroke font
// that scales to any size, a dot-matrix "LED" font and a seven-segment one.
type Font int

const (
	FontLine Font = iota // smooth strokes
	FontLED              // 5x7 dot matrix, every pixel a round dot
	FontSeg              // seven-segment display
	fontCount
)

// Fonts is the number of digit fonts, for cycling through them.
const Fonts = int(fontCount)

func (f Font) String() string {
	switch f {
	case FontLED:
		return "led"
	case FontSeg:
		return "seg"
	default:
		return "line"
	}
}

// ParseFont turns a stored name back into a Font (unknown -> FontLine).
func ParseFont(s string) Font {
	switch s {
	case "led":
		return FontLED
	case "seg":
		return FontSeg
	}
	return FontLine
}

// glyph advance as a fraction of the text height.
const (
	digitW = 0.58
	gapW   = 0.2
	colonW = 0.2
)

func (f Font) advance(r rune, h float64) float64 {
	switch r {
	case ':', '.', ',', '\'':
		w := colonW
		if f == FontLED {
			w = 0.16
		}
		return w*h + gapW*h
	case ' ':
		return 0.35 * h
	}
	w := digitW
	if f == FontLED {
		w = 5.0 / 7.0 // 5 columns over 7 rows
	}
	return w*h + gapW*h
}

// TextWidth is the width in dots of s at the given height.
func (f Font) TextWidth(s string, h int) int {
	if h < 1 {
		return 0
	}
	w := 0.0
	n := 0
	for _, r := range s {
		w += f.advance(r, float64(h))
		n++
	}
	if n > 0 {
		w -= gapW * float64(h) // no trailing gap
		if f == FontLED {
			// the LED font already ends on a dot, trim to taste
			_ = w
		}
	}
	return int(math.Ceil(w))
}

// FitHeight is the tallest text height that makes s fit within maxW dots.
func (f Font) FitHeight(s string, maxW, maxH int) int {
	h := maxH
	for h > 4 && f.TextWidth(s, h) > maxW {
		h--
	}
	return h
}

// Text draws s with its top-left at (x, y), h dots tall, and returns the width.
func (c *Canvas) Text(f Font, s string, x, y float64, h int, fn ColorFn) int {
	fh := float64(h)
	cur := x
	for _, r := range s {
		f.glyph(c, r, cur, y, fh, fn)
		cur += f.advance(r, fh)
	}
	return f.TextWidth(s, h)
}

// TextCentered draws s centered on (cx, cy).
func (c *Canvas) TextCentered(f Font, s string, cx, cy float64, h int, fn ColorFn) {
	w := float64(f.TextWidth(s, h))
	c.Text(f, s, cx-w/2, cy-float64(h)/2, h, fn)
}

func (f Font) glyph(c *Canvas, r rune, x, y, h float64, fn ColorFn) {
	switch f {
	case FontLED:
		ledGlyph(c, r, x, y, h, fn)
	case FontSeg:
		segGlyph(c, r, x, y, h, fn)
	default:
		lineGlyph(c, r, x, y, h, fn)
	}
}

// ------------------------------------------------------------------ line font

type pt = [2]float64

// bez samples a cubic bezier.
func bez(p0, p1, p2, p3 pt, n int) []pt {
	out := make([]pt, 0, n+1)
	for i := 0; i <= n; i++ {
		t := float64(i) / float64(n)
		u := 1 - t
		out = append(out, pt{
			u*u*u*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t*t*t*p3[0],
			u*u*u*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t*t*t*p3[1],
		})
	}
	return out
}

// arcPts samples an ellipse arc; angles are clockwise from 12 o'clock.
func arcPts(cx, cy, rx, ry, a0, a1 float64, n int) []pt {
	out := make([]pt, 0, n+1)
	for i := 0; i <= n; i++ {
		a := a0 + (a1-a0)*float64(i)/float64(n)
		out = append(out, pt{cx + rx*math.Sin(a), cy - ry*math.Cos(a)})
	}
	return out
}

func join(parts ...[]pt) []pt {
	var out []pt
	for _, p := range parts {
		out = append(out, p...)
	}
	return out
}

const deg = math.Pi / 180

// Glyph strokes live in a box W wide (digitW) and 1 tall, y down.
var lineStrokes = func() map[rune][][]pt {
	w := digitW
	r := w / 2
	m := map[rune][][]pt{}

	// 0: a stadium.
	m['0'] = [][]pt{join(
		arcPts(r, r, r, r, -90*deg, 90*deg, 14),
		arcPts(r, 1-r, r, r, 90*deg, 270*deg, 14),
		[]pt{{0, r}},
	)}
	// 1: flag and stem.
	m['1'] = [][]pt{{{0.04, 0.2}, {w * 0.5, 0}, {w * 0.5, 1}}}
	// 2
	m['2'] = [][]pt{join(
		arcPts(r, r*1.05, r, r*1.05, -75*deg, 145*deg, 16),
		[]pt{{0, 1}, {w, 1}},
	)}
	// 3
	m['3'] = [][]pt{
		join(
			arcPts(r, 0.25, r*0.97, 0.25, -65*deg, 180*deg, 16),
			arcPts(r, 0.75, r, 0.25, 0*deg, 245*deg, 18),
		),
	}
	// 4
	m['4'] = [][]pt{
		{{w * 0.72, 1}, {w * 0.72, 0}, {0, 0.68}, {w, 0.68}},
	}
	// 5
	m['5'] = [][]pt{join(
		[]pt{{w * 0.94, 0}, {w * 0.1, 0}, {w * 0.02, 0.45}},
		bez(pt{w * 0.02, 0.45}, pt{w * 0.3, 0.36}, pt{w, 0.38}, pt{w, 0.7}, 10),
		bez(pt{w, 0.7}, pt{w, 1.02}, pt{w * 0.3, 1.04}, pt{0, 0.86}, 10),
	)}
	// 6
	m['6'] = [][]pt{
		join(
			bez(pt{w * 0.92, 0.06}, pt{w * 0.5, -0.04}, pt{0, 0.16}, pt{0, 0.66}, 14),
			[]pt{{0, 1 - r}},
		),
		arcPts(r, 1-r, r, r, 0, 360*deg, 24),
	}
	// 7
	m['7'] = [][]pt{{{0, 0}, {w, 0}, {w * 0.3, 1}}}
	// 8
	m['8'] = [][]pt{
		arcPts(r, 0.25, r*0.9, 0.25, 0, 360*deg, 22),
		arcPts(r, 0.75, r, 0.25, 0, 360*deg, 24),
	}
	// 9: a 6 turned half a revolution.
	m['9'] = rot180(m['6'], w)
	m['-'] = [][]pt{{{w * 0.1, 0.5}, {w * 0.9, 0.5}}}
	m['/'] = [][]pt{{{w * 0.9, 0}, {w * 0.1, 1}}}
	return m
}()

func rot180(strokes [][]pt, w float64) [][]pt {
	out := make([][]pt, len(strokes))
	for i, s := range strokes {
		o := make([]pt, len(s))
		for j, p := range s {
			o[j] = pt{w - p[0], 1 - p[1]}
		}
		out[i] = o
	}
	return out
}

func lineGlyph(c *Canvas, r rune, x, y, h float64, fn ColorFn) {
	thick := math.Max(1.6, h*0.115)
	switch r {
	case ':':
		cx := x + colonW*h/2
		rad := math.Max(1.2, thick*0.62)
		c.Disc(cx, y+h*0.3, rad, fn)
		c.Disc(cx, y+h*0.7, rad, fn)
		return
	case '.', ',':
		c.Disc(x+colonW*h/2, y+h-thick*0.6, math.Max(1.2, thick*0.62), fn)
		return
	case '\'':
		c.Line(x+0.05*h, y, x+0.02*h, y+h*0.22, thick*0.8, fn)
		return
	case ' ':
		return
	}
	strokes, ok := lineStrokes[r]
	if !ok {
		return
	}
	// keep strokes fully inside the glyph box
	inset := thick / 2
	sx, sy := h-thick, h-thick
	for _, s := range strokes {
		pts := make([][2]float64, len(s))
		for i, p := range s {
			pts[i] = [2]float64{x + inset + p[0]/1*sx, y + inset + p[1]*sy}
		}
		c.Polyline(pts, thick, fn)
	}
}

// ------------------------------------------------------------------- LED font

// 5x7 dot-matrix bitmaps, one string row per line.
var ledBitmaps = map[rune][7]string{
	'0': {".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."},
	'1': {"..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."},
	'2': {".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"},
	'3': {".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."},
	'4': {"...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."},
	'5': {"#####", "#....", "####.", "....#", "....#", "#...#", ".###."},
	'6': {"..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."},
	'7': {"#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."},
	'8': {".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."},
	'9': {".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."},
	'-': {".....", ".....", ".....", "#####", ".....", ".....", "....."},
	'/': {"....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."},
}

func ledGlyph(c *Canvas, r rune, x, y, h float64, fn ColorFn) {
	pitch := h / 7
	rad := math.Max(0.55, pitch*0.46)
	dot := func(col, row float64) {
		cx, cy := x+(col+0.5)*pitch, y+(row+0.5)*pitch
		if rad < 0.9 {
			c.Dot(cx, cy, fn(cx, cy))
			return
		}
		c.Disc(cx, cy, rad, fn)
	}
	switch r {
	case ':':
		dot(0.4, 2)
		dot(0.4, 5)
		return
	case '.', ',':
		dot(0.4, 6)
		return
	case ' ':
		return
	}
	bm, ok := ledBitmaps[r]
	if !ok {
		return
	}
	for row, line := range bm {
		for col, ch := range line {
			if ch == '#' {
				dot(float64(col), float64(row))
			}
		}
	}
}

// ------------------------------------------------------------- seven-segment

// bits: a top, b top-right, c bottom-right, d bottom, e bottom-left,
// f top-left, g middle.
var segDigits = map[rune]uint8{
	'0': 0b0111111, '1': 0b0000110, '2': 0b1011011, '3': 0b1001111,
	'4': 0b1100110, '5': 0b1101101, '6': 0b1111101, '7': 0b0000111,
	'8': 0b1111111, '9': 0b1101111, '-': 0b1000000,
}

func segGlyph(c *Canvas, r rune, x, y, h float64, fn ColorFn) {
	t := math.Max(1.8, h*0.13)
	switch r {
	case ':':
		cx := x + colonW*h/2
		c.Disc(cx, y+h*0.32, t*0.62, fn)
		c.Disc(cx, y+h*0.68, t*0.62, fn)
		return
	case '.', ',':
		c.Disc(x+colonW*h/2, y+h-t*0.6, t*0.62, fn)
		return
	case ' ':
		return
	}
	bits, ok := segDigits[r]
	if !ok {
		return
	}
	w := digitW * h
	g := t * 0.35 // gap between segments
	l, rgt := x+t/2, x+w-t/2
	top, mid, bot := y+t/2, y+h/2, y+h-t/2
	hseg := func(yy float64) {
		c.Line(l+t*0.6+g, yy, rgt-t*0.6-g, yy, t, fn)
	}
	vseg := func(xx, y0, y1 float64) {
		c.Line(xx, y0+t*0.6+g, xx, y1-t*0.6-g, t, fn)
	}
	if bits&0b0000001 != 0 {
		hseg(top)
	}
	if bits&0b0000010 != 0 {
		vseg(rgt, top, mid)
	}
	if bits&0b0000100 != 0 {
		vseg(rgt, mid, bot)
	}
	if bits&0b0001000 != 0 {
		hseg(bot)
	}
	if bits&0b0010000 != 0 {
		vseg(l, mid, bot)
	}
	if bits&0b0100000 != 0 {
		vseg(l, top, mid)
	}
	if bits&0b1000000 != 0 {
		hseg(mid)
	}
}
