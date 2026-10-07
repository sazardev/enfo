package ui

import (
	"math"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/theme"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// eventTint picks one of a few palette-derived colors for an event.
func eventTint(p theme.Palette, idx int) (main, hi braille.RGB) {
	switch ((idx % 6) + 6) % 6 {
	case 1:
		return p.Rest, p.RestHi
	case 2:
		return p.Sun, p.Sun.Lighten(0.4)
	case 3:
		return p.Good, p.Good.Lighten(0.4)
	case 4:
		return p.Bad, p.Bad.Lighten(0.4)
	case 5:
		return p.Moon, p.Moon.Lighten(0.4)
	}
	return p.Accent, p.Bright
}

// eventStars scatters faint twinkling stars over the canvas. They sit behind
// everything else, so only dots nothing else lit remain visible.
func eventStars(c *braille.Canvas, p theme.Palette, t float64, still bool, density float64) {
	n := int(float64(c.W*c.H) * density)
	for i := 0; i < n; i++ {
		x := int(anim.Hash01(uint32(i*3+1)) * float64(c.W))
		y := int(anim.Hash01(uint32(i*3+2)) * float64(c.H))
		ph := anim.Hash01(uint32(i*3+3)) * 6.28
		k := 0.5
		if !still {
			k = 0.5 + 0.5*math.Sin(t*(0.5+anim.Hash01(uint32(i))*1.4)+ph)
		}
		c.Set(x, y, p.Bg.Mix(p.Muted, 0.12+0.5*k*k))
	}
}

// eventHero draws the ring, the digits and the stars of one event. It returns
// labels (cell coordinates) to stamp on top.
func eventHero(c *braille.Canvas, p theme.Palette, font braille.Font, v eventView, now time.Time, t float64, still bool) []visual.Label {
	main, hi := eventTint(p, v.Item.Accent)
	cx, cy := float64(c.W)/2, float64(c.H)/2
	eventStars(c, p, t, still, 0.006)

	R := math.Min(float64(c.W), float64(c.H))/2 - 3
	if R < 6 {
		return nil
	}
	thick := math.Max(2, math.Min(5, R*0.06))
	R -= thick/2 + 1
	grad := braille.Gradient{main.Darken(0.42), main, hi}

	c.Ring(cx, cy, R, thick, braille.Solid(p.Bg.Mix(main, 0.2)))
	prog := v.Progress
	if prog > 0 {
		end := prog * 2 * math.Pi
		c.Arc(cx, cy, R, thick, 0, end, true, func(x, y float64) braille.RGB {
			a := braille.Angle(cx, cy, x, y)
			if a > end+0.3 {
				a = 0
			}
			col := grad.At(a / (2 * math.Pi))
			if d := end - a; d >= 0 && d < 0.5 {
				col = col.Mix(hi.Lighten(0.3), math.Pow(1-d/0.5, 1.5))
			}
			return col
		})
		hx, hy := braille.Polar(cx, cy, R, end)
		if !v.Past && !still {
			halo := thick * (1.8 + 0.5*math.Sin(t*1.6))
			for dy := -halo; dy <= halo; dy++ {
				for dx := -halo; dx <= halo; dx++ {
					d := math.Hypot(dx, dy)
					if d <= halo && d > thick*0.7 && (int(hx+dx)+int(hy+dy))&1 == 0 {
						c.Dot(hx+dx, hy+dy, p.Bg.Mix(hi, 0.18+0.4*(1-d/halo)))
					}
				}
			}
		}
		c.Disc(hx, hy, thick*0.62, braille.Solid(hi.Lighten(0.5)))
	}
	// twelve quiet marks inside the ring
	if R > 20 {
		c.Ticks(cx, cy, R-thick/2-4, R-thick/2-2, 12, 1, func(i int) (braille.RGB, bool) {
			if float64(i)/12 < prog {
				return main.Mix(p.Bg, 0.45), true
			}
			return p.Faint, true
		})
	}

	var labels []visual.Label
	inner := R - thick/2 - 6
	if inner < 8 {
		return nil
	}
	// ripples when the event is here
	if v.Arrived && !still {
		for i := 0; i < 3; i++ {
			ph := math.Mod(t*0.5+float64(i)/3, 1)
			c.Ring(cx, cy, ph*R, 1.4, braille.Solid(p.Bg.Mix(hi, 0.7*(1-ph))))
		}
	}

	days, h, m, s := eventParts(v.Left)
	hms := padTime(h, m, s)
	digitCol := p.Text
	if v.Past && !v.Arrived {
		digitCol = p.Muted
	}
	maxW := int(inner * 1.7)
	if v.Arrived {
		// the words say it; digits stay out of the way
		hms = "00:00:00"
		days = 0
	}
	if days > 0 {
		hBig := font.FitHeight(itoa(days), maxW, int(inner*0.8))
		hSmall := maxi(5, mini(hBig*45/100, font.FitHeight(hms, maxW, int(inner*0.5))))
		gap := 6 + hSmall/6
		total := hBig + gap + hSmall
		top := cy - float64(total)/2
		eventText(c, font, itoa(days), cx, top+float64(hBig)/2, hBig, digitCol)
		lblRow := int(top+float64(hBig)+float64(gap)/2) / 4
		label := i18n.T("event.days")
		if days == 1 {
			label = i18n.T("event.day")
		}
		if lblRow < c.Rows {
			labels = append(labels, visual.Label{Col: int(cx) / 2, Row: lblRow, Text: label, Color: main, Bold: true, Center: true})
		}
		eventText(c, font, hms, cx, top+float64(hBig+gap)+float64(hSmall)/2, hSmall, p.Muted.Mix(p.Text, 0.35))
	} else if h > 0 {
		// hours left: HH:MM big, the seconds smaller underneath
		big := padTime2(h, m)
		hBig := font.FitHeight(big, maxW, int(inner*0.8))
		hSmall := maxi(5, hBig*40/100)
		gap := 4 + hSmall/5
		total := hBig + gap + hSmall
		top := cy - float64(total)/2
		eventText(c, font, big, cx, top+float64(hBig)/2, hBig, digitCol)
		eventText(c, font, pad2(s), cx, top+float64(hBig+gap)+float64(hSmall)/2, hSmall, p.Muted.Mix(p.Text, 0.35))
	} else {
		str := padTime2(m, s)
		hh := font.FitHeight(str, maxW, int(inner*0.8))
		eventText(c, font, str, cx, cy, hh, digitCol)
	}
	if v.Arrived {
		row := int(cy) / 4
		if row < c.Rows {
			labels = append(labels, visual.Label{Col: int(cx) / 2, Row: row, Text: strings.ToUpper(i18n.T("event.now")), Color: hi, Bold: true, Center: true})
		}
	}
	return labels
}

func eventText(c *braille.Canvas, f braille.Font, s string, cx, cy float64, h int, col braille.RGB) {
	w := f.TextWidth(s, h)
	pad := 2
	c.Erase(int(cx)-w/2-pad, int(cy)-h/2-pad, w+2*pad, h+2*pad)
	c.TextCentered(f, s, cx, cy, h, braille.Solid(col))
}

func padTime(h, m, s int) string { return pad2(h) + ":" + pad2(m) + ":" + pad2(s) }
func padTime2(m, s int) string   { return pad2(m) + ":" + pad2(s) }
func pad2(n int) string {
	if n < 10 {
		return "0" + itoa(n)
	}
	return itoa(n)
}

// eventFlag is the empty-state picture: a flag on a hill under the stars.
func eventFlag(c *braille.Canvas, p theme.Palette, t float64, still bool) {
	eventStars(c, p, t, still, 0.01)
	W, H := float64(c.W), float64(c.H)
	cx := W / 2
	// hill
	for x := 0; x < c.W; x++ {
		dx := (float64(x) - cx) / (W * 0.42)
		if math.Abs(dx) > 1 {
			continue
		}
		y := H*0.86 - (H*0.2)*(1-dx*dx)
		for yy := int(y); yy < c.H; yy++ {
			c.Set(x, yy, p.Bg.Mix(p.Accent, 0.16+0.18*float64(yy-int(y))/(H*0.2+1)*0))
		}
	}
	top := H*0.86 - H*0.2
	pole := top - H*0.36
	c.Line(cx, top, cx, pole, 2, braille.Solid(p.Muted))
	// a waving flag
	fw, fh := W*0.16, H*0.17
	for i := 0; i <= int(fw); i++ {
		u := float64(i) / fw
		wave := 0.0
		if !still {
			wave = math.Sin(t*3-u*4.5) * fh * 0.12 * u
		}
		y0 := pole + wave
		taper := fh * (1 - 0.35*u)
		c.Line(cx+float64(i), y0, cx+float64(i), y0+taper, 1.2, braille.Solid(p.Accent.Mix(p.Bright, u*0.5)))
	}
	c.Disc(cx, pole, 2, braille.Solid(p.Bright))
}
