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

func kitchenTestApp(t *testing.T) (*App, *appClock) {
	t.Helper()
	a, clk := newTestApp(t)
	cfg, _ := a.core.Store.LoadConfig()
	cfg.Modes = append(cfg.Modes, "kitchen", "versus")
	_ = a.core.Store.SaveConfig(cfg)
	b := New(a.core.Store, Options{NoSplash: true, Now: clk.now})
	b.Update(tea.WindowSizeMsg{Width: 120, Height: 36})
	return b, clk
}

func kitchenType(a *App, s string) {
	for _, r := range s {
		if r == ' ' {
			a.Update(press("space"))
			continue
		}
		a.Update(press(string(r)))
	}
}

func TestKitchenAddRunRingPersist(t *testing.T) {
	a, clk := kitchenTestApp(t)
	a.switchTo("kitchen")
	a.Update(press("n"))
	if !a.capturing() {
		t.Fatal("adding should capture keys")
	}
	kitchenType(a, "5s tea")
	a.Update(press("enter"))
	km := a.ids["kitchen"].(*kitchenMode)
	if len(km.k.List) != 1 || km.k.List[0].Label != "tea" || km.k.List[0].Total != 5*time.Second {
		t.Fatalf("timer not added: %+v", km.k.List)
	}
	// shows up in the footer chip while another mode is open
	a.switchTo("pomodoro")
	if r := km.Runner(); r == nil {
		t.Fatal("running timer should have a footer chip")
	}
	a.advance(clk, 6*time.Second)
	if a.ring == nil || !strings.Contains(a.ring.ann.Title, "tea") {
		t.Fatal("a finished kitchen timer should ring even from another tab")
	}
	a.Update(press("enter"))
	// persisted file reloads with the same timer, done
	km2 := newKitchen(a.core, func(string) {})
	if len(km2.k.List) != 1 || !km2.k.List[0].Done {
		t.Fatalf("not persisted: %+v", km2.k.List)
	}
	evs := a.core.Events()
	if len(evs) == 0 || evs[len(evs)-1].Kind != "kitchen" {
		t.Fatal("history should record it")
	}
}

func TestKitchenPresetsAndInvalid(t *testing.T) {
	a, _ := kitchenTestApp(t)
	a.switchTo("kitchen")
	km := a.ids["kitchen"].(*kitchenMode)
	a.Update(press("n"))
	kitchenType(a, "zzz")
	a.Update(press("enter"))
	if len(km.k.List) != 0 || !km.adding {
		t.Fatal("garbage must be rejected and the input kept")
	}
	for i := 0; i < 3; i++ {
		a.Update(press("backspace"))
	}
	a.Update(tea.KeyPressMsg{Code: tea.KeyBackspace})
	km.input.SetValue("")
	a.Update(press("right")) // first chip pick = 10m
	a.Update(press("enter"))
	if len(km.k.List) != 1 || km.k.List[0].Total != 10*time.Minute {
		t.Fatalf("preset add: %+v", km.k.List)
	}
}

func TestKitchenControls(t *testing.T) {
	a, clk := kitchenTestApp(t)
	a.switchTo("kitchen")
	km := a.ids["kitchen"].(*kitchenMode)
	km.k.Add("a", 10*time.Minute, clk.t)
	km.k.Add("b", 20*time.Minute, clk.t)
	km.sel = km.order()[0].ID
	a.Update(press("space")) // pause the selected (a)
	if km.k.List[0].Run != engine.Paused {
		t.Fatal("space pauses")
	}
	a.Update(press("+"))
	if km.k.List[0].Left != 11*time.Minute {
		t.Fatalf("+1 min: %v", km.k.List[0].Left)
	}
	a.Update(press("x"))
	if !a.capturing() {
		t.Fatal("delete confirm is inline and captures")
	}
	a.Update(press("n"))
	if len(km.k.List) != 2 {
		t.Fatal("anything but y cancels")
	}
	a.Update(press("x"))
	a.Update(press("y"))
	if len(km.k.List) != 1 {
		t.Fatal("y deletes")
	}
}

func TestKitchenRenderMatrix(t *testing.T) {
	a, clk := kitchenTestApp(t)
	a.switchTo("kitchen")
	km := a.ids["kitchen"].(*kitchenMode)
	for _, n := range []int{0, 1, 2, 5, 12} {
		km.k = engine.Kitchen{}
		for i := 0; i < n; i++ {
			km.k.Add("timer number "+strings.Repeat("x", i), time.Duration(i+1)*7*time.Minute, clk.t)
		}
		if n > 3 {
			km.k.Toggle(km.k.List[1].ID, clk.t)
			km.k.Tick(clk.t.Add(3 * time.Hour))
		}
		for _, adding := range []bool{false, true} {
			km.adding = adding
			for _, sz := range [][2]int{{1, 1}, {4, 2}, {10, 3}, {24, 7}, {30, 10}, {50, 14}, {80, 24}, {120, 36}, {250, 70}, {67, 9}, {111, 40}} {
				lines := strings.Split(km.View(sz[0], sz[1]), "\n")
				if len(lines) != sz[1] {
					t.Fatalf("n=%d %v: %d lines", n, sz, len(lines))
				}
				for _, l := range lines {
					if ansi.StringWidth(l) != sz[0] {
						t.Fatalf("n=%d %v adding=%v: width %d", n, sz, adding, ansi.StringWidth(l))
					}
				}
			}
		}
	}
	_ = store.Config{}
}
