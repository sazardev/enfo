package ui

import (
	"math"
	"time"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// alarmIntensity says how urgent the next alarm is, 0..1: faint when it is
// hours away, full (and pulsing) in the last minute.
func alarmIntensity(until time.Duration) float64 {
	switch {
	case until <= 0:
		return 1
	case until <= time.Minute:
		return 1
	case until <= 10*time.Minute:
		return 0.55 + 0.45*(1-float64(until-time.Minute)/float64(9*time.Minute))
	case until <= time.Hour:
		return 0.3 + 0.25*(1-float64(until-10*time.Minute)/float64(50*time.Minute))
	}
	return 0.3
}

// alarmRipples draws sound arcs on both sides of (cx, cy). strength 0..1 sets
// how many show and how fast they travel; t is the animation clock.
func alarmRipples(c *braille.Canvas, cx, cy, s, strength, t float64, col, bg braille.RGB, still bool) {
	n := 3
	speed := 0.35 + 0.9*strength
	for k := 0; k < n; k++ {
		ph := math.Mod(t*speed+float64(k)/float64(n), 1)
		if still {
			ph = (float64(k) + 0.5) / float64(n)
		}
		r := s * (0.5 + 0.6*ph)
		fade := (1 - ph) * (0.25 + 0.75*strength)
		if fade < 0.06 {
			continue
		}
		cc := bg.Mix(col, fade)
		half := 36 * math.Pi / 180
		for _, mid := range []float64{math.Pi / 2, 3 * math.Pi / 2} {
			c.Arc(cx, cy, r, 1.5, mid-half, mid+half, true, braille.Solid(cc))
		}
	}
}

// alarmDrawBell fills a bell hanging from a pivot above its centre. swing is
// the angle in radians.
func alarmDrawBell(c *braille.Canvas, cx, cy, s, swing float64, col, hi braille.RGB) {
	px, py := cx, cy-s*0.5
	sn, cs := math.Sin(swing), math.Cos(swing)
	r := s * 1.1
	x0, x1 := clampi(int(px-r), 0, c.W-1), clampi(int(px+r), 0, c.W-1)
	y0, y1 := clampi(int(py-s*0.2), 0, c.H-1), clampi(int(py+r), 0, c.H-1)
	clapOff := -swing * 0.5
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-px, float64(y)-py
			u := (dx*cs + dy*sn) / s
			v := (-dx*sn + dy*cs) / s
			in := false
			switch {
			case math.Hypot(u, v-0.05) < 0.05:
				in = true
			case v >= 0.09 && v <= 0.80:
				var hw float64
				if v < 0.5 {
					q := (0.5 - v) / 0.41
					hw = 0.34 * math.Sqrt(math.Max(0, 1-q*q))
				} else {
					hw = 0.34 + 0.13*math.Pow((v-0.5)/0.30, 1.7)
				}
				in = math.Abs(u) <= hw
			case v > 0.80 && v <= 0.86:
				in = math.Abs(u) <= 0.49
			case math.Hypot(u-clapOff*0.4, v-0.95) < 0.075:
				in = true
			}
			if in {
				k := anim.Clamp01((-u + 0.3) / 0.7)
				c.Set(x, y, col.Mix(hi, 0.55*k*k))
			}
		}
	}
}

// alarmBellCanvas renders the animated bell with sound ripples. strength
// (0..1) grows as the alarm approaches; in the last minute it shakes.
func alarmBellCanvas(c *braille.Canvas, pal theme.Palette, strength, t float64, urgent, still bool, armed bool) {
	cx, cy := float64(c.W)/2, float64(c.H)*0.52
	s := math.Min(float64(c.H)*0.78, float64(c.W)*0.5)
	col, hi := pal.Accent, pal.Bright
	if !armed {
		col, hi = pal.Faint.Mix(pal.Muted, 0.35), pal.Muted
		strength = 0
	}
	swing := 0.0
	if !still && armed {
		amp := 0.05 + 0.1*strength
		freq := 0.8 + 1.4*strength
		if urgent {
			amp, freq = 0.36, 3.6
		}
		swing = amp * math.Sin(t*2*math.Pi*freq)
	}
	if armed {
		alarmRipples(c, cx, cy, s, strength, t, hi, pal.Bg, still)
	}
	alarmDrawBell(c, cx, cy, s, swing, col, hi)
}

// alarmClockCanvas is the empty-state illustration: a twin-bell alarm clock
// ringing softly.
func alarmClockCanvas(c *braille.Canvas, pal theme.Palette, t float64, still bool) {
	cx, cy := float64(c.W)/2, float64(c.H)*0.55
	R := math.Min(float64(c.W), float64(c.H)) * 0.36
	col, hi := pal.Accent, pal.Bright
	shake := 0.0
	if !still {
		shake = math.Sin(t*2*math.Pi*2.2) * math.Max(0, math.Sin(t*2*math.Pi/3.2)) * 1.2
		alarmRipples(c, cx, cy, R*1.9, 0.35, t, hi, pal.Bg, false)
	}
	// legs
	for _, sg := range []float64{-1, 1} {
		bx, by := braille.Polar(cx, cy, R*1.0, math.Pi+sg*0.55)
		ex, ey := braille.Polar(cx, cy, R*1.32, math.Pi+sg*0.62)
		c.Line(bx, by, ex, ey, 2.2, braille.Solid(pal.Muted))
	}
	// bells
	for _, sg := range []float64{-1, 1} {
		bx, by := braille.Polar(cx, cy, R*1.13, sg*0.74)
		c.Disc(bx+sg*shake, by-math.Abs(shake)*0.4, R*0.26, braille.Solid(hi))
	}
	c.Ring(cx, cy, R, math.Max(1.8, R*0.1), braille.Solid(col))
	for i := 0; i < 4; i++ {
		x, y := braille.Polar(cx, cy, R*0.76, float64(i)*math.Pi/2)
		c.Disc(x, y, 0.9, braille.Solid(pal.Text))
	}
	hx, hy := braille.Polar(cx, cy, R*0.45, -60*math.Pi/180)
	c.Line(cx, cy, hx, hy, 1.6, braille.Solid(pal.Text))
	mx, my := braille.Polar(cx, cy, R*0.66, 60*math.Pi/180)
	c.Line(cx, cy, mx, my, 1.2, braille.Solid(pal.Text))
	c.Disc(cx, cy, 1.6, braille.Solid(hi))
}

// alarmToggle draws a spring-driven switch, rows cells tall (1 or 2): a hollow
// pill with a dim knob when off, a solid accent pill with a bright knob when on.
func alarmToggle(pos float64, rows int, pal theme.Palette) []string {
	cols := 8
	if rows < 2 {
		rows, cols = 1, 6
	}
	c := braille.New(cols, rows)
	W, H := float64(c.W), float64(c.H)
	k := anim.Clamp01(pos)
	track := pal.Muted.Mix(pal.Accent, k)
	c.RoundRect(0, 0, W, H, H/2, braille.Solid(track))
	if k < 0.5 {
		// hollow: carve the inside, leaving an outline
		for y := 1; y < int(H)-1; y++ {
			for x := 1; x < int(W)-1; x++ {
				px, py := float64(x)+0.5, float64(y)+0.5
				r := H/2 - 1
				cx := math.Min(math.Max(px, H/2), W-H/2)
				if math.Hypot(px-cx, py-H/2) <= r {
					c.Unset(x, y)
				}
			}
		}
	}
	kr := H/2 - 1.2
	if rows < 2 {
		kr = H/2 - 0.8
	}
	x0, x1 := H/2, W-H/2
	kx := x0 + (x1-x0)*k
	c.EraseDisc(kx, H/2, kr+0.9)
	knob := pal.Muted.Mix(pal.Bright.Lighten(0.3), k)
	c.Disc(kx, H/2, kr, braille.Solid(knob))
	return c.Lines()
}

// alarmBigTime renders HH:MM in tall braille digits, rows cells high.
func alarmBigTime(s string, rows int, col braille.RGB) []string {
	h := rows * 4
	w := braille.FontLine.TextWidth(s, h)
	c := braille.New((w+1)/2+1, rows)
	c.Text(braille.FontLine, s, 1, 0, h, braille.Solid(col))
	return c.Lines()
}
