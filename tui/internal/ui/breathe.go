package ui

import (
	"fmt"
	"math"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// breatheGoals are the session lengths to cycle through (minutes, 0 = free).
var breatheGoals = []int{0, 1, 3, 5, 10}

// breatheMinLog is the shortest session worth writing to the history.
const breatheMinLog = 30 * time.Second

type breatheMode struct {
	c   *Core
	say func(string)

	vis    visual.BreatheVisual
	visN   string
	canvas *braille.Canvas

	running    bool
	sessStart  time.Time // when the session began (history)
	cycleStart time.Time // when the pattern's first breath began
	goal       int       // index into breatheGoals
}

func init() {
	registerMode("breathe", func(c *Core, say func(string)) Mode { return newBreathe(c, say) })
}

func newBreathe(c *Core, say func(string)) *breatheMode {
	m := &breatheMode{c: c, say: say, goal: 3}
	m.setVisual(c.Cfg.BreatheVisual)
	return m
}

func (m *breatheMode) ID() string { return "breathe" }

func (m *breatheMode) setVisual(name string) {
	m.vis = visual.NewBreatheVisual(name)
	m.visN = m.vis.Name()
}

func (m *breatheMode) pattern() engine.Pattern { return engine.PatternByID(m.c.Cfg.Breathe) }

func (m *breatheMode) Animated() bool { return m.running || m.c.Cfg.Motion != "still" }

// point is where the breath is now. Idle shows a slow preview.
func (m *breatheMode) point() (engine.BreathePoint, float64) {
	p := m.pattern()
	cyc := p.Cycle()
	var el time.Duration
	switch {
	case m.running:
		el = m.c.Now.Sub(m.cycleStart)
	case m.c.Cfg.Motion == "still":
		el = time.Duration(p.Inhale) * time.Second / 2
	default:
		el = time.Duration(m.c.Anim * 0.5 * float64(time.Second))
	}
	if el < 0 {
		el = 0
	}
	frac := 0.0
	if cyc > 0 {
		frac = float64(el%cyc) / float64(cyc)
	}
	return p.At(el), frac
}

func breatheBeatKey(ph engine.BreathePhase) string {
	switch ph {
	case engine.Inhale:
		return "breathe.inhale"
	case engine.Exhale:
		return "breathe.exhale"
	case engine.HoldFull:
		return "breathe.hold.full"
	}
	return "breathe.hold.empty"
}

func breatheSecs(pt engine.BreathePoint) int {
	n := int(math.Ceil(pt.Left().Seconds()))
	if n < 1 {
		n = 1
	}
	return n
}

func (m *breatheMode) Title() string {
	if !m.running {
		return ""
	}
	pt, _ := m.point()
	return fmt.Sprintf("❋ %s %d", strings.ToLower(i18n.T(breatheBeatKey(pt.Phase))), breatheSecs(pt))
}

func (m *breatheMode) Help() []key.Binding {
	run := i18n.T("breathe.start")
	if m.running {
		run = i18n.T("breathe.stop")
	}
	return []key.Binding{
		kb("space|enter", "space", run),
		kb("p|P", "p", i18n.T("breathe.pattern")),
		kb("d|D", "d", i18n.T("breathe.style")),
		kb("+|=|-|_", "+/-", i18n.T("breathe.goal")),
	}
}

func (m *breatheMode) start() {
	m.running = true
	m.sessStart, m.cycleStart = m.c.Now, m.c.Now
}

// stop ends the session, logging it when it was long enough. It returns the
// elapsed time and the number of breaths taken.
func (m *breatheMode) stop() (time.Duration, int) {
	el := m.c.Now.Sub(m.sessStart)
	pt := m.pattern().At(m.c.Now.Sub(m.cycleStart))
	breaths := pt.Breath
	if pt.Phase == engine.Exhale && pt.Into == pt.PhaseLen {
		breaths++
	}
	if m.running && el >= breatheMinLog {
		m.c.Log(engine.Event{Kind: engine.KindBreathe, Label: m.pattern().ID, Start: m.sessStart,
			Planned: time.Duration(breatheGoals[m.goal]) * time.Minute, Actual: el, Completed: true})
	}
	m.running = false
	return el, breaths
}

func (m *breatheMode) Frame(dt time.Duration) {
	if !m.running {
		return
	}
	g := breatheGoals[m.goal]
	if g > 0 && m.c.Now.Sub(m.sessStart) >= time.Duration(g)*time.Minute {
		el, breaths := m.stop()
		// goes through the shared announcement path: toast, notification, chime
		m.c.announce = append(m.c.announce, Announce{
			Kind:  engine.KindBreathe,
			Title: i18n.T("breathe.done"),
			Body:  i18n.T("breathe.done.body", fmtDur(el.Round(time.Second)), breaths),
		})
	}
}

func (m *breatheMode) Update(msg tea.Msg) tea.Cmd {
	c := m.c
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch {
		case matches(msg, kb("space|enter", "", "")):
			if m.running {
				m.stop()
			} else {
				m.start()
			}
		case matches(msg, kb("p", "", "")):
			m.cyclePattern(1)
		case matches(msg, kb("P", "", "")):
			m.cyclePattern(-1)
		case matches(msg, kb("d", "", "")):
			m.cycleVisual(1)
		case matches(msg, kb("D", "", "")):
			m.cycleVisual(-1)
		case matches(msg, kb("+|=", "", "")):
			m.stepGoal(1)
		case matches(msg, kb("-|_", "", "")):
			m.stepGoal(-1)
		}
	case tea.MouseClickMsg:
		if msg.Button == tea.MouseLeft {
			if m.running {
				m.stop()
			} else {
				m.start()
			}
		}
	case tea.MouseWheelMsg:
		if msg.Button == tea.MouseWheelUp {
			m.stepGoal(1)
		} else if msg.Button == tea.MouseWheelDown {
			m.stepGoal(-1)
		}
	}
	_ = c
	return nil
}

func (m *breatheMode) cyclePattern(d int) {
	idx := 0
	for i, p := range engine.Patterns {
		if p.ID == m.c.Cfg.Breathe {
			idx = i
		}
	}
	idx = (idx + d + len(engine.Patterns)) % len(engine.Patterns)
	m.c.Cfg.Breathe = engine.Patterns[idx].ID
	m.c.ApplyConfig()
	if m.running {
		m.cycleStart = m.c.Now // a new rhythm starts from the first inhale
	}
	m.say("❋ " + m.patternName(engine.Patterns[idx]))
}

func (m *breatheMode) cycleVisual(d int) {
	names := visual.BreatheVisualNames()
	idx := 0
	for i, n := range names {
		if n == m.visN {
			idx = i
		}
	}
	idx = (idx + d + len(names)) % len(names)
	m.setVisual(names[idx])
	m.c.Cfg.BreatheVisual = names[idx]
	m.c.ApplyConfig()
	m.say("❋ " + i18n.T("breathe.style."+names[idx]))
}

func (m *breatheMode) stepGoal(d int) {
	m.goal = (m.goal + d + len(breatheGoals)) % len(breatheGoals)
	m.say("❋ " + m.goalText())
}

func (m *breatheMode) goalText() string {
	g := breatheGoals[m.goal]
	if g == 0 {
		return i18n.T("breathe.free")
	}
	return fmtDur(time.Duration(g) * time.Minute)
}

func (m *breatheMode) patternName(p engine.Pattern) string {
	return i18n.T("breathe.pattern."+p.ID) + " " + p.Timings()
}

// letterSpace spreads a label's letters apart for a calmer look.
func breatheLetterSpace(s string) string {
	r := []rune(s)
	parts := make([]string, len(r))
	for i, ch := range r {
		parts[i] = string(ch)
	}
	return strings.Join(parts, " ")
}

func (m *breatheMode) frame(pt engine.BreathePoint, cycle float64) *visual.BreatheFrame {
	prog := 0.0
	if pt.PhaseLen > 0 {
		prog = float64(pt.Into) / float64(pt.PhaseLen)
	}
	return &visual.BreatheFrame{
		Fill: pt.Fill, Phase: pt.Phase, PhaseProg: prog, Cycle: cycle,
		Running: m.running, Time: m.c.Anim, Dt: m.c.Dt.Seconds(),
		Pal: m.c.Pal, Still: m.c.Cfg.Motion == "still",
	}
}

func (m *breatheMode) View(w, h int) string {
	c := m.c
	if w < 1 || h < 1 {
		return ""
	}
	pt, cycle := m.point()
	pal := c.Pal
	col := pal.Rest.Mix(pal.Accent, pt.Fill)
	zen := c.H > 0 && h == c.H

	label := i18n.T(breatheBeatKey(pt.Phase))
	secs := breatheSecs(pt)
	var head string
	if m.running {
		head = bold(col, breatheLetterSpace(label))
	} else {
		head = faint(col, breatheLetterSpace(label))
	}

	// tiny: only words
	if h < 5 || w < 16 {
		txt := fmt.Sprintf("%s %d", label, secs)
		if !m.running {
			txt = label
		}
		out := blank(w, h)
		out[h/2] = centerIn(bold(col, txt), w)
		return join(fit(out, w, h))
	}

	textRows := 3
	switch {
	case zen:
		textRows = 0
	case h < 10:
		textRows = 2
	case h >= 16:
		textRows = 4 // a blank row keeps the words off the footer
	}
	areaW, areaH := w, h-textRows
	cols, rows := areaW, areaH
	if visual.BreatheWantsFill(m.vis) {
		cols, rows = mini(cols, 240), mini(rows, 64)
	} else {
		rows = mini(areaH, areaW/2)
		cols = rows * 2
	}
	if cols < 2 || rows < 1 {
		cols, rows = areaW, areaH
	}
	if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
		m.canvas = braille.New(cols, rows)
	} else {
		m.canvas.Clear()
	}
	m.vis.Draw(m.canvas, m.frame(pt, cycle))
	lines := m.canvas.Lines()
	top, left := (areaH-rows)/2, (areaW-cols)/2
	body := blank(w, h)
	for i, l := range lines {
		if top+i < areaH {
			body[top+i] = padRight(spaces(left)+l, w)
		}
	}

	if zen {
		txt := strings.ToLower(label)
		if m.running {
			txt += " · " + itoa(secs)
		}
		body[h-1] = stamp(body[h-1], (w-width(txt))/2, faint(col, txt))
		return join(fit(body, w, h))
	}

	// the words under the art
	base := areaH
	body[base] = centerIn(head, w)
	if textRows >= 3 || !m.running {
		body[base+1] = centerIn(m.beatLine(pt, col, w), w)
	} else {
		body[base+1] = centerIn(m.beatLine(pt, col, w), w)
	}
	if textRows >= 3 {
		body[base+2] = centerIn(m.metaLine(pt), w)
	}
	return join(fit(body, w, h))
}

// beatLine is the thin beat progress bar with the countdown.
func (m *breatheMode) beatLine(pt engine.BreathePoint, col braille.RGB, w int) string {
	pal := m.c.Pal
	if !m.running {
		return paint(pal.Muted, i18n.T("breathe.press"))
	}
	bw := clampi(w-14, 6, 30)
	prog := 0.0
	if pt.PhaseLen > 0 {
		prog = float64(pt.Into) / float64(pt.PhaseLen)
	}
	filled := int(prog * float64(bw))
	bar := paint(col, strings.Repeat("⣿", filled)) + paint(pal.Faint, strings.Repeat("⣀", bw-filled))
	return bar + "  " + bold(pal.Text, itoa(breatheSecs(pt)))
}

// metaLine: the rhythm, the breath count, the session clock and goal.
func (m *breatheMode) metaLine(pt engine.BreathePoint) string {
	pal := m.c.Pal
	p := m.pattern()
	parts := []string{m.patternName(p)}
	if m.running {
		parts = append(parts, i18n.T("breathe.breath", pt.Breath+1))
		el := swText(m.c.Now.Sub(m.sessStart), false)
		if g := breatheGoals[m.goal]; g > 0 {
			el += " / " + fmtDur(time.Duration(g)*time.Minute)
		}
		parts = append(parts, el)
	} else {
		parts = append(parts, i18n.T("breathe.goal.is", m.goalText()))
	}
	for i := range parts {
		parts[i] = paint(pal.Muted, parts[i])
	}
	return strings.Join(parts, paint(pal.Faint, "  ·  "))
}
