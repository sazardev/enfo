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

var intervalsT0 = time.Date(2026, 10, 7, 9, 30, 0, 0, time.UTC)

func intervalsNew(t *testing.T) (*intervalsMode, *Core) {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	t.Setenv("ENFO_QUIET", "1")
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	c := NewCore(st, intervalsT0)
	c.Cfg.Motion = "full"
	return newIntervals(c, func(string) {}), c
}

func intervalsKey(s string) tea.KeyPressMsg {
	switch s {
	case "space":
		return tea.KeyPressMsg{Code: tea.KeySpace, Text: " "}
	case "right":
		return tea.KeyPressMsg{Code: tea.KeyRight}
	case "left":
		return tea.KeyPressMsg{Code: tea.KeyLeft}
	case "up":
		return tea.KeyPressMsg{Code: tea.KeyUp}
	case "down":
		return tea.KeyPressMsg{Code: tea.KeyDown}
	}
	r := []rune(s)
	return tea.KeyPressMsg{Code: r[0], Text: s}
}

func intervalsAdvance(m *intervalsMode, c *Core, d time.Duration) []Announce {
	var all []Announce
	for left := d; left > 0; left -= 100 * time.Millisecond {
		c.Now = c.Now.Add(100 * time.Millisecond)
		all = append(all, m.Step(c.Now, 100*time.Millisecond)...)
		m.Frame(100 * time.Millisecond)
	}
	return all
}

func TestIntervalsRenderMatrix(t *testing.T) {
	m, c := intervalsNew(t)
	check := func(label string) {
		for _, sz := range [][2]int{{1, 1}, {5, 2}, {12, 3}, {24, 7}, {30, 10}, {39, 12}, {40, 11}, {60, 20}, {80, 24}, {99, 23}, {100, 24}, {120, 36}, {200, 60}, {250, 70}, {33, 9}, {101, 25}} {
			out := m.View(sz[0], sz[1])
			lines := strings.Split(out, "\n")
			if len(lines) != sz[1] {
				t.Fatalf("%s %v: %d lines", label, sz, len(lines))
			}
			for i, l := range lines {
				if wd := ansi.StringWidth(l); wd != sz[0] {
					t.Fatalf("%s %v: line %d is %d wide", label, sz, i, wd)
				}
			}
		}
	}
	check("idle")
	for _, style := range []string{"ring", "hex"} {
		m.f.Style = style
		for p := 0; p <= intervalsCustom; p++ {
			m.f.Preset = p
			m.f.Run = engine.IntervalsRun{Plan: m.plan()}
			m.Update(intervalsKey("space"))
			check(style + " running")
			intervalsAdvance(m, c, 25*time.Second)
			check(style + " later")
			m.Update(intervalsKey("space"))
			check(style + " paused")
			m.Update(intervalsKey("r"))
		}
	}
	c.Cfg.Motion = "still"
	check("still")
}

func TestIntervalsRunsAndRingsAtTheEnd(t *testing.T) {
	m, c := intervalsNew(t)
	m.Update(intervalsKey("space")) // tabata
	if !m.f.Run.Active() {
		t.Fatal("space should start")
	}
	if r := m.Runner(); r == nil || !strings.Contains(r.Text, "00:20") {
		t.Fatalf("runner: %+v", r)
	}
	if got := m.Title(); !strings.Contains(got, "1/8") {
		t.Fatalf("title %q", got)
	}
	anns := intervalsAdvance(m, c, 8*20*time.Second+7*10*time.Second+time.Second)
	if len(anns) != 1 || !anns[0].Ring || anns[0].Kind != engine.IntervalsKind {
		t.Fatalf("announcements: %+v", anns)
	}
	if m.f.Run.Active() {
		t.Fatal("finished workout goes idle")
	}
	ev := c.Events()
	if len(ev) != 1 || !ev[0].Completed || ev[0].Kind != engine.IntervalsKind {
		t.Fatalf("history: %+v", ev)
	}
}

func TestIntervalsEditingSwitchesToCustomAndPersists(t *testing.T) {
	m, c := intervalsNew(t)
	m.Update(intervalsKey("right")) // work
	m.Update(intervalsKey("up"))    // +5s
	if m.f.Preset != intervalsCustom || m.f.Custom.Work != 25*time.Second {
		t.Fatalf("preset %d work %v", m.f.Preset, m.f.Custom.Work)
	}
	// rounds field
	m.Update(intervalsKey("right"))
	m.Update(intervalsKey("right"))
	m.Update(intervalsKey("up"))
	if m.f.Custom.Rounds != 9 {
		t.Fatalf("rounds %d", m.f.Custom.Rounds)
	}
	m2 := newIntervals(c, func(string) {})
	if m2.f.Preset != intervalsCustom || m2.f.Custom.Work != 25*time.Second {
		t.Fatalf("not persisted: %+v", m2.f)
	}
	// cannot edit while running
	m.Update(intervalsKey("space"))
	m.Update(intervalsKey("up"))
	if m.f.Custom.Rounds != 9 {
		t.Fatal("editing while running must be refused")
	}
}

func TestIntervalsRestoresARunningWorkoutAfterRestart(t *testing.T) {
	m, c := intervalsNew(t)
	m.Update(intervalsKey("space"))
	intervalsAdvance(m, c, 25*time.Second) // into the first rest
	m2 := newIntervals(c, func(string) {})
	pt := m2.f.Run.Point(c.Now)
	if !m2.f.Run.Active() || pt.Seg.Phase != engine.IntervalsRest {
		t.Fatalf("restored: %+v %+v", m2.f.Run.Run, pt.Seg)
	}
	// away for an hour: logged, not rung
	c.Now = c.Now.Add(time.Hour)
	m3 := newIntervals(c, func(string) {})
	if m3.f.Run.Active() {
		t.Fatal("a workout that ended while away must be closed")
	}
	if ev := c.Events(); len(ev) != 1 || !ev[0].Late {
		t.Fatalf("history: %+v", ev)
	}
	if anns := m3.Step(c.Now, time.Second); len(anns) != 0 {
		t.Fatal("nothing should ring for a workout that finished while away")
	}
}

func TestIntervalsPresetCycle(t *testing.T) {
	m, _ := intervalsNew(t)
	for i := 0; i < 5; i++ {
		m.Update(intervalsKey("p"))
	}
	if m.f.Preset != 0 {
		t.Fatalf("5 presses should wrap, got %d", m.f.Preset)
	}
	m.Update(intervalsKey("P"))
	if m.f.Preset != intervalsCustom {
		t.Fatalf("shift-p goes back, got %d", m.f.Preset)
	}
}

func TestIntervalsWordFont(t *testing.T) {
	for _, w := range []string{"WARM UP", "WORK", "REST", "COOL DOWN", "CALENTAR", "TRABAJO", "DESCANSO", "ENFRIAR", "Pirámide"} {
		if p := intervalsWordSize(w, 400, 40); p < 1 {
			t.Fatalf("%q does not fit 400x40", w)
		}
	}
}
