package ui

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/store"
)

func statsTestCore(t *testing.T, withEvents bool) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 10, 7, 15, 30, 0, 0, time.Local)
	if withEvents {
		var evs []engine.Event
		for i := 0; i < 70; i++ {
			day := now.AddDate(0, 0, -i)
			n := (i*7)%5 + 1
			if i%6 == 5 {
				continue
			}
			for k := 0; k < n; k++ {
				s := time.Date(day.Year(), day.Month(), day.Day(), 9+k, 5, 0, 0, time.Local)
				evs = append(evs, engine.Event{Kind: engine.KindFocus, Start: s, Planned: 25 * time.Minute, Actual: 25 * time.Minute, Completed: k != 3})
				evs = append(evs, engine.Event{Kind: engine.KindRest, Start: s.Add(25 * time.Minute), Actual: 5 * time.Minute, Completed: true})
			}
			evs = append(evs, engine.Event{Kind: engine.KindTimer, Label: "tea", Start: day.Add(-time.Hour), Actual: 3 * time.Minute, Completed: true})
		}
		_ = st.AppendEvents(evs...)
	}
	return NewCore(st, now)
}

func statsCheck(t *testing.T, name string, out string, w, h int) {
	t.Helper()
	lines := splitLines(out)
	if len(lines) != h {
		t.Fatalf("%s %dx%d: %d lines", name, w, h, len(lines))
	}
	for i, l := range lines {
		if got := ansi.StringWidth(l); got != w {
			t.Fatalf("%s %dx%d: line %d width %d: %q", name, w, h, i, got, ansi.Strip(l))
		}
	}
}

func TestStatsRenderSizes(t *testing.T) {
	for _, withEv := range []bool{true, false} {
		c := statsTestCore(t, withEv)
		for _, motion := range []string{"full", "still"} {
			c.Cfg.Motion = motion
			p := newStatsPage(c, func(string) {})
			for _, sz := range [][2]int{{1, 1}, {5, 2}, {10, 4}, {24, 7}, {30, 9}, {40, 12}, {59, 20}, {80, 24}, {100, 30}, {104, 36}, {120, 40}, {160, 50}, {250, 70}, {97, 13}, {200, 20}} {
				for sec := 0; sec < statsSections; sec++ {
					p.sec = sec
					p.t = 5
					statsCheck(t, "stats", p.View(sz[0], sz[1]), sz[0], sz[1])
				}
			}
		}
	}
}

func TestStatsKeysAndMouse(t *testing.T) {
	c := statsTestCore(t, true)
	p := newStatsPage(c, func(string) {})
	p.t = 5
	p.View(120, 40)
	if !p.dash {
		t.Fatal("expected dashboard layout")
	}
	p.sel = 0
	p.Update(statsKeyPress("left"))
	if p.sel != 1 {
		t.Fatalf("sel %d", p.sel)
	}
	p.Update(statsKeyPress("r"))
	if p.rng != 90 {
		t.Fatalf("range %d", p.rng)
	}
	// click on a bar selects it
	p.View(120, 40)
	x := p.chart.r.x + (p.chart.left+3*p.chart.pitch+1)/2
	y := p.chart.r.y + 2
	p.click(x, y)
	if p.sel != p.chart.n-1-3 {
		t.Fatalf("click sel %d want %d", p.sel, p.chart.n-4)
	}
	// paged mode: tab cycles sections
	p.View(80, 24)
	p.Update(statsKeyPress("tab"))
	if p.sec != 1 {
		t.Fatalf("sec %d", p.sec)
	}
}

func TestStatsPreview(t *testing.T) {
	if os.Getenv("PREVIEW") == "" {
		t.Skip("PREVIEW=1 to print")
	}
	c := statsTestCore(t, os.Getenv("EMPTY") == "")
	c.Cfg.Motion = "still"
	p := newStatsPage(c, func(string) {})
	var w, h int
	fmt.Sscanf(os.Getenv("PREVIEW"), "%dx%d", &w, &h)
	if w == 0 {
		w, h = 130, 42
	}
	for sec := 0; sec < statsSections; sec++ {
		p.sec = sec
		fmt.Println(ansi.Strip(p.View(w, h)))
		if p.dash {
			break
		}
	}
}
