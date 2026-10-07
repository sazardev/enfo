package ui

import (
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/visual"
)

func clockTestCore(t *testing.T, now time.Time) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	return NewCore(st, now)
}

func TestClockRendersEverySize(t *testing.T) {
	now := time.Date(2026, 10, 7, 21, 41, 17, 350_000_000, time.Local)
	c := clockTestCore(t, now)
	sizes := [][2]int{{1, 1}, {2, 1}, {4, 2}, {10, 3}, {24, 7}, {29, 12}, {30, 8}, {40, 12},
		{60, 14}, {79, 23}, {80, 24}, {99, 19}, {100, 20}, {101, 21}, {120, 30}, {160, 40}, {250, 70}, {33, 100}}
	for _, name := range visual.ClockFaceNames {
		for _, h24 := range []bool{true, false} {
			for _, secs := range []bool{true, false} {
				c.Cfg.ClockDesign, c.Cfg.Clock24, c.Cfg.ClockSeconds = name, h24, secs
				m := newClockMode(c, nil)
				for _, sz := range sizes {
					c.Step(now.Add(time.Second), 33*time.Millisecond)
					m.Frame(33 * time.Millisecond)
					out := m.View(sz[0], sz[1])
					lines := strings.Split(out, "\n")
					if len(lines) != sz[1] {
						t.Fatalf("%s %dx%d: %d lines", name, sz[0], sz[1], len(lines))
					}
					for i, l := range lines {
						if got := ansi.StringWidth(l); got != sz[0] {
							t.Fatalf("%s %dx%d line %d width %d", name, sz[0], sz[1], i, got)
						}
					}
				}
			}
		}
	}
}

func TestClockKeysPersist(t *testing.T) {
	now := time.Date(2026, 10, 7, 9, 5, 0, 0, time.Local)
	c := clockTestCore(t, now)
	m := newClockMode(c, func(string) {})
	m.cycle(1)
	if c.Cfg.ClockDesign != "digital" {
		t.Fatalf("design = %s", c.Cfg.ClockDesign)
	}
	m.cycle(-1)
	m.cycle(-1)
	if c.Cfg.ClockDesign != "sun" {
		t.Fatalf("wrap to last, got %s", c.Cfg.ClockDesign)
	}
	cfg, _ := c.Store.LoadConfig()
	if cfg.ClockDesign != "sun" {
		t.Fatal("design not saved")
	}
}

func TestClockStaticDesignsDoNotAnimate(t *testing.T) {
	now := time.Date(2026, 10, 7, 9, 5, 0, 0, time.Local)
	c := clockTestCore(t, now)
	c.Cfg.ClockDesign = "digital"
	m := newClockMode(c, nil)
	m.Frame(33 * time.Millisecond)
	if m.Animated() {
		t.Fatal("digital should only need per-second redraws")
	}
	c.Cfg.ClockDesign = "analog"
	m = newClockMode(c, nil)
	m.Frame(33 * time.Millisecond)
	if !m.Animated() {
		t.Fatal("analog with seconds sweeps")
	}
	c.Cfg.Motion = "still"
	if m.Animated() {
		t.Fatal("still motion must not animate")
	}
}
