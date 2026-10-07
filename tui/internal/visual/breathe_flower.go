package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// breatheFlower is a lotus: three rings of petals that bloom with the inhale and
// close with the exhale while the whole flower turns very slowly.
type breatheFlower struct{}

func (*breatheFlower) Name() string { return "flower" }

func (*breatheFlower) Draw(c *braille.Canvas, f *BreatheFrame) {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := radius(c, 1.5)
	if R < 5 {
		return
	}
	const n = 8
	sector := 2 * math.Pi / n
	open := 0.28 + 0.72*f.Fill
	main, hi := f.col(), f.hi()
	bg := f.Pal.Bg
	rot := f.ambient() * 0.06

	type layer struct {
		length, off, wid float64
		col              braille.RGB
	}
	wf := 0.19 + 0.05*f.Fill // petals widen as they open
	layers := []layer{
		{R * 0.98 * open, 0, wf, bg.Mix(f.Pal.Rest, 0.42).Mix(main, 0.2)},
		{R * 0.78 * open, sector / 2, wf * 1.02, main.Darken(0.28)},
		{R * 0.54 * open, 0, wf * 1.1, hi.Lighten(0.18)},
	}
	// the nearest three axes decide membership so neighbouring petals overlap
	// instead of clipping each other
	x0, x1 := clampiBreatheF(int(cx-R-1), c.W), clampiBreatheF(int(cx+R+1), c.W)
	y0, y1 := clampiBreatheF(int(cy-R-1), c.H), clampiBreatheF(int(cy+R+1), c.H)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			rad := math.Hypot(dx, dy)
			if rad > R || rad < 1 {
				continue
			}
			ang := math.Atan2(dx, -dy) - rot
			var out braille.RGB
			hit := false
			for _, ly := range layers {
				if ly.length < 2 {
					continue
				}
				w := ly.length * ly.wid
				base := math.Mod(ang-ly.off+4*math.Pi+sector/2, sector) - sector/2
				for k := -1; k <= 1; k++ {
					da := base + float64(k)*sector
					u, v := rad*math.Cos(da), rad*math.Sin(da)
					if u <= 0 || u >= ly.length {
						continue
					}
					// a leaf: pointed at both ends
					lim := w * math.Pow(math.Sin(math.Pi*u/ly.length), 0.8)
					e := math.Abs(v) / lim
					if e > 1 {
						continue
					}
					col := ly.col.Mix(hi, (1-u/ly.length)*0.45)
					if e > 0.8 {
						col = col.Lighten(0.35) // bright rim
					} else if e < 0.12 {
						col = col.Lighten(0.12) // midrib
					}
					out, hit = col, true
				}
			}
			if hit {
				c.Set(x, y, out)
			}
		}
	}
	core := R*0.06 + R*0.05*f.Fill
	c.Disc(cx, cy, core, braille.Solid(f.Pal.Text.Mix(hi, 0.3)))
}

func clampiBreatheF(v, n int) int {
	if v < 0 {
		return 0
	}
	if v > n-1 {
		return n - 1
	}
	return v
}
