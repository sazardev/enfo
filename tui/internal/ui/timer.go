package ui

import (
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

const (
	timerMaxSecs    = 99*3600 + 59*60 + 59
	timerMaxPresets = 12
)

var timerUnits = [3]int{3600, 60, 1}

type timerRect struct{ x, y, w, h int }

func (r timerRect) has(x, y int) bool { return x >= r.x && x < r.x+r.w && y >= r.y && y < r.y+r.h }

type timerChipHit struct{ x, y, w, idx int }

type timerMode struct {
	c   *Core
	say func(string)

	dial   visual.Visual
	dialN  string
	canvas *braille.Canvas
	pick   *braille.Canvas
	fx     *anim.Particles
	pulse  float64

	field      int
	curX, curW *anim.Spring

	editing bool
	input   textinput.Model

	// hit areas, body-relative cells, refreshed by View
	dialArea   timerRect
	fieldRects [3]timerRect
	chipHits   []timerChipHit
}

func init() {
	registerMode("timer", func(c *Core, say func(string)) Mode { return newTimerMode(c, say) })
}

func newTimerMode(c *Core, say func(string)) *timerMode {
	m := &timerMode{c: c, say: say, fx: anim.NewParticles(11), field: 1}
	m.curX, m.curW = anim.NewSpring(0, 9, 0.8), anim.NewSpring(0, 9, 0.8)
	m.setDial(c.Cfg.Dial)
	m.input = textinput.New()
	m.input.CharLimit = 32
	m.input.SetWidth(28)
	return m
}

func (m *timerMode) ID() string { return "timer" }

func (m *timerMode) setDial(name string) {
	m.dial = visual.NewDial(name)
	m.dialN = m.dial.Name()
	m.c.Cfg.Dial = m.dialN
}

func (m *timerMode) Capturing() bool { return m.editing }

func (m *timerMode) Title() string {
	t := m.c.Timer
	if !t.Active() {
		return ""
	}
	icon := iconTimer
	if t.Run == engine.Paused {
		icon = "⏸"
	}
	return icon + " " + clockText(t.Remaining(m.c.Now))
}

func (m *timerMode) Animated() bool {
	if m.c.Cfg.Motion == "still" {
		return false
	}
	return m.c.Timer.Active() || m.pulse > 0 || m.fx.Len() > 0 ||
		!m.curX.Settled() || !m.curW.Settled()
}

func (m *timerMode) Help() []key.Binding {
	t := m.c.Timer
	run := i18n.T("timer.start")
	switch t.Run {
	case engine.Running:
		run = i18n.T("timer.pause")
	case engine.Paused:
		run = i18n.T("timer.resume")
	}
	if m.editing {
		return []key.Binding{
			kb("enter", "enter", i18n.T("key.confirm")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	}
	b := []key.Binding{kb("space|enter", "space", run), kb("r", "r", i18n.T("timer.reset"))}
	if t.Run == engine.Idle {
		b = append(b,
			kb("left|right|h|l", "←→", i18n.T("timer.field")),
			kb("up|down|k|j", "↑↓", i18n.T("timer.adjust")),
			kb("p|P", "p", i18n.T("timer.preset")),
			kb("a", "a", i18n.T("timer.save")),
			kb("x", "x", i18n.T("timer.del")),
			kb("e", "e", i18n.T("timer.label")),
		)
	} else {
		b = append(b, kb("+|=|-|_", "+/-", i18n.T("timer.add")))
	}
	return append(b, kb("d|D", "d", i18n.T("timer.dial")), kb("t", "t", i18n.T("timer.font")))
}

// ----------------------------------------------------------------- values

func timerSecs(t *engine.Timer) int { return int(t.Total / time.Second) }

// presetIndex is the preset equal to the current time, or -1.
func (m *timerMode) presetIndex() int {
	s := timerSecs(m.c.Timer)
	for i, p := range m.c.Cfg.Presets {
		if p == s {
			return i
		}
	}
	return -1
}

func (m *timerMode) setSecs(s int) {
	t := m.c.Timer
	if t.Run != engine.Idle {
		return
	}
	s = clampi(s, 0, timerMaxSecs)
	t.Set(time.Duration(s)*time.Second, t.Label)
	m.c.MarkDirty()
}

func (m *timerMode) adjust(field, steps int) {
	m.setSecs(timerSecs(m.c.Timer) + steps*timerUnits[field])
}

// timerPresetLabel writes a preset compactly: 45s, 5m, 1m30s, 1h, 1h05.
func timerPresetLabel(s int) string {
	h, mi, sec := s/3600, s%3600/60, s%60
	switch {
	case h > 0 && mi == 0 && sec == 0:
		return fmt.Sprintf("%dh", h)
	case h > 0 && sec == 0:
		return fmt.Sprintf("%dh%02d", h, mi)
	case h > 0:
		return fmt.Sprintf("%d:%02d:%02d", h, mi, sec)
	case mi > 0 && sec == 0:
		return fmt.Sprintf("%dm", mi)
	case mi > 0:
		return fmt.Sprintf("%dm%02ds", mi, sec)
	}
	return fmt.Sprintf("%ds", sec)
}

func timerHMS(s int) string { return fmt.Sprintf("%02d:%02d:%02d", s/3600, s%3600/60, s%60) }

func (m *timerMode) start() {
	c := m.c
	t := c.Timer
	if t.Run == engine.Idle {
		if t.Left <= 0 {
			m.say(i18n.T("timer.set"))
			return
		}
		m.pulse = 1
		m.burst(26)
	}
	t.Toggle(c.Now)
	c.MarkDirty()
}

func (m *timerMode) burst(n int) {
	if m.canvas == nil {
		return
	}
	pal := m.c.Pal
	cx, cy := float64(m.canvas.W)/2, float64(m.canvas.H)/2
	m.fx.Burst(cx, cy, n, math.Min(cx, cy)*1.1, []braille.RGB{pal.Rest, pal.RestHi, pal.Text})
}

// ----------------------------------------------------------------- input

func (m *timerMode) Update(msg tea.Msg) tea.Cmd {
	c := m.c
	t := c.Timer
	now := c.Now
	if m.editing {
		if k, ok := msg.(tea.KeyPressMsg); ok {
			switch k.String() {
			case "enter":
				t.Label = strings.TrimSpace(m.input.Value())
				m.editing = false
				m.input.Blur()
				c.MarkDirty()
				return nil
			case "esc":
				m.editing = false
				m.input.Blur()
				return nil
			}
			var cmd tea.Cmd
			m.input, cmd = m.input.Update(msg)
			return cmd
		}
		return nil
	}
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		idle := t.Run == engine.Idle
		s := msg.String()
		switch s {
		case "space", "enter":
			m.start()
		case "r":
			c.Log(t.Reset(now)...)
			c.MarkDirty()
		case "left", "h":
			if idle {
				m.focus(m.field - 1)
			}
		case "right", "l":
			if idle {
				m.focus(m.field + 1)
			}
		case "up", "k":
			if idle {
				m.adjust(m.field, 1)
			} else {
				t.Add(5*time.Minute, now)
				c.MarkDirty()
			}
		case "down", "j":
			if idle {
				m.adjust(m.field, -1)
			} else {
				t.Add(-5*time.Minute, now)
				c.MarkDirty()
			}
		case "K", "shift+up":
			if idle {
				m.adjust(m.field, m.bigStep())
			}
		case "J", "shift+down":
			if idle {
				m.adjust(m.field, -m.bigStep())
			}
		case "+", "=":
			t.Add(time.Minute, now)
			c.MarkDirty()
		case "-", "_":
			t.Add(-time.Minute, now)
			c.MarkDirty()
		case "d":
			m.cycleDial(1)
		case "D":
			m.cycleDial(-1)
		case "t":
			f := (braille.ParseFont(c.Cfg.Font) + 1) % braille.Font(braille.Fonts)
			c.Cfg.Font = f.String()
		case "p":
			m.nextPreset(1)
		case "P":
			m.nextPreset(-1)
		case "a":
			m.savePreset()
		case "x":
			m.removePreset()
		case "e":
			if idle {
				m.editing = true
				m.input.SetValue(t.Label)
				m.input.Placeholder = i18n.T("timer.ph")
				return m.input.Focus()
			}
			m.say(i18n.T("timer.busy"))
		}
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			return nil
		}
		if t.Run == engine.Idle {
			for i, r := range m.fieldRects {
				if r.has(msg.X, msg.Y) {
					m.focus(i)
					return nil
				}
			}
			for _, h := range m.chipHits {
				if msg.Y == h.y && msg.X >= h.x && msg.X < h.x+h.w {
					m.pickPreset(h.idx)
					return nil
				}
			}
		}
		if m.dialArea.has(msg.X, msg.Y) && t.Run != engine.Idle {
			m.start()
		}
	case tea.MouseWheelMsg:
		up := msg.Button == tea.MouseWheelUp
		if !up && msg.Button != tea.MouseWheelDown {
			return nil
		}
		d := 1
		if !up {
			d = -1
		}
		if t.Run == engine.Idle {
			for i, r := range m.fieldRects {
				if r.has(msg.X, msg.Y) {
					m.focus(i)
					m.adjust(i, d)
					return nil
				}
			}
		} else if m.dialArea.has(msg.X, msg.Y) {
			t.Add(time.Duration(d)*time.Minute, now)
			c.MarkDirty()
		}
	}
	return nil
}

func (m *timerMode) bigStep() int {
	if m.field == 0 {
		return 1
	}
	return 5
}

func (m *timerMode) focus(i int) { m.field = clampi(i, 0, 2) }

func (m *timerMode) cycleDial(d int) {
	names := visual.DialNames()
	idx := 0
	for i, n := range names {
		if n == m.dialN {
			idx = i
		}
	}
	m.setDial(names[(idx+d+len(names))%len(names)])
	m.fx.P = nil
	m.say(iconTimer + " " + m.dialN)
}

func (m *timerMode) pickPreset(i int) {
	p := m.c.Cfg.Presets
	if i < 0 || i >= len(p) {
		return
	}
	m.setSecs(p[i])
}

func (m *timerMode) nextPreset(d int) {
	if m.c.Timer.Run != engine.Idle {
		m.say(i18n.T("timer.busy"))
		return
	}
	n := len(m.c.Cfg.Presets)
	if n == 0 {
		return
	}
	cur := m.presetIndex()
	var next int
	switch {
	case cur < 0 && d > 0:
		next = 0
	case cur < 0:
		next = n - 1
	default:
		next = (cur + d + n) % n
	}
	m.pickPreset(next)
}

func (m *timerMode) savePreset() {
	c := m.c
	s := timerSecs(c.Timer)
	if s <= 0 || c.Timer.Run != engine.Idle {
		m.say(i18n.T("timer.set"))
		return
	}
	for _, p := range c.Cfg.Presets {
		if p == s {
			m.say(i18n.T("timer.exists"))
			return
		}
	}
	if len(c.Cfg.Presets) >= timerMaxPresets {
		m.say(i18n.T("timer.full"))
		return
	}
	c.Cfg.Presets = append(append([]int(nil), c.Cfg.Presets...), s)
	sort.Ints(c.Cfg.Presets)
	c.ApplyConfig()
	m.say(i18n.T("timer.saved", timerPresetLabel(s)))
}

func (m *timerMode) removePreset() {
	c := m.c
	i := m.presetIndex()
	if i < 0 {
		m.say(i18n.T("timer.nopreset"))
		return
	}
	if len(c.Cfg.Presets) <= 1 {
		m.say(i18n.T("timer.keep"))
		return
	}
	p := append([]int(nil), c.Cfg.Presets[:i]...)
	c.Cfg.Presets = append(p, c.Cfg.Presets[i+1:]...)
	c.ApplyConfig()
	m.say(i18n.T("timer.removed"))
}

// ----------------------------------------------------------------- frame

func (m *timerMode) Frame(dt time.Duration) {
	if m.pulse > 0 {
		m.pulse = math.Max(0, m.pulse-dt.Seconds()/0.9)
	}
	m.fx.Step(dt.Seconds())
	if m.c.Cfg.Motion == "still" {
		m.curX.Snap(m.curX.Target)
		m.curW.Snap(m.curW.Target)
		return
	}
	m.curX.Step(dt)
	m.curW.Step(dt)
}

// urgency is 0 until the last ten seconds, then ramps up to 1.
func (m *timerMode) urgency() float64 {
	t := m.c.Timer
	if t.Run != engine.Running {
		return 0
	}
	rem := t.Remaining(m.c.Now).Seconds()
	if rem > 10 || rem <= 0 {
		return 0
	}
	return 1 - rem/10
}

func (m *timerMode) frame() *visual.Frame {
	c := m.c
	t := c.Timer
	now := c.Now
	pal := c.Pal
	pulse := m.pulse
	if u := m.urgency(); u > 0 {
		// the ring and digits turn warm, and flash once a second
		pal.Rest = pal.Rest.Mix(pal.Warn, 0.25+0.6*u)
		pal.RestHi = pal.RestHi.Mix(pal.Warn.Lighten(0.3), 0.25+0.6*u)
		pal.Text = pal.Text.Mix(pal.Warn, 0.5+0.5*u)
		if c.Cfg.Motion != "still" {
			rem := t.Remaining(now).Seconds()
			pulse = math.Max(pulse, rem-math.Floor(rem))
		}
	}
	f := &visual.Frame{
		Progress: t.Progress(now),
		Running:  t.Run == engine.Running,
		Rest:     true,
		Idle:     t.Run == engine.Idle,
		Time:     c.Anim,
		Dt:       c.Dt.Seconds(),
		Pulse:    pulse,
		Pal:      pal,
		Text:     clockText(t.Remaining(now)),
		Font:     braille.ParseFont(c.Cfg.Font),
		Still:    c.Cfg.Motion == "still",
	}
	switch {
	case t.Run == engine.Paused:
		f.Sub = i18n.T("state.paused")
	case t.Label != "":
		f.Sub = strings.ToUpper(t.Label)
	default:
		f.Sub = i18n.T("timer.title")
	}
	return f
}

// ----------------------------------------------------------------- view

func (m *timerMode) View(w, h int) string {
	if w < 12 || h < 3 {
		return join(blank(w, h))
	}
	m.chipHits = m.chipHits[:0]
	m.dialArea = timerRect{}
	m.fieldRects = [3]timerRect{}

	wide := w >= 100 && h >= 20
	panelW := 0
	if wide {
		panelW = clampi(w*30/100, 32, 46)
	}
	areaW := w - panelW
	if wide {
		areaW -= 2
	}
	var left []string
	var panel []string
	if m.c.Timer.Run == engine.Idle {
		left = m.viewPicker(areaW, h, wide)
	} else {
		left = m.viewDial(areaW, h, wide)
	}
	if wide {
		panel = m.panel(panelW, h, areaW+2)
		return join(fit(hcat(fit(left, areaW, h), blank(2, h), panel), w, h))
	}
	return join(fit(left, w, h))
}

func (m *timerMode) editorLine(w int) string {
	pal := m.c.Pal
	st := m.input.Styles()
	st.Focused.Text = lipgloss.NewStyle().Foreground(pal.Text)
	st.Focused.Prompt = lipgloss.NewStyle().Foreground(pal.Rest)
	st.Focused.Placeholder = lipgloss.NewStyle().Foreground(pal.Muted)
	m.input.SetStyles(st)
	m.input.Prompt = "▸ "
	m.input.SetWidth(clampi(w-6, 8, 30))
	return m.input.View()
}

func (m *timerMode) infoLine(w int) string {
	c := m.c
	t := c.Timer
	pal := c.Pal
	switch {
	case m.editing:
		return m.editorLine(w)
	case t.Run == engine.Running:
		return paint(pal.Muted, i18n.T("timer.ends", t.EndsAt.Format("15:04")))
	case t.Run == engine.Paused:
		return paint(pal.Warn, i18n.T("state.paused"))
	case t.Label != "":
		return paint(pal.Rest, t.Label) + paint(pal.Faint, "  ·  ") + paint(pal.Muted, i18n.T("timer.press"))
	}
	return paint(pal.Rest, i18n.T("timer.press"))
}

// viewDial draws the running or paused timer on the shared dial visuals.
func (m *timerMode) viewDial(areaW, h int, wide bool) []string {
	c := m.c
	infoRows := 0
	if !wide && h >= 14 {
		infoRows = 2
	}
	areaH := h - infoRows
	cols, rows := areaW, areaH
	if !wantsFill(m.dial) {
		rows = mini(areaH, areaW/2)
		cols = rows * 2
	} else {
		cols, rows = mini(cols, 120), mini(rows, 36)
	}
	if cols < 8 || rows < 3 {
		cols, rows = areaW, areaH
	}
	if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
		m.canvas = braille.New(cols, rows)
	} else {
		m.canvas.Clear()
	}
	f := m.frame()
	labels := m.dial.Draw(m.canvas, f)
	m.fx.Draw(m.canvas, c.Pal.Bg)
	lines := m.canvas.Lines()
	overlayLabels(lines, labels)

	top, left := (areaH-rows)/2, (areaW-cols)/2
	m.dialArea = timerRect{left, top, cols, rows}
	out := blank(areaW, areaH)
	for i, l := range lines {
		if top+i < areaH {
			out[top+i] = padRight(spaces(left)+l, areaW)
		}
	}
	if infoRows > 0 {
		out = append(out, centerIn(m.infoLine(areaW), areaW), centerIn(m.metaLine(), areaW))
	}
	return out
}

func (m *timerMode) metaLine() string {
	t := m.c.Timer
	pal := m.c.Pal
	return paint(pal.Faint, i18n.T("timer.title")+" "+fmtDur(t.Total))
}

// viewPicker is the idle screen: big HH:MM:SS with a springy field cursor.
func (m *timerMode) viewPicker(areaW, h int, wide bool) []string {
	c := m.c
	pal := c.Pal
	font := braille.ParseFont(c.Cfg.Font)
	secs := timerSecs(c.Timer)
	text := timerHMS(secs)

	// rows reserved below the digits: field captions are inside the canvas;
	// then chips (compact only), the info line and a spacer
	chipRows := 0
	if !wide && h >= 12 {
		chipRows = 1
		if areaW >= 60 && h >= 18 {
			chipRows = 2
		}
	}
	reserved := 2 + chipRows
	if chipRows > 0 {
		reserved++
	}
	if h < 7 {
		// tiny: one text line of digits
		return centerBlock([]string{m.tinyDigits(text), m.infoLine(areaW)}, areaW, h)
	}
	availRows := h - reserved
	dh := clampi(availRows*4-10, 8, 4*22)
	for dh > 8 && font.TextWidth(text, dh)+8 > areaW*2*85/100 {
		dh--
	}
	tw := font.TextWidth(text, dh)
	cols := mini(areaW, (tw+8)/2+1)
	rows := (2+dh+3+2)/4 + 2
	if rows > availRows {
		rows = availRows
	}
	if m.pick == nil || m.pick.Cols != cols || m.pick.Rows != rows {
		m.pick = braille.New(cols, rows)
	} else {
		m.pick.Clear()
	}
	cv := m.pick
	x0 := float64(cv.W-tw) / 2
	y0 := 2.0
	// field geometry in dots
	var xs [3]float64
	fw := float64(font.TextWidth("00", dh))
	advance := func(prefix string) float64 {
		if prefix == "" {
			return 0
		}
		return float64(font.TextWidth(prefix+"0", dh) - font.TextWidth("0", dh))
	}
	for i := 0; i < 3; i++ {
		xs[i] = x0 + advance(strings.Repeat("00:", i))
	}
	vals := [3]int{secs / 3600, secs % 3600 / 60, secs % 60}
	for i := 0; i < 3; i++ {
		col := pal.Muted.Mix(pal.Text, 0.35)
		if vals[i] == 0 {
			col = pal.Faint.Mix(pal.Muted, 0.5)
		}
		if i == m.field {
			col = pal.Text
		}
		cv.Text(font, fmt.Sprintf("%02d", vals[i]), xs[i], y0, dh, braille.Solid(col))
	}
	colonCol := pal.Faint.Mix(pal.Rest, 0.35)
	for i := 1; i < 3; i++ {
		cx := x0 + advance(strings.Repeat("00:", i-1)+"00")
		cv.Text(font, ":", cx, y0, dh, braille.Solid(colonCol))
	}

	// the underline springs between fields
	m.curX.Target, m.curW.Target = xs[m.field], fw
	if m.curW.Pos == 0 {
		m.curX.Snap(xs[m.field])
		m.curW.Snap(fw)
	}
	ulY := y0 + float64(dh) + 3
	ulCol := pal.Rest
	if !m.editing && c.Cfg.Motion != "still" {
		ulCol = pal.Rest.Mix(pal.RestHi, 0.5*math.Sin(c.Anim*3)*0.5+0.25)
	}
	cv.Line(m.curX.Pos, ulY, m.curX.Pos+m.curW.Pos, ulY, 2, braille.Solid(ulCol))

	lines := cv.Lines()
	names := [3]string{i18n.T("timer.h"), i18n.T("timer.m"), i18n.T("timer.s")}
	capRow := int(ulY+2)/4 + 1
	var labels []visual.Label
	for i := 0; i < 3; i++ {
		col := pal.Faint
		if i == m.field {
			col = pal.Rest
		}
		labels = append(labels, visual.Label{
			Col: int(xs[i]+fw/2) / 2, Row: capRow, Text: names[i], Color: col, Bold: i == m.field, Center: true,
		})
	}
	if capRow < rows {
		overlayLabels(lines, labels)
	}

	// assemble: canvas, chips, info
	block := append([]string(nil), lines...)
	left := (areaW - cols) / 2
	top := (h - (len(block) + reserved)) / 2
	if top < 0 {
		top = 0
	}
	for i := 0; i < 3; i++ {
		m.fieldRects[i] = timerRect{
			x: left + int(xs[i])/2 - 1, y: top, w: int(fw)/2 + 2, h: len(block),
		}
	}
	out := make([]string, 0, h)
	for i := 0; i < top; i++ {
		out = append(out, spaces(areaW))
	}
	for _, l := range block {
		out = append(out, padRight(spaces(left)+l, areaW))
	}
	out = append(out, spaces(areaW))
	if chipRows > 0 {
		cl, hits := m.chips(areaW-4, chipRows)
		rowY := len(out)
		for _, l := range cl {
			out = append(out, centerIn(l, areaW))
		}
		for _, ht := range hits {
			lw := 0
			if ht.y < len(cl) {
				lw = width(cl[ht.y])
			}
			ht.x += (areaW - lw) / 2
			ht.y += rowY
			m.chipHits = append(m.chipHits, ht)
		}
		out = append(out, spaces(areaW))
	}
	out = append(out, centerIn(m.infoLine(areaW), areaW))
	return out
}

func (m *timerMode) tinyDigits(text string) string {
	return bold(m.c.Pal.Rest, text)
}

// chips lays the presets out in at most maxRows rows of width w, keeping the
// selected one in view. Hit rectangles are relative to the returned block.
func (m *timerMode) chips(w, maxRows int) ([]string, []timerChipHit) {
	pal := m.c.Pal
	presets := m.c.Cfg.Presets
	sel := m.presetIndex()
	chip := func(i int, on bool) string {
		txt := " " + timerPresetLabel(presets[i]) + " "
		if on {
			return lipgloss.NewStyle().Bold(true).Foreground(pal.RestHi).Background(pal.Bg.Mix(pal.Rest, 0.25)).Render(txt)
		}
		return paint(pal.Muted, txt)
	}
	type placed struct{ row, x, w, idx int }
	layout := func(start int) (lines [][]string, ps []placed, last int) {
		lines = make([][]string, 1)
		x := 0
		last = start - 1
		for i := start; i < len(presets); i++ {
			s := chip(i, i == sel)
			cw := width(s)
			if x > 0 && x+cw > w {
				if len(lines) == maxRows {
					break
				}
				lines = append(lines, nil)
				x = 0
			}
			if cw > w {
				break
			}
			ps = append(ps, placed{len(lines) - 1, x, cw, i})
			lines[len(lines)-1] = append(lines[len(lines)-1], s)
			x += cw + 1
			last = i
		}
		return
	}
	start := 0
	for start < len(presets) {
		_, _, last := layout(start)
		if sel < 0 || sel <= last {
			break
		}
		start++
	}
	lines, ps, _ := layout(start)
	out := make([]string, len(lines))
	for i, l := range lines {
		out[i] = strings.Join(l, " ")
	}
	var hits []timerChipHit
	for _, p := range ps {
		hits = append(hits, timerChipHit{x: p.x, y: p.row, w: p.w, idx: p.idx})
	}
	return out, hits
}

// panel is the wide layout's side column: status, presets, recent runs.
func (m *timerMode) panel(w, h, originX int) []string {
	c := m.c
	t := c.Timer
	pal := c.Pal
	section := lipgloss.NewStyle().Foreground(pal.Muted).Bold(true)
	mut := lipgloss.NewStyle().Foreground(pal.Muted)
	val := lipgloss.NewStyle().Foreground(pal.Text)

	var rows []string
	title := i18n.T("timer.title")
	if t.Label != "" {
		title = strings.ToUpper(t.Label)
	}
	rows = append(rows, lipgloss.NewStyle().Foreground(pal.Rest).Bold(true).Render("● "+title))
	rows = append(rows, m.infoLine(w))
	rows = append(rows, mut.Render(fmtDur(t.Total)))
	rows = append(rows, "")
	rows = append(rows, section.Render(strings.ToUpper(i18n.T("timer.presets"))))
	chipRow := len(rows)
	cl, hits := m.chips(w-1, 4)
	rows = append(rows, cl...)
	rows = append(rows, "")
	rows = append(rows, section.Render(strings.ToUpper(i18n.T("timer.recent"))))
	var recent []engine.Event
	for _, e := range engine.Recent(c.Events(), 200) {
		if e.Kind == engine.KindTimer {
			recent = append(recent, e)
		}
		if len(recent) == 5 {
			break
		}
	}
	if len(recent) == 0 {
		rows = append(rows, mut.Render(i18n.T("timer.none")))
	}
	for _, e := range recent {
		mark, col := "✓", pal.Good
		dur := fmtDur(e.Planned)
		if !e.Completed {
			mark, col = "◦", pal.Muted
			dur = fmtDur(e.Actual.Round(time.Second)) + "/" + fmtDur(e.Planned)
		}
		name := e.Label
		line := lipgloss.NewStyle().Foreground(col).Render(mark) + " " + val.Render(dur)
		if name != "" {
			line += " " + mut.Render(name)
		}
		line += " " + lipgloss.NewStyle().Foreground(pal.Faint).Render(e.Start.Format("Mon 15:04"))
		rows = append(rows, ansi.Truncate(line, w, "…"))
	}

	out := blank(w, h)
	top := (h - len(rows)) / 2
	if top < 0 {
		top = 0
	}
	for i, l := range rows {
		if top+i < h {
			out[top+i] = padRight(l, w)
		}
	}
	if t.Run == engine.Idle {
		for _, ht := range hits {
			m.chipHits = append(m.chipHits, timerChipHit{x: originX + ht.x, y: top + chipRow + ht.y, w: ht.w, idx: ht.idx})
		}
	}
	return out
}
