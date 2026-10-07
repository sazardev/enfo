package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// ClockOrbit shows hours, minutes and seconds as three planets on concentric
// orbits around a pulsing sun, each dragging a comet tail.
type ClockOrbit struct{}

func (ClockOrbit) Name() string                { return "orbit" }
func (ClockOrbit) Step(f *ClockFrame)          {}
func (ClockOrbit) Animated(f *ClockFrame) bool { return !f.Still }

func clockPlanet(c *braille.Canvas, cx, cy, R, a, tail, rad float64, col, bg braille.RGB) {
	steps := int(math.Max(10, R*tail*0.9))
	for i := steps; i >= 1; i-- {
		k := float64(i) / float64(steps)
		x, y := braille.Polar(cx, cy, R, a-tail*k)
		c.Dot(x, y, bg.Mix(col, 1-k*0.88))
		if k < 0.5 && rad > 2.5 {
			x2, y2 := braille.Polar(cx, cy, R+1, a-tail*k)
			c.Dot(x2, y2, bg.Mix(col, 1-k*0.9))
		}
	}
	px, py := braille.Polar(cx, cy, R, a)
	c.Disc(px, py, rad+0.7, braille.Solid(bg.Mix(col, 0.45)))
	c.Disc(px, py, rad, braille.Solid(col))
	if rad >= 3 {
		c.Disc(px-rad*0.3, py-rad*0.3, rad*0.4, braille.Solid(col.Lighten(0.6)))
	}
}

func (ClockOrbit) Draw(c *braille.Canvas, f *ClockFrame) []Label {
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := math.Min(float64(c.W), float64(c.H))/2 - 3
	if R < 10 {
		return nil
	}
	pal := f.Pal
	rs, rm, rh := R*0.93, R*0.66, R*0.40
	if !f.Seconds {
		rm, rh = R*0.88, R*0.52
	}
	orbit := func(r float64, marks int, col braille.RGB) {
		n := int(2 * math.Pi * r / 2.4)
		dottedRing(c, cx, cy, r, n, 0, pal.Muted.Mix(pal.Bg, 0.5))
		for i := 0; i < marks; i++ {
			a := 2 * math.Pi * float64(i) / float64(marks)
			x, y := braille.Polar(cx, cy, r, a)
			c.Disc(x, y, 1, braille.Solid(col))
		}
	}
	orbit(rh, 12, pal.Muted.Mix(pal.Bg, 0.3))
	orbit(rm, 12, pal.Muted.Mix(pal.Bg, 0.3))
	if f.Seconds {
		orbit(rs, 12, pal.Muted.Mix(pal.Bg, 0.3))
	}

	// the sun breathes
	breath := 0.5
	if !f.Still {
		breath = (math.Sin(f.Time*2*math.Pi/3.2) + 1) / 2
	}
	sr := clamp(R*0.075, 2, 7)
	for r := sr * 3.2; r > sr*1.4; r -= 1.5 {
		k := (sr*3.2 - r) / (sr * 1.8)
		// halo as a sparse stipple around the sun
		n := int(2 * math.Pi * r / 3)
		for i := 0; i < n; i++ {
			if (i+int(r))%2 == 0 {
				continue
			}
			x, y := braille.Polar(cx, cy, r, float64(i)/float64(n)*2*math.Pi)
			c.Dot(x, y, pal.Bg.Mix(pal.Sun, (0.1+0.25*breath)*k))
		}
	}
	c.Disc(cx, cy, sr*(1+0.08*breath), braille.Solid(pal.Sun))
	c.Disc(cx-sr*0.25, cy-sr*0.25, sr*0.45, braille.Solid(pal.Sun.Lighten(0.6)))

	rad := func(k float64) float64 { return clamp(R*k, 1.8, 7) }
	clockPlanet(c, cx, cy, rh, f.hourFrac()*2*math.Pi, 0.35, rad(0.06), pal.Accent, pal.Bg)
	clockPlanet(c, cx, cy, rm, f.minFrac()*2*math.Pi, 0.7, rad(0.045), pal.Bright, pal.Bg)
	if f.Seconds {
		clockPlanet(c, cx, cy, rs, f.secFrac()*2*math.Pi, 1.25, rad(0.034), pal.RestHi, pal.Bg)
	}

	var labels []Label
	if R >= 30 && c.Rows >= 12 {
		row := int(cy+sr*3.4)/4 + 1
		labels = append(labels, Label{Col: c.Cols / 2, Row: row, Text: f.TimeText(f.Seconds) + ampmSuffix(f), Color: pal.Text, Bold: true, Center: true})
	}
	return labels
}

func ampmSuffix(f *ClockFrame) string {
	if a := f.AMPM(); a != "" {
		return " " + a
	}
	return ""
}
