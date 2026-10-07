package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// Hourglass drains sand from the top bulb into the bottom one.
type Hourglass struct{}

func (Hourglass) Name() string { return "hourglass" }

// bulb geometry helpers -------------------------------------------------

type glass struct {
	cx, cy, gh, half, neck float64
}

// halfWidth of the glass at dot row y (0 outside).
func (g glass) halfWidth(y float64) float64 {
	d := math.Abs(y - g.cy) // distance from the neck
	u := d / (g.gh / 2)
	if u > 1 {
		return 0
	}
	// smooth funnel: narrow neck, round shoulders
	s := 1 - math.Pow(1-u, 2.3)
	return g.neck + (g.half-g.neck)*math.Pow(s, 0.85)
}

// levelFor finds the row where the sand in a bulb (counting from its base)
// reaches the given share of the bulb's area.
func (g glass) levelFor(top bool, share float64) float64 {
	if share <= 0 {
		if top {
			return g.cy + 0.5
		}
		return g.cy + g.gh/2
	}
	total, acc := 0.0, 0.0
	step := 0.5
	start, end := g.cy-g.gh/2, g.cy
	if !top {
		start, end = g.cy, g.cy+g.gh/2
	}
	for y := start; y < end; y += step {
		total += g.halfWidth(y)
	}
	want := total * share
	if top {
		// sand rests on the neck: accumulate from the neck upward
		for y := end; y > start; y -= step {
			acc += g.halfWidth(y)
			if acc >= want {
				return y
			}
		}
		return start
	}
	// bottom sand rests on the base: accumulate from the base upward
	for y := end; y > start; y -= step {
		acc += g.halfWidth(y)
		if acc >= want {
			return y
		}
	}
	return start
}

func (Hourglass) Draw(c *braille.Canvas, f *Frame) []Label {
	W, H := float64(c.W), float64(c.H)
	wide := W >= H*1.7
	var g glass
	var tx, ty float64
	var tw, th int
	if wide {
		g.gh = H - 6
		g.cx = W * 0.3
		tx, ty = W*0.68, H/2
		tw, th = int(W*0.5), int(H*0.5)
	} else {
		g.gh = math.Min(H*0.74, W*1.5)
		g.cx = W / 2
		tx, ty = W/2, H-H*0.1
		tw, th = int(W*0.9), int(H*0.14)
	}
	g.half = g.gh * 0.3
	g.neck = math.Max(1.2, g.gh*0.018)
	if wide {
		g.cy = H / 2
	} else {
		g.cy = 3 + g.gh/2
	}
	if g.gh < 14 {
		return nil
	}
	prog := clamp(f.Progress, 0, 1)
	sand := f.main()
	sandHi := f.hi()
	glassCol := f.Pal.Muted.Mix(f.Pal.Bg, 0.25)

	top, bot := g.cy-g.gh/2, g.cy+g.gh/2
	lvTop := g.levelFor(true, 1-prog)
	lvBot := g.levelFor(false, prog)

	// sand in the top bulb
	for y := int(lvTop); y < int(g.cy); y++ {
		hw := g.halfWidth(float64(y)) - 2
		for x := int(g.cx - hw); x <= int(g.cx+hw); x++ {
			// a tiny funnel in the surface where the sand drains
			dip := 0.0
			if f.Running && prog < 1 {
				dx := math.Abs(float64(x)-g.cx) / math.Max(hw, 1)
				dip = (1 - dx) * 2
			}
			if float64(y) < lvTop+dip {
				continue
			}
			k := (float64(y) - lvTop) / math.Max(g.gh/2-(lvTop-top), 1)
			c.Set(x, y, sand.Mix(f.Pal.Bg, 0.1+0.3*clamp(k, 0, 1)*0.5))
		}
	}
	// sand in the bottom bulb, with a mound under the stream
	mound := 0.0
	if prog > 0 && prog < 1 {
		mound = math.Min(g.gh*0.07, 5)
	}
	for y := int(lvBot - mound); y < int(bot-1); y++ {
		hw := g.halfWidth(float64(y)) - 2
		for x := int(g.cx - hw); x <= int(g.cx+hw); x++ {
			dx := math.Abs(float64(x) - g.cx)
			m := mound * math.Max(0, 1-dx/(g.half*0.8))
			if float64(y) < lvBot-m {
				continue
			}
			k := (float64(y) - (lvBot - mound)) / math.Max(bot-(lvBot-mound), 1)
			c.Set(x, y, sand.Mix(f.Pal.Bg, 0.05+0.25*(1-clamp(k, 0, 1))*0.4).Mix(sandHi, 0.12*(1-k)))
		}
	}
	// the falling stream
	if f.Running && prog < 1 {
		surf := lvBot - mound
		span := surf - g.cy
		if span > 2 {
			for y := g.cy - 2; y < surf; y++ {
				ph := math.Mod((y-g.cy)+f.Time*55, 5)
				if ph < 3.2 || f.Still {
					c.Dot(g.cx, y, sandHi)
					if g.gh > 40 {
						c.Dot(g.cx+1, y, sand)
					}
				}
			}
		}
	}

	// glass outline: left and right walls, plus the two plates
	var left, right [][2]float64
	for y := top; y <= bot; y += 1.5 {
		hw := g.halfWidth(y)
		left = append(left, [2]float64{g.cx - hw, y})
		right = append(right, [2]float64{g.cx + hw, y})
	}
	c.Polyline(left, 1.4, braille.Solid(glassCol))
	c.Polyline(right, 1.4, braille.Solid(glassCol))
	plate := g.half + 3
	c.Line(g.cx-plate, top-1, g.cx+plate, top-1, 2.2, braille.Solid(f.Pal.Muted))
	c.Line(g.cx-plate, bot+1, g.cx+plate, bot+1, 2.2, braille.Solid(f.Pal.Muted))

	c.Erase(int(tx)-tw/2-2, int(ty)-th/2-2, tw+4, th+4)
	bottom := f.drawTime(c, tx, ty-3, tw, th)
	return f.subLabel(c, tx, bottom)
}
