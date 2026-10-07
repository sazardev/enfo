package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// BreaksGuideFrame is what a break guide needs to draw one frame.
type BreaksGuideFrame struct {
	T        float64 // seconds since the guide opened (animation clock)
	Progress float64 // 0..1 of the guide's countdown
	Pal      theme.Palette
	Still    bool // reduced motion: hold a pleasant pose
}

// BreaksGuide draws the animated how-to for a habit: "eyes", "stretch",
// "water", "posture"; anything else gets a breathing ring.
func BreaksGuide(kind string, c *braille.Canvas, f *BreaksGuideFrame) {
	if c.W < 16 || c.H < 12 {
		return
	}
	switch kind {
	case "eyes":
		breaksEyes(c, f)
	case "stretch":
		breaksStretch(c, f)
	case "water":
		breaksWater(c, f)
	case "posture":
		breaksPosture(c, f)
	default:
		breaksBreathe(c, f)
	}
}

func (f *BreaksGuideFrame) t() float64 {
	if f.Still {
		return 2
	}
	return f.T
}

// ------------------------------------------------------------------- eyes

// lens reports whether (x, y) is inside an almond eye centred on (cx, cy).
func breaksLens(x, y, cx, cy, rx, ry float64) bool {
	dx := math.Abs(x-cx) / rx
	if dx >= 1 {
		return false
	}
	return math.Abs(y-cy) <= ry*(1-dx*dx)
}

func breaksEyes(c *braille.Canvas, f *BreaksGuideFrame) {
	pal := f.Pal
	W, H := float64(c.W), float64(c.H)
	cy := H / 2
	rx := math.Min(W*0.2, H*0.62)
	ry := rx * 0.5
	gap := rx * 1.35
	t := f.t()

	// three poses on a 12 s loop: left, right, far away
	targets := [][3]float64{{-0.55, 0.05, 1}, {0.55, 0.05, 1}, {0, 0, 0.55}}
	lens := []float64{3.2, 3.2, 5.6}
	total := 12.0
	lt := math.Mod(t, total)
	idx, start := 0, 0.0
	for i, l := range lens {
		if lt < start+l {
			idx = i
			break
		}
		start += l
		idx = i
	}
	prev := targets[(idx+len(targets)-1)%len(targets)]
	cur := targets[idx]
	k := anim.Smooth((lt - start) / 0.8)
	px := anim.Lerp(prev[0], cur[0], k)
	py := anim.Lerp(prev[1], cur[1], k)
	pz := anim.Lerp(prev[2], cur[2], k)

	// a blink every ~5 s
	blink := 1.0
	if b := math.Mod(t, 5); !f.Still && b > 4.75 {
		blink = math.Abs(b-4.875) / 0.125
	}
	// "far away": distance rings drifting outward behind the eyes
	if pz < 0.9 {
		a := (1 - pz) / 0.45
		for i := 0; i < 5; i++ {
			ph := math.Mod(t*0.5+float64(i)/5, 1)
			r := rx*0.6 + ph*math.Min(W, H)*0.5
			col := pal.Bg.Mix(pal.Rest, 0.55*(1-ph)*a)
			c.Ring(W/2, cy, r, 1, braille.Solid(col))
		}
		// a horizon
		hy := cy + ry*2.4
		for x := 0.0; x < W; x += 3 {
			c.Dot(x, hy, pal.Bg.Mix(pal.Muted, 0.5*a))
		}
	}
	for _, side := range []float64{-1, 1} {
		cx := W/2 + side*gap
		eryy := ry * blink
		if eryy < 1 {
			eryy = 1
		}
		// outline: inside the lens but not inside the slightly smaller one
		th := math.Max(1.5, rx*0.07)
		x0, x1 := int(cx-rx-2), int(cx+rx+2)
		y0, y1 := int(cy-ry-2), int(cy+ry+2)
		for y := y0; y <= y1; y++ {
			for x := x0; x <= x1; x++ {
				fx, fy := float64(x), float64(y)
				if breaksLens(fx, fy, cx, cy, rx, eryy) && !breaksLens(fx, fy, cx, cy, rx-th*1.4, eryy-th) {
					c.Set(x, y, pal.Text)
				}
			}
		}
		if blink > 0.3 {
			// iris and pupil follow the look direction (they look together)
			ix := cx + px*rx*0.45
			iy := cy + py*ry
			ir := ry * 0.78 * (0.75 + 0.25*pz)
			// only inside the open lens
			for y := int(iy - ir); y <= int(iy+ir); y++ {
				for x := int(ix - ir); x <= int(ix+ir); x++ {
					fx, fy := float64(x), float64(y)
					d := math.Hypot(fx-ix, fy-iy)
					if d <= ir && breaksLens(fx, fy, cx, cy, rx-th*2, eryy-th*1.2) {
						if d <= ir*0.42 {
							continue // pupil: left dark
						}
						c.Set(x, y, pal.Accent.Mix(pal.Bright, 0.5*(1-d/ir)))
					}
				}
			}
			c.Dot(ix-ir*0.3, iy-ir*0.45, pal.Text)
		}
	}
}

// ---------------------------------------------------------------- stretch

func breaksStretch(c *braille.Canvas, f *BreaksGuideFrame) {
	pal := f.Pal
	W, H := float64(c.W), float64(c.H)
	t := f.t()
	cx := W / 2
	unit := math.Min(H*0.9, W*0.7) // figure height
	top := (H - unit) / 2
	headR := unit * 0.075
	thick := math.Max(2, unit*0.045)
	// 6 s loop: arms rise, lean left, lean right, down
	arms := anim.InOutSine(clamp(math.Sin(t*2*math.Pi/6)*0.9+0.45, 0, 1))
	lean := 0.0
	if arms > 0.6 {
		lean = math.Sin(t*2*math.Pi/3) * 0.22
	}
	hipY := top + unit*0.58
	hip := [2]float64{cx, hipY}
	torsoL := unit * 0.3
	neckX, neckY := braille.Polar(hip[0], hip[1], torsoL, lean)
	head := [2]float64{0, 0}
	head[0], head[1] = braille.Polar(neckX, neckY, headR*1.7, lean)
	col := braille.Solid(pal.Accent)
	hi := braille.Solid(pal.Bright)

	// legs
	c.Line(hip[0], hip[1], cx-unit*0.1, top+unit, thick, col)
	c.Line(hip[0], hip[1], cx+unit*0.1, top+unit, thick, col)
	// torso and head
	c.Line(hip[0], hip[1], neckX, neckY, thick*1.15, col)
	c.Disc(head[0], head[1], headR, hi)
	// arms: from the shoulders, angle 0 = down, pi = straight up
	shX, shY := braille.Polar(hip[0], hip[1], torsoL*0.92, lean)
	for _, side := range []float64{-1, 1} {
		ang := arms*math.Pi*0.96 + 0.15
		upper := unit * 0.17
		lower := unit * 0.16
		ex, ey := shX+side*math.Sin(ang)*upper, shY+math.Cos(ang)*upper
		bend := (1 - arms) * 0.5
		ang2 := ang + bend
		hx, hy := ex+side*math.Sin(ang2)*lower, ey+math.Cos(ang2)*lower
		c.Line(shX, shY, ex, ey, thick*0.9, col)
		c.Line(ex, ey, hx, hy, thick*0.9, col)
		c.Disc(hx, hy, thick*0.6, hi)
		// reaching sparkles above the hands
		if arms > 0.7 && !f.Still {
			for i := 0; i < 3; i++ {
				ph := math.Mod(t*1.3+float64(i)/3+side*0.2, 1)
				c.Dot(hx+side*ph*thick*2, hy-ph*unit*0.12, pal.Bg.Mix(pal.Bright, 1-ph))
			}
		}
	}
	// the floor
	c.Line(cx-unit*0.45, top+unit+thick, cx+unit*0.45, top+unit+thick, 1.5, braille.Solid(pal.Faint))
}

// ------------------------------------------------------------------ water

func breaksWater(c *braille.Canvas, f *BreaksGuideFrame) {
	pal := f.Pal
	W, H := float64(c.W), float64(c.H)
	t := f.t()
	gh := H * 0.78
	gw := math.Min(gh*0.62, W*0.5)
	cx := W / 2
	top := H - gh - 3
	bot := H - 3
	topHalf, botHalf := gw/2, gw*0.34
	half := func(y float64) float64 {
		return botHalf + (topHalf-botHalf)*(bot-y)/(bot-top)
	}
	level := bot - (0.12+0.78*clamp(f.Progress, 0, 1))*gh
	if f.Still {
		level = bot - 0.6*gh
	}
	amp := gh * 0.012
	if f.Still {
		amp = 0
	}
	water := pal.Rest
	for y := int(top); y <= int(bot); y++ {
		hw := half(float64(y)) - 2
		for x := int(cx - hw); x <= int(cx+hw); x++ {
			surf := level + amp*math.Sin(float64(x)*0.3+t*3)
			if float64(y) < surf {
				continue
			}
			depth := clamp((float64(y)-surf)/gh, 0, 1)
			col := water.Mix(pal.Bg, 0.1+0.5*depth)
			if float64(y) < surf+2 {
				col = pal.RestHi
			}
			c.Set(x, y, col)
		}
	}
	// the glass
	var l, r [][2]float64
	for y := top; y <= bot; y += 2 {
		l = append(l, [2]float64{cx - half(y), y})
		r = append(r, [2]float64{cx + half(y), y})
	}
	c.Polyline(l, 1.5, braille.Solid(pal.Text))
	c.Polyline(r, 1.5, braille.Solid(pal.Text))
	c.Line(cx-botHalf, bot, cx+botHalf, bot, 2, braille.Solid(pal.Text))
	// a drop falls every 1.6 s and rings the surface
	if !f.Still {
		ph := math.Mod(t, 1.6) / 1.6
		if ph < 0.55 {
			k := ph / 0.55
			y := 2 + k*k*(level-2)
			c.Disc(cx, y, math.Max(1.2, gw*0.03), braille.Solid(pal.RestHi))
			c.Disc(cx, y-gw*0.05, math.Max(0.8, gw*0.018), braille.Solid(pal.Rest))
		} else {
			k := (ph - 0.55) / 0.45
			r := k * gw * 0.28
			c.Arc(cx, level+1, r, 1, 0, 2*math.Pi, false, braille.Solid(pal.Bg.Mix(pal.RestHi, 1-k)))
		}
	}
}

// ---------------------------------------------------------------- posture

func breaksPosture(c *braille.Canvas, f *BreaksGuideFrame) {
	pal := f.Pal
	W, H := float64(c.W), float64(c.H)
	t := f.t()
	cx := W / 2
	unit := math.Min(H*0.92, W*0.6)
	bot := (H + unit) / 2
	top := bot - unit
	// 8 s loop: slouch -> straighten -> hold -> slouch
	ph := math.Mod(t, 8) / 8
	slouch := 0.0
	switch {
	case ph < 0.2:
		slouch = 1
	case ph < 0.45:
		slouch = 1 - anim.InOutSine((ph-0.2)/0.25)
	case ph < 0.8:
		slouch = 0
	default:
		slouch = anim.InOutSine((ph - 0.8) / 0.2)
	}
	if f.Still {
		slouch = 0
	}
	const n = 13
	pts := make([][2]float64, n)
	for i := 0; i < n; i++ {
		u := float64(i) / float64(n-1) // 0 at the hip .. 1 at the head
		// lumbar curves in, upper back rounds out, head juts forward
		bend := slouch * unit * (0.16*math.Sin(math.Pi*u) + 0.14*u*u)
		pts[i] = [2]float64{cx - unit*0.1 + bend, bot - u*unit*0.8}
	}
	straight := slouch < 0.12
	plumb := pal.Warn
	if straight {
		plumb = pal.Good
	}
	// plumb line through the hip, dotted
	for y := top; y < bot; y += 3 {
		c.Dot(cx-unit*0.1, y, pal.Bg.Mix(plumb, 0.65))
	}
	c.Polyline(pts, math.Max(1.5, unit*0.02), braille.Solid(pal.Faint.Mix(pal.Text, 0.4)))
	for i, p := range pts {
		r := math.Max(1.5, unit*(0.032+0.008*math.Sin(float64(i)*0.5)))
		col := pal.Accent.Mix(pal.Bright, float64(i)/float64(n))
		c.Disc(p[0], p[1], r, braille.Solid(col))
	}
	head := pts[n-1]
	c.Disc(head[0]+unit*0.02, head[1]-unit*0.09, unit*0.07, braille.Solid(pal.Bright))
	// the seat
	c.Line(cx-unit*0.35, bot+unit*0.04, cx+unit*0.12, bot+unit*0.04, 2, braille.Solid(pal.Faint))
	// the hip anchor
	c.Disc(pts[0][0], pts[0][1], unit*0.04, braille.Solid(pal.Text))
}

// ----------------------------------------------------------------- generic

func breaksBreathe(c *braille.Canvas, f *BreaksGuideFrame) {
	pal := f.Pal
	W, H := float64(c.W), float64(c.H)
	t := f.t()
	cx, cy := W/2, H/2
	R := math.Min(W, H) * 0.42
	k := (math.Sin(t*2*math.Pi/5) + 1) / 2
	r := R * (0.55 + 0.45*k)
	for i := 3; i >= 1; i-- {
		c.Ring(cx, cy, r+float64(i)*R*0.09, 1.2, braille.Solid(pal.Bg.Mix(pal.Accent, 0.12*float64(4-i))))
	}
	c.Disc(cx, cy, r*0.8, braille.Solid(pal.Bg.Mix(pal.Accent, 0.35+0.3*k)))
	c.Ring(cx, cy, r, 2.2, braille.Solid(pal.Bright))
}
