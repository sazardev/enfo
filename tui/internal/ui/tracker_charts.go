package ui

import (
	"math"
	"sort"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

var trackerEnDays = [...]string{"S", "M", "T", "W", "T", "F", "S"}
var trackerEsDays = [...]string{"D", "L", "M", "X", "J", "V", "S"}

func trackerDayInitial(t time.Time) string {
	if i18n.Lang() == "es" {
		return trackerEsDays[t.Weekday()]
	}
	return trackerEnDays[t.Weekday()]
}

// trackerLabel is a styled piece of text to place on a label row.
type trackerLabel struct {
	col  int
	text string // already styled
}

// trackerLabelRow lays labels out left to right on one row of w cells. It
// builds the row in a single pass: stamping many styled labels onto one line
// with stamp() makes the escape sequences pile up exponentially.
func trackerLabelRow(w int, items []trackerLabel) string {
	sort.SliceStable(items, func(i, j int) bool { return items[i].col < items[j].col })
	var sb strings.Builder
	pos := 0
	for _, it := range items {
		tw := width(it.text)
		if it.col < pos || it.col+tw > w || it.col < 0 {
			continue
		}
		sb.WriteString(spaces(it.col - pos))
		sb.WriteString(it.text)
		pos = it.col + tw
	}
	sb.WriteString(spaces(w - pos))
	return sb.String()
}

// timeline draws today as a 24-hour strip with every span in its color, the
// current moment marked, and hour labels underneath.
func (m *trackerMode) timeline(w int) []string {
	pal := m.c.Pal
	now := m.c.Now
	if w < 12 {
		return nil
	}
	if m.tl == nil || m.tl.Cols != w {
		m.tl = braille.New(w, 2)
	}
	c := m.tl
	c.Clear()
	day := 24 * time.Hour
	x := func(d time.Duration) float64 { return float64(d) / float64(day) * float64(c.W) }
	// the track: a faint dotted rail, with working hours (9-18) a touch brighter
	for dx := 0; dx < c.W; dx++ {
		for dy := 2; dy <= 5; dy++ {
			frac := float64(dx) / float64(c.W) * 24
			col := pal.Bg.Mix(pal.Faint, 0.35)
			if frac >= 9 && frac < 18 {
				col = pal.Bg.Mix(pal.Faint, 0.6)
			}
			if (dx+dy)%2 == 0 {
				c.Set(dx, dy, col)
			}
		}
	}
	for _, s := range m.t.Segments(now, now) {
		a := m.t.Get(s.Act)
		col := pal.Muted
		if a != nil {
			col = m.hue(a)
		}
		x0, x1 := x(s.From), x(s.To)
		if x1-x0 < 1.5 {
			x1 = x0 + 1.5
		}
		c.Rect(int(x0), 1, int(math.Ceil(x1-x0)), 6, braille.Solid(col))
		if s.Live && m.c.Cfg.Motion != "still" {
			// the live edge shimmers
			k := 0.5 + 0.5*math.Sin(m.c.Anim*6)
			c.Rect(int(x1)-1, 0, 2, 8, braille.Solid(col.Mix(pal.Text, 0.3+0.5*k)))
		}
	}
	// now
	nowOff := now.Sub(time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location()))
	nx := int(x(nowOff))
	c.Rect(nx, 0, 1, 8, braille.Solid(pal.Text))

	lines := c.Lines()
	// hour labels
	var items []trackerLabel
	step := 3
	if w < 50 {
		step = 6
	}
	for hr := 0; hr <= 24; hr += step {
		col := int(float64(hr) / 24 * float64(w))
		txt := itoa(hr)
		if hr == 24 {
			continue
		}
		items = append(items, trackerLabel{trackerMin2(col, w-len(txt)), paint(pal.Muted, txt)})
	}
	label := trackerLabelRow(w, items)
	title := bold(pal.Muted, strings.ToUpper(i18n.T("tracker.timeline")))
	return append([]string{padRight(title, w)}, append(lines, label)...)
}

func trackerMin2(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// chart is the stacked bar chart of the last N days, one color per activity,
// with a legend. It uses `h` rows in total.
func (m *trackerMode) chart(w, h int) []string {
	pal := m.c.Pal
	now := m.c.Now
	if w < 14 || h < 5 {
		return nil
	}
	days := trackerRanges[m.rng]
	rows := h - 3 // title, labels, legend
	if rows < 2 {
		return nil
	}
	if m.ch == nil || m.ch.Cols != w || m.ch.Rows != rows {
		m.ch = braille.New(w, rows)
	}
	c := m.ch
	c.Clear()

	type dayData struct {
		day    time.Time
		totals map[int]time.Duration
		sum    time.Duration
	}
	data := make([]dayData, days)
	var mx time.Duration
	for i := 0; i < days; i++ {
		d := now.AddDate(0, 0, -(days - 1 - i))
		t := m.t.DayTotals(d, now)
		data[i] = dayData{d, t, engine.TrackerSum(t)}
		if data[i].sum > mx {
			mx = data[i].sum
		}
	}
	// scale: the next whole hour above the busiest day (at least 1 h)
	scale := time.Hour * time.Duration(math.Ceil(mx.Hours()))
	if scale < time.Hour {
		scale = time.Hour
	}
	// order activities by color index so stacks are stable
	acts := append([]*engine.TrackerActivity(nil), m.t.Acts...)
	sort.SliceStable(acts, func(i, j int) bool { return acts[i].ID < acts[j].ID })

	pitch := float64(c.W) / float64(days)
	barW := math.Max(1, math.Floor(pitch*0.68))
	if pitch < 3 {
		barW = math.Max(1, pitch-1)
	}
	base := float64(c.H) - 1
	top := 3.0
	hmax := base - top
	// scale rail
	for x := 0; x < c.W; x += 4 {
		c.Dot(float64(x), top-1, pal.Bg.Mix(pal.Faint, 0.5))
	}
	for i, d := range data {
		x0 := float64(i)*pitch + (pitch-barW)/2
		if i == days-1 {
			// today gets a soft backdrop
			c.Rect(int(float64(i)*pitch), int(top), int(pitch), int(hmax)+1, braille.Solid(pal.Bg.Mix(pal.Faint, 0.18)))
		}
		y := base
		for _, a := range acts {
			dur := d.totals[a.ID]
			if dur <= 0 {
				continue
			}
			hh := float64(dur) / float64(scale) * hmax
			if hh < 1 {
				hh = 1
			}
			// draw the segment from y up
			c.Rect(int(x0), int(math.Round(y-hh)), int(barW), int(math.Max(1, math.Round(hh))), braille.Solid(m.hue(a)))
			y -= hh
		}
		if d.sum == 0 {
			c.Rect(int(x0), int(base), int(barW), 1, braille.Solid(pal.Bg.Mix(pal.Faint, 0.5)))
		}
	}
	lines := c.Lines()
	// the scale label sits on the top rail
	axis := paint(pal.Muted, itoa(int(scale.Hours()))+"h")
	lines[0] = stamp(lines[0], 0, axis)

	// day labels under the bars
	var items []trackerLabel
	cellPitch := pitch / 2
	every := 1
	if cellPitch < 2 {
		every = 5
	} else if cellPitch < 3.2 {
		every = 2
	}
	for i, d := range data {
		if (days-1-i)%every != 0 {
			continue
		}
		txt := trackerDayInitial(d.day)
		if every >= 5 || days > 14 {
			txt = itoa(d.day.Day())
		}
		col := int((float64(i)+0.5)*cellPitch) - len(txt)/2
		sty := paint(pal.Muted, txt)
		if i == days-1 {
			sty = bold(pal.Accent, txt)
		}
		items = append(items, trackerLabel{maxi(col, 0), sty})
	}
	label := trackerLabelRow(w, items)

	// legend
	var lg strings.Builder
	used := 0
	for _, a := range acts {
		item := paint(m.hue(a), "▌") + paint(pal.Muted, a.Name) + "  "
		iw := width(item)
		if used+iw > w {
			break
		}
		lg.WriteString(item)
		used += iw
	}
	title := bold(pal.Muted, strings.ToUpper(i18n.T("tracker.range", days))) +
		paint(pal.Faint, "   ←→")
	out := []string{padRight(title, w)}
	out = append(out, lines...)
	out = append(out, label, padRight(lg.String(), w))
	return out
}
