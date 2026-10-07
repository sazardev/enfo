// Package braille draws on a grid of Unicode braille cells. Each terminal cell
// holds 2x4 dots, so a canvas of C columns by R rows has a dot resolution of
// 2C x 4R. In a terminal where a cell is about twice as tall as it is wide the
// dots are square, which is what makes circles look like circles.
//
// A braille cell can only show one foreground color, so every cell carries a
// single RGB: dots drawn into it later win the cell's color.
package braille

import (
	"math"
	"strconv"
	"strings"
)

// dotBit maps (x&1, y&3) to the bit of the braille pattern (U+2800 + mask).
var dotBit = [2][4]uint8{
	{0x01, 0x02, 0x04, 0x40},
	{0x08, 0x10, 0x20, 0x80},
}

// Canvas is a grid of braille cells.
type Canvas struct {
	Cols, Rows int // size in terminal cells
	W, H       int // size in dots
	bits       []uint8
	col        []RGB
}

// New makes a canvas that fills cols x rows terminal cells.
func New(cols, rows int) *Canvas {
	if cols < 0 {
		cols = 0
	}
	if rows < 0 {
		rows = 0
	}
	return &Canvas{
		Cols: cols, Rows: rows,
		W: cols * 2, H: rows * 4,
		bits: make([]uint8, cols*rows),
		col:  make([]RGB, cols*rows),
	}
}

// Clear erases every dot.
func (c *Canvas) Clear() {
	for i := range c.bits {
		c.bits[i] = 0
	}
}

// Resize reallocates only when the size actually changed, and always clears.
func (c *Canvas) Resize(cols, rows int) {
	if cols == c.Cols && rows == c.Rows {
		c.Clear()
		return
	}
	*c = *New(cols, rows)
}

// Set lights the dot at (x, y) and colors its cell. Out of range is ignored.
func (c *Canvas) Set(x, y int, col RGB) {
	if x < 0 || y < 0 || x >= c.W || y >= c.H {
		return
	}
	i := (y>>2)*c.Cols + x>>1
	c.bits[i] |= dotBit[x&1][y&3]
	c.col[i] = col
}

// SetBits ORs a raw braille mask into the cell (cx, cy) with a color.
func (c *Canvas) SetBits(cx, cy int, mask uint8, col RGB) {
	if cx < 0 || cy < 0 || cx >= c.Cols || cy >= c.Rows || mask == 0 {
		return
	}
	i := cy*c.Cols + cx
	c.bits[i] |= mask
	c.col[i] = col
}

// Unset turns the dot at (x, y) off.
func (c *Canvas) Unset(x, y int) {
	if x < 0 || y < 0 || x >= c.W || y >= c.H {
		return
	}
	c.bits[(y>>2)*c.Cols+x>>1] &^= dotBit[x&1][y&3]
}

// Has reports whether the dot at (x, y) is lit.
func (c *Canvas) Has(x, y int) bool {
	if x < 0 || y < 0 || x >= c.W || y >= c.H {
		return false
	}
	return c.bits[(y>>2)*c.Cols+x>>1]&dotBit[x&1][y&3] != 0
}

// CellColor returns the color a cell is painted with.
func (c *Canvas) CellColor(cx, cy int) RGB {
	if cx < 0 || cy < 0 || cx >= c.Cols || cy >= c.Rows {
		return RGB{}
	}
	return c.col[cy*c.Cols+cx]
}

// Tint recolors every lit cell with fn evaluated at the cell's center. Handy
// for washing a finished drawing in a gradient.
func (c *Canvas) Tint(fn ColorFn) {
	for cy := 0; cy < c.Rows; cy++ {
		for cx := 0; cx < c.Cols; cx++ {
			i := cy*c.Cols + cx
			if c.bits[i] != 0 {
				c.col[i] = fn(float64(cx*2+1), float64(cy*4+2))
			}
		}
	}
}

// Fade multiplies the color of every lit cell (used to dim a background layer).
func (c *Canvas) Fade(k float64) {
	for i := range c.bits {
		if c.bits[i] != 0 {
			c.col[i] = c.col[i].Scale(k)
		}
	}
}

// Blit copies the lit cells of src onto c with its top-left at cell (cx, cy).
// Cells of src that are empty leave c untouched, so layers stack.
func (c *Canvas) Blit(src *Canvas, cx, cy int) {
	for y := 0; y < src.Rows; y++ {
		for x := 0; x < src.Cols; x++ {
			s := y*src.Cols + x
			if src.bits[s] == 0 {
				continue
			}
			tx, ty := cx+x, cy+y
			if tx < 0 || ty < 0 || tx >= c.Cols || ty >= c.Rows {
				continue
			}
			d := ty*c.Cols + tx
			c.bits[d] = src.bits[s]
			c.col[d] = src.col[s]
		}
	}
}

// Empty reports whether no dot is lit.
func (c *Canvas) Empty() bool {
	for _, b := range c.bits {
		if b != 0 {
			return false
		}
	}
	return true
}

// Lines renders each row as an ANSI string. Runs of the same color share one
// escape sequence and empty cells are plain spaces, so the terminal's own
// background shows through.
func (c *Canvas) Lines() []string {
	out := make([]string, c.Rows)
	var sb strings.Builder
	for cy := 0; cy < c.Rows; cy++ {
		sb.Reset()
		var cur RGB
		on := false
		for cx := 0; cx < c.Cols; cx++ {
			i := cy*c.Cols + cx
			b := c.bits[i]
			if b == 0 {
				sb.WriteByte(' ')
				continue
			}
			if !on || c.col[i] != cur {
				cur = c.col[i]
				on = true
				sb.WriteString("\x1b[38;2;")
				sb.WriteString(strconv.Itoa(int(cur.R)))
				sb.WriteByte(';')
				sb.WriteString(strconv.Itoa(int(cur.G)))
				sb.WriteByte(';')
				sb.WriteString(strconv.Itoa(int(cur.B)))
				sb.WriteByte('m')
			}
			sb.WriteRune(rune(0x2800) + rune(b))
		}
		if on {
			sb.WriteString("\x1b[39m")
		}
		out[cy] = sb.String()
	}
	return out
}

// String joins Lines with newlines.
func (c *Canvas) String() string { return strings.Join(c.Lines(), "\n") }

// Plain renders without color (for tests and debugging); empty cells are
// U+2800 so alignment is visible.
func (c *Canvas) Plain() string {
	var sb strings.Builder
	for cy := 0; cy < c.Rows; cy++ {
		if cy > 0 {
			sb.WriteByte('\n')
		}
		for cx := 0; cx < c.Cols; cx++ {
			sb.WriteRune(rune(0x2800) + rune(c.bits[cy*c.Cols+cx]))
		}
	}
	return sb.String()
}

// ---------------------------------------------------------------- polar helpers

// Polar returns the dot at distance r from (cx, cy) at angle a, where a is in
// radians measured clockwise from 12 o'clock (the way clocks think).
func Polar(cx, cy, r, a float64) (x, y float64) {
	return cx + r*math.Sin(a), cy - r*math.Cos(a)
}

// Angle is the inverse of Polar's angle: clockwise from 12 o'clock, 0..2pi.
func Angle(cx, cy, x, y float64) float64 {
	a := math.Atan2(x-cx, -(y - cy))
	if a < 0 {
		a += 2 * math.Pi
	}
	return a
}

// Erase clears the dot rectangle [x, x+w) x [y, y+h) (a hole for text).
func (c *Canvas) Erase(x, y, w, h int) {
	for yy := y; yy < y+h; yy++ {
		for xx := x; xx < x+w; xx++ {
			c.Unset(xx, yy)
		}
	}
}

// EraseDisc clears every dot within r of (cx, cy).
func (c *Canvas) EraseDisc(cx, cy, r float64) {
	x0, x1 := clampi(int(cx-r-1), 0, c.W-1), clampi(int(cx+r+1), 0, c.W-1)
	y0, y1 := clampi(int(cy-r-1), 0, c.H-1), clampi(int(cy+r+1), 0, c.H-1)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			if dx*dx+dy*dy <= r*r {
				c.Unset(x, y)
			}
		}
	}
}

// Frost thins the dots in a rectangle to a sparse stipple (keep one dot in
// every `keep`), so text drawn on top stands out while the layer behind still
// shows through, like frosted glass.
func (c *Canvas) Frost(x, y, w, h, keep int) {
	for yy := y; yy < y+h; yy++ {
		for xx := x; xx < x+w; xx++ {
			if (xx+2*yy)%keep != 0 {
				c.Unset(xx, yy)
			}
		}
	}
}
