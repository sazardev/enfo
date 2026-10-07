package ui

import (
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/store"
)

var timerTestNow = time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)

func timerTestCore(t *testing.T) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	t.Setenv("ENFO_QUIET", "1")
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	return NewCore(st, timerTestNow)
}

func timerTestKey(m Mode, s string) {
	var msg tea.KeyPressMsg
	switch s {
	case "space":
		msg = tea.KeyPressMsg{Code: tea.KeySpace, Text: " "}
	case "up":
		msg = tea.KeyPressMsg{Code: tea.KeyUp}
	case "down":
		msg = tea.KeyPressMsg{Code: tea.KeyDown}
	case "left":
		msg = tea.KeyPressMsg{Code: tea.KeyLeft}
	case "right":
		msg = tea.KeyPressMsg{Code: tea.KeyRight}
	case "enter":
		msg = tea.KeyPressMsg{Code: tea.KeyEnter}
	case "esc":
		msg = tea.KeyPressMsg{Code: tea.KeyEscape}
	default:
		r := []rune(s)
		msg = tea.KeyPressMsg{Code: r[0], Text: s}
	}
	m.Update(msg)
}

func timerTestCheck(t *testing.T, name string, m Mode, w, h int) {
	t.Helper()
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("%s %dx%d panicked: %v", name, w, h, r)
		}
	}()
	lines := strings.Split(m.View(w, h), "\n")
	if len(lines) != h {
		t.Fatalf("%s %dx%d: %d lines", name, w, h, len(lines))
	}
	for i, l := range lines {
		if got := ansi.StringWidth(l); got != w {
			t.Fatalf("%s %dx%d: line %d is %d wide: %q", name, w, h, i, got, ansi.Strip(l))
		}
	}
}

var timerTestSizes = [][2]int{{1, 1}, {5, 3}, {12, 3}, {24, 7}, {30, 9}, {40, 12}, {60, 16}, {80, 24}, {83, 20},
	{84, 12}, {99, 30}, {100, 20}, {120, 40}, {160, 50}, {250, 70}, {37, 61}, {101, 19}}

func TestTimerRenderAllSizes(t *testing.T) {
	c := timerTestCore(t)
	m := newTimerMode(c, func(string) {})
	step := func() {
		c.Step(c.Now.Add(33*time.Millisecond), 33*time.Millisecond)
		m.Frame(33 * time.Millisecond)
	}
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "timer idle", m, sz[0], sz[1])
		step()
	}
	timerTestKey(m, "space")
	for _, d := range []string{"ring", "orbit", "hourglass", "liquid", "radar", "spiral", "bars"} {
		m.setDial(d)
		for _, sz := range timerTestSizes {
			timerTestCheck(t, "timer running "+d, m, sz[0], sz[1])
			step()
		}
	}
	timerTestKey(m, "space") // pause
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "timer paused", m, sz[0], sz[1])
	}
	// urgency window
	c.Timer.Begin(c.Now)
	c.Now = c.Timer.EndsAt.Add(-4 * time.Second)
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "timer urgent", m, sz[0], sz[1])
	}
}

func TestTimerPicker(t *testing.T) {
	c := timerTestCore(t)
	m := newTimerMode(c, func(string) {})
	c.Timer.Set(0, "")
	m.field = 2
	timerTestKey(m, "up")
	timerTestKey(m, "up")
	if c.Timer.Total != 2*time.Second {
		t.Fatalf("seconds: %v", c.Timer.Total)
	}
	timerTestKey(m, "left")
	timerTestKey(m, "up")
	if c.Timer.Total != 62*time.Second {
		t.Fatalf("minute: %v", c.Timer.Total)
	}
	timerTestKey(m, "K")
	if c.Timer.Total != 6*time.Minute+2*time.Second {
		t.Fatalf("big step: %v", c.Timer.Total)
	}
	timerTestKey(m, "left")
	timerTestKey(m, "down") // below zero clamps
	if c.Timer.Total != 0 {
		t.Fatalf("clamp at zero: %v", c.Timer.Total)
	}
	for i := 0; i < 100; i++ {
		timerTestKey(m, "K")
	}
	if timerSecs(c.Timer) > timerMaxSecs {
		t.Fatal("over the maximum")
	}
	// zero never starts
	c.Timer.Set(0, "")
	timerTestKey(m, "space")
	if c.Timer.Run != engine.Idle {
		t.Fatal("a zero timer must not start")
	}
}

func TestTimerPresets(t *testing.T) {
	c := timerTestCore(t)
	var said []string
	m := newTimerMode(c, func(s string) { said = append(said, s) })
	n := len(c.Cfg.Presets)
	c.Timer.Set(13*time.Second, "")
	timerTestKey(m, "p")
	if timerSecs(c.Timer) != c.Cfg.Presets[0] {
		t.Fatalf("first preset: %d", timerSecs(c.Timer))
	}
	timerTestKey(m, "P")
	if timerSecs(c.Timer) != c.Cfg.Presets[n-1] {
		t.Fatalf("previous wraps: %d", timerSecs(c.Timer))
	}
	// add a new one
	c.Timer.Set(7*time.Minute, "")
	timerTestKey(m, "a")
	if len(c.Cfg.Presets) != n+1 || m.presetIndex() < 0 {
		t.Fatalf("save: %v", c.Cfg.Presets)
	}
	timerTestKey(m, "a")
	if len(c.Cfg.Presets) != n+1 {
		t.Fatal("duplicates are not saved")
	}
	// the list is sorted and persists
	cfg, _ := c.Store.LoadConfig()
	if len(cfg.Presets) != n+1 {
		t.Fatal("presets not persisted")
	}
	timerTestKey(m, "x")
	if len(c.Cfg.Presets) != n {
		t.Fatalf("remove: %v", c.Cfg.Presets)
	}
	c.Timer.Set(13*time.Second, "")
	timerTestKey(m, "x") // not a preset
	if len(c.Cfg.Presets) != n {
		t.Fatal("must not remove when none selected")
	}
	if timerPresetLabel(90) != "1m30s" || timerPresetLabel(3600) != "1h" || timerPresetLabel(300) != "5m" || timerPresetLabel(45) != "45s" {
		t.Fatal("labels")
	}
}

func TestTimerLabelEditingCaptures(t *testing.T) {
	c := timerTestCore(t)
	m := newTimerMode(c, func(string) {})
	timerTestKey(m, "e")
	if !m.Capturing() {
		t.Fatal("editing must capture keys")
	}
	for _, r := range "tea" {
		timerTestKey(m, string(r))
	}
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "timer editing", m, sz[0], sz[1])
	}
	timerTestKey(m, "enter")
	if m.Capturing() || c.Timer.Label != "tea" {
		t.Fatalf("label %q capturing %v", c.Timer.Label, m.Capturing())
	}
	timerTestKey(m, "e")
	timerTestKey(m, "x")
	timerTestKey(m, "esc")
	if c.Timer.Label != "tea" {
		t.Fatal("esc must cancel")
	}
}

func TestTimerRunAddReset(t *testing.T) {
	c := timerTestCore(t)
	m := newTimerMode(c, func(string) {})
	c.Timer.Set(2*time.Minute, "")
	timerTestKey(m, "space")
	if c.Timer.Run != engine.Running {
		t.Fatal("should run")
	}
	timerTestKey(m, "+")
	if c.Timer.Total != 3*time.Minute {
		t.Fatalf("+1 min: %v", c.Timer.Total)
	}
	c.Now = c.Now.Add(30 * time.Second)
	timerTestKey(m, "r")
	if c.Timer.Run != engine.Idle {
		t.Fatal("reset")
	}
	var logged int
	for _, e := range c.Events() {
		if e.Kind == engine.KindTimer {
			logged++
		}
	}
	if logged != 1 {
		t.Fatalf("abandoned run should be logged once, got %d", logged)
	}
}

func TestStopwatchRenderAndLaps(t *testing.T) {
	c := timerTestCore(t)
	m := newStopwatchMode(c, func(string) {})
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "stopwatch idle", m, sz[0], sz[1])
	}
	timerTestKey(m, "space")
	for i := 0; i < 40; i++ {
		c.Now = c.Now.Add(time.Duration(5+i%7) * time.Second)
		timerTestKey(m, "l")
		if i%9 == 0 {
			for _, sz := range timerTestSizes {
				timerTestCheck(t, "stopwatch laps", m, sz[0], sz[1])
			}
		}
	}
	if len(c.SW.Laps) != 40 {
		t.Fatalf("laps: %d", len(c.SW.Laps))
	}
	m.View(100, 30)
	for i := 0; i < 100; i++ {
		timerTestKey(m, "down")
	}
	if m.scroll > len(c.SW.Laps)-1 {
		t.Fatal("scroll out of range")
	}
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "stopwatch scrolled", m, sz[0], sz[1])
	}
	timerTestKey(m, "space") // pause
	for _, sz := range timerTestSizes {
		timerTestCheck(t, "stopwatch paused", m, sz[0], sz[1])
	}
	timerTestKey(m, "r")
	if c.SW.Active() || len(c.SW.Laps) != 0 {
		t.Fatal("reset clears")
	}
	var logged bool
	for _, e := range c.Events() {
		if e.Kind == engine.KindStopwatch {
			logged = true
		}
	}
	if !logged {
		t.Fatal("run should be logged on reset")
	}
}

func TestTimerStopwatchTitlesAndMotion(t *testing.T) {
	c := timerTestCore(t)
	tm := newTimerMode(c, func(string) {})
	sm := newStopwatchMode(c, func(string) {})
	if tm.Title() != "" || sm.Title() != "" {
		t.Fatal("no title while idle")
	}
	timerTestKey(tm, "space")
	timerTestKey(sm, "space")
	if !strings.HasPrefix(tm.Title(), iconTimer+" ") || !strings.HasPrefix(sm.Title(), iconStopwatch+" ") {
		t.Fatalf("titles: %q %q", tm.Title(), sm.Title())
	}
	c.Cfg.Motion = "still"
	if tm.Animated() || sm.Animated() {
		t.Fatal("still motion must not animate")
	}
	c.Cfg.Motion = "full"
	if !tm.Animated() || !sm.Animated() {
		t.Fatal("running modes animate")
	}
}
