package ui

import (
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/visual"
)

var breatheT0 = time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)

func breatheCore(t *testing.T) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	return NewCore(st, breatheT0)
}

func breatheStep(c *Core, m *breatheMode, d time.Duration) {
	c.Now = c.Now.Add(d)
	c.Dt = 33 * time.Millisecond
	c.Anim += c.Dt.Seconds()
	m.Frame(c.Dt)
}

func TestBreatheRenderSizes(t *testing.T) {
	for _, motion := range []string{"full", "still"} {
		c := breatheCore(t)
		c.Cfg.Motion = motion
		m := newBreathe(c, func(string) {})
		for _, name := range visual.BreatheVisualNames() {
			m.setVisual(name)
			for _, run := range []bool{false, true} {
				m.running = run
				m.sessStart, m.cycleStart = c.Now, c.Now
				for _, sz := range [][2]int{{1, 1}, {2, 3}, {10, 4}, {15, 5}, {24, 7}, {30, 9}, {40, 12}, {80, 24}, {81, 25}, {120, 40}, {250, 70}} {
					for _, zen := range []bool{false, true} {
						c.H = 0
						if zen {
							c.H = sz[1]
						}
						breatheStep(c, m, 700*time.Millisecond)
						out := m.View(sz[0], sz[1])
						lines := strings.Split(out, "\n")
						if len(lines) != sz[1] {
							t.Fatalf("%s %v zen=%v: %d lines, want %d", name, sz, zen, len(lines), sz[1])
						}
						for i, l := range lines {
							if got := ansi.StringWidth(l); got != sz[0] {
								t.Fatalf("%s %v zen=%v line %d: width %d, want %d", name, sz, zen, i, got, sz[0])
							}
						}
					}
				}
			}
		}
	}
}

func TestBreatheSessionLogsAndFinishes(t *testing.T) {
	c := breatheCore(t)
	m := newBreathe(c, func(string) {})
	m.goal = 1 // 1 minute
	m.Update(tea.KeyPressMsg{Code: ' ', Text: " "})
	if !m.running {
		t.Fatal("space should start")
	}
	breatheStep(c, m, 20*time.Second)
	if !m.running {
		t.Fatal("still running before the goal")
	}
	breatheStep(c, m, 41*time.Second)
	if m.running {
		t.Fatal("goal reached: session should end")
	}
	var logged int
	for _, e := range c.Events() {
		if e.Kind == engine.KindBreathe && e.Actual >= 60*time.Second {
			logged++
		}
	}
	if logged != 1 {
		t.Fatalf("want 1 logged breathe event, got %d", logged)
	}
	ann := c.Announcements()
	if len(ann) != 1 || ann[0].Kind != engine.KindBreathe {
		t.Fatalf("announcements: %+v", ann)
	}
}

func TestBreatheShortSessionNotLogged(t *testing.T) {
	c := breatheCore(t)
	m := newBreathe(c, func(string) {})
	m.start()
	breatheStep(c, m, 10*time.Second)
	m.stop()
	for _, e := range c.Events() {
		if e.Kind == engine.KindBreathe {
			t.Fatal("a 10 s session must not be logged")
		}
	}
}

func TestBreathePatternCycleAndTitle(t *testing.T) {
	c := breatheCore(t)
	m := newBreathe(c, func(string) {})
	first := c.Cfg.Breathe
	m.Update(tea.KeyPressMsg{Code: 'p', Text: "p"})
	if c.Cfg.Breathe == first {
		t.Fatal("p should change the pattern")
	}
	m.Update(tea.KeyPressMsg{Code: 'P', Text: "P"})
	if c.Cfg.Breathe != first {
		t.Fatal("P should go back")
	}
	if m.Title() != "" {
		t.Fatal("no title when idle")
	}
	m.start()
	breatheStep(c, m, 1500*time.Millisecond)
	if got := m.Title(); !strings.HasPrefix(got, "❋ ") {
		t.Fatalf("title: %q", got)
	}
}

func TestBreatheI18nBothLanguages(t *testing.T) {
	for k := range i18n.Table("en") {
		if strings.HasPrefix(k, "breathe.") || k == "help.mode.breathe" {
			if !i18n.Has("es", k) {
				t.Errorf("missing es key %s", k)
			}
		}
	}
}
