package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/braille"
)

// breatheWaves is a tide: layered sine waves that rise and swell with the
// inhale and sink flat with the exhale, edge to edge.
type breatheWaves struct{}

func (*breatheWaves) Name() string { return "waves" }

func (*breatheWaves) Draw(c *braille.Canvas, f *BreatheFrame) {
	W, H := float64(c.W), float64(c.H)
	if c.W < 6 || c.H < 6 {
		return
	}
	const layers = 5
	t := f.ambient()
	bg := f.Pal.Bg
	for i := 0; i < layers; i++ {
		frac := float64(i) / (layers - 1) // 0 back .. 1 front
		// the water climbs the screen with the inhale; the back layers ride higher
		level := H * (0.80 - 0.50*f.Fill - (1-frac)*0.07)
		amp := H * (0.012 + 0.05*f.Fill) * (0.6 + 0.4*frac)
		k := 2 * math.Pi / (W * (0.95 - 0.13*float64(i)))
		omega := 0.32 + 0.11*float64(i)
		if i%2 == 1 {
			omega = -omega
		}
		ph := float64(i) * 1.9
		base := f.Pal.Rest.Mix(f.Pal.Accent, f.Fill*(0.35+0.65*frac))
		body := bg.Mix(base, 0.16+0.34*frac)
		crest := bg.Mix(base, 0.45+0.55*frac).Lighten(0.12 * frac)
		prevY := 0.0
		for x := 0; x < c.W; x++ {
			fx := float64(x)
			ys := level + amp*math.Sin(k*fx+omega*t+ph) + amp*0.22*math.Sin(2.1*k*fx-0.8*omega*t)
			// the body of the water: dense at the crest, thinning to the floor
			for y := int(ys) + 1; y < c.H; y++ {
				d := float64(y) - ys
				dens := 0.7*math.Exp(-d/(H*0.14)) + 0.02
				if hash(x*7919+y*104729+i*31) < dens*(0.45+0.55*frac) {
					c.Set(x, y, body)
				}
			}
			if x > 0 {
				c.Line(fx-1, prevY, fx, ys, 1.3, braille.Solid(crest))
			}
			prevY = ys
		}
	}
}
