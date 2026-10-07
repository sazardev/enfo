package ui

import (
	"math"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/theme"
	"github.com/sazardev/enfo/tui/internal/worldmap"
)

// The map is cropped to the latitudes people live at: Antarctica would eat a
// quarter of the height for nothing. Longitude is the whole world, and the
// scale is the same in both axes (dots are square, so it is a true
// equirectangular map).
const (
	worldLatTop  = 84.0
	worldLatBot  = -60.0
	worldLatSpan = worldLatTop - worldLatBot
)

var worldDotBit = [2][4]uint8{{0x01, 0x02, 0x04, 0x40}, {0x08, 0x10, 0x20, 0x80}}

// worldMapView draws the day/night world map into a braille canvas. The land
// mask and graticule are sampled once per size; each frame only colors cells.
type worldMapView struct {
	canvas     *braille.Canvas
	cols, rows int
	s          float64 // dots per degree
	ox, oy     float64 // top-left of the map in dots
	mw, mh     float64
	landBits   []uint8
	gridBits   []uint8
	cellLat    []float32
	cellLon    []float32
	cellIn     []bool
	// where each city landed on the last draw, in cells (for labels and clicks)
	marks []worldMark
}

type worldMark struct {
	idx    int
	cx, cy int
}

// worldIdealRows is how many rows a map of the given columns needs.
func worldIdealRows(cols int) int {
	s := float64(cols*2) / 360
	return int(math.Ceil(worldLatSpan * s / 4))
}

func (v *worldMapView) rebuild(cols, rows int) {
	v.cols, v.rows = cols, rows
	v.canvas = braille.New(cols, rows)
	W, H := float64(cols*2), float64(rows*4)
	v.s = math.Min(W/360, H/worldLatSpan)
	v.mw, v.mh = 360*v.s, worldLatSpan*v.s
	v.ox, v.oy = (W-v.mw)/2, (H-v.mh)/2
	n := cols * rows
	v.landBits = make([]uint8, n)
	v.gridBits = make([]uint8, n)
	v.cellLat = make([]float32, n)
	v.cellLon = make([]float32, n)
	v.cellIn = make([]bool, n)
	grid := cols >= 44
	for y := 0; y < rows*4; y++ {
		fy := float64(y)
		if fy < v.oy || fy >= v.oy+v.mh {
			continue
		}
		lat0 := worldLatTop - (fy-v.oy)/v.s
		lat1 := worldLatTop - (fy+1-v.oy)/v.s
		for x := 0; x < cols*2; x++ {
			fx := float64(x)
			if fx < v.ox || fx >= v.ox+v.mw {
				continue
			}
			lon0 := (fx-v.ox)/v.s - 180
			lon1 := (fx+1-v.ox)/v.s - 180
			cell := (y/4)*cols + x/2
			bit := worldDotBit[x&1][y&3]
			if worldmap.Coverage(lon0, lat0, lon1, lat1) >= 0.4 {
				v.landBits[cell] |= bit
				continue
			}
			if grid {
				vert := math.Floor(lon0/30) != math.Floor(lon1/30) && y%3 == 0
				horz := math.Floor(lat0/30) != math.Floor(lat1/30) && x%3 == 0
				if vert || horz {
					v.gridBits[cell] |= bit
				}
			}
		}
	}
	for cy := 0; cy < rows; cy++ {
		for cx := 0; cx < cols; cx++ {
			i := cy*cols + cx
			px, py := float64(cx*2+1), float64(cy*4+2)
			if px < v.ox || px >= v.ox+v.mw || py < v.oy || py >= v.oy+v.mh {
				continue
			}
			v.cellIn[i] = true
			v.cellLon[i] = float32((px-v.ox)/v.s - 180)
			v.cellLat[i] = float32(worldLatTop - (py-v.oy)/v.s)
		}
	}
}

// project converts a place to dot coordinates (ok is false off the map).
func (v *worldMapView) project(lat, lon float64) (x, y float64, ok bool) {
	x = v.ox + (lon+180)*v.s
	y = v.oy + (worldLatTop-lat)*v.s
	return x, y, lat <= worldLatTop && lat >= worldLatBot
}

// worldDayFactor maps the sun's height to how lit a place is: 0 in full night
// (below -18°, astronomical twilight), 1 once the sun is a few degrees up,
// smooth in between so the terminator is a soft band, not a line.
func worldDayFactor(alt float64) float64 {
	return anim.Smooth((alt + 18) / 24)
}

// worldColors derive the map palette from the theme.
type worldColors struct {
	dayLand, nightLand braille.RGB
	dayGrid, nightGrid braille.RGB
	dusk               braille.RGB
}

func worldPalette(p theme.Palette) worldColors {
	day := p.Accent
	if !p.Dark {
		day = p.Bright
	}
	return worldColors{
		dayLand:   day,
		nightLand: p.Bg.Mix(day, 0.34),
		dayGrid:   p.Bg.Mix(p.Muted, 0.42),
		nightGrid: p.Bg.Mix(p.Muted, 0.16),
		dusk:      p.Sun,
	}
}

// draw renders the map for the given instant. cities are drawn as markers;
// sel is the selected one (-1 for none); t is the animation clock; ping is
// the age (seconds) of the selection ring.
func (v *worldMapView) draw(pal theme.Palette, now time.Time, cities []engine.City, sel int, t, ping float64, still bool) {
	c := v.canvas
	c.Clear()
	col := worldPalette(pal)
	sunLat, sunLon := engine.SubSolar(now)
	for cy := 0; cy < v.rows; cy++ {
		for cx := 0; cx < v.cols; cx++ {
			i := cy*v.cols + cx
			if !v.cellIn[i] {
				continue
			}
			land, grid := v.landBits[i], v.gridBits[i]
			if land == 0 && grid == 0 {
				continue
			}
			alt := engine.SunAltitude(float64(v.cellLat[i]), float64(v.cellLon[i]), sunLat, sunLon)
			f := worldDayFactor(alt)
			if land != 0 {
				cc := col.nightLand.Mix(col.dayLand, f)
				// a breath of warmth right on the terminator
				if w := 1 - math.Min(1, math.Abs(alt+1.5)/7); w > 0 {
					cc = cc.Mix(col.dusk, 0.28*w*w)
				}
				c.SetBits(cx, cy, land, cc)
			} else {
				c.SetBits(cx, cy, grid, col.nightGrid.Mix(col.dayGrid, f))
			}
		}
	}

	// the sun, over the sub-solar point
	if x, y, ok := v.project(sunLat, sunLon); ok {
		pulse := 0.5
		if !still {
			pulse = 0.5 + 0.5*math.Sin(t*2)
		}
		c.Disc(x, y, 2.2, braille.Solid(pal.Sun))
		for k := 0; k < 8; k++ {
			a := float64(k) * math.Pi / 4
			x0, y0 := braille.Polar(x, y, 3.6, a)
			x1, y1 := braille.Polar(x, y, 5+1.6*pulse, a)
			c.Line(x0, y0, x1, y1, 1, braille.Solid(pal.Sun.Mix(pal.Bg, 0.25)))
		}
	}

	// cities
	v.marks = v.marks[:0]
	for i, city := range cities {
		x, y, ok := v.project(city.Lat, city.Lon)
		if !ok {
			continue
		}
		v.marks = append(v.marks, worldMark{idx: i, cx: int(x) / 2, cy: int(y) / 4})
		if i == sel {
			continue // drawn last, on top
		}
		r := 1.3
		mc := pal.Text
		if i == 0 {
			c.Arc(x, y, 3.2, 1, 0, 2*math.Pi, false, braille.Solid(pal.Faint.Mix(pal.Text, 0.35)))
		}
		c.Disc(x, y, r, braille.Solid(mc))
	}
	if sel >= 0 && sel < len(cities) {
		if x, y, ok := v.project(cities[sel].Lat, cities[sel].Lon); ok {
			ring := 5.0
			if !still {
				ring = 5 + 1.6*math.Sin(t*3.2)
			}
			c.Arc(x, y, ring, 1.6, 0, 2*math.Pi, false, braille.Solid(pal.Accent))
			c.Arc(x, y, 3.6, 1, 0, 2*math.Pi, false, braille.Solid(pal.Bright))
			if !still && ping < 1.3 {
				k := ping / 1.3
				r := anim.OutCubic(k) * 16
				c.Arc(x, y, r, 1, 0, 2*math.Pi, false, braille.Solid(pal.Bg.Mix(pal.Bright, 1-k)))
			}
			c.EraseDisc(x, y, 2.6)
			c.Disc(x, y, 2.1, braille.Solid(pal.Bright.Lighten(0.3)))
		}
	}
}

// lines renders the canvas with city labels stamped on top.
func (v *worldMapView) lines(pal theme.Palette, cities []engine.City, sel int, lang string) []string {
	lines := v.canvas.Lines()
	if v.cols < 36 {
		return lines
	}
	type rect struct{ x0, y0, x1, y1 int } // [x0,x1) x [y0,y1)
	var taken []rect
	free := func(r rect) bool {
		if r.x0 < 0 || r.y0 < 0 || r.x1 > v.cols || r.y1 > v.rows {
			return false
		}
		for _, t := range taken {
			if r.x0 < t.x1+1 && r.x1+1 > t.x0 && r.y0 < t.y1 && r.y1 > t.y0 {
				return false
			}
		}
		for _, m := range v.marks {
			if m.cx >= r.x0-1 && m.cx <= r.x1 && m.cy >= r.y0 && m.cy < r.y1 {
				return false
			}
		}
		return true
	}
	// markers first, so labels never sit on a city
	order := make([]worldMark, 0, len(v.marks))
	for _, m := range v.marks {
		if m.idx == sel {
			order = append(order, m)
		}
	}
	for _, m := range v.marks {
		if m.idx != sel {
			order = append(order, m)
		}
	}
	for _, m := range order {
		if m.idx != sel && v.cols < 56 {
			continue
		}
		name := cities[m.idx].Name(lang)
		if r := []rune(name); len(r) > 14 {
			name = string(r[:13]) + "…"
		}
		w := width(name)
		cands := []rect{
			{m.cx + 2, m.cy, m.cx + 2 + w, m.cy + 1},
			{m.cx - 1 - w, m.cy, m.cx - 1, m.cy + 1},
			{m.cx - w/2, m.cy - 1, m.cx - w/2 + w, m.cy},
			{m.cx - w/2, m.cy + 1, m.cx - w/2 + w, m.cy + 2},
		}
		for _, r := range cands {
			if !free(r) {
				continue
			}
			taken = append(taken, r)
			style := paint(pal.Muted, name)
			if m.idx == sel {
				style = bold(pal.Text, name)
			}
			lines[r.y0] = stamp(lines[r.y0], r.x0, style)
			break
		}
	}
	return lines
}

func worldFmtLat(lat float64) string {
	h := "N"
	if lat < 0 {
		h, lat = "S", -lat
	}
	return strings.TrimRight(strings.TrimRight(worldFmt1(lat), "0"), ".") + "°" + h
}

func worldFmtLon(lon float64) string {
	h := "E"
	if lon < 0 {
		h, lon = "W", -lon
	}
	return strings.TrimRight(strings.TrimRight(worldFmt1(lon), "0"), ".") + "°" + h
}

func worldFmt1(f float64) string {
	n := int(math.Round(f * 10))
	return itoa(n/10) + "." + itoa(n%10)
}
