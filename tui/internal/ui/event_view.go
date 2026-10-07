package ui

import (
	"strings"
	"time"

	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func (m *eventMode) View(w, h int) string {
	if w < 8 || h < 2 {
		return join(blank(maxi(w, 0), maxi(h, 0)))
	}
	items := m.st.data.Items
	if len(items) == 0 && m.form == nil {
		return join(fit(m.emptyView(w, h), w, h))
	}
	if m.selID == 0 || m.st.find(m.selID) == nil {
		if len(items) > 0 {
			m.selectNear()
		}
	}
	var hv eventView
	hasHero := false
	if m.form != nil {
		// the hero previews the event being edited
		it := &eventItem{Name: strings.TrimSpace(m.form.name.Value()), At: m.form.at, Yearly: m.form.yearly, Created: m.c.Now, Accent: 0}
		if m.form.id != 0 {
			if cur := m.st.find(m.form.id); cur != nil {
				it.Accent, it.Created = cur.Accent, cur.Created
			}
		}
		hv, hasHero = eventResolve(it, m.c.Now), true
		if hv.Item.Name == "" {
			hv.Item.Name = i18n.T("event.default")
		}
	} else if v, ok := m.selected(); ok {
		hv, hasHero = v, true
	}

	switch {
	case w >= 96 && h >= 18:
		return join(fit(m.wideView(w, h, hv, hasHero), w, h))
	case h >= 15 && w >= 40:
		return join(fit(m.stackedView(w, h, hv, hasHero), w, h))
	}
	return join(fit(m.tinyView(w, h, hv, hasHero), w, h))
}

// heroBlock renders the canvas plus the name and caption lines in a w x h box.
func (m *eventMode) heroBlock(w, h int, v eventView, x0, y0 int) []string {
	c := m.c
	textRows := 2
	rows := h - textRows
	if rows > w/2 {
		rows = w / 2
	}
	if rows < 12 {
		return m.heroText(w, h, v)
	}
	cols := rows * 2
	if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
		m.canvas = braille.New(cols, rows)
	} else {
		m.canvas.Clear()
	}
	still := c.Cfg.Motion == "still"
	labels := eventHero(m.canvas, c.Pal, braille.ParseFont(c.Cfg.Font), v, c.Now, m.t, still)
	m.shimmer.Draw(m.canvas, c.Pal.Bg)
	m.confetti.Draw(m.canvas, c.Pal.Bg)
	lines := m.canvas.Lines()
	overlayLabels(lines, labels)
	main, hi := eventTint(c.Pal, v.Item.Accent)
	out := make([]string, 0, h)
	top := (h - textRows - rows) / 2
	for i := 0; i < top; i++ {
		out = append(out, spaces(w))
	}
	for _, l := range lines {
		out = append(out, centerIn(l, w))
	}
	m.hero.x, m.hero.y, m.hero.w, m.hero.h = x0+(w-cols)/2, y0+top, cols, rows
	name := ansi.Truncate(v.Item.Name, w, "…")
	out = append(out, centerIn(bold(hi, name), w))
	cap := ansi.Truncate(eventCaption(v, c.Now), w, "…")
	out = append(out, centerIn(paint(c.Pal.Muted, cap), w))
	_ = main
	return fit(out, w, h)
}

// heroText is the picture-less hero for tiny spaces.
func (m *eventMode) heroText(w, h int, v eventView) []string {
	c := m.c
	_, hi := eventTint(c.Pal, v.Item.Accent)
	days, hh, mm, ss := eventParts(v.Left)
	var count string
	switch {
	case v.Arrived:
		count = strings.ToUpper(i18n.T("event.now"))
	case days > 0:
		count = itoa(days) + "d " + padTime(hh, mm, ss)
	default:
		count = padTime(hh, mm, ss)
	}
	if v.Past && !v.Arrived {
		count = i18n.T("event.ago", count)
	}
	lines := []string{
		centerIn(bold(hi, ansi.Truncate(v.Item.Name, w, "…")), w),
		centerIn(bold(c.Pal.Text, count), w),
		centerIn(paint(c.Pal.Muted, ansi.Truncate(eventCaption(v, c.Now), w, "…")), w),
	}
	if h >= 4 {
		main, _ := eventTint(c.Pal, v.Item.Accent)
		bw := clampi(w-6, 4, 44)
		filled := int(v.Progress*float64(bw) + 0.5)
		var sb strings.Builder
		for i := 0; i < bw; i++ {
			if i < filled {
				sb.WriteString(paint(main, "⣿"))
			} else {
				sb.WriteString(paint(c.Pal.Faint, "⣀"))
			}
		}
		lines = append(lines, centerIn(sb.String(), w))
	}
	return centerBlock(lines, w, h)
}

func (m *eventMode) wideView(w, h int, hv eventView, ok bool) []string {
	listW := clampi(w*36/100, 34, 52)
	heroW := w - listW - 2
	var hero []string
	if ok {
		hero = m.heroBlock(heroW, h, hv, 0, 0)
	} else {
		hero = blank(heroW, h)
	}
	var side []string
	if m.form != nil {
		side = m.formLines(listW, h)
	} else {
		side = m.listLines(listW, h, heroW+2, 0)
	}
	return hcat(hero, blank(2, h), side)
}

func (m *eventMode) stackedView(w, h int, hv eventView, ok bool) []string {
	if m.form != nil {
		return m.formLines(w, h)
	}
	listRows := clampi(h/3, 4, 8)
	heroH := h - listRows
	var out []string
	if ok {
		out = m.heroBlock(w, heroH, hv, 0, 0)
	} else {
		out = blank(w, heroH)
	}
	return append(out, m.listLines(w, listRows, 0, heroH)...)
}

func (m *eventMode) tinyView(w, h int, hv eventView, ok bool) []string {
	if m.form != nil {
		return m.formLines(w, h)
	}
	if h < 5 {
		if ok {
			return m.heroText(w, h, hv)
		}
		return blank(w, h)
	}
	heroH := 4
	out := m.heroText(w, heroH, hv)
	return append(out, m.listLines(w, h-heroH, 0, heroH)...)
}

// ---------------------------------------------------------------- list

func (m *eventMode) listLines(w, h, x0, y0 int) []string {
	c := m.c
	pal := c.Pal
	vs := eventSorted(m.st.data.Items, c.Now)
	out := blank(w, h)
	m.ids = m.ids[:0]
	if len(vs) == 0 {
		return out
	}
	// the title row (only when there is room); a short list floats to the middle
	start := 0
	rows := h
	if h >= 6 {
		rows = minI(h-2, len(vs))
		top := 0
		if h >= 12 {
			top = (h - (rows + 2)) / 2
		}
		out[top] = paint(pal.Muted, ansi.Truncate(strings.ToUpper(i18n.T("mode.event")), w, ""))
		start = top + 2
	}
	sel := 0
	for i, v := range vs {
		if v.Item.ID == m.selID {
			sel = i
		}
	}
	first := 0
	if sel >= rows {
		first = sel - rows + 1
	}
	m.list.x, m.list.y, m.list.w, m.list.rows, m.list.first = x0, y0+start, w, rows, first
	for r := 0; r < rows && first+r < len(vs); r++ {
		v := vs[first+r]
		m.ids = append(m.ids, v.Item.ID)
		out[start+r] = m.listRow(w, v, v.Item.ID == m.selID)
	}
	if m.confirmDel != 0 && m.st.find(m.confirmDel) != nil {
		msg := i18n.T("event.confirm", m.st.find(m.confirmDel).Name) + "  " + paint(pal.Muted, i18n.T("event.confirm.keys"))
		out[h-1] = padRight(bold(pal.Warn, ansi.Truncate(msg, w, "…")), w)
	}
	return out
}

func (m *eventMode) listRow(w int, v eventView, sel bool) string {
	pal := m.c.Pal
	main, hi := eventTint(pal, v.Item.Accent)
	when := eventShort(v.Left)
	switch {
	case v.Arrived:
		when = i18n.T("event.now")
	case v.Past:
		when = i18n.T("event.ago", eventShort(v.Left))
	}
	barW := 0
	if w >= 30 {
		barW = 6
	}
	mark := "  "
	if sel {
		mark = bold(hi, "▸ ")
	}
	whenW := 9
	nameW := w - 2 - whenW - 1
	if barW > 0 {
		nameW -= barW + 1
	}
	if nameW < 4 {
		nameW = 4
	}
	name := ansi.Truncate(v.Item.Name, nameW, "…")
	nameS := paint(pal.Muted, padRight(name, nameW))
	if sel {
		nameS = bold(pal.Text, padRight(name, nameW))
	}
	tag := " "
	if v.Item.Yearly {
		tag = "↻"
	}
	_ = tag
	whenS := padLeft(when, whenW)
	if v.Past && !v.Arrived {
		whenS = paint(pal.Faint, whenS)
	} else {
		whenS = paint(main, whenS)
	}
	line := mark + nameS + " " + whenS
	if barW > 0 {
		var sb strings.Builder
		filled := int(v.Progress*float64(barW) + 0.5)
		for i := 0; i < barW; i++ {
			if i < filled {
				sb.WriteString(paint(main, "⣿"))
			} else {
				sb.WriteString(paint(pal.Faint, "⣀"))
			}
		}
		line += " " + sb.String()
	}
	return padRight(line, w)
}

// ---------------------------------------------------------------- form

func (m *eventMode) formLines(w, h int) []string {
	f := m.form
	pal := m.c.Pal
	_, hi := eventTint(pal, 0)
	title := i18n.T("event.new")
	if f.id != 0 {
		title = i18n.T("event.edit")
	}
	label := func(s string) string { return paint(pal.Muted, padRight(s, 8)) }
	chip := func(idx int, text string) string {
		if f.focus == idx {
			return bold(pal.Bg, "\x1b[48;2;"+rgbCSV(hi)+"m "+text+" \x1b[49m")
		}
		return paint(pal.Text, " "+text+" ")
	}
	t := f.at
	month := t.Format("Jan")
	if i18n.Lang() == "es" {
		month = esMonths[t.Month()-1]
	}
	f.name.SetWidth(maxi(8, minI(32, w-12)))
	nameLine := label(i18n.T("event.name")) + f.name.View()
	if f.focus != 0 {
		nameLine = label(i18n.T("event.name")) + paint(pal.Text, f.name.View())
	}
	yearly := "○"
	if f.yearly {
		yearly = "●"
	}
	yl := chip(6, yearly+" "+i18n.T("event.yearly"))
	lines := []string{
		bold(hi, strings.ToUpper(title)),
		"",
		nameLine,
		label(i18n.T("event.date")) + chip(1, itoa(t.Year())) + chip(2, month) + chip(3, pad2(t.Day())),
		label(i18n.T("event.time")) + chip(4, pad2(t.Hour())) + paint(pal.Muted, ":") + chip(5, pad2(t.Minute())),
		label("") + yl,
		"",
	}
	prev := eventResolve(&eventItem{Name: "x", At: f.at, Yearly: f.yearly, Created: m.c.Now}, m.c.Now)
	lines = append(lines, paint(pal.Muted, ansi.Truncate(eventCaption(prev, m.c.Now), w, "…")))
	lines = append(lines, "", paint(pal.Muted, ansi.Truncate(i18n.T("event.form.hint"), w, "…")))
	out := blank(w, h)
	top := maxi(0, (h-len(lines))/2)
	if h < len(lines) {
		top = 0
	}
	for i, l := range lines {
		if top+i < h {
			out[top+i] = padRight(l, w)
		}
	}
	return out
}

// ---------------------------------------------------------------- empty

func (m *eventMode) emptyView(w, h int) []string {
	c := m.c
	pal := c.Pal
	textRows := 3
	rows := minI(h-textRows, w/2)
	var lines []string
	if rows >= 4 {
		cols := rows * 2
		if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
			m.canvas = braille.New(cols, rows)
		} else {
			m.canvas.Clear()
		}
		eventFlag(m.canvas, pal, m.t, c.Cfg.Motion == "still")
		for _, l := range m.canvas.Lines() {
			lines = append(lines, centerIn(l, w))
		}
	}
	lines = append(lines, "",
		centerIn(bold(pal.Text, ansi.Truncate(i18n.T("event.empty.title"), w, "…")), w),
		centerIn(paint(pal.Muted, ansi.Truncate(i18n.T("event.empty.body"), w, "…")), w))
	return centerBlock(lines, w, h)
}

var _ = time.Second
