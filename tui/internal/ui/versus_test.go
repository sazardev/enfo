package ui

import (
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
)

func TestVersusFlowAndFlag(t *testing.T) {
	a, clk := kitchenTestApp(t)
	a.switchTo("versus")
	vm := a.ids["versus"].(*versusMode)
	if vm.g.State != engine.VersusSetup {
		t.Fatal("starts in setup")
	}
	a.Update(press("right")) // 5+0 -> 10+0
	if vm.g.Total != 10*time.Minute {
		t.Fatalf("preset: %v", vm.g.Total)
	}
	a.Update(press("e"))
	if !a.capturing() {
		t.Fatal("editing captures")
	}
	for i := 0; i < 20; i++ {
		a.Update(press("down")) // minutes down to the floor
	}
	a.Update(tea.KeyPressMsg{Code: tea.KeyRight})
	a.Update(press("up")) // +1s increment
	a.Update(press("enter"))
	if vm.g.Total != 1*time.Minute || vm.g.Inc != time.Second {
		t.Fatalf("custom: %v +%v", vm.g.Total, vm.g.Inc)
	}
	a.Update(press("s")) // player 2 first
	a.Update(press("space"))
	if vm.g.State != engine.VersusRunning || vm.g.Active != 1 {
		t.Fatalf("start: %+v", vm.g)
	}
	a.advance(clk, 5*time.Second)
	a.Update(press("space")) // switch turn
	if vm.g.Active != 0 || vm.g.Moves[1] != 1 {
		t.Fatal("space switches the turn")
	}
	if r := vm.Runner(); r == nil {
		t.Fatal("footer chip while running")
	}
	a.switchTo("pomodoro")
	a.advance(clk, 70*time.Second)
	if vm.g.State != engine.VersusFlag || vm.g.Flagged != 0 {
		t.Fatalf("flag: %+v", vm.g.State)
	}
	if a.ring == nil || !strings.Contains(a.ring.ann.Title, "Time") {
		t.Fatal("flag fall rings even from another tab")
	}
	a.Update(press("enter"))
	a.switchTo("versus")
	a.Update(press("space")) // game over -> reset
	if vm.g.State != engine.VersusSetup {
		t.Fatal("space after game over returns to setup")
	}
	// persisted setup comes back
	vm2 := newVersus(a.core, func(string) {})
	if vm2.g.Total != 1*time.Minute || vm2.set.First != 1 {
		t.Fatalf("setup not persisted: %+v", vm2.set)
	}
}

func TestVersusGamePersistsAndFlagsLate(t *testing.T) {
	a, clk := kitchenTestApp(t)
	a.switchTo("versus")
	vm := a.ids["versus"].(*versusMode)
	a.Update(press("space"))
	a.Update(press("q"))
	late := &appClock{t: clk.t.Add(3 * time.Hour)}
	b := New(a.core.Store, Options{NoSplash: true, Now: late.now})
	b.Update(tea.WindowSizeMsg{Width: 100, Height: 30})
	vm2 := b.ids["versus"].(*versusMode)
	if vm2.g.State != engine.VersusFlag {
		t.Fatalf("a game that ran out while away must be flagged: %v", vm2.g.State)
	}
	b.advance(late, 100*time.Millisecond)
	if b.ring != nil {
		t.Fatal("not rung when it happened while away")
	}
	_ = vm
}

func TestVersusRenderMatrix(t *testing.T) {
	a, clk := kitchenTestApp(t)
	a.switchTo("versus")
	vm := a.ids["versus"].(*versusMode)
	check := func(label string) {
		for _, sz := range [][2]int{{1, 1}, {5, 2}, {19, 6}, {24, 7}, {30, 10}, {50, 14}, {80, 24}, {120, 36}, {250, 70}, {250, 40}, {160, 30}, {61, 20}} {
			lines := strings.Split(vm.View(sz[0], sz[1]), "\n")
			if len(lines) != sz[1] {
				t.Fatalf("%s %v: %d lines", label, sz, len(lines))
			}
			for _, l := range lines {
				if ansi.StringWidth(l) != sz[0] {
					t.Fatalf("%s %v: width %d", label, sz, ansi.StringWidth(l))
				}
			}
		}
	}
	check("setup")
	vm.editing = true
	check("editing")
	vm.editing = false
	vm.g.Begin(0, clk.t)
	vm.now = clk.t.Add(7 * time.Second)
	check("running")
	vm.set.Flip = true
	check("running-flip")
	vm.g.Pause(vm.now)
	check("paused")
	vm.g.Resume(vm.now)
	vm.now = clk.t.Add(time.Hour)
	vm.g.Tick(vm.now)
	check("flag")
}
