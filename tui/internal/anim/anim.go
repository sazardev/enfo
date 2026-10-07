// Package anim has the small motion toolkit the interface is built on:
// easing curves, damped springs (Harmonica) and a particle system.
package anim

import (
	"math"
	"math/rand"
	"time"

	"github.com/charmbracelet/harmonica"
	"github.com/sazardev/enfo/tui/internal/braille"
)

// ------------------------------------------------------------------- easing

func Clamp01(t float64) float64 {
	if t < 0 {
		return 0
	}
	if t > 1 {
		return 1
	}
	return t
}

func Lerp(a, b, t float64) float64 { return a + (b-a)*t }

func Smooth(t float64) float64 { t = Clamp01(t); return t * t * (3 - 2*t) }

func OutCubic(t float64) float64 { t = Clamp01(t); u := 1 - t; return 1 - u*u*u }

func InCubic(t float64) float64 { t = Clamp01(t); return t * t * t }

func InOutCubic(t float64) float64 {
	t = Clamp01(t)
	if t < 0.5 {
		return 4 * t * t * t
	}
	u := -2*t + 2
	return 1 - u*u*u/2
}

func InOutSine(t float64) float64 { return -(math.Cos(math.Pi*Clamp01(t)) - 1) / 2 }

func OutBack(t float64) float64 {
	t = Clamp01(t)
	const c1, c3 = 1.70158, 2.70158
	u := t - 1
	return 1 + c3*u*u*u + c1*u*u
}

func OutElastic(t float64) float64 {
	t = Clamp01(t)
	if t == 0 || t == 1 {
		return t
	}
	return math.Pow(2, -10*t)*math.Sin((t*10-0.75)*(2*math.Pi/3)) + 1
}

// Window maps t through [a, b] to 0..1 (for staggering parts of an intro).
func Window(t, a, b float64) float64 {
	if b <= a {
		return 0
	}
	return Clamp01((t - a) / (b - a))
}

// ------------------------------------------------------------------- spring

// Spring is a critically/under-damped spring that chases a target value.
// Step it once per frame with the frame's duration.
type Spring struct {
	Pos, Vel, Target float64
	freq, damp       float64
	cached           time.Duration
	s                harmonica.Spring
}

// NewSpring creates a spring at rest on value v. A higher freq is snappier;
// damp below 1 overshoots (bounce), 1 is critical, above 1 is sluggish.
func NewSpring(v, freq, damp float64) *Spring {
	return &Spring{Pos: v, Target: v, freq: freq, damp: damp}
}

func (sp *Spring) Step(dt time.Duration) float64 {
	if dt <= 0 {
		return sp.Pos
	}
	if dt != sp.cached {
		sp.cached = dt
		sp.s = harmonica.NewSpring(dt.Seconds(), sp.freq, sp.damp)
	}
	sp.Pos, sp.Vel = sp.s.Update(sp.Pos, sp.Vel, sp.Target)
	return sp.Pos
}

// Snap jumps to v with no motion.
func (sp *Spring) Snap(v float64) { sp.Pos, sp.Vel, sp.Target = v, 0, v }

// Settled reports whether the spring has effectively stopped on its target.
func (sp *Spring) Settled() bool {
	return math.Abs(sp.Pos-sp.Target) < 0.002 && math.Abs(sp.Vel) < 0.002
}

// ---------------------------------------------------------------- particles

// Particle is one dot of confetti, spark or dust.
type Particle struct {
	X, Y, VX, VY float64
	Life, Max    float64 // seconds left, seconds total
	Col          braille.RGB
	Size         float64
	Drag         float64
}

// Particles is a tiny physics system drawn in dot coordinates.
type Particles struct {
	P       []Particle
	Gravity float64 // dots per second squared
	rng     *rand.Rand
}

func NewParticles(seed int64) *Particles {
	return &Particles{Gravity: 60, rng: rand.New(rand.NewSource(seed))}
}

func (ps *Particles) Rand() float64 { return ps.rng.Float64() }

// Burst throws n particles outward from (x, y).
func (ps *Particles) Burst(x, y float64, n int, speed float64, cols []braille.RGB) {
	for i := 0; i < n; i++ {
		a := ps.rng.Float64() * 2 * math.Pi
		v := speed * (0.35 + 0.65*ps.rng.Float64())
		life := 0.9 + 1.1*ps.rng.Float64()
		ps.P = append(ps.P, Particle{
			X: x, Y: y, VX: math.Cos(a) * v, VY: math.Sin(a)*v - speed*0.25,
			Life: life, Max: life, Col: cols[ps.rng.Intn(len(cols))],
			Size: 0.6 + ps.rng.Float64()*0.9, Drag: 0.6,
		})
	}
}

// Emit adds one custom particle.
func (ps *Particles) Emit(p Particle) { ps.P = append(ps.P, p) }

func (ps *Particles) Step(dt float64) {
	live := ps.P[:0]
	for _, p := range ps.P {
		p.Life -= dt
		if p.Life <= 0 {
			continue
		}
		p.VY += ps.Gravity * dt
		damp := math.Max(0, 1-p.Drag*dt)
		p.VX *= damp
		p.VY *= damp
		p.X += p.VX * dt
		p.Y += p.VY * dt
		live = append(live, p)
	}
	ps.P = live
}

func (ps *Particles) Len() int { return len(ps.P) }

// Draw paints the particles; they fade toward bg as they die.
func (ps *Particles) Draw(c *braille.Canvas, bg braille.RGB) {
	for _, p := range ps.P {
		k := Clamp01(p.Life / p.Max)
		col := bg.Mix(p.Col, math.Sqrt(k))
		if p.Size > 1.1 && k > 0.35 {
			c.Disc(p.X, p.Y, p.Size*0.7, braille.Solid(col))
		} else {
			c.Dot(p.X, p.Y, col)
		}
	}
}

// ------------------------------------------------------------------- noise

// Noise is smooth 2D value noise in 0..1, cheap enough for per-dot use.
func Noise(x, y float64, seed uint32) float64 {
	x0, y0 := math.Floor(x), math.Floor(y)
	fx, fy := Smooth(x-x0), Smooth(y-y0)
	h := func(ix, iy float64) float64 {
		n := uint32(int32(ix))*374761393 + uint32(int32(iy))*668265263 + seed*2246822519
		n = (n ^ (n >> 13)) * 1274126177
		return float64(n^(n>>16)) / 4294967295
	}
	a, b := h(x0, y0), h(x0+1, y0)
	c, d := h(x0, y0+1), h(x0+1, y0+1)
	return Lerp(Lerp(a, b, fx), Lerp(c, d, fx), fy)
}

// Hash01 is a stable pseudo-random value in 0..1 for an integer key.
func Hash01(k uint32) float64 {
	k = (k ^ 61) ^ (k >> 16)
	k *= 9
	k ^= k >> 4
	k *= 0x27d4eb2d
	k ^= k >> 15
	return float64(k) / 4294967295
}
