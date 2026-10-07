package ui

import (
	"path/filepath"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func init() {
	registerMode("tracker", func(c *Core, say func(string)) Mode { return newTracker(c, say) })
}

var trackerRanges = []int{7, 14, 30}

type trackerEditor struct {
	id    int // 0 = new activity
	input textinput.Model
}

type trackerRect struct{ y0, y1, idx int }

type trackerMode struct {
	c    *Core
	say  func(string)
	t    *engine.Tracker
	path string

	sel, scroll int
	rng         int // index into trackerRanges
	dirty       bool
	lastSave    time.Time

	edit       *trackerEditor
	confirmDel bool

	big, tl, ch *braille.Canvas
	rects       []trackerRect
	listX       int
}

func newTracker(c *Core, say func(string)) *trackerMode {
	m := &trackerMode{c: c, say: say, path: filepath.Join(c.Store.StateDir, "tracker.json")}
	t := &engine.Tracker{}
	if !breaksLoadJSON(m.path, t) {
		t = engine.NewTracker(i18n.T("tracker.act.work"), i18n.T("tracker.act.meet"), i18n.T("tracker.act.learn"))
		m.dirty = true
	}
	m.t = t
	return m
}

func (m *trackerMode) ID() string { return "tracker" }

func (m *trackerMode) Animated() bool {
	return m.t.Running != 0 && m.c.Cfg.Motion != "still"
}

func (m *trackerMode) Capturing() bool { return m.edit != nil || m.confirmDel }

func (m *trackerMode) Frame(dt time.Duration) {}

func (m *trackerMode) Title() string {
	if a := m.t.Get(m.t.Running); a != nil {
		return iconTracker + " " + clockText(m.t.Elapsed(m.c.Now)) + " " + a.Name
	}
	return ""
}

// Step has nothing to announce, but keeps the file fresh.
func (m *trackerMode) Step(now time.Time, dt time.Duration) []Announce {
	if m.dirty && now.Sub(m.lastSave) >= time.Second {
		breaksSaveJSON(m.path, m.t)
		m.dirty, m.lastSave = false, now
	}
	return nil
}

func (m *trackerMode) Runner() *Running {
	a := m.t.Get(m.t.Running)
	if a == nil {
		return nil
	}
	return &Running{Icon: iconTracker, Text: clockText(m.t.Elapsed(m.c.Now)) + " " + a.Name}
}

func (m *trackerMode) hue(a *engine.TrackerActivity) braille.RGB {
	return breaksHue(m.c.Pal.Accent, a.Color)
}

func (m *trackerMode) cur() *engine.TrackerActivity {
	if len(m.t.Acts) == 0 {
		return nil
	}
	m.sel = clampi(m.sel, 0, len(m.t.Acts)-1)
	return m.t.Acts[m.sel]
}

func (m *trackerMode) logSpan(s engine.TrackerSpan, ok bool) {
	if !ok {
		return
	}
	name := ""
	if a := m.t.Get(s.Act); a != nil {
		name = a.Name
	}
	m.c.Log(engine.Event{Kind: engine.KindTracker, Label: name, Start: s.Start, Actual: s.End.Sub(s.Start), Completed: true})
}

func (m *trackerMode) toggle(a *engine.TrackerActivity) {
	now := m.c.Now
	if m.t.Running == a.ID {
		m.logSpan(m.t.Stop(now))
		m.say(i18n.T("tracker.stopped", a.Name))
	} else {
		m.logSpan(m.t.Start(a.ID, now))
		m.say(i18n.T("tracker.started", a.Name))
	}
	m.dirty = true
}

// ------------------------------------------------------------------- input

func (m *trackerMode) Help() []key.Binding {
	switch {
	case m.edit != nil:
		return []key.Binding{kb("enter", "enter", i18n.T("breaks.k.save")), kb("esc", "esc", i18n.T("key.cancel"))}
	case m.confirmDel:
		return []key.Binding{kb("y", "y", i18n.T("key.confirm")), kb("n|esc", "n", i18n.T("key.cancel"))}
	}
	return []key.Binding{
		kb("up|down|k|j", "↑↓", i18n.T("key.select")),
		kb("space|enter", "space", i18n.T("tracker.k.toggle")),
		kb("s", "s", i18n.T("tracker.k.stop")),
		kb("n", "n", i18n.T("tracker.k.new")),
		kb("e", "e", i18n.T("tracker.k.rename")),
		kb("c", "c", i18n.T("tracker.k.color")),
		kb("left|right|h|l", "←→", i18n.T("tracker.k.range")),
		kb("x", "x", i18n.T("tracker.k.del")),
	}
}

func (m *trackerMode) Update(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch {
		case m.edit != nil:
			m.editKey(msg)
		case m.confirmDel:
			switch msg.String() {
			case "y", "enter":
				if a := m.cur(); a != nil {
					m.t.Delete(a.ID)
					m.dirty = true
				}
				m.confirmDel = false
			case "n", "esc", "q":
				m.confirmDel = false
			}
		default:
			m.listKey(msg)
		}
	case tea.MouseClickMsg:
		if m.edit == nil && msg.Button == tea.MouseLeft {
			for _, r := range m.rects {
				if msg.Y >= r.y0 && msg.Y < r.y1 {
					if m.sel == r.idx || msg.X < m.listX+3 {
						m.sel = r.idx
						m.toggle(m.t.Acts[r.idx])
					}
					m.sel = r.idx
					break
				}
			}
		}
	case tea.MouseWheelMsg:
		if m.edit == nil {
			if msg.Button == tea.MouseWheelUp {
				m.sel--
			} else if msg.Button == tea.MouseWheelDown {
				m.sel++
			}
			m.sel = clampi(m.sel, 0, maxi(len(m.t.Acts)-1, 0))
		}
	}
	return nil
}

func (m *trackerMode) listKey(msg tea.KeyPressMsg) {
	a := m.cur()
	switch msg.String() {
	case "up", "k":
		m.sel = clampi(m.sel-1, 0, maxi(len(m.t.Acts)-1, 0))
	case "down", "j":
		m.sel = clampi(m.sel+1, 0, maxi(len(m.t.Acts)-1, 0))
	case "enter", "space":
		if a != nil {
			m.toggle(a)
		}
	case "s":
		if m.t.Running != 0 {
			m.logSpan(m.t.Stop(m.c.Now))
			m.dirty = true
		}
	case "n":
		m.openEditor(0)
	case "e":
		if a != nil {
			m.openEditor(a.ID)
		}
	case "c":
		if a != nil {
			m.t.CycleColor(a.ID)
			m.dirty = true
		}
	case "x":
		if a != nil {
			m.confirmDel = true
		}
	case "left", "h":
		m.rng = clampi(m.rng-1, 0, len(trackerRanges)-1)
	case "right", "l":
		m.rng = clampi(m.rng+1, 0, len(trackerRanges)-1)
	}
}

func (m *trackerMode) openEditor(id int) {
	ti := breaksInput(m.c, i18n.T("tracker.name.ph"), 28, 28)
	if id != 0 {
		if a := m.t.Get(id); a != nil {
			ti.SetValue(a.Name)
		}
	}
	ti.Focus()
	m.edit = &trackerEditor{id: id, input: ti}
}

func (m *trackerMode) editKey(msg tea.KeyPressMsg) {
	e := m.edit
	switch msg.String() {
	case "esc":
		m.edit = nil
	case "enter":
		name := strings.TrimSpace(e.input.Value())
		if name == "" {
			m.edit = nil
			return
		}
		if e.id == 0 {
			a := m.t.Add(name)
			for i, x := range m.t.Acts {
				if x == a {
					m.sel = i
				}
			}
		} else {
			m.t.Rename(e.id, name)
		}
		m.dirty = true
		m.edit = nil
	default:
		e.input, _ = e.input.Update(msg)
	}
}

// -------------------------------------------------------------------- views

func (m *trackerMode) View(w, h int) string {
	if w < 8 || h < 2 {
		return join(blank(w, h))
	}
	return join(fit(m.layout(w, h), w, h))
}

var trackerSpin = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

func (m *trackerMode) header(w int) string {
	pal := m.c.Pal
	now := m.c.Now
	total := engine.TrackerSum(m.t.DayTotals(now, now))
	var s string
	if a := m.t.Get(m.t.Running); a != nil {
		sp := trackerSpin[0]
		if m.c.Cfg.Motion != "still" {
			sp = trackerSpin[int(m.c.Anim*12)%len(trackerSpin)]
		}
		s = bold(m.hue(a), sp+" ") + bold(pal.Text, a.Name) + "  " + bold(m.hue(a), clockText(m.t.Elapsed(now)))
	} else {
		s = bold(pal.Muted, iconTracker+" ") + paint(pal.Muted, i18n.T("tracker.idle"))
	}
	s += paint(pal.Faint, "  ·  ") + paint(pal.Muted, i18n.T("tracker.today")+" ") + paint(pal.Text, fmtDur(total.Round(time.Minute)))
	return padRight(" "+s, w)
}

func (m *trackerMode) layout(w, h int) []string {
	pal := m.c.Pal
	m.rects = m.rects[:0]
	out := blank(w, h)
	out[0] = m.header(w)
	body := h - 1
	if m.edit != nil || m.confirmDel {
		body--
	}
	if body < 1 {
		return out
	}
	var rows []string
	n := len(m.t.Acts)
	switch {
	case n == 0:
		rows = centerBlock([]string{paint(pal.Muted, i18n.T("tracker.empty"))}, w, body)
	case w >= 100 && h >= 18:
		lw := 40
		rw := w - lw - 4
		left := m.list(lw, body, 1)
		m.listX = 0
		right := m.rightColumn(rw, body)
		rows = hcat(fit(left, lw, body), blank(4, body), fit(right, rw, body))
	default:
		rows = m.stacked(w, body)
	}
	for i, l := range rows {
		if 1+i < h {
			out[1+i] = padRight(l, w)
		}
	}
	switch {
	case m.edit != nil:
		label := i18n.T("tracker.new")
		if m.edit.id != 0 {
			label = i18n.T("tracker.rename")
		}
		m.edit.input.SetWidth(maxi(w-width(label)-12, 6))
		out[h-1] = padRight(" "+bold(pal.Accent, "▸ "+label+": ")+m.edit.input.View(), w)
	case m.confirmDel:
		if a := m.cur(); a != nil {
			out[h-1] = padRight(" "+bold(pal.Warn, i18n.T("tracker.confirm", a.Name)), w)
		}
	}
	return out
}

// list draws the activities, one row each, starting at body row y0.
func (m *trackerMode) list(w, h, y0 int) []string {
	pal := m.c.Pal
	now := m.c.Now
	n := len(m.t.Acts)
	m.sel = clampi(m.sel, 0, n-1)
	if m.sel < m.scroll {
		m.scroll = m.sel
	}
	if m.sel >= m.scroll+h {
		m.scroll = m.sel - h + 1
	}
	m.scroll = clampi(m.scroll, 0, maxi(n-h, 0))
	totals := m.t.DayTotals(now, now)
	var dayMax time.Duration
	for _, d := range totals {
		if d > dayMax {
			dayMax = d
		}
	}
	var out []string
	for i := m.scroll; i < n && i < m.scroll+h; i++ {
		a := m.t.Acts[i]
		hue := m.hue(a)
		sel := i == m.sel
		mark := "  "
		if sel {
			mark = bold(pal.Accent, "▸ ")
		}
		running := m.t.Running == a.ID
		chip := paint(hue, "▌")
		nameS := paint(pal.Muted, a.Name)
		if sel {
			nameS = bold(pal.Text, a.Name)
		} else if running {
			nameS = paint(pal.Text, a.Name)
		}
		tot := paint(pal.Muted, fmtDur(totals[a.ID].Round(time.Minute)))
		if totals[a.ID] == 0 {
			tot = paint(pal.Faint, "—")
		}
		state := " "
		if running {
			sp := trackerSpin[0]
			if m.c.Cfg.Motion != "still" {
				sp = trackerSpin[int(m.c.Anim*12)%len(trackerSpin)]
			}
			state = bold(hue, sp)
		}
		// columns: mark(2) chip(1) sp name | share bar | total(7) sp state(1)
		barW := 0
		if w >= 34 {
			barW = trackerMin(10, (w-14)/3)
		}
		nameW := maxi(w-14-barW-trackerBoolInt(barW > 0), 4)
		bar := ""
		if barW > 0 {
			share := 0.0
			if dayMax > 0 {
				share = float64(totals[a.ID]) / float64(dayMax)
			}
			bar = " " + trackerShare(share, barW, hue, pal.Faint)
		}
		line := mark + chip + " " + padRight(nameS, nameW) + bar + " " + padLeft(tot, 7) + " " + state
		m.rects = append(m.rects, trackerRect{y0: y0 + i - m.scroll, y1: y0 + i - m.scroll + 1, idx: i})
		out = append(out, padRight(line, w))
	}
	return out
}

func (m *trackerMode) rightColumn(w, h int) []string {
	var out []string
	remaining := h
	if remaining >= 18 {
		big := m.bigCard(w)
		out = append(out, big...)
		out = append(out, "")
		remaining -= len(big) + 1
	}
	if remaining >= 12 {
		tl := m.timeline(w)
		out = append(out, tl...)
		out = append(out, "")
		remaining -= len(tl) + 1
	}
	if remaining >= 6 {
		out = append(out, m.chart(w, remaining)...)
	}
	return out
}

// stacked is the single-column layout: the list, then whatever else fits.
func (m *trackerMode) stacked(w, h int) []string {
	n := len(m.t.Acts)
	listH := trackerMin(n, maxi(h/2, 1))
	if h < 14 {
		listH = trackerMin(n, h)
	}
	rows := m.list(w, listH, 1)
	m.listX = 0
	remaining := h - len(rows)
	if remaining >= 6 {
		rows = append(rows, "")
		tl := m.timeline(w)
		rows = append(rows, tl...)
		remaining -= len(tl) + 1
	}
	if remaining >= 8 {
		rows = append(rows, "")
		rows = append(rows, m.chart(w, remaining-1)...)
	}
	return rows
}

func trackerMin(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// bigCard: the running timer (or today's total) in big braille digits.
func (m *trackerMode) bigCard(w int) []string {
	pal := m.c.Pal
	now := m.c.Now
	cols := trackerMin(w, 40)
	if m.big == nil || m.big.Cols != cols {
		m.big = braille.New(cols, 4)
	}
	c := m.big
	c.Clear()
	text := "00:00"
	label := i18n.T("tracker.today")
	col := pal.Muted
	if a := m.t.Get(m.t.Running); a != nil {
		text = clockText(m.t.Elapsed(now))
		label = strings.ToUpper(i18n.T("tracker.running")) + " · " + a.Name
		col = m.hue(a)
	} else {
		d := engine.TrackerSum(m.t.DayTotals(now, now))
		s := int(d.Seconds())
		text = breaksPad2(s/3600) + ":" + breaksPad2(s%3600/60)
	}
	f := braille.ParseFont(m.c.Cfg.Font)
	h := f.FitHeight(text, c.W-2, 14)
	c.TextCentered(f, text, float64(c.W)/2, float64(c.H)/2, h, braille.Solid(col))
	out := []string{paint(pal.Muted, strings.ToUpper(label))}
	for _, l := range c.Lines() {
		out = append(out, padRight(l, w))
	}
	return out
}

func trackerBoolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

// trackerShare draws a braille meter of w cells filled to share (0..1).
func trackerShare(share float64, w int, on, off braille.RGB) string {
	half := int(share*float64(w*2) + 0.5)
	if share > 0 && half == 0 {
		half = 1
	}
	var sb strings.Builder
	for i := 0; i < w; i++ {
		switch {
		case half >= (i+1)*2:
			sb.WriteString(paint(on, "⣿"))
		case half == i*2+1:
			sb.WriteString(paint(on, "⡇"))
		default:
			sb.WriteString(paint(off, "⣀"))
		}
	}
	return sb.String()
}
