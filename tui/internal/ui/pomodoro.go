package ui

import (
	"fmt"
	"math"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

type pomodoroMode struct {
	c      *Core
	dial   visual.Visual
	dialN  string
	canvas *braille.Canvas
	fx     *anim.Particles
	pulse  float64
	toast  func(string)
	area   struct{ x, y, w, h int } // dial hit area (body-relative cells)
	stage  *braille.Canvas          // dial + starfield
}

func init() {
	registerMode("pomodoro", func(c *Core, say func(string)) Mode { return newPomodoro(c, say) })
}

func newPomodoro(c *Core, toast func(string)) *pomodoroMode {
	m := &pomodoroMode{c: c, fx: anim.NewParticles(7), toast: toast}
	m.setDial(c.Cfg.Dial)
	return m
}

func (m *pomodoroMode) ID() string { return "pomodoro" }

func (m *pomodoroMode) setDial(name string) {
	m.dial = visual.NewDial(name)
	m.dialN = m.dial.Name()
	m.c.Cfg.Dial = m.dialN
}

func (m *pomodoroMode) Animated() bool { return m.c.Cfg.Motion != "still" }

func (m *pomodoroMode) Title() string {
	p := m.c.Pomo
	if !p.Active() {
		return ""
	}
	icon := "▶"
	if p.Run == engine.Paused {
		icon = "⏸"
	}
	return fmt.Sprintf("%s %s %s", icon, clockText(p.Remaining(m.c.Now)), i18n.T("phase."+string(p.Phase)))
}

func (m *pomodoroMode) Help() []key.Binding {
	run := i18n.T("pomo.start")
	switch m.c.Pomo.Run {
	case engine.Running:
		run = i18n.T("pomo.pause")
	case engine.Paused:
		run = i18n.T("pomo.resume")
	}
	return []key.Binding{
		kb("space|enter", "space", run),
		kb("r", "r", i18n.T("pomo.reset")),
		kb("s", "s", i18n.T("pomo.skip")),
		kb("+|=|-|_", "+/-", i18n.T("pomo.time")),
		kb("d|D", "d", i18n.T("pomo.dial")),
		kb("t", "t", i18n.T("pomo.font")),
		kb("p", "p", i18n.T("pomo.preset")),
	}
}

type rhythm struct {
	id         string
	work, rest int
	long       int
}

var rhythms = []rhythm{
	{"classic", 25, 5, 15},
	{"extended", 50, 10, 20},
	{"deep", 90, 20, 30},
}

func (m *pomodoroMode) currentRhythm() (string, bool) {
	for _, r := range rhythms {
		if r.work == m.c.Cfg.Work && r.rest == m.c.Cfg.Rest {
			return r.id, true
		}
	}
	return "custom", false
}

func (m *pomodoroMode) Celebrate(a Announce) {
	switch a.Kind {
	case engine.KindFocus, engine.KindRest, engine.KindLong:
	default:
		return // other tools finishing do not throw Pomodoro confetti
	}
	m.pulse = 1
	if m.canvas == nil {
		return
	}
	cx, cy := float64(m.canvas.W)/2, float64(m.canvas.H)/2
	pal := m.c.Pal
	cols := []braille.RGB{pal.Accent, pal.Bright, pal.Rest, pal.RestHi, pal.Sun, pal.Text}
	for i := 0; i < 3; i++ {
		m.fx.Burst(cx, cy, 70, math.Min(cx, cy)*1.5, cols)
	}
}

func (m *pomodoroMode) Frame(dt time.Duration) {
	if m.pulse > 0 {
		m.pulse = math.Max(0, m.pulse-dt.Seconds()/0.9)
	}
	m.fx.Step(dt.Seconds())
}

func (m *pomodoroMode) Update(msg tea.Msg) tea.Cmd {
	c := m.c
	now := c.Now
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch {
		case matches(msg, kb("space|enter", "", "")):
			wasIdle := c.Pomo.Run == engine.Idle
			c.Pomo.Toggle(now)
			if wasIdle {
				m.pulse = 1
			}
			c.MarkDirty()
		case matches(msg, kb("r", "", "")):
			c.Log(c.Pomo.Reset(now)...)
			c.MarkDirty()
		case matches(msg, kb("s", "", "")):
			c.Log(c.Pomo.Skip(now)...)
			c.MarkDirty()
		case matches(msg, kb("+|=", "", "")):
			c.Pomo.Add(time.Minute, now)
			c.MarkDirty()
		case matches(msg, kb("-|_", "", "")):
			c.Pomo.Add(-time.Minute, now)
			c.MarkDirty()
		case matches(msg, kb("up|k", "", "")):
			c.Pomo.Add(5*time.Minute, now)
			c.MarkDirty()
		case matches(msg, kb("down|j", "", "")):
			c.Pomo.Add(-5*time.Minute, now)
			c.MarkDirty()
		case matches(msg, kb("d", "", "")):
			m.cycleDial(1)
		case matches(msg, kb("D", "", "")):
			m.cycleDial(-1)
		case matches(msg, kb("t", "", "")):
			f := (braille.ParseFont(c.Cfg.Font) + 1) % braille.Font(braille.Fonts)
			c.Cfg.Font = f.String()
		case matches(msg, kb("p", "", "")):
			m.nextPreset()
		}
	case tea.MouseClickMsg:
		if msg.Button == tea.MouseLeft && m.hitDial(msg.X, msg.Y) {
			c.Pomo.Toggle(now)
			c.MarkDirty()
		}
	case tea.MouseWheelMsg:
		if m.hitDial(msg.X, msg.Y) {
			if msg.Button == tea.MouseWheelUp {
				c.Pomo.Add(time.Minute, now)
			} else if msg.Button == tea.MouseWheelDown {
				c.Pomo.Add(-time.Minute, now)
			}
			c.MarkDirty()
		}
	}
	return nil
}

func (m *pomodoroMode) hitDial(x, y int) bool {
	a := m.area
	return x >= a.x && x < a.x+a.w && y >= a.y && y < a.y+a.h
}

func (m *pomodoroMode) cycleDial(d int) {
	names := visual.DialNames()
	idx := 0
	for i, n := range names {
		if n == m.dialN {
			idx = i
		}
	}
	idx = (idx + d + len(names)) % len(names)
	m.setDial(names[idx])
	m.fx.P = nil
	if m.toast != nil {
		m.toast("◔ " + names[idx])
	}
}

func (m *pomodoroMode) nextPreset() {
	c := m.c
	if c.Pomo.Run != engine.Idle {
		if m.toast != nil {
			m.toast(i18n.T("pomo.busy"))
		}
		return
	}
	idx := -1
	for i, r := range rhythms {
		if r.work == c.Cfg.Work && r.rest == c.Cfg.Rest {
			idx = i
		}
	}
	r := rhythms[(idx+1)%len(rhythms)]
	c.Cfg.Work, c.Cfg.Rest, c.Cfg.Long = r.work, r.rest, r.long
	c.Pomo.SetConfig(c.Cfg.Pomodoro())
	c.MarkDirty()
	if m.toast != nil {
		m.toast(i18n.T("pomo.preset.set", fmt.Sprintf("%s %d/%d", i18n.T("pomo.preset."+r.id), r.work, r.rest)))
	}
}

// frame builds the visual frame from the engine.
func (m *pomodoroMode) frame() *visual.Frame {
	c := m.c
	p := c.Pomo
	now := c.Now
	f := &visual.Frame{
		Progress: p.Progress(now),
		Running:  p.Run == engine.Running,
		Rest:     p.Phase.IsRest(),
		Idle:     p.Run == engine.Idle,
		Time:     c.Anim,
		Dt:       c.Dt.Seconds(),
		Pulse:    m.pulse,
		Pal:      c.Pal,
		Text:     clockText(p.Remaining(now)),
		Font:     braille.ParseFont(c.Cfg.Font),
		Still:    c.Cfg.Motion == "still",
	}
	switch p.Run {
	case engine.Paused:
		f.Sub = i18n.T("state.paused")
	case engine.Idle:
		f.Sub = i18n.T("phase." + string(p.Phase))
	default:
		f.Sub = i18n.T("phase." + string(p.Phase))
	}
	return f
}

func wantsFill(v visual.Visual) bool {
	switch v.Name() {
	case "hourglass", "bars":
		return true
	}
	return false
}

func (m *pomodoroMode) View(w, h int) string {
	c := m.c
	if m.dialN != c.Cfg.Dial {
		m.setDial(c.Cfg.Dial) // changed in Settings
	}
	if w < 12 || h < 3 {
		return join(blank(w, h))
	}
	wide := w >= 100 && h >= 20
	panelW := 0
	if wide {
		panelW = clampi(w*30/100, 32, 46)
	}
	infoRows := 0
	if !wide && h >= 14 {
		infoRows = 2
	}
	areaW, areaH := w-panelW, h-infoRows
	if wide {
		areaW -= 2
	}

	cols, rows := areaW, areaH
	if !wantsFill(m.dial) {
		rows = mini(areaH, areaW/2)
		cols = rows * 2
	} else {
		cols = mini(cols, 120)
		rows = mini(rows, 36)
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
	// center the dial in its area, over a faint starfield
	top := (areaH - rows) / 2
	left := (areaW - cols) / 2
	m.area.x, m.area.y, m.area.w, m.area.h = left, top, cols, rows
	if m.stage == nil || m.stage.Cols != areaW || m.stage.Rows != areaH {
		m.stage = braille.New(areaW, areaH)
	} else {
		m.stage.Clear()
	}
	if c.Cfg.Stars {
		m.drawStars(m.stage, left, top, cols, rows)
	}
	m.stage.Blit(m.canvas, left, top)
	dial := m.stage.Lines()
	for i := range labels {
		labels[i].Row += top
		labels[i].Col += left
	}
	overlayLabels(dial, labels)

	var body []string
	if wide {
		panel := m.panel(panelW, h)
		body = hcat(dial, blank(2, h), panel)
	} else {
		body = dial
		if infoRows > 0 {
			body = append(body, m.info(w)...)
		}
	}
	return join(fit(body, w, h))
}

// dots draws the cycle as braille beads: done, current, pending.
func (m *pomodoroMode) dots() string {
	p := m.c.Pomo
	pal := m.c.Pal
	total := p.Cfg.Cycles
	if total <= 0 {
		return ""
	}
	var sb strings.Builder
	for i := 0; i < total; i++ {
		switch {
		case i < p.Done:
			sb.WriteString(paint(pal.Accent, "⣿"))
		case i == p.Done && p.Phase == engine.Focus && p.Active():
			sb.WriteString(paint(pal.Bright, "⣶"))
		default:
			sb.WriteString(paint(pal.Faint, "⠶"))
		}
		sb.WriteString(" ")
	}
	return sb.String()
}

func (m *pomodoroMode) info(w int) []string {
	c := m.c
	p := c.Pomo
	pal := c.Pal
	col := pal.Phase(p.Phase.IsRest())
	var l1 string
	switch {
	case p.Cfg.Cycles > 0:
		l1 = m.dots() + paint(pal.Muted, i18n.T("pomo.session", p.Done+1, p.Cfg.Cycles))
	default:
		l1 = paint(pal.Muted, i18n.T("pomo.session.n", p.Done+1))
	}
	l2 := ""
	if p.Run == engine.Running {
		l2 = paint(pal.Muted, i18n.T("pomo.ends", p.EndsAt.Format("15:04")))
	} else if p.Run == engine.Idle {
		l2 = paint(col, i18n.T("pomo.press"))
	}
	return []string{centerIn(l1, w), centerIn(l2, w)}
}

// drawStars scatters faint twinkling stars around (never inside) the dial.
func (m *pomodoroMode) drawStars(c *braille.Canvas, dx, dy, dw, dh int) {
	pal := m.c.Pal
	still := m.c.Cfg.Motion == "still"
	cx, cy := float64(dx+dw/2)*2, float64(dy+dh/2)*4
	keep := math.Min(float64(dw*2), float64(dh*4))/2 + 3
	n := c.W * c.H / 90
	for i := 0; i < n; i++ {
		x := int(anim.Hash01(uint32(i*2+1)) * float64(c.W))
		y := int(anim.Hash01(uint32(i*2+2)) * float64(c.H))
		if !wantsFill(m.dial) && math.Hypot(float64(x)-cx, float64(y)-cy) < keep {
			continue
		}
		if wantsFill(m.dial) && x >= dx*2 && x < (dx+dw)*2 && y >= dy*4 && y < (dy+dh)*4 {
			continue
		}
		tw := 0.5
		if !still {
			tw = 0.5 + 0.5*math.Sin(m.c.Anim*(0.6+anim.Hash01(uint32(i*7+3))*1.4)+float64(i))
		}
		c.Set(x, y, pal.Bg.Mix(pal.Muted, 0.08+0.38*tw))
	}
}
