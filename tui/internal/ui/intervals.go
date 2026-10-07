package ui

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/notify"
)

func init() {
	registerMode("intervals", func(c *Core, say func(string)) Mode { return newIntervals(c, say) })
}

const intervalsCustom = 4 // preset index of the user's own plan

type intervalsField int

const (
	intervalsFWarm intervalsField = iota
	intervalsFWork
	intervalsFRest
	intervalsFRounds
	intervalsFCool
	intervalsFRamp
	intervalsFields
)

var intervalsFieldKeys = [intervalsFields]string{"warm", "work", "rest", "rounds", "cool", "ramp"}

// intervalsFile is what is kept in intervals.json.
type intervalsFile struct {
	Run    engine.IntervalsRun  `json:"run"`
	Custom engine.IntervalsPlan `json:"custom"`
	Preset int                  `json:"preset"`
	Style  string               `json:"style"`
}

type intervalsHit struct {
	x, y, w, h int
	field      int // -1 = the scene
}

type intervalsMode struct {
	c   *Core
	say func(string)
	f   intervalsFile

	focus    intervalsField
	lastKey  int // timeline index when last seen (-2 = unknown)
	lastBeep int
	flashAt  time.Time

	// mood: the screen color eases between phases on a spring
	moodFrom, moodTo braille.RGB
	moodSp           *anim.Spring
	moodPhase        engine.IntervalsPhase

	scene, word, ladder *braille.Canvas
	hits                []intervalsHit
	dirty               bool
	lastSave            time.Time
	t                   float64 // animation seconds
}

func intervalsPath(c *Core) string { return filepath.Join(c.Store.StateDir, "intervals.json") }

func newIntervals(c *Core, say func(string)) *intervalsMode {
	m := &intervalsMode{c: c, say: say, lastKey: -2, lastBeep: -1}
	m.f.Preset = 0
	m.f.Custom = engine.IntervalsPlan{Warm: 30 * time.Second, Work: 45 * time.Second, Rest: 15 * time.Second, Rounds: 6, Cool: 30 * time.Second}
	m.f.Style = "ring"
	if b, err := os.ReadFile(intervalsPath(c)); err == nil {
		var f intervalsFile
		if json.Unmarshal(b, &f) == nil {
			m.f = f
		}
	}
	m.f.Custom.Normalize()
	if m.f.Preset < 0 || m.f.Preset > intervalsCustom {
		m.f.Preset = 0
	}
	if m.f.Style != "ring" && m.f.Style != "hex" {
		m.f.Style = "ring"
	}
	if !m.f.Run.Active() {
		m.f.Run.Plan = m.plan()
	}
	m.f.Run.Plan.Normalize()
	// Whatever finished while Enfo was closed is logged, not rung.
	if evs := m.f.Run.Tick(c.Now); len(evs) > 0 {
		c.Log(evs...)
		m.dirty = true
	}
	pt := m.f.Run.Point(c.Now)
	m.moodPhase = pt.Seg.Phase
	m.moodFrom, m.moodTo = m.phaseColor(m.moodPhase), m.phaseColor(m.moodPhase)
	m.moodSp = anim.NewSpring(1, 6, 0.75)
	if m.f.Run.Run == engine.Running {
		m.lastKey = pt.Index
	}
	return m
}

func (m *intervalsMode) save() {
	b, err := json.Marshal(m.f)
	if err != nil {
		return
	}
	p := intervalsPath(m.c)
	tmp := p + ".tmp"
	if os.WriteFile(tmp, b, 0o644) == nil {
		_ = os.Rename(tmp, p)
	}
	m.dirty = false
	m.lastSave = m.c.Now
}

func (m *intervalsMode) plan() engine.IntervalsPlan {
	if m.f.Preset >= 0 && m.f.Preset < len(engine.IntervalsPresets) {
		return engine.IntervalsPresets[m.f.Preset].Plan
	}
	return m.f.Custom
}

func (m *intervalsMode) presetName() string {
	if m.f.Preset >= 0 && m.f.Preset < len(engine.IntervalsPresets) {
		return i18n.T("intervals.preset." + engine.IntervalsPresets[m.f.Preset].ID)
	}
	return i18n.T("intervals.preset.custom")
}

func (m *intervalsMode) ID() string { return "intervals" }

func (m *intervalsMode) Animated() bool { return m.c.Cfg.Motion != "still" }

// ---------------------------------------------------------------- Background

func (m *intervalsMode) Step(now time.Time, dt time.Duration) []Announce {
	var out []Announce
	run := &m.f.Run
	for _, ev := range run.Tick(now) {
		m.c.Log(ev)
		m.dirty = true
		if ev.Late {
			continue
		}
		out = append(out, Announce{
			Kind:  engine.IntervalsKind,
			Title: i18n.T("intervals.done"),
			Body:  i18n.T("intervals.done.body", run.Plan.Rounds, fmtDur(ev.Planned)),
			Ring:  true,
		})
	}
	if run.Run == engine.Running {
		pt := run.Point(now)
		if pt.Index != m.lastKey {
			if m.lastKey != -2 {
				m.flashAt = now
				m.beep(notify.SoundStart)
			}
			m.lastKey = pt.Index
			m.lastBeep = -1
			m.setMood(pt.Seg.Phase)
		}
		// the last three seconds tick
		if left := ceilSecs(pt.Left); left <= 3 && left >= 1 && pt.Seg.Len > 4*time.Second && left != m.lastBeep {
			m.lastBeep = left
			m.beep(notify.SoundStart)
		}
	} else {
		m.lastKey = -2
		m.setMood(engine.IntervalsReady)
	}
	if m.dirty && now.Sub(m.lastSave) > time.Second {
		m.save()
	}
	return out
}

// beep plays a cue (the app rings the terminal bell if there is no player).
func (m *intervalsMode) beep(name string) { m.c.Beep(name) }

func (m *intervalsMode) Runner() *Running {
	run := &m.f.Run
	if !run.Active() {
		return nil
	}
	pt := run.Point(m.c.Now)
	return &Running{
		Mode: "intervals", Icon: iconIntervals,
		Text: i18n.T("intervals.phase."+string(pt.Seg.Phase)) + " " + clockText(pt.Left),
		Rest: pt.Seg.Phase.IsRest(), Paused: run.Run == engine.Paused,
	}
}

func (m *intervalsMode) Title() string {
	run := &m.f.Run
	if !run.Active() {
		return ""
	}
	pt := run.Point(m.c.Now)
	s := fmt.Sprintf("%s %s", i18n.T("intervals.phase."+string(pt.Seg.Phase)), clockText(pt.Left))
	if pt.Seg.Round > 0 {
		s += fmt.Sprintf(" · %d/%d", pt.Seg.Round, pt.Rounds)
	}
	if run.Run == engine.Paused {
		s = "⏸ " + s
	}
	return s
}

// ---------------------------------------------------------------- mood

func (m *intervalsMode) phaseColor(ph engine.IntervalsPhase) braille.RGB {
	pal := m.c.Pal
	switch ph {
	case engine.IntervalsRest:
		return pal.Rest
	case engine.IntervalsWarm:
		return pal.Sun
	case engine.IntervalsCool:
		return pal.Moon.Mix(pal.Rest, 0.4)
	}
	return pal.Accent
}

func (m *intervalsMode) mood() braille.RGB {
	t := m.moodSp.Pos
	if t < 0 {
		t = 0
	}
	return m.moodFrom.Mix(m.moodTo, t)
}

func (m *intervalsMode) setMood(ph engine.IntervalsPhase) {
	if ph == m.moodPhase {
		// follow palette changes (accent picked in settings)
		if m.moodSp.Settled() {
			m.moodFrom, m.moodTo = m.phaseColor(ph), m.phaseColor(ph)
		}
		return
	}
	m.moodFrom = m.mood()
	m.moodTo = m.phaseColor(ph)
	m.moodPhase = ph
	m.moodSp.Snap(0)
	m.moodSp.Target = 1
}

func (m *intervalsMode) Frame(dt time.Duration) {
	m.t += dt.Seconds()
	if m.c.Cfg.Motion == "still" {
		m.moodSp.Snap(1)
		m.moodFrom = m.moodTo
		return
	}
	m.moodSp.Step(dt)
}

// flash is 1 right after a phase change and fades to 0 in under a second.
func (m *intervalsMode) flash() float64 {
	if m.flashAt.IsZero() || m.c.Cfg.Motion == "still" {
		return 0
	}
	f := 1 - m.c.Now.Sub(m.flashAt).Seconds()/0.95
	if f < 0 {
		return 0
	}
	return f
}

// ---------------------------------------------------------------- keys

func (m *intervalsMode) Help() []key.Binding {
	run := i18n.T("pomo.start")
	switch m.f.Run.Run {
	case engine.Running:
		run = i18n.T("pomo.pause")
	case engine.Paused:
		run = i18n.T("pomo.resume")
	}
	if m.f.Run.Active() {
		return []key.Binding{
			kb("space|enter", "space", run),
			kb("r", "r", i18n.T("pomo.reset")),
			kb("s", "s", i18n.T("pomo.skip")),
			kb("d", "d", i18n.T("pomo.dial")),
		}
	}
	return []key.Binding{
		kb("space|enter", "space", run),
		kb("p|P", "p", i18n.T("pomo.preset")),
		kb("left|right|h|l", "←→", i18n.T("intervals.field")),
		kb("up|down|k|j|+|-", "↑↓", i18n.T("intervals.value")),
		kb("d", "d", i18n.T("pomo.dial")),
	}
}

func (m *intervalsMode) persist() { m.dirty = true; m.save() }

func (m *intervalsMode) toggle() {
	run := &m.f.Run
	wasIdle := !run.Active()
	if wasIdle {
		run.Plan = m.plan()
		run.Plan.Normalize()
	}
	run.Toggle(m.c.Now)
	if wasIdle && run.Active() {
		m.flashAt = m.c.Now
		m.lastKey = -2
		m.beep(notify.SoundStart)
	}
	m.persist()
}

func (m *intervalsMode) adjust(f intervalsField, dir int, big bool) {
	if m.f.Run.Active() {
		m.say(i18n.T("intervals.busy"))
		return
	}
	p := m.plan()
	step := 5 * time.Second
	if big {
		step = 30 * time.Second
	}
	d := time.Duration(dir) * step
	switch f {
	case intervalsFWarm:
		p.Warm += d
	case intervalsFWork:
		p.Work += d
	case intervalsFRest:
		p.Rest += d
	case intervalsFCool:
		p.Cool += d
	case intervalsFRounds:
		n := dir
		if big {
			n *= 5
		}
		p.Rounds += n
	case intervalsFRamp:
		p.Ramp += time.Duration(dir) * 5 * time.Second
	}
	p.Normalize()
	if p == m.plan() {
		return
	}
	m.f.Custom, m.f.Preset = p, intervalsCustom
	m.f.Run.Plan = p
	m.persist()
}

func (m *intervalsMode) nextPreset(d int) {
	if m.f.Run.Active() {
		m.say(i18n.T("intervals.busy"))
		return
	}
	n := intervalsCustom + 1
	m.f.Preset = (m.f.Preset + d + n) % n
	m.f.Run.Plan = m.plan()
	m.persist()
	m.say(i18n.T("intervals.preset.set", m.presetName()))
}

func (m *intervalsMode) Update(msg tea.Msg) tea.Cmd {
	now := m.c.Now
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch msg.String() {
		case "space", "enter":
			m.toggle()
		case "r":
			m.c.Log(m.f.Run.Reset(now)...)
			m.f.Run.Plan = m.plan()
			m.persist()
		case "s":
			m.f.Run.Skip(now)
			m.persist()
		case "p":
			m.nextPreset(1)
		case "P":
			m.nextPreset(-1)
		case "d", "D":
			if m.f.Style == "ring" {
				m.f.Style = "hex"
			} else {
				m.f.Style = "ring"
			}
			m.persist()
			m.say("⟳ " + i18n.T("intervals.style."+m.f.Style))
		case "left", "h":
			m.focus = (m.focus + intervalsFields - 1) % intervalsFields
		case "right", "l", "tab":
			m.focus = (m.focus + 1) % intervalsFields
		case "up", "k", "+", "=":
			m.adjust(m.focus, 1, false)
		case "down", "j", "-", "_":
			m.adjust(m.focus, -1, false)
		case "K", "shift+up":
			m.adjust(m.focus, 1, true)
		case "J", "shift+down":
			m.adjust(m.focus, -1, true)
		}
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			break
		}
		for _, h := range m.hits {
			if msg.X >= h.x && msg.X < h.x+h.w && msg.Y >= h.y && msg.Y < h.y+h.h {
				if h.field < 0 {
					m.toggle()
				} else {
					m.focus = intervalsField(h.field)
				}
				break
			}
		}
	case tea.MouseWheelMsg:
		switch msg.Button {
		case tea.MouseWheelUp:
			m.adjust(m.focus, 1, false)
		case tea.MouseWheelDown:
			m.adjust(m.focus, -1, false)
		}
	}
	return nil
}

// ---------------------------------------------------------------- text helpers

func (m *intervalsMode) fieldLabel(f intervalsField) string {
	return i18n.T("intervals.f." + intervalsFieldKeys[f])
}

func (m *intervalsMode) fieldValue(f intervalsField) string {
	p := m.plan()
	if m.f.Run.Active() {
		p = m.f.Run.Plan
	}
	dur := func(d time.Duration) string {
		if d <= 0 {
			return i18n.T("intervals.off")
		}
		return fmtDur(d)
	}
	switch f {
	case intervalsFWarm:
		return dur(p.Warm)
	case intervalsFWork:
		return dur(p.Work)
	case intervalsFRest:
		return dur(p.Rest)
	case intervalsFCool:
		return dur(p.Cool)
	case intervalsFRounds:
		return fmt.Sprintf("×%d", p.Rounds)
	case intervalsFRamp:
		if p.Ramp <= 0 {
			return i18n.T("intervals.off")
		}
		return "+" + fmtDur(p.Ramp)
	}
	return ""
}

func (m *intervalsMode) summary() string {
	p := m.plan()
	if m.f.Run.Active() {
		p = m.f.Run.Plan
	}
	s := fmt.Sprintf("%s / %s × %d", fmtDur(p.Work), fmtDur(p.Rest), p.Rounds)
	if p.Rest <= 0 {
		s = fmt.Sprintf("%s × %d", fmtDur(p.Work), p.Rounds)
	}
	return s
}

var _ = strings.ToUpper
