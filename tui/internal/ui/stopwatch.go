package ui

import (
	"fmt"
	"math"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"charm.land/lipgloss/v2/table"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

type stopwatchMode struct {
	c   *Core
	say func(string)

	face   *visual.StopwatchFace
	canvas *braille.Canvas
	pulse  float64
	scroll int

	faceArea timerRect
	lapArea  timerRect
	pageRows int
}

func init() {
	registerMode("stopwatch", func(c *Core, say func(string)) Mode { return newStopwatchMode(c, say) })
}

func newStopwatchMode(c *Core, say func(string)) *stopwatchMode {
	return &stopwatchMode{c: c, say: say, face: &visual.StopwatchFace{}, pageRows: 5}
}

func (m *stopwatchMode) ID() string { return "stopwatch" }

func (m *stopwatchMode) Title() string {
	sw := m.c.SW
	if !sw.Active() {
		return ""
	}
	icon := iconStopwatch
	if sw.Run != engine.Running {
		icon = "⏸"
	}
	return icon + " " + swText(sw.Elapsed(m.c.Now), true)
}

func (m *stopwatchMode) Animated() bool {
	if m.c.Cfg.Motion == "still" {
		return false
	}
	return m.c.SW.Run == engine.Running || m.pulse > 0
}

func (m *stopwatchMode) Help() []key.Binding {
	run := i18n.T("stopwatch.start")
	switch {
	case m.c.SW.Run == engine.Running:
		run = i18n.T("stopwatch.pause")
	case m.c.SW.Accum > 0:
		run = i18n.T("stopwatch.resume")
	}
	b := []key.Binding{kb("space", "space", run)}
	if m.c.SW.Run == engine.Running {
		b = append(b, kb("l|enter", "l", i18n.T("stopwatch.lap")))
	}
	b = append(b, kb("r", "r", i18n.T("stopwatch.reset")))
	if len(m.c.SW.Laps) > m.pageRows {
		b = append(b, kb("up|down|k|j", "↑↓", i18n.T("stopwatch.scroll")))
	}
	return append(b, kb("t", "t", i18n.T("stopwatch.font")))
}

func (m *stopwatchMode) Frame(dt time.Duration) {
	if m.pulse > 0 {
		m.pulse = math.Max(0, m.pulse-dt.Seconds()/0.7)
	}
}

func (m *stopwatchMode) toggle() {
	c := m.c
	if c.SW.Run != engine.Running {
		m.pulse = 1
	}
	c.SW.Toggle(c.Now)
	c.MarkDirty()
}

func (m *stopwatchMode) lap() {
	c := m.c
	if _, ok := c.SW.Lap(c.Now); ok {
		m.scroll = 0
		m.pulse = 1
		c.MarkDirty()
	}
}

func (m *stopwatchMode) scrollBy(d int) {
	n := len(m.c.SW.Laps)
	m.scroll = clampi(m.scroll+d, 0, maxi(0, n-1))
}

func (m *stopwatchMode) Update(msg tea.Msg) tea.Cmd {
	c := m.c
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch msg.String() {
		case "space":
			m.toggle()
		case "enter":
			if c.SW.Run == engine.Running {
				m.lap()
			} else {
				m.toggle()
			}
		case "l":
			m.lap()
		case "r":
			c.Log(c.SW.Reset(c.Now)...)
			m.scroll = 0
			c.MarkDirty()
		case "up", "k":
			m.scrollBy(-1)
		case "down", "j":
			m.scrollBy(1)
		case "pgup":
			m.scrollBy(-m.pageRows)
		case "pgdown":
			m.scrollBy(m.pageRows)
		case "t":
			f := (braille.ParseFont(c.Cfg.Font) + 1) % braille.Font(braille.Fonts)
			c.Cfg.Font = f.String()
		}
	case tea.MouseClickMsg:
		if msg.Button == tea.MouseLeft && m.faceArea.has(msg.X, msg.Y) {
			m.toggle()
		}
	case tea.MouseWheelMsg:
		if m.lapArea.has(msg.X, msg.Y) || len(c.SW.Laps) > m.pageRows {
			if msg.Button == tea.MouseWheelUp {
				m.scrollBy(-1)
			} else if msg.Button == tea.MouseWheelDown {
				m.scrollBy(1)
			}
		}
	}
	return nil
}

// ----------------------------------------------------------------- view

func (m *stopwatchMode) frame() *visual.Frame {
	c := m.c
	sw := c.SW
	el := sw.Elapsed(c.Now)
	f := &visual.Frame{
		Progress: float64(el%time.Minute) / float64(time.Minute),
		Running:  sw.Run == engine.Running,
		Idle:     !sw.Active(),
		Time:     c.Anim,
		Dt:       c.Dt.Seconds(),
		Pulse:    m.pulse * 0.8,
		Pal:      c.Pal,
		Text:     swText(el, true),
		Font:     braille.ParseFont(c.Cfg.Font),
		Still:    c.Cfg.Motion == "still",
	}
	switch {
	case sw.Run == engine.Running:
		f.Sub = i18n.T("stopwatch.running")
	case sw.Accum > 0:
		f.Sub = i18n.T("state.paused")
	default:
		f.Sub = i18n.T("stopwatch.ready")
	}
	return f
}

func (m *stopwatchMode) marks() []visual.StopwatchMark {
	laps := m.c.SW.Laps
	best, worst := m.c.SW.Extremes()
	start := maxi(0, len(laps)-12)
	var out []visual.StopwatchMark
	for i := start; i < len(laps); i++ {
		kind := 0
		if i == best {
			kind = 1
		} else if i == worst {
			kind = 2
		}
		out = append(out, visual.StopwatchMark{
			Frac: float64(laps[i].Total%time.Minute) / float64(time.Minute), Kind: kind,
		})
	}
	return out
}

func (m *stopwatchMode) View(w, h int) string {
	if w < 12 || h < 3 {
		return join(blank(w, h))
	}
	m.faceArea, m.lapArea = timerRect{}, timerRect{}
	c := m.c
	pal := c.Pal
	laps := c.SW.Laps

	side := w >= 84 && h >= 12
	stacked := !side && h >= 17
	tableW := 0
	if side {
		tableW = clampi(w*40/100, 38, 58)
	}

	switch {
	case side:
		faceW := w - tableW - 2
		face := m.drawFace(faceW, h)
		tbl := m.lapTable(tableW, h)
		m.lapArea.x += faceW + 2
		return join(fit(hcat(fit(face, faceW, h), blank(2, h), tbl), w, h))
	case stacked:
		faceH := clampi(h*55/100, 9, h-6)
		face := m.drawFace(w, faceH)
		tbl := m.lapTable(mini(w, 56), h-faceH)
		var rows []string
		rows = append(rows, fit(face, w, faceH)...)
		for i, l := range tbl {
			rows = append(rows, centerIn(l, w))
			_ = i
		}
		m.lapArea.y += faceH
		m.lapArea.x += (w - mini(w, 56)) / 2
		return join(fit(rows, w, h))
	default:
		if h >= 9 {
			face := m.drawFace(w, h-1)
			info := paint(pal.Muted, i18n.T("stopwatch.laps")+" "+itoa(len(laps)))
			return join(fit(append(fit(face, w, h-1), centerIn(info, w)), w, h))
		}
		digits := bold(pal.Accent, swText(c.SW.Elapsed(c.Now), true))
		lines := []string{digits}
		if len(laps) > 0 {
			lines = append(lines, paint(pal.Muted, i18n.T("stopwatch.laps")+" "+itoa(len(laps))))
		}
		return join(centerBlock(centerAll(lines, w), w, h))
	}
}

func centerAll(lines []string, w int) []string {
	out := make([]string, len(lines))
	for i, l := range lines {
		out[i] = centerIn(l, w)
	}
	return out
}

// drawFace renders the sweep ring centered in a w x h area and records its
// hit area.
func (m *stopwatchMode) drawFace(w, h int) []string {
	rows := mini(h, w/2)
	cols := rows * 2
	if cols < 8 || rows < 3 {
		return centerBlock([]string{bold(m.c.Pal.Accent, swText(m.c.SW.Elapsed(m.c.Now), true))}, w, h)
	}
	if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
		m.canvas = braille.New(cols, rows)
	} else {
		m.canvas.Clear()
	}
	m.face.Marks = m.marks()
	labels := m.face.Draw(m.canvas, m.frame())
	lines := m.canvas.Lines()
	overlayLabels(lines, labels)
	top, left := (h-rows)/2, (w-cols)/2
	m.faceArea = timerRect{left, top, cols, rows}
	out := blank(w, h)
	for i, l := range lines {
		if top+i < h {
			out[top+i] = padRight(spaces(left)+l, w)
		}
	}
	return out
}

// stopwatchDur formats a lap: MM:SS.cc.
func stopwatchDur(d time.Duration) string { return swText(d, true) }

// stopwatchDelta formats the gap to the best lap: +1.23.
func stopwatchDelta(d time.Duration) string {
	if d < 0 {
		d = 0
	}
	cs := int(d/(10*time.Millisecond)) % 100
	s := int(d / time.Second)
	if s >= 60 {
		return fmt.Sprintf("+%d:%02d.%02d", s/60, s%60, cs)
	}
	return fmt.Sprintf("+%d.%02d", s, cs)
}

// lapTable is the lap list (newest first) as a Lip Gloss table in h rows.
func (m *stopwatchMode) lapTable(w, h int) []string {
	c := m.c
	pal := c.Pal
	laps := c.SW.Laps
	out := blank(w, h)
	if h < 3 {
		return out
	}
	title := paint(pal.Muted, strings.ToUpper(i18n.T("stopwatch.laps")))
	if len(laps) > 0 {
		title += paint(pal.Faint, "  "+itoa(len(laps)))
	}
	pad := 0
	put := func(i int, s string) {
		i += pad
		if i >= 0 && i < h {
			out[i] = padRight(s, w)
		}
	}
	if len(laps) == 0 {
		hint := i18n.T("stopwatch.nolaps")
		if !c.SW.Active() {
			hint = i18n.T("stopwatch.press")
		}
		mid := h / 2
		put(mid, centerIn(paint(pal.Muted, hint), w))
		m.lapArea = timerRect{0, 0, w, h}
		return out
	}

	// rows available: title, header+rule, legend; the block is centered
	avail := mini(h-4, 12)
	if avail < 1 {
		avail = 1
	}
	topPad := 0
	if blockH := avail + 4; blockH < h {
		topPad = (h - blockH) / 2
	}
	m.pageRows = avail
	pad = topPad
	n := len(laps)
	best, worst := c.SW.Extremes()
	m.scroll = clampi(m.scroll, 0, maxi(0, n-avail))
	// newest first: displayed row r is lap index n-1-(scroll+r)
	var idx []int
	var rows [][]string
	for r := 0; r < avail && m.scroll+r < n; r++ {
		i := n - 1 - (m.scroll + r)
		l := laps[i]
		delta := "—"
		switch {
		case best >= 0 && i == best:
			delta = i18n.T("stopwatch.best")
		case best >= 0:
			delta = stopwatchDelta(l.Split - laps[best].Split)
		}
		rows = append(rows, []string{itoa(l.N), stopwatchDur(l.Split), stopwatchDur(l.Total), delta})
		idx = append(idx, i)
	}
	right := lipgloss.NewStyle().Align(lipgloss.Right)
	t := table.New().
		Border(lipgloss.NormalBorder()).
		BorderStyle(lipgloss.NewStyle().Foreground(pal.Faint)).
		BorderTop(false).BorderBottom(false).BorderLeft(false).BorderRight(false).
		BorderColumn(false).BorderHeader(true).
		Headers(i18n.T("stopwatch.n"), i18n.T("stopwatch.split"), i18n.T("stopwatch.total"), i18n.T("stopwatch.delta")).
		Rows(rows...).
		StyleFunc(func(row, col int) lipgloss.Style {
			st := right.Padding(0, 1)
			if row == table.HeaderRow {
				return st.Foreground(pal.Muted).Bold(true)
			}
			lap := idx[row]
			switch {
			case lap == best:
				return st.Foreground(pal.Good).Bold(col == 1)
			case lap == worst:
				return st.Foreground(pal.Bad).Bold(col == 1)
			case col == 1:
				return st.Foreground(pal.Text).Bold(true)
			}
			return st.Foreground(pal.Muted)
		})
	lines := strings.Split(t.Render(), "\n")
	tw := 0
	for _, l := range lines {
		tw = maxi(tw, width(l))
	}
	lx := maxi(0, (w-tw)/2)
	put(0, spaces(lx)+title)
	for i, l := range lines {
		put(1+i, spaces(lx)+l)
	}
	// the legend and the "more" indicator
	var foot []string
	if best >= 0 {
		foot = append(foot, paint(pal.Good, "● "+i18n.T("stopwatch.best")), paint(pal.Bad, "● "+i18n.T("stopwatch.worst")))
	}
	if more := n - (m.scroll + len(rows)); more > 0 {
		foot = append(foot, paint(pal.Muted, "↓ "+i18n.T("stopwatch.more", more)))
	} else if m.scroll > 0 {
		foot = append(foot, paint(pal.Muted, "↑"))
	}
	put(1+len(lines), spaces(lx)+strings.Join(foot, "  "))
	m.lapArea = timerRect{0, topPad, w, h - topPad}
	return out
}
