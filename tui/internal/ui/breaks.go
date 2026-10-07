package ui

import (
	"math"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

func init() {
	registerMode("breaks", func(c *Core, say func(string)) Mode { return newBreaks(c, say) })
}

// breaksGuide is the guided exercise for one reminder.
type breaksGuide struct {
	id     string
	start  time.Time
	length time.Duration
	doneAt time.Time // set when the countdown ran out or enter was pressed
}

type breaksEditor struct {
	id    string // "" = new
	name  textinput.Model
	every textinput.Model
	field int
	err   string
}

type breaksRect struct{ y0, y1, idx int }

type breaksMode struct {
	c    *Core
	say  func(string)
	b    *engine.Breaks
	path string

	sel, scroll int
	dirty       bool
	lastSave    time.Time

	guide      *breaksGuide
	edit       *breaksEditor
	confirmDel bool

	vis, dig, ring, spk *braille.Canvas
	rects               []breaksRect
	listW, margin       int
}

func newBreaks(c *Core, say func(string)) *breaksMode {
	m := &breaksMode{c: c, say: say, path: filepath.Join(c.Store.StateDir, "breaks.json")}
	b := &engine.Breaks{}
	if !breaksLoadJSON(m.path, b) || len(b.List) == 0 {
		b = engine.BreaksDefaults(c.Now)
		m.dirty = true
	}
	b.CatchUp(c.Now)
	m.b = b
	return m
}

func (m *breaksMode) ID() string { return "breaks" }

func (m *breaksMode) Animated() bool { return m.c.Cfg.Motion != "still" }

func (m *breaksMode) Capturing() bool { return m.guide != nil || m.edit != nil || m.confirmDel }

func (m *breaksMode) Frame(dt time.Duration) {}

// ------------------------------------------------------------- reminders

func (m *breaksMode) name(r *engine.BreaksReminder) string {
	if r.Custom {
		return r.Label
	}
	return i18n.T("breaks." + r.ID + ".name")
}

func (m *breaksMode) title(r *engine.BreaksReminder) string {
	if r.Custom {
		return r.Label
	}
	return i18n.T("breaks." + r.ID + ".title")
}

func (m *breaksMode) body(r *engine.BreaksReminder) string {
	if r.Custom {
		return i18n.T("breaks.custom.body")
	}
	return i18n.T("breaks." + r.ID + ".body")
}

func (m *breaksMode) cue(r *engine.BreaksReminder) string {
	if r.Custom {
		return i18n.T("breaks.custom.cue")
	}
	return i18n.T("breaks." + r.ID + ".cue")
}

func (m *breaksMode) guideLen(r *engine.BreaksReminder) time.Duration {
	switch r.ID {
	case "eyes":
		return 20 * time.Second
	case "stretch":
		return 60 * time.Second
	case "water":
		return 15 * time.Second
	case "posture":
		return 30 * time.Second
	}
	return 20 * time.Second
}

func (m *breaksMode) current() *engine.BreaksReminder {
	if len(m.b.List) == 0 {
		return nil
	}
	m.sel = clampi(m.sel, 0, len(m.b.List)-1)
	return m.b.List[m.sel]
}

func (m *breaksMode) hue(i int) braille.RGB {
	return breaksHue(m.c.Pal.Accent, i+2)
}

// ---------------------------------------------------------------- background

// Step keeps the schedule running whichever tab is open.
func (m *breaksMode) Step(now time.Time, dt time.Duration) []Announce {
	var out []Announce
	for _, d := range m.b.Tick(now) {
		out = append(out, Announce{
			Kind: engine.KindBreaks, Title: m.title(d.R), Body: m.body(d.R), Ring: true, Rest: true,
		})
		m.dirty = true
	}
	if g := m.guide; g != nil {
		if g.doneAt.IsZero() && now.Sub(g.start) >= g.length {
			m.finishGuide(now)
		} else if !g.doneAt.IsZero() && now.Sub(g.doneAt) > 2200*time.Millisecond {
			m.guide = nil
		}
	}
	if m.dirty && now.Sub(m.lastSave) >= time.Second {
		breaksSaveJSON(m.path, m.b)
		m.dirty, m.lastSave = false, now
	}
	return out
}

func (m *breaksMode) Runner() *Running {
	if len(m.b.List) == 0 {
		return nil
	}
	r := m.b.Nearest(m.c.Now)
	if r == nil {
		return nil
	}
	txt := "now"
	if left := m.b.Until(r, m.c.Now); !r.Pending && left > 0 {
		txt = breaksShort(left)
	}
	return &Running{Icon: iconBreaks, Text: txt, Rest: true, Paused: m.b.Paused}
}

// breaksShort is "12m", "45s" or "1h05".
func breaksShort(d time.Duration) string {
	s := ceilSecs(d)
	switch {
	case s >= 3600:
		return strconv.Itoa(s/3600) + "h" + breaksPad2(s%3600/60)
	case s >= 60:
		return strconv.Itoa((s+59)/60) + "m"
	}
	return strconv.Itoa(s) + "s"
}

func (m *breaksMode) startGuide(r *engine.BreaksReminder, now time.Time) {
	m.guide = &breaksGuide{id: r.ID, start: now, length: m.guideLen(r)}
	r.Pending = false
}

func (m *breaksMode) finishGuide(now time.Time) {
	g := m.guide
	if g == nil || !g.doneAt.IsZero() {
		return
	}
	r := m.b.Get(g.id)
	g.doneAt = now
	if r == nil {
		m.guide = nil
		return
	}
	el := now.Sub(g.start)
	if el > g.length {
		el = g.length
	}
	m.b.Complete(g.id, now)
	m.c.Log(engine.Event{Kind: engine.KindBreaks, Label: m.name(r), Start: g.start, Planned: g.length, Actual: el, Completed: true})
	m.dirty = true
}

// ------------------------------------------------------------------- input

func (m *breaksMode) Help() []key.Binding {
	switch {
	case m.guide != nil:
		return []key.Binding{
			kb("enter", "enter", i18n.T("breaks.k.done")),
			kb("s", "s", i18n.T("breaks.k.snooze")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	case m.edit != nil:
		return []key.Binding{
			kb("tab", "tab", i18n.T("breaks.k.field")),
			kb("enter", "enter", i18n.T("breaks.k.save")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	case m.confirmDel:
		return []key.Binding{kb("y", "y", i18n.T("key.confirm")), kb("n|esc", "n", i18n.T("key.cancel"))}
	}
	pause := i18n.T("breaks.k.pause")
	if m.b.Paused {
		pause = i18n.T("breaks.k.resume")
	}
	return []key.Binding{
		kb("up|down|k|j", "↑↓", i18n.T("key.select")),
		kb("space", "space", i18n.T("breaks.k.toggle")),
		kb("enter", "enter", i18n.T("breaks.k.doit")),
		kb("+|-|=|_", "+/-", i18n.T("breaks.k.every")),
		kb("s", "s", i18n.T("breaks.k.snooze")),
		kb("p", "p", pause),
		kb("a", "a", i18n.T("breaks.k.add")),
	}
}

func (m *breaksMode) Update(msg tea.Msg) tea.Cmd {
	now := m.c.Now
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch {
		case m.guide != nil:
			m.guideKey(msg, now)
		case m.edit != nil:
			m.editKey(msg, now)
		case m.confirmDel:
			switch msg.String() {
			case "y", "enter":
				if r := m.current(); r != nil {
					m.b.Delete(r.ID)
					m.dirty = true
				}
				m.confirmDel = false
			case "n", "esc", "q":
				m.confirmDel = false
			}
		default:
			m.listKey(msg, now)
		}
	case tea.MouseClickMsg:
		if m.guide == nil && m.edit == nil && msg.Button == tea.MouseLeft {
			for _, r := range m.rects {
				if msg.Y >= r.y0 && msg.Y < r.y1 {
					m.sel = r.idx
					if msg.X >= m.margin+1 && msg.X < m.margin+10 && r.y1-r.y0 > 1 {
						m.b.Toggle(m.b.List[r.idx].ID, now)
						m.dirty = true
					}
					break
				}
			}
		}
	case tea.MouseWheelMsg:
		if m.guide == nil && m.edit == nil {
			if msg.Button == tea.MouseWheelUp {
				m.sel--
			} else if msg.Button == tea.MouseWheelDown {
				m.sel++
			}
			m.sel = clampi(m.sel, 0, maxi(len(m.b.List)-1, 0))
		}
	}
	return nil
}

func (m *breaksMode) guideKey(msg tea.KeyPressMsg, now time.Time) {
	g := m.guide
	switch msg.String() {
	case "enter", "space":
		if g.doneAt.IsZero() {
			m.finishGuide(now)
		} else {
			m.guide = nil
		}
	case "s":
		if g.doneAt.IsZero() {
			m.b.Snooze(g.id, now)
			m.dirty = true
			m.say(i18n.T("breaks.snoozed", int(engine.BreaksSnooze.Minutes())))
		}
		m.guide = nil
	case "esc", "q":
		m.guide = nil
	}
}

func (m *breaksMode) listKey(msg tea.KeyPressMsg, now time.Time) {
	r := m.current()
	switch msg.String() {
	case "up", "k":
		m.sel = clampi(m.sel-1, 0, maxi(len(m.b.List)-1, 0))
	case "down", "j":
		m.sel = clampi(m.sel+1, 0, maxi(len(m.b.List)-1, 0))
	case "space":
		if r != nil {
			m.b.Toggle(r.ID, now)
			m.dirty = true
		}
	case "enter":
		if r != nil {
			m.startGuide(r, now)
		}
	case "+", "=":
		if r != nil {
			m.b.SetEvery(r.ID, r.Min+5, now)
			m.dirty = true
		}
	case "-", "_":
		if r != nil {
			m.b.SetEvery(r.ID, r.Min-5, now)
			m.dirty = true
		}
	case "s":
		if r != nil && r.On {
			m.b.Snooze(r.ID, now)
			m.dirty = true
			m.say(i18n.T("breaks.snoozed", int(engine.BreaksSnooze.Minutes())))
		}
	case "x":
		if r != nil {
			if r.Custom {
				m.confirmDel = true
			} else {
				m.say(i18n.T("breaks.builtin"))
			}
		}
	case "p":
		m.b.SetPaused(!m.b.Paused, now)
		m.dirty = true
	case "a":
		m.openEditor("")
	case "e":
		if r != nil {
			if r.Custom {
				m.openEditor(r.ID)
			} else {
				m.say(i18n.T("breaks.builtin.edit"))
			}
		}
	}
}

func (m *breaksMode) openEditor(id string) {
	e := &breaksEditor{id: id}
	e.name = breaksInput(m.c, i18n.T("breaks.edit.name.ph"), 28, 28)
	e.every = breaksInput(m.c, "30", 3, 5)
	e.every.SetValue("30")
	if id != "" {
		if r := m.b.Get(id); r != nil {
			e.name.SetValue(r.Label)
			e.every.SetValue(strconv.Itoa(r.Min))
		}
	}
	e.name.Focus()
	m.edit = e
}

func (m *breaksMode) editKey(msg tea.KeyPressMsg, now time.Time) {
	e := m.edit
	switch msg.String() {
	case "esc":
		m.edit = nil
		return
	case "tab", "down":
		m.editField(1)
		return
	case "shift+tab", "up":
		m.editField(-1)
		return
	case "enter":
		if e.field == 0 {
			m.editField(1)
			return
		}
		m.saveEditor(now)
		return
	}
	if e.field == 1 {
		// minutes: digits only
		if t := msg.Text; t != "" {
			for _, r := range t {
				if r < '0' || r > '9' {
					return
				}
			}
		}
		e.every, _ = e.every.Update(msg)
	} else {
		e.name, _ = e.name.Update(msg)
	}
	e.err = ""
}

func (m *breaksMode) editField(d int) {
	e := m.edit
	e.field = (e.field + d + 2) % 2
	if e.field == 0 {
		e.name.Focus()
		e.every.Blur()
	} else {
		e.every.Focus()
		e.name.Blur()
	}
}

func (m *breaksMode) saveEditor(now time.Time) {
	e := m.edit
	name := strings.TrimSpace(e.name.Value())
	if name == "" {
		e.err = i18n.T("breaks.edit.err")
		e.field = 1
		m.editField(-1)
		return
	}
	mins, err := strconv.Atoi(strings.TrimSpace(e.every.Value()))
	if err != nil || mins <= 0 {
		mins = 30
	}
	if e.id == "" {
		r := m.b.Add(name, mins, now)
		for i, x := range m.b.List {
			if x == r {
				m.sel = i
			}
		}
	} else {
		m.b.Edit(e.id, name, mins, now)
	}
	m.dirty = true
	m.edit = nil
}

// -------------------------------------------------------------------- views

func (m *breaksMode) View(w, h int) string {
	if w < 8 || h < 2 {
		return join(blank(w, h))
	}
	switch {
	case m.guide != nil:
		return join(fit(m.guideView(w, h), w, h))
	case m.edit != nil:
		return join(fit(m.editorView(w, h), w, h))
	}
	return join(fit(m.listView(w, h), w, h))
}

func (m *breaksMode) summary(w int) string {
	pal := m.c.Pal
	done, skipped := m.b.DoneToday(m.c.Now)
	s := bold(pal.Rest, iconBreaks+" ") + paint(pal.Muted, i18n.T("breaks.today")+" ") +
		bold(pal.Text, strconv.Itoa(done)) + paint(pal.Muted, " "+i18n.T("breaks.taken"))
	_ = skipped
	if st := m.b.Streak(m.c.Now); st > 0 {
		s += paint(pal.Faint, "  ·  ") + paint(pal.Warn, i18n.T("breaks.streak", st))
	}
	if m.b.Paused {
		s += paint(pal.Faint, "  ·  ") + bold(pal.Warn, "⏸ "+i18n.T("breaks.paused"))
	}
	return padRight(" "+s, w)
}

func (m *breaksMode) listView(w, h int) []string {
	pal := m.c.Pal
	m.rects = m.rects[:0]
	wide := w >= 100 && h >= 16
	listW := w
	margin := 0
	if wide {
		listW = breaksMin(54, w-46)
		margin = maxi(0, (w-(listW+4+breaksMin(44, w-listW-4)))/2)
	}
	m.listW, m.margin = listW, margin
	out := blank(w, h)
	out[0] = m.summary(w)
	ah := h - 2
	if m.confirmDel {
		ah--
	}
	n := len(m.b.List)
	var rows []string
	if n == 0 {
		rows = []string{centerIn(paint(pal.Muted, i18n.T("breaks.empty")), listW)}
		rows = centerBlock(rows, listW, ah)
	} else if ah >= 9 && w >= 40 {
		rows = m.cards(listW, ah)
	} else {
		rows = m.lines(listW, ah)
	}
	if wide {
		panel := m.panel(breaksMin(44, w-listW-4-margin), ah)
		rows = hcat(blank(margin, ah), fit(rows, listW, ah), blank(4, ah), panel)
	}
	for i, l := range rows {
		if 2+i < h {
			out[2+i] = padRight(l, w)
		}
	}
	if m.confirmDel {
		if r := m.current(); r != nil {
			out[h-1] = padRight(" "+bold(pal.Warn, i18n.T("breaks.confirm", m.name(r))), w)
		}
	}
	return out
}

func breaksMin(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// status chip text and color for a reminder.
func (m *breaksMode) status(r *engine.BreaksReminder) (string, braille.RGB) {
	pal := m.c.Pal
	switch {
	case !r.On:
		return i18n.T("breaks.off"), pal.Faint
	case m.b.Paused:
		return i18n.T("breaks.paused"), pal.Muted
	case r.Pending || m.b.Until(r, m.c.Now) <= 0:
		return i18n.T("breaks.due"), pal.Warn
	}
	return i18n.T("breaks.on"), pal.Good
}

func (m *breaksMode) cards(w, ah int) []string {
	const ch = 4
	per := (ah + 1) / (ch + 1)
	if per < 1 {
		per = 1
	}
	n := len(m.b.List)
	m.sel = clampi(m.sel, 0, n-1)
	if m.sel < m.scroll {
		m.scroll = m.sel
	}
	if m.sel >= m.scroll+per {
		m.scroll = m.sel - per + 1
	}
	m.scroll = clampi(m.scroll, 0, maxi(n-per, 0))
	var out []string
	for i := m.scroll; i < n && i < m.scroll+per; i++ {
		y0 := len(out)
		out = append(out, m.card(i, w)...)
		m.rects = append(m.rects, breaksRect{y0: y0 + 2, y1: y0 + 2 + ch, idx: i})
		out = append(out, spaces(w))
	}
	if n > per {
		// scroll hint on the last row
		hint := paint(m.c.Pal.Faint, "↑↓ "+strconv.Itoa(m.sel+1)+"/"+strconv.Itoa(n))
		if len(out) > 0 {
			out[len(out)-1] = padLeft(hint, w)
		}
	}
	return out
}

func (m *breaksMode) miniRing(r *engine.BreaksReminder, hue braille.RGB) []string {
	pal := m.c.Pal
	if m.ring == nil {
		m.ring = braille.New(8, 4)
	}
	c := m.ring
	c.Clear()
	cx, cy := float64(c.W)/2, float64(c.H)/2
	R := 6.6
	frac := 0.0
	due := false
	if r.On {
		left := m.b.Until(r, m.c.Now)
		frac = breaksClampF(float64(left)/float64(time.Duration(r.Min)*time.Minute), 0, 1)
		due = r.Pending || left <= 0
	}
	track := pal.Bg.Mix(hue, 0.2)
	c.Ring(cx, cy, R, 2, braille.Solid(track))
	switch {
	case !r.On:
		c.Ring(cx, cy, R, 2, braille.Solid(pal.Faint.Mix(pal.Bg, 0.3)))
	case due:
		k := 0.5 + 0.5*math.Sin(m.c.Anim*5)
		if m.c.Cfg.Motion == "still" {
			k = 1
		}
		c.Ring(cx, cy, R, 2, braille.Solid(pal.Warn.Mix(pal.Bg, 0.4*(1-k))))
		c.Disc(cx, cy, 2.4, braille.Solid(pal.Warn))
	default:
		c.Arc(cx, cy, R, 2, 0, frac*2*math.Pi, true, braille.Solid(hue))
		c.Disc(cx, cy, 1.6, braille.Solid(pal.Bg.Mix(hue, 0.6)))
	}
	return c.Lines()
}

func breaksClampF(v, lo, hi float64) float64 { return math.Max(lo, math.Min(hi, v)) }

func (m *breaksMode) card(i, w int) []string {
	pal := m.c.Pal
	r := m.b.List[i]
	sel := i == m.sel
	hue := m.hue(i)
	ring := m.miniRing(r, hue)
	chip, chipCol := m.status(r)
	nameS := paint(pal.Text, m.name(r))
	if sel {
		nameS = bold(pal.Text, m.name(r))
	}
	if !r.On {
		nameS = paint(pal.Muted, m.name(r))
	}
	left := ""
	switch {
	case !r.On:
		left = paint(pal.Faint, "—")
	case r.Pending || m.b.Until(r, m.c.Now) <= 0:
		left = bold(pal.Warn, i18n.T("breaks.due")+" · enter")
	default:
		left = bold(pal.Text, breaksFmtLeft(m.b.Until(r, m.c.Now))) + paint(pal.Muted, " "+i18n.T("breaks.left"))
	}
	counts := paint(pal.Faint, "—")
	if r.Day == breaksDayKey(m.c.Now) && (r.Done > 0 || r.Skipped > 0) {
		counts = paint(pal.Good, "✓ "+strconv.Itoa(r.Done))
		if r.Skipped > 0 {
			counts += paint(pal.Muted, "  ·  "+i18n.T("breaks.skipped", r.Skipped))
		}
	}
	text := []string{
		nameS + "  " + paint(chipCol, "● "+chip),
		paint(pal.Muted, i18n.T("breaks.every", r.Min)),
		left,
		counts,
	}
	var out []string
	for row := 0; row < 4; row++ {
		bar := " "
		if sel {
			bar = bold(pal.Accent, "▌")
		}
		out = append(out, padRight(bar+ring[row]+"  "+text[row], w))
	}
	return out
}

func breaksDayKey(t time.Time) string { return t.Format("2006-01-02") }

func (m *breaksMode) lines(w, ah int) []string {
	pal := m.c.Pal
	n := len(m.b.List)
	m.sel = clampi(m.sel, 0, n-1)
	if m.sel < m.scroll {
		m.scroll = m.sel
	}
	if m.sel >= m.scroll+ah {
		m.scroll = m.sel - ah + 1
	}
	m.scroll = clampi(m.scroll, 0, maxi(n-ah, 0))
	var out []string
	for i := m.scroll; i < n && i < m.scroll+ah; i++ {
		r := m.b.List[i]
		chip, col := m.status(r)
		mark := "  "
		if i == m.sel {
			mark = bold(pal.Accent, "▸ ")
		}
		nameS := paint(pal.Muted, m.name(r))
		if i == m.sel {
			nameS = bold(pal.Text, m.name(r))
		}
		var left string
		switch {
		case !r.On:
			left = paint(pal.Faint, chip)
		case r.Pending || m.b.Until(r, m.c.Now) <= 0:
			left = bold(pal.Warn, chip)
		default:
			left = paint(pal.Text, breaksShort(m.b.Until(r, m.c.Now)))
		}
		dot := paint(col, "● ")
		line := mark + dot + padRight(nameS, breaksMin(14, maxi(w-24, 6))) + paint(pal.Muted, " "+i18n.T("breaks.every.short", r.Min)) + "  " + left
		m.rects = append(m.rects, breaksRect{y0: i - m.scroll + 2, y1: i - m.scroll + 3, idx: i})
		out = append(out, padRight(line, w))
	}
	return out
}

// panel is the wide layout's side column: today's tally, the streak and a
// two-week sparkline of breaks taken.
func (m *breaksMode) panel(w, h int) []string {
	pal := m.c.Pal
	if w < 20 {
		return blank(breaksMax(w, 0), h)
	}
	done, skipped := m.b.DoneToday(m.c.Now)
	sec := lipgloss.NewStyle().Foreground(pal.Muted).Bold(true)
	mut := lipgloss.NewStyle().Foreground(pal.Muted)

	if m.spk == nil || m.spk.Cols != 5 {
		m.spk = braille.New(5, 4)
	}
	m.spk.Clear()
	m.spk.TextCentered(braille.ParseFont(m.c.Cfg.Font), strconv.Itoa(done%100), float64(m.spk.W)/2, float64(m.spk.H)/2, 14, braille.Solid(pal.Rest))
	big := m.spk.Lines()

	var rows []string
	rows = append(rows, sec.Render(strings.ToUpper(i18n.T("breaks.today"))))
	for i, l := range big {
		switch i {
		case 1:
			rows = append(rows, l+" "+mut.Render(i18n.T("breaks.taken")))
		case 2:
			if skipped > 0 {
				rows = append(rows, l+" "+mut.Render(i18n.T("breaks.skipped", skipped)))
			} else {
				rows = append(rows, l)
			}
		default:
			rows = append(rows, l)
		}
	}
	if st := m.b.Streak(m.c.Now); st > 0 {
		rows = append(rows, "", lipgloss.NewStyle().Foreground(pal.Warn).Render(i18n.T("breaks.streak", st)))
	}
	vals := m.b.LastDays(m.c.Now, 14)
	fv := make([]float64, len(vals))
	for i, v := range vals {
		fv[i] = float64(v)
	}
	rows = append(rows, "", sec.Render(strings.ToUpper(i18n.T("breaks.last", len(vals)))), spark(fv, pal.Rest, pal.Faint))
	rows = append(rows, "", mut.Render(breaksWrap(i18n.T("breaks.tip"), w)))
	lines := strings.Split(strings.Join(rows, "\n"), "\n")
	out := blank(w, h)
	top := maxi(0, (h-len(lines))/2)
	for i, l := range lines {
		if top+i < h {
			out[top+i] = padRight(l, w)
		}
	}
	return out
}

func breaksMax(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// breaksWrap wraps plain text to w cells.
func breaksWrap(s string, w int) string {
	if w < 8 {
		return s
	}
	var lines []string
	cur := ""
	for _, word := range strings.Fields(s) {
		if cur == "" {
			cur = word
		} else if width(cur)+1+width(word) <= w {
			cur += " " + word
		} else {
			lines = append(lines, cur)
			cur = word
		}
	}
	if cur != "" {
		lines = append(lines, cur)
	}
	return strings.Join(lines, "\n")
}

// ------------------------------------------------------------------- guide

func (m *breaksMode) guideView(w, h int) []string {
	pal := m.c.Pal
	g := m.guide
	r := m.b.Get(g.id)
	if r == nil {
		return blank(w, h)
	}
	now := m.c.Now
	el := now.Sub(g.start)
	finished := !g.doneAt.IsZero()
	left := g.length - el
	if finished || left < 0 {
		left = 0
	}
	prog := breaksClampF(float64(el)/float64(g.length), 0, 1)
	if finished {
		prog = 1
	}
	title := bold(pal.Text, strings.ToUpper(m.title(r)))
	cue := paint(pal.Muted, m.cue(r))
	count := breaksFmtLeft(left)
	if finished {
		title = bold(pal.Good, "✓ "+i18n.T("breaks.guide.done"))
		cue = paint(pal.Muted, i18n.T("breaks.guide.next", r.Min))
	}
	hint := paint(pal.Muted, "enter ") + paint(pal.Text, i18n.T("breaks.k.done")) + paint(pal.Faint, "  ·  ") +
		paint(pal.Muted, "s ") + paint(pal.Text, i18n.T("breaks.k.snooze")) + paint(pal.Faint, "  ·  ") +
		paint(pal.Muted, "esc ") + paint(pal.Text, i18n.T("key.cancel"))

	digRows := 0
	if h >= 17 {
		digRows = 4
	}
	fixed := 3 + digRows
	visRows := h - fixed
	out := make([]string, 0, h)
	out = append(out, centerIn(title, w), centerIn(cue, w))
	if visRows >= 3 && w >= 16 {
		cols := breaksMin(w, visRows*3)
		if m.vis == nil || m.vis.Cols != cols || m.vis.Rows != visRows {
			m.vis = braille.New(cols, visRows)
		} else {
			m.vis.Clear()
		}
		visual.BreaksGuide(breaksGuideKind(r), m.vis, &visual.BreaksGuideFrame{
			T: m.c.Anim - 0, Progress: prog, Pal: pal, Still: m.c.Cfg.Motion == "still",
		})
		for _, l := range m.vis.Lines() {
			out = append(out, centerIn(l, w))
		}
	} else {
		for i := 0; i < visRows; i++ {
			out = append(out, spaces(w))
		}
		if visRows >= 1 {
			out[len(out)-1] = centerIn(bold(pal.Rest, count), w)
		}
	}
	if digRows > 0 {
		cols := breaksMin(w, 30)
		if m.dig == nil || m.dig.Cols != cols {
			m.dig = braille.New(cols, digRows)
		} else {
			m.dig.Clear()
		}
		d := m.dig
		col := pal.Rest
		if finished {
			col = pal.Good
		}
		d.TextCentered(braille.ParseFont(m.c.Cfg.Font), count, float64(d.W)/2, 6, 12, braille.Solid(col))
		bw := d.W - 8
		d.Line(4, 14, 4+float64(bw), 14, 2, braille.Solid(pal.Faint))
		if prog > 0 {
			d.Line(4, 14, 4+float64(bw)*prog, 14, 2, braille.Solid(col))
		}
		for _, l := range d.Lines() {
			out = append(out, centerIn(l, w))
		}
	}
	out = append(out, centerIn(hint, w))
	return out
}

func breaksGuideKind(r *engine.BreaksReminder) string {
	if r.Custom {
		return "custom"
	}
	return r.ID
}

// ------------------------------------------------------------------ editor

func (m *breaksMode) editorView(w, h int) []string {
	pal := m.c.Pal
	e := m.edit
	bw := clampi(w-4, 24, 52)
	title := i18n.T("breaks.edit.new")
	if e.id != "" {
		title = i18n.T("breaks.edit.edit")
	}
	label := func(s string, on bool) string {
		if on {
			return bold(pal.Accent, s)
		}
		return paint(pal.Muted, s)
	}
	e.name.SetWidth(bw - 6)
	rows := []string{
		bold(pal.Text, title),
		"",
		label(i18n.T("breaks.edit.name"), e.field == 0),
		e.name.View(),
		"",
		label(i18n.T("breaks.edit.every"), e.field == 1),
		e.every.View(),
	}
	if e.err != "" {
		rows = append(rows, "", paint(pal.Bad, e.err))
	}
	rows = append(rows, "", paint(pal.Muted, i18n.T("breaks.edit.hint")))
	box := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).BorderForeground(pal.Rest).
		Padding(0, 2).Width(bw).Render(strings.Join(rows, "\n"))
	return centerBlock(strings.Split(box, "\n"), w, h)
}
