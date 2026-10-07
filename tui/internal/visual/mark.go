package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
)

// Mark draws the Enfo logo, a lowercase "e": a ring open at the lower right
// whose crossbar is the clock hand, with a pivot at the centre. Geometry mirrors
// the app icon (ring radius 140 and stroke 52 in a 332-unit box).
//
// t plays the build, 0..1: the dial sketches itself, the pivot pops in and the
// hand shoots out to meet the ring. At 1 it is the finished logo.
func Mark(c *braille.Canvas, cx, cy, size float64, t float64, ring, tint braille.RGB, bg braille.RGB) {
	k := size / 332
	R, W := 140*k, 52*k
	ringT := anim.InOutCubic(anim.Window(t, 0, 0.55))
	trackT := anim.OutCubic(anim.Window(t, 0, 0.2)) * (1 - anim.Window(t, 0.45, 0.6))
	pivotT := anim.OutBack(anim.Window(t, 0.42, 0.7))
	handT := anim.OutCubic(anim.Window(t, 0.62, 0.92))

	if trackT > 0 {
		c.Ring(cx, cy, R, W, braille.Solid(bg.Mix(ring, 0.16*trackT)))
	}
	if ringT > 0 {
		// from 140 deg clockwise from 12 o'clock, 310 deg of sweep
		a0 := 140 * math.Pi / 180
		c.Arc(cx, cy, R, W, a0, a0+310*math.Pi/180*ringT, true, braille.Solid(ring))
	}
	if handT > 0 {
		c.Line(cx, cy, cx+R*handT, cy, W, braille.Solid(tint))
	}
	if pivotT > 0 {
		c.Disc(cx, cy, 44*k*pivotT, braille.Solid(tint))
	}
}
