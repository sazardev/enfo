package visual

import (
	"math"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
)

// ClockSun is a day-arc: the sun climbs an arc between sunrise and sunset, the
// moon (in its real phase) takes the night, the sky shifts from night blue to
// dawn orange to day. Time sits in the water below the horizon.
type ClockSun struct{}

func (ClockSun) Name() string                { return "sun" }
func (ClockSun) Step(f *ClockFrame)          {}
func (ClockSun) Animated(f *ClockFrame) bool { return !f.Still }

var (
	clockSkyTopNight = braille.Hex("070b22")
	clockSkyHorNight = braille.Hex("2a3680")
	clockSkyTopDay   = braille.Hex("3a7bd8")
	clockSkyHorDay   = braille.Hex("a9d9ff")
	clockSkyWarm     = braille.Hex("ff8a45")
	clockSkyDusk     = braille.Hex("5a3a8a")
)

// clockSkyLight is how bright the sky is at hour h: 0 deep night, 1 full day.
func clockSkyLight(h, rise, set float64) float64 {
	if h >= rise && h <= set {
		d := math.Min(h-rise, set-h)
		return 0.38 + 0.62*anim.Smooth(d/1.3)
	}
	// night: distance to the nearest of sunrise / sunset on the 24 h circle
	d1 := math.Mod(rise-h+48, 24)
	d2 := math.Mod(h-set+48, 24)
	d := math.Min(d1, d2)
	return 0.38 * (1 - anim.Smooth(d/0.9))
}

// clockBayer is a 4x4 ordered-dither threshold matrix in (0,1): ordered
// patterns read as a smooth gradient in braille where white noise reads as grit.
var clockBayer = func() [4][4]float64 {
	m := [4][4]int{{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}
	var out [4][4]float64
	for y := range m {
		for x := range m[y] {
			out[y][x] = (float64(m[y][x]) + 0.5) / 16
		}
	}
	return out
}()

func clockHM(h float64, h24 bool) string {
	h = math.Mod(h+24, 24)
	hh := int(h)
	mm := int((h-float64(hh))*60 + 0.5)
	if mm == 60 {
		mm, hh = 0, (hh+1)%24
	}
	if !h24 {
		hh %= 12
		if hh == 0 {
			hh = 12
		}
		return clockItoa2(hh) + ":" + clockPad2(mm)
	}
	return clockPad2(hh) + ":" + clockPad2(mm)
}

func (ClockSun) Draw(c *braille.Canvas, f *ClockFrame) []Label {
	W, H := float64(c.W), float64(c.H)
	if W < 24 || H < 16 {
		return clockSunTiny(c, f)
	}
	pal := f.Pal
	h := f.Hours()
	rise, set := f.Sunrise, f.Sunset
	night := f.Polar < 0
	if f.Polar > 0 {
		rise, set = 0, 24
	}
	if set <= rise {
		rise, set = 6, 18
	}
	L := clockSkyLight(h, rise, set)
	if night {
		L = 0
	}
	warm := clamp(1-math.Abs(L-0.34)/0.34, 0, 1)
	if night || f.Polar > 0 {
		warm = 0
	}

	hy := math.Floor(H * 0.64)
	if c.Rows < 14 {
		hy = math.Floor(H * 0.72)
	}
	top := clockSkyTopNight.Mix(clockSkyTopDay, L).Mix(clockSkyDusk, warm*0.5)
	hor := clockSkyHorNight.Mix(clockSkyHorDay, L).Mix(clockSkyWarm, warm*0.9)

	// sky: a dithered gradient that thickens toward the horizon
	bright := 0.3 + 0.7*math.Max(L, warm)
	for y := 0; y < int(hy); y++ {
		g := float64(y) / hy
		p := 0.02 + 0.55*math.Pow(g, 2.4)*bright
		col := top.Mix(hor, math.Pow(g, 1.3))
		for x := 0; x < c.W; x++ {
			if clockBayer[y&3][x&3] < p {
				c.Set(x, y, col)
			}
		}
	}

	// stars come out as the sky darkens
	starA := math.Pow(1-clamp(L*1.6, 0, 1), 1.5)
	if starA > 0.02 {
		for i := 0; i < 90; i++ {
			sx, sy := hash(i*31+1)*W, hash(i*17+5)*hy*0.92
			tw := 0.65 + 0.35*math.Sin(f.Time*(0.8+hash(i)*2.2)+hash(i*3)*20)
			if f.Still {
				tw = 1
			}
			if starA*tw > 0.18+0.5*hash(i*13+9) {
				col := pal.Text.Mix(top, 1-clamp(starA*tw, 0, 1)*0.9)
				c.Dot(sx, sy, col)
				if hash(i*5+2) > 0.93 && W > 80 {
					c.Dot(sx+1, sy, col)
					c.Dot(sx, sy+1, col)
				}
			}
		}
	}

	// the arc
	cx := W / 2
	rx := W * 0.42
	ry := math.Min(hy-7, rx*0.95)
	if ry < 4 {
		ry = 4
	}
	n := int(math.Pi * rx / 3.2)
	for i := 0; i <= n; i++ {
		th := math.Pi * float64(i) / float64(n)
		x, y := cx-rx*math.Cos(th), hy-ry*math.Sin(th)
		c.Dot(x, y, pal.Faint.Mix(hor, 0.3).Mix(pal.Bg, 0.1))
	}

	// sun by day, moon by night, both on the same arc
	dayLen := set - rise
	sunUp := h >= rise && h <= set && !night
	var bx, by, frac float64
	if sunUp {
		frac = (h - rise) / dayLen
	} else {
		nightLen := 24 - dayLen
		since := math.Mod(h-set+24, 24)
		if night {
			since, nightLen = h, 24
		}
		frac = since / nightLen
	}
	th := math.Pi * clamp(frac, 0, 1)
	bx, by = cx-rx*math.Cos(th), hy-ry*math.Sin(th)
	size := clamp(math.Min(W, H)*0.05, 2.6, 10)
	if sunUp {
		low := 1 - math.Sin(th) // near the horizon the sun reddens
		col := pal.Sun.Mix(clockSkyWarm, clamp(low*1.4, 0, 0.8))
		for r := size * 2.6; r > size*1.3; r -= 1.6 {
			k := (size*2.6 - r) / (size * 1.3)
			m := int(2 * math.Pi * r / 3)
			for i := 0; i < m; i++ {
				if (i+int(r))%2 == 0 {
					continue
				}
				x, y := braille.Polar(bx, by, r, float64(i)/float64(m)*2*math.Pi)
				if y < hy {
					c.Dot(x, y, hor.Mix(col, 0.16*k+0.1))
				}
			}
		}
		if size >= 4 {
			spin := 0.0
			if !f.Still {
				spin = f.Time * 0.18
			}
			for i := 0; i < 12; i++ {
				a := spin + float64(i)*math.Pi/6
				x0, y0 := braille.Polar(bx, by, size*1.55, a)
				x1, y1 := braille.Polar(bx, by, size*(1.9+0.35*float64(i%2)), a)
				if y1 < hy && y0 < hy {
					c.Line(x0, y0, x1, y1, 1, braille.Solid(col))
				}
			}
		}
		c.Disc(bx, by, size, braille.Solid(col))
		c.Disc(bx-size*0.28, by-size*0.28, size*0.4, braille.Solid(col.Lighten(0.55)))
	} else {
		mr := size * 1.05
		p := f.MoonPhase
		lit := math.Min(p, 1-p) * 2 // 0 new .. 1 full
		d := 2 * mr * lit
		ox := -d
		if p > 0.5 {
			ox = d
		}
		// only the lit part is set; the sky behind is never erased
		for y := int(by - mr - 1); y <= int(by+mr+1); y++ {
			for x := int(bx - mr - 1); x <= int(bx+mr+1); x++ {
				dx, dy := float64(x)-bx, float64(y)-by
				if dx*dx+dy*dy > mr*mr {
					continue
				}
				sx := float64(x) - (bx + ox)
				if lit < 0.97 && sx*sx+dy*dy <= mr*mr*1.04 {
					continue
				}
				c.Set(x, y, pal.Moon)
			}
		}
		c.Ring(bx, by, mr+0.5, 1, func(x, y float64) braille.RGB {
			if c.Has(int(x), int(y)) {
				return pal.Moon
			}
			return pal.Faint.Mix(top, 0.35)
		})
	}

	// the horizon swallows whatever is below it
	c.Erase(int(bx-size*3.2), int(hy)+1, int(size*6.4), int(size*3.5))

	// horizon and the water below
	horCol := pal.Muted.Mix(hor, 0.4)
	c.Line(2, hy, W-3, hy, 1, braille.Solid(horCol))
	for k := 1; k <= 5; k++ {
		y := hy + 3.2*float64(k)
		if y > H-2 {
			break
		}
		fade := 1 - float64(k)/6.5
		off := 0.0
		if !f.Still {
			off = math.Sin(f.Time*0.9+float64(k)*1.7) * 3
		}
		for x := 4.0; x < W-4; x += 1 {
			if hash(int(x)*13+k*977+int(off*0.5)) < 0.22*fade+0.04 && math.Mod(x+off+float64(k)*5, 9) < 5 {
				c.Dot(x, y, pal.Bg.Mix(hor, 0.5*fade))
			}
		}
	}

	// text: sunrise/sunset flank the horizon; the time floats in the water
	var labels []Label
	row := int(hy)/4 + 1
	if c.Rows >= 12 && f.SunReal {
		labels = append(labels,
			Label{Col: int(cx-rx) / 2, Row: row, Text: "↑ " + clockHM(rise, f.H24), Color: pal.Sun.Mix(pal.Muted, 0.35), Center: true},
			Label{Col: int(cx+rx) / 2, Row: row, Text: "↓ " + clockHM(set, f.H24), Color: clockSkyWarm.Mix(pal.Muted, 0.4), Center: true})
	}
	text := f.TimeText(f.Seconds && c.Cols < 56)
	textTop := float64((row + 1) * 4)
	remain := H - textTop - 3
	if c.Rows >= 12 && remain >= 12 {
		dh := clockFitDigits(f.Font, text, int(W*0.7), int(math.Min(remain-4, H*0.34)))
		clockDrawDigits(c, f.Font, text, W/2, textTop+(remain)/2, dh, braille.Solid(pal.Text))
		if ap := f.AMPM(); ap != "" {
			labels = append(labels, Label{Col: (int(W/2)+clockDigitsWidth(f.Font, text, dh)/2)/2 + 1, Row: int(textTop+remain/2-float64(dh)/2) / 4, Text: ap, Color: pal.Accent, Bold: true})
		}
	} else {
		labels = append(labels, Label{Col: c.Cols / 2, Row: clockMinInt(row, c.Rows-1), Text: text + ampmSuffix(f), Color: pal.Text, Bold: true, Center: true})
	}
	return labels
}

// clockSunTiny is the fallback when there is no room for a scene.
func clockSunTiny(c *braille.Canvas, f *ClockFrame) []Label {
	return []Label{{Col: c.Cols / 2, Row: c.Rows / 2, Text: f.TimeText(f.Seconds) + ampmSuffix(f), Color: f.Pal.Text, Bold: true, Center: true}}
}

func clockMinInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}
