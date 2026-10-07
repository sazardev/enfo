package ui

import (
	"fmt"
	"strings"
	"time"

	"charm.land/lipgloss/v2"
	"charm.land/lipgloss/v2/table"
	"charm.land/lipgloss/v2/tree"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func statsDayStart(t time.Time) time.Time {
	y, m, d := t.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, t.Location())
}

// ------------------------------------------------------------------- hero

type statsCard struct {
	label, value, sub string
	col               braille.RGB
}

func (s *statsPage) cards() []statsCard {
	pal := s.pal
	d := s.data
	e := s.count()
	scaleD := func(x time.Duration) time.Duration { return time.Duration(float64(x) * e) }
	scaleN := func(n int) int { return int(float64(n)*e + 0.5) }

	today := d.all.Today
	week := d.all.Week
	cards := []statsCard{
		{i18n.T("stats.card.today"), statsDur(scaleD(today.Focus)), statsPlural(scaleN(today.Sessions), "pomo.session.1", "pomo.sessions"), pal.Accent},
		{i18n.T("stats.card.week"), statsDur(scaleD(week)), i18n.T("stats.card.perday", statsDur(scaleD(week/7))), pal.Accent},
	}
	streak := d.all.Streak
	sv := fmt.Sprintf("🔥 %d", scaleN(streak))
	ss := i18n.T("pomo.streak.d", streak)
	if streak == 1 {
		ss = i18n.T("pomo.streak.1")
	}
	if streak == 0 {
		sv, ss = "—", i18n.T("stats.card.nostreak")
	}
	cards = append(cards, statsCard{i18n.T("pomo.streak"), sv, ss, pal.Warn})
	cards = append(cards, statsCard{i18n.T("stats.card.sessions"), fmt.Sprint(scaleN(d.rng.Sessions)), i18n.T("stats.range", s.rng), pal.Good})
	if d.hasComp {
		cards = append(cards, statsCard{i18n.T("stats.card.completion"), fmt.Sprintf("%d%%", scaleN(int(d.comp*100+0.5))),
			i18n.T("stats.card.stopped", d.rng.Abandoned), pal.Rest})
	} else {
		cards = append(cards, statsCard{i18n.T("stats.card.completion"), "—", i18n.T("stats.card.nodata"), pal.Rest})
	}
	cards = append(cards, statsCard{i18n.T("stats.card.avg"), statsDur(scaleD(d.rng.AvgPerDay)), i18n.T("stats.card.activeday"), pal.Soft.Lighten(0.25)})
	best := i18n.T("stats.card.nodata")
	if d.rng.BestDay.Focus > 0 {
		best = statsDate(d.rng.BestDay.Day)
	}
	cards = append(cards, statsCard{i18n.T("stats.card.best"), statsDur(scaleD(d.rng.BestDay.Focus)), best, pal.Sun})
	return cards
}

// hero is a grid of cards: a faint bar, the label, the number, a footnote.
func (s *statsPage) hero(w, h int) []string {
	pal := s.pal
	cards := s.cards()
	if h < 1 {
		return nil
	}
	if h < 3 {
		// one line of label value pairs
		var parts []string
		for _, c := range cards {
			parts = append(parts, paint(pal.Muted, c.label+" ")+bold(c.col, c.value))
		}
		return fit([]string{" " + strings.Join(parts, paint(pal.Faint, "  ·  "))}, w, h)
	}
	cols := clampi(w/15, 1, len(cards))
	cw := w / cols
	perRow := cols
	rowsFit := maxi(h/4, 1)
	if h < 7 {
		rowsFit = 1
	}
	var out []string
	for r := 0; r < rowsFit && r*perRow < len(cards); r++ {
		var blocks [][]string
		for i := r * perRow; i < mini((r+1)*perRow, len(cards)); i++ {
			c := cards[i]
			bar := paint(pal.Faint.Mix(c.col, 0.55), "▎")
			iw := cw - 3
			blocks = append(blocks, []string{
				bar + " " + padRight(paint(pal.Muted, strings.ToUpper(c.label)), iw),
				bar + " " + padRight(bold(c.col, c.value), iw),
				bar + " " + padRight(paint(pal.Muted, c.sub), iw),
				spaces(cw - 1),
			})
			blocks = append(blocks, statsBlank(1, 4))
		}
		out = append(out, hcat(blocks...)...)
	}
	return fit(out, w, h)
}

// ------------------------------------------------------------------ chart

// statsNiceMax rounds the chart's top up to a friendly step.
func statsNiceMax(mx time.Duration) (top, step time.Duration) {
	for _, st := range []time.Duration{15 * time.Minute, 30 * time.Minute, time.Hour, 2 * time.Hour, 4 * time.Hour} {
		if mx <= 4*st {
			n := (mx + st - 1) / st
			if n < 1 {
				n = 1
			}
			return n * st, st
		}
	}
	return mx, mx
}

func statsAxis(d time.Duration) string {
	if d == 0 {
		return "0"
	}
	if d%time.Hour == 0 {
		return fmt.Sprintf("%dh", int(d/time.Hour))
	}
	if d < time.Hour {
		return fmt.Sprintf("%dm", int(d/time.Minute))
	}
	return fmt.Sprintf("%dh%02d", int(d/time.Hour), int(d%time.Hour/time.Minute))
}

func (s *statsPage) chartBlock(w, h int) []string {
	pal := s.pal
	if h < 5 || w < 22 {
		return statsBlank(w, h)
	}
	yw := 6
	plotCols := w - yw
	plotRows := h - 3
	cv := s.cv("chart", plotCols, plotRows)
	days := s.data.rng.Days
	n := mini(len(days), cv.W/2)
	shown := days[len(days)-n:]
	pitch := mini(cv.W/n, 10)
	left := (cv.W - n*pitch) / 2
	barW := pitch - 1
	if pitch >= 8 {
		barW = pitch - 2
	}
	if barW < 1 {
		barW = 1
	}
	var mx time.Duration
	for _, d := range shown {
		if d.Focus > mx {
			mx = d.Focus
		}
	}
	if mx < 10*time.Minute {
		mx = 10 * time.Minute
	}
	ymax, step := statsNiceMax(mx)
	H := float64(cv.H)
	base := H - 1
	span := H - 3
	yOf := func(v time.Duration) float64 { return base - float64(v)/float64(ymax)*span }

	// grid
	gridCol := pal.Bg.Mix(pal.Faint, 0.8)
	var gridRows []int
	for v := time.Duration(0); v <= ymax; v += step {
		y := int(yOf(v) + 0.5)
		gridRows = append(gridRows, y)
		for x := 0; x < cv.W; x += 4 {
			cv.Set(x, y, gridCol)
		}
	}
	// selected column guide
	selI := n - 1 - s.sel
	if selI >= 0 && selI < n {
		x := left + selI*pitch + pitch/2
		for y := 0; y < cv.H; y += 3 {
			cv.Set(x, y, pal.Faint)
		}
	}
	// bars
	grad := braille.Gradient{pal.Bg.Mix(pal.Accent, 0.45), pal.Accent, pal.Bright}
	for i, d := range shown {
		x := float64(left + i*pitch + (pitch-barW)/2)
		g := s.grow(i, 0.014)
		frac := float64(d.Focus) / float64(ymax)
		hgt := frac * span * g
		col := grad.At(float64(d.Focus) / float64(mx))
		if i == selI {
			col = pal.Bright.Lighten(0.45)
		}
		if d.Focus == 0 {
			cv.Rect(int(x), int(base), barW, 1, braille.Solid(pal.Faint))
			continue
		}
		if hgt < 2 {
			hgt = 2
		}
		cv.RoundRect(x, base-hgt+1, float64(barW), hgt, float64(minInt(barW/2, 2)), braille.Solid(col))
	}
	// average of active days
	if avg := s.data.rng.AvgPerDay; avg > 0 {
		y := yOf(avg)
		for x := 0; x < cv.W; x += 3 {
			cv.Set(x, int(y+0.5), pal.Warn.Mix(pal.Bg, 0.55))
		}
	}
	lines := cv.Lines()
	// y axis
	ylab := statsBlank(yw, plotRows)
	for i, v := 0, time.Duration(0); v <= ymax; i, v = i+1, v+step {
		r := gridRows[i] / 4
		if r >= 0 && r < plotRows {
			ylab[r] = padLeft(paint(pal.Muted, statsAxis(v)), yw-1) + " "
		}
	}
	body := hcat(ylab, lines)

	// header: title, legend and the selected day
	title := bold(pal.Text, i18n.T("stats.chart.title")) + paint(pal.Muted, " · "+i18n.T("stats.range", s.rng))
	if avg := s.data.rng.AvgPerDay; avg > 0 {
		legend := paint(pal.Warn.Mix(pal.Bg, 0.7), "⠒⠒ ") + paint(pal.Muted, i18n.T("stats.chart.avg", statsDur(avg)))
		if width(title)+width(legend)+3 < w {
			title = padRight(title, w-width(legend)-1) + legend
		}
	}
	readout := paint(pal.Muted, " ")
	if selI >= 0 && selI < n {
		d := shown[selI]
		name := statsDate(d.Day)
		if s.sel == 0 {
			name += " · " + i18n.T("stats.today")
		}
		readout = bold(pal.Accent, "▸ ") + bold(pal.Text, name) + paint(pal.Muted, "  "+statsDur(d.Focus)+" · "+sessionsText(d.Sessions))
	}
	// x axis
	axis := spaces(w)
	put := func(i int, text string, align int) {
		col := yw + (left+i*pitch+pitch/2)/2
		tw := width(text)
		switch align {
		case 0:
			col -= tw / 2
		case 1:
			col = col - tw + 1
		}
		axis = stamp(axis, clampi(col, yw, w-tw), paint(pal.Muted, text))
	}
	first := shown[0].Day
	put(0, itoa(first.Day())+" "+statsMonthName(first.Month()), -1)
	if n > 12 {
		mid := shown[n/2].Day
		put(n/2, itoa(mid.Day())+" "+statsMonthName(mid.Month()), 0)
	}
	put(n-1, i18n.T("stats.today"), 1)

	s.chart.r = statsRect{x: yw, y: 2, w: plotCols, h: plotRows}
	s.chart.cols, s.chart.left, s.chart.pitch, s.chart.n = plotCols, left, pitch, n
	out := []string{padRight(" "+title, w), padRight(" "+readout, w)}
	out = append(out, body...)
	out = append(out, axis)
	return fit(out, w, h)
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ---------------------------------------------------------------- heat map

func (s *statsPage) heatBlock(w, h int) []string {
	pal := s.pal
	if h < 5 || w < 16 {
		return statsBlank(w, h)
	}
	step := 2
	weeks := (w - 4) / 2
	if weeks < 14 {
		step = 1
		weeks = w - 4
	}
	weeks = mini(weeks, 26)
	today := statsDayStart(s.c.Now)
	wd := (int(today.Weekday()) + 6) % 7
	first := today.AddDate(0, 0, -wd-(weeks-1)*7)
	byDay := map[time.Time]engine.DayStat{}
	for _, d := range s.data.all.Days {
		byDay[d.Day] = d
	}
	grad := braille.Gradient{pal.Bg.Mix(pal.Accent, 0.55), pal.Accent, pal.Bright}
	selDay := today.AddDate(0, 0, -s.sel)

	title := bold(pal.Text, i18n.T("stats.heat.title")) + paint(pal.Muted, " · "+i18n.T("stats.heat.weeks", weeks))
	out := []string{padRight(" "+title, w)}

	// month labels
	mrow := spaces(w)
	lastEnd := 0
	for c := 0; c < weeks; c++ {
		mon := first.AddDate(0, 0, c*7)
		if mon.Day() <= 7 {
			lb := statsMonthName(mon.Month())
			x := 4 + c*step
			if x >= lastEnd && x+width(lb) <= w {
				mrow = stamp(mrow, x, paint(pal.Muted, lb))
				lastEnd = x + width(lb) + 1
			}
		}
	}
	out = append(out, mrow)
	gridY := len(out)
	for r := 0; r < 7; r++ {
		lab := "    "
		if r%2 == 0 {
			lab = padRight(paint(pal.Muted, statsWeekdayName(time.Weekday((r+1)%7))), 4)
		}
		var sb strings.Builder
		sb.WriteString(lab)
		for c := 0; c < weeks; c++ {
			day := first.AddDate(0, 0, c*7+r)
			cell := " "
			if !day.After(today) && s.grow(c, 0.022) > 0.12 {
				ds := byDay[day]
				lvl := ds.Level()
				var ch string
				if lvl == 0 {
					ch = paint(pal.Faint, "⠶")
				} else {
					ch = paint(grad.At(float64(lvl-1)/3), "⣿")
				}
				if day.Equal(selDay) {
					col := pal.Text
					if lvl > 0 {
						col = pal.Bright.Lighten(0.5)
					}
					ch = "\x1b[7m" + paint(col, "⣿") + "\x1b[27m"
				}
				cell = ch
			}
			sb.WriteString(cell)
			if step == 2 {
				sb.WriteString(" ")
			}
		}
		out = append(out, padRight(sb.String(), w))
	}
	s.heat.r = statsRect{x: 4, y: gridY, w: weeks * step, h: 7}
	s.heat.weeks, s.heat.step, s.heat.first, s.heat.gridY = weeks, step, first, gridY

	if h >= 11 {
		legend := paint(pal.Muted, i18n.T("stats.heat.less")+" ") + paint(pal.Faint, "⠶ ")
		for l := 1; l <= 4; l++ {
			legend += paint(grad.At(float64(l-1)/3), "⣿ ")
		}
		legend += paint(pal.Muted, i18n.T("stats.heat.more"))
		out = append(out, padRight("    "+legend, w))
		ro := paint(pal.Muted, "    ")
		if ds, ok := engine.StatsDayAt(s.data.all, selDay); ok {
			ro = "    " + bold(pal.Accent, "▸ ") + bold(pal.Text, statsDate(ds.Day)) +
				paint(pal.Muted, "  "+statsDur(ds.Focus)+" · "+sessionsText(ds.Sessions))
		}
		out = append(out, padRight(ro, w))
	}
	return fit(out, w, h)
}

// -------------------------------------------------------------- hour / week

func (s *statsPage) hoursBlock(w, h int) []string {
	pal := s.pal
	if h < 5 || w < 28 {
		return statsBlank(w, h)
	}
	title := bold(pal.Text, i18n.T("stats.hours.title")) + paint(pal.Muted, " · "+i18n.T("stats.range", s.rng))
	hr := s.data.hourly
	pitch := clampi((w*2)/24, 2, 5)
	cols := (24*pitch + 1) / 2
	rows := h - 3
	cv := s.cv("hours", cols, rows)
	var mx time.Duration
	for _, d := range hr {
		if d > mx {
			mx = d
		}
	}
	best, ok := s.data.best, s.data.hasBest
	grad := braille.Gradient{pal.Bg.Mix(pal.Rest, 0.45), pal.Rest, pal.RestHi}
	base := float64(cv.H - 1)
	for i, d := range hr {
		x := float64(i * pitch)
		bw := float64(maxi(pitch-1, 1))
		if mx == 0 {
			cv.Rect(int(x), int(base), int(bw), 1, braille.Solid(pal.Faint))
			continue
		}
		f := float64(d) / float64(mx)
		hgt := f * float64(cv.H-3) * s.grow(i, 0.02)
		col := grad.At(f)
		if ok && i == best {
			col = pal.Accent.Lighten(0.2)
		}
		if d == 0 {
			cv.Rect(int(x), int(base), int(bw), 1, braille.Solid(pal.Faint))
			continue
		}
		if hgt < 2 {
			hgt = 2
		}
		cv.RoundRect(x, base-hgt+1, bw, hgt, 1, braille.Solid(col))
	}
	lines := cv.Lines()
	left := (w - cols) / 2
	axis := spaces(w)
	for _, hh := range []int{0, 6, 12, 18} {
		lb := fmt.Sprintf("%02d", hh)
		axis = stamp(axis, left+(hh*pitch)/2, paint(pal.Muted, lb))
	}
	axis = stamp(axis, left+(23*pitch)/2, paint(pal.Muted, "23"))
	peak := paint(pal.Muted, i18n.T("stats.hours.none"))
	if ok {
		peak = bold(pal.Accent, "▸ ") + paint(pal.Muted, i18n.T("stats.hours.peak", fmt.Sprintf("%02d:00–%02d:00", best, (best+1)%24)))
	}
	out := []string{padRight(" "+title, w)}
	for _, l := range lines {
		out = append(out, spaces(left)+l)
	}
	out = append(out, axis, padRight(" "+peak, w))
	return fit(out, w, h)
}

func (s *statsPage) weekdaysBlock(w, h int) []string {
	pal := s.pal
	if h < 3 || w < 24 {
		return statsBlank(w, h)
	}
	title := bold(pal.Text, i18n.T("stats.week.title")) + paint(pal.Muted, " · "+i18n.T("stats.range", s.rng))
	out := []string{padRight(" "+title, w)}
	var mx time.Duration
	bestI := -1
	for i, d := range s.data.weekday {
		if d > mx {
			mx, bestI = d, i
		}
	}
	bw := clampi(w-18, 6, 40)
	for i := 0; i < 7 && len(out) < h; i++ {
		d := s.data.weekday[i]
		name := statsWeekdayName(time.Weekday((i + 1) % 7))
		col := pal.Accent.Mix(pal.Bg, 0.25)
		nameCol := pal.Muted
		if i == bestI {
			col, nameCol = pal.Bright, pal.Text
		}
		frac := 0.0
		if mx > 0 {
			frac = float64(d) / float64(mx) * s.grow(i, 0.05)
		}
		out = append(out, padRight(" "+padRight(paint(nameCol, name), 4)+statsHBar(frac, bw, col, pal.Faint)+" "+paint(pal.Muted, statsDur(d)), w))
	}
	return fit(out, w, h)
}

// ------------------------------------------------------------------ kinds

func (s *statsPage) kindsBlock(w, h int) []string {
	pal := s.pal
	if h < 4 || w < 30 {
		return statsBlank(w, h)
	}
	title := bold(pal.Text, i18n.T("stats.kinds.title")) + paint(pal.Muted, " · "+i18n.T("stats.range", s.rng))
	out := []string{padRight(" "+title, w)}
	var mx time.Duration
	for _, k := range s.data.kinds {
		if k.Dur > mx {
			mx = k.Dur
		}
	}
	barW := clampi(w-34, 4, 30)
	var rows [][]string
	var used []engine.StatsKind
	for _, k := range s.data.kinds {
		if k.Count == 0 && k.Kind != engine.KindFocus {
			continue
		}
		frac := 0.0
		if mx > 0 {
			frac = float64(k.Dur) / float64(mx)
		}
		col := statsKindColor(pal, k.Kind)
		rows = append(rows, []string{
			paint(col, statsKindIcon(k.Kind)) + " " + i18n.T("stats.kind."+string(k.Kind)),
			fmt.Sprint(k.Count),
			statsDur(k.Dur),
			statsHBar(frac*s.grow(len(rows), 0.07), barW, col, pal.Faint),
		})
		used = append(used, k)
	}
	if len(rows) > h-2 {
		rows = rows[:maxi(h-2, 1)]
	}
	hs := lipgloss.NewStyle().Foreground(pal.Muted)
	t := table.New().
		Border(lipgloss.NormalBorder()).
		BorderStyle(lipgloss.NewStyle().Foreground(pal.Faint)).
		BorderTop(false).BorderBottom(false).BorderLeft(false).BorderRight(false).
		BorderColumn(false).BorderHeader(true).
		Headers(i18n.T("stats.kinds.h.tool"), "#", i18n.T("stats.kinds.h.time"), "").
		StyleFunc(func(row, col int) lipgloss.Style {
			st := lipgloss.NewStyle().PaddingRight(2)
			if row == table.HeaderRow {
				return st.Inherit(hs)
			}
			if col == 1 || col == 2 {
				return st.Align(lipgloss.Right).Foreground(pal.Text)
			}
			return st.Foreground(pal.Text)
		}).
		Rows(rows...)
	tl := strings.Split(t.String(), "\n")
	for _, l := range tl {
		out = append(out, " "+l)
	}
	// the Pomodoro split as a tree
	if len(out)+4 <= h {
		var f engine.StatsKind
		for _, k := range used {
			if k.Kind == engine.KindFocus {
				f = k
			}
		}
		if f.Count > 0 {
			tr := tree.Root(paint(pal.Accent, "◔ ") + i18n.T("stats.kind.focus")).
				Child(paint(pal.Good, "✓ ") + i18n.T("stats.tree.done", f.Completed)).
				Child(paint(pal.Warn, "✗ ") + i18n.T("stats.tree.stopped", f.Count-f.Completed)).
				Enumerator(tree.RoundedEnumerator).
				EnumeratorStyle(lipgloss.NewStyle().Foreground(pal.Faint)).
				RootStyle(lipgloss.NewStyle().Foreground(pal.Text).Bold(true)).
				ItemStyle(lipgloss.NewStyle().Foreground(pal.Muted))
			out = append(out, "")
			for _, l := range strings.Split(tr.String(), "\n") {
				out = append(out, " "+l)
			}
		}
	}
	return fit(out, w, h)
}

// -------------------------------------------------------------------- log

func statsEvDur(d time.Duration) string {
	if d > 0 && d < time.Minute {
		return fmtDur(d)
	}
	return statsDur(d)
}

func (s *statsPage) logLines(w int) []string {
	pal := s.pal
	evs := engine.Recent(s.data.events, 400)
	lines := make([]string, 0, len(evs))
	for _, e := range evs {
		col := statsKindColor(pal, e.Kind)
		mark := paint(pal.Faint, "·")
		if e.Kind == engine.KindFocus || e.Kind == engine.KindRest || e.Kind == engine.KindLong {
			if e.Completed {
				mark = paint(pal.Good, "✓")
			} else {
				mark = paint(pal.Warn, "✗")
			}
		}
		st := e.Start.In(s.c.Now.Location())
		line := " " + paint(col, statsKindIcon(e.Kind)) + " " +
			padRight(paint(pal.Muted, statsDate(st)+" "+st.Format("15:04")), 17) + " " +
			padRight(paint(pal.Text, i18n.T("stats.kind."+string(e.Kind))), 12) +
			padLeft(paint(pal.Text, statsEvDur(e.Actual)), 7) + " " + mark
		if e.Label != "" {
			line += " " + paint(pal.Muted, e.Label)
		}
		lines = append(lines, padRight(line, w))
	}
	return lines
}

func (s *statsPage) logBlock(w, h int) []string {
	pal := s.pal
	if h < 3 || w < 24 {
		return statsBlank(w, h)
	}
	key := len(s.data.events)*100003 + w*131 + h
	if s.vpKey != key {
		s.vp.SetWidth(w)
		s.vp.SetHeight(h - 1)
		s.vp.SetContentLines(s.logLines(w))
		s.vpKey = key
		s.vpW, s.vpH = w, h
	}
	s.vp.SetWidth(w)
	s.vp.SetHeight(h - 1)
	pct := ""
	if s.vp.TotalLineCount() > s.vp.Height() {
		pct = paint(pal.Muted, fmt.Sprintf("%d%% ", int(s.vp.ScrollPercent()*100)))
	}
	title := bold(pal.Text, i18n.T("stats.log.title"))
	head := padRight(" "+title, w-width(pct)) + pct
	out := []string{padRight(head, w)}
	body := splitLines(s.vp.View())
	if len(s.data.events) == 0 {
		body = nil
	}
	out = append(out, body...)
	return fit(out, w, h)
}
