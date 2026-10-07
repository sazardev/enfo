package braille

import "math"

func clampi(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

// Dot lights a single dot at float coordinates (rounded to the nearest dot).
func (c *Canvas) Dot(x, y float64, col RGB) {
	c.Set(int(math.Floor(x+0.5)), int(math.Floor(y+0.5)), col)
}

// Disc fills a circle of radius r centered on (cx, cy).
func (c *Canvas) Disc(cx, cy, r float64, fn ColorFn) {
	x0, x1 := clampi(int(cx-r-1), 0, c.W-1), clampi(int(cx+r+1), 0, c.W-1)
	y0, y1 := clampi(int(cy-r-1), 0, c.H-1), clampi(int(cy+r+1), 0, c.H-1)
	r2 := r * r
	for y := y0; y <= y1; y++ {
		dy := float64(y) - cy
		for x := x0; x <= x1; x++ {
			dx := float64(x) - cx
			if dx*dx+dy*dy <= r2 {
				c.Set(x, y, fn(float64(x), float64(y)))
			}
		}
	}
}

// Ring strokes the full circle of radius r with the given thickness.
func (c *Canvas) Ring(cx, cy, r, thick float64, fn ColorFn) {
	c.Arc(cx, cy, r, thick, 0, 2*math.Pi, false, fn)
}

// Arc strokes the circle of radius r between angles a0 and a1 (radians,
// clockwise from 12 o'clock, a1 >= a0). With round set the ends are capped.
func (c *Canvas) Arc(cx, cy, r, thick, a0, a1 float64, round bool, fn ColorFn) {
	if a1 <= a0 {
		return
	}
	half := thick / 2
	out := r + half + 1
	x0, x1 := clampi(int(cx-out), 0, c.W-1), clampi(int(cx+out), 0, c.W-1)
	y0, y1 := clampi(int(cy-out), 0, c.H-1), clampi(int(cy+out), 0, c.H-1)
	full := a1-a0 >= 2*math.Pi-1e-9
	var sx, sy, ex, ey float64
	if round && !full {
		sx, sy = Polar(cx, cy, r, a0)
		ex, ey = Polar(cx, cy, r, a1)
	}
	for y := y0; y <= y1; y++ {
		dy := float64(y) - cy
		for x := x0; x <= x1; x++ {
			dx := float64(x) - cx
			d := math.Hypot(dx, dy)
			if full {
				if math.Abs(d-r) <= half {
					c.Set(x, y, fn(float64(x), float64(y)))
				}
				continue
			}
			if math.Abs(d-r) <= half {
				a := math.Atan2(dx, -dy)
				if a < 0 {
					a += 2 * math.Pi
				}
				// compare in the window [a0, a0+2pi)
				w := a - math.Mod(a0, 2*math.Pi)
				for w < 0 {
					w += 2 * math.Pi
				}
				if w <= a1-a0 {
					c.Set(x, y, fn(float64(x), float64(y)))
					continue
				}
			}
			if round {
				fx, fy := float64(x), float64(y)
				if math.Hypot(fx-sx, fy-sy) <= half || math.Hypot(fx-ex, fy-ey) <= half {
					c.Set(x, y, fn(fx, fy))
				}
			}
		}
	}
}

// Line draws a capsule (a thick segment with round ends).
func (c *Canvas) Line(x0, y0, x1, y1, thick float64, fn ColorFn) {
	half := thick / 2
	bx0, bx1 := clampi(int(math.Min(x0, x1)-half-1), 0, c.W-1), clampi(int(math.Max(x0, x1)+half+1), 0, c.W-1)
	by0, by1 := clampi(int(math.Min(y0, y1)-half-1), 0, c.H-1), clampi(int(math.Max(y0, y1)+half+1), 0, c.H-1)
	dx, dy := x1-x0, y1-y0
	l2 := dx*dx + dy*dy
	for y := by0; y <= by1; y++ {
		for x := bx0; x <= bx1; x++ {
			px, py := float64(x), float64(y)
			var t float64
			if l2 > 0 {
				t = ((px-x0)*dx + (py-y0)*dy) / l2
				if t < 0 {
					t = 0
				} else if t > 1 {
					t = 1
				}
			}
			ex, ey := px-(x0+t*dx), py-(y0+t*dy)
			if ex*ex+ey*ey <= half*half {
				c.Set(x, y, fn(px, py))
			}
		}
	}
}

// Polyline strokes consecutive segments.
func (c *Canvas) Polyline(pts [][2]float64, thick float64, fn ColorFn) {
	for i := 0; i+1 < len(pts); i++ {
		c.Line(pts[i][0], pts[i][1], pts[i+1][0], pts[i+1][1], thick, fn)
	}
}

// Rect fills the dot rectangle [x, x+w) x [y, y+h).
func (c *Canvas) Rect(x, y, w, h int, fn ColorFn) {
	for yy := y; yy < y+h; yy++ {
		for xx := x; xx < x+w; xx++ {
			c.Set(xx, yy, fn(float64(xx), float64(yy)))
		}
	}
}

// RoundRect fills a rectangle with rounded corners of radius rad.
func (c *Canvas) RoundRect(x, y, w, h, rad float64, fn ColorFn) {
	x0, x1 := clampi(int(x), 0, c.W-1), clampi(int(x+w), 0, c.W-1)
	y0, y1 := clampi(int(y), 0, c.H-1), clampi(int(y+h), 0, c.H-1)
	if rad > w/2 {
		rad = w / 2
	}
	if rad > h/2 {
		rad = h / 2
	}
	for yy := y0; yy <= y1; yy++ {
		for xx := x0; xx <= x1; xx++ {
			px, py := float64(xx)+0.5, float64(yy)+0.5
			if px < x || px > x+w || py < y || py > y+h {
				continue
			}
			// distance into the nearest corner circle
			cx := math.Min(math.Max(px, x+rad), x+w-rad)
			cy := math.Min(math.Max(py, y+rad), y+h-rad)
			if math.Hypot(px-cx, py-cy) <= rad {
				c.Set(xx, yy, fn(float64(xx), float64(yy)))
			}
		}
	}
}

// Ellipse fills an axis-aligned ellipse.
func (c *Canvas) Ellipse(cx, cy, rx, ry float64, fn ColorFn) {
	x0, x1 := clampi(int(cx-rx-1), 0, c.W-1), clampi(int(cx+rx+1), 0, c.W-1)
	y0, y1 := clampi(int(cy-ry-1), 0, c.H-1), clampi(int(cy+ry+1), 0, c.H-1)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := (float64(x)-cx)/rx, (float64(y)-cy)/ry
			if dx*dx+dy*dy <= 1 {
				c.Set(x, y, fn(float64(x), float64(y)))
			}
		}
	}
}

// Fill sets every dot where inside(x, y) is true. The general escape hatch for
// signed-distance style shapes.
func (c *Canvas) Fill(inside func(x, y float64) (RGB, bool)) {
	for y := 0; y < c.H; y++ {
		for x := 0; x < c.W; x++ {
			if col, ok := inside(float64(x), float64(y)); ok {
				c.Set(x, y, col)
			}
		}
	}
}

// Ticks draws n marks around a circle between radii r0 and r1; fn gets the
// index so marks can be colored (or skipped by returning ok=false).
func (c *Canvas) Ticks(cx, cy, r0, r1 float64, n int, thick float64, fn func(i int) (RGB, bool)) {
	for i := 0; i < n; i++ {
		col, ok := fn(i)
		if !ok {
			continue
		}
		a := 2 * math.Pi * float64(i) / float64(n)
		x0, y0 := Polar(cx, cy, r0, a)
		x1, y1 := Polar(cx, cy, r1, a)
		c.Line(x0, y0, x1, y1, thick, Solid(col))
	}
}
