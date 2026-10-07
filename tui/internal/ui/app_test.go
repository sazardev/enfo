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

var appT0 = time.Date(2026, 10, 7, 9, 30, 0, 0, time.UTC)

type appClock struct{ t time.Time }

func (c *appClock) now() time.Time { return c.t }

func newTestApp(t *testing.T) (*App, *appClock) {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	t.Setenv("ENFO_QUIET", "1")
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	cfg, _ := st.LoadConfig()
	cfg.Onboarded = true
	_ = st.SaveConfig(cfg)
	clk := &appClock{t: appT0}
	a := New(st, Options{NoSplash: true, Now: clk.now})
	a.Update(tea.WindowSizeMsg{Width: 120, Height: 36})
	return a, clk
}

func (a *App) advance(clk *appClock, d time.Duration) {
	// tick in 33 ms frames like the real loop does
	for left := d; left > 0; left -= 33 * time.Millisecond {
		step := 33 * time.Millisecond
		if left < step {
			step = left
		}
		clk.t = clk.t.Add(step)
		a.Update(tickMsg(clk.t))
	}
}

func press(s string) tea.KeyPressMsg {
	switch s {
	case "space":
		return tea.KeyPressMsg{Code: tea.KeySpace, Text: " "}
	case "tab":
		return tea.KeyPressMsg{Code: tea.KeyTab}
	case "esc":
		return tea.KeyPressMsg{Code: tea.KeyEscape}
	case "enter":
		return tea.KeyPressMsg{Code: tea.KeyEnter}
	case "down":
		return tea.KeyPressMsg{Code: tea.KeyDown}
	case "up":
		return tea.KeyPressMsg{Code: tea.KeyUp}
	case "left":
		return tea.KeyPressMsg{Code: tea.KeyLeft}
	case "right":
		return tea.KeyPressMsg{Code: tea.KeyRight}
	}
	r := []rune(s)
	return tea.KeyPressMsg{Code: r[0], Text: s}
}

func plain(a *App) []string {
	return strings.Split(ansi.Strip(a.View().Content), "\n")
}

func TestViewIsExactlyTheWindowSize(t *testing.T) {
	a, _ := newTestApp(t)
	for _, sz := range [][2]int{{24, 7}, {30, 10}, {40, 12}, {60, 20}, {80, 24}, {100, 30}, {120, 36}, {200, 60}, {250, 70}, {33, 9}} {
		a.Update(tea.WindowSizeMsg{Width: sz[0], Height: sz[1]})
		lines := plain(a)
		if len(lines) != sz[1] {
			t.Fatalf("%v: %d lines", sz, len(lines))
		}
		for i, l := range lines {
			if w := ansi.StringWidth(l); w != sz[0] {
				t.Fatalf("%v: line %d is %d wide: %q", sz, i, w, l)
			}
		}
	}
}

func TestTooSmallShowsAMessage(t *testing.T) {
	a, _ := newTestApp(t)
	a.Update(tea.WindowSizeMsg{Width: 10, Height: 3})
	if !strings.Contains(strings.Join(plain(a), "\n"), "Too small") {
		t.Fatal("expected the too-small message")
	}
}

func TestPomodoroStartPauseAndPersistence(t *testing.T) {
	a, clk := newTestApp(t)
	a.Update(press("space"))
	if a.core.Pomo.Run != engine.Running {
		t.Fatal("space should start")
	}
	a.advance(clk, 90*time.Second)
	if got := clockText(a.core.Pomo.Remaining(clk.t)); got != "23:30" {
		t.Fatalf("remaining %s", got)
	}
	a.Update(press("space"))
	if a.core.Pomo.Run != engine.Paused {
		t.Fatal("space should pause")
	}
	a.Update(press("q")) // quits and saves
	st := a.core.Store.LoadState()
	if st.Pomodoro == nil || st.Pomodoro.Run != engine.Paused || st.Pomodoro.Left != 23*time.Minute+30*time.Second {
		t.Fatalf("state not saved: %+v", st.Pomodoro)
	}
}

func TestFinishingAFocusPhaseToastsAndLogs(t *testing.T) {
	a, clk := newTestApp(t)
	a.Update(press("space"))
	a.advance(clk, 25*time.Minute+time.Second)
	if a.core.Pomo.Phase != engine.Rest {
		t.Fatalf("phase %s", a.core.Pomo.Phase)
	}
	if len(a.toasts) == 0 {
		t.Fatal("a toast should announce the finished phase")
	}
	ev := a.core.Events()
	if len(ev) != 1 || ev[0].Kind != engine.KindFocus || !ev[0].Completed {
		t.Fatalf("history: %+v", ev)
	}
	if !strings.Contains(strings.Join(plain(a), "\n"), "Focus complete") {
		t.Fatal("toast text should be drawn")
	}
}

func TestTimerDoneRingsFullScreenAndDismisses(t *testing.T) {
	a, clk := newTestApp(t)
	a.core.Timer.Set(5*time.Second, "tea")
	a.core.Timer.Begin(clk.t)
	a.advance(clk, 6*time.Second)
	if a.ring == nil {
		t.Fatal("a finished timer should ring")
	}
	if !strings.Contains(strings.Join(plain(a), "\n"), "TIMER FINISHED") {
		t.Fatal("ringer should show the title")
	}
	a.Update(press("enter"))
	if a.ring != nil {
		t.Fatal("enter dismisses")
	}
}

func TestAlarmRingsAndSnoozes(t *testing.T) {
	a, clk := newTestApp(t)
	a.core.Alarms.Add(engine.Alarm{Hour: 9, Min: 31, Label: "stand up", Enabled: true}, clk.t)
	a.advance(clk, 70*time.Second)
	if a.ring == nil || a.ring.ann.Alarm == nil {
		t.Fatal("alarm should ring")
	}
	a.Update(press("z"))
	if a.ring != nil {
		t.Fatal("snooze closes the ringer")
	}
	if got := a.core.Alarms.List[0].SnoozeAt; got.IsZero() {
		t.Fatal("alarm should be snoozed")
	}
	a.advance(clk, 5*time.Minute+time.Second)
	if a.ring == nil {
		t.Fatal("should ring again after the snooze")
	}
}

func TestHelpOpensAndCloses(t *testing.T) {
	a, _ := newTestApp(t)
	a.Update(press("?"))
	if !a.showHelp {
		t.Fatal("? opens help")
	}
	txt := strings.Join(plain(a), "\n")
	if !strings.Contains(txt, "Everywhere") {
		t.Fatalf("help content missing:\n%s", txt)
	}
	a.Update(press("esc"))
	if a.showHelp {
		t.Fatal("esc closes help")
	}
}

func TestZenHidesChrome(t *testing.T) {
	a, _ := newTestApp(t)
	a.Update(press("f"))
	lines := plain(a)
	joined := strings.Join(lines, "\n")
	if strings.Contains(joined, "quit") || strings.Contains(joined, "enfo") {
		t.Fatal("zen should hide header and footer")
	}
	a.Update(press("esc"))
	if a.zen {
		t.Fatal("esc leaves zen")
	}
}

func TestCatchUpAfterBeingAway(t *testing.T) {
	a, clk := newTestApp(t)
	a.Update(press("space"))
	a.Update(press("q"))
	st := a.core.Store
	// reopen 40 minutes later
	clk2 := &appClock{t: clk.t.Add(40 * time.Minute)}
	b := New(st, Options{NoSplash: true, Now: clk2.now})
	b.Update(tea.WindowSizeMsg{Width: 100, Height: 30})
	b.advance(clk2, 50*time.Millisecond)
	if b.core.Pomo.Phase != engine.Rest || b.core.Pomo.Run != engine.Idle {
		t.Fatalf("a phase that ended while away: %s/%s", b.core.Pomo.Phase, b.core.Pomo.Run)
	}
	if len(b.toasts) == 0 || !strings.Contains(b.toasts[0].title, "Welcome back") {
		t.Fatal("a welcome-back summary is expected")
	}
	if b.ring != nil {
		t.Fatal("things that finished while away must not ring")
	}
}

func TestWelcomeWizardAppliesChoicesLiveAndFinishes(t *testing.T) {
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	t.Setenv("ENFO_QUIET", "1")
	st, _ := store.Open()
	clk := &appClock{t: appT0}
	a := New(st, Options{NoSplash: true, Now: clk.now})
	a.Update(tea.WindowSizeMsg{Width: 100, Height: 32})
	if a.page == nil || a.pageID != "welcome" {
		t.Fatal("a first run should open the welcome wizard")
	}
	// step 1: pick Español
	a.Update(press("down"))
	if a.core.Cfg.Lang != "es" {
		t.Fatalf("language should apply live, got %q", a.core.Cfg.Lang)
	}
	a.Update(press("enter"))
	// step 2: rhythm -> extended
	a.Update(press("down"))
	if a.core.Cfg.Work != 50 || a.core.Cfg.Rest != 10 {
		t.Fatalf("rhythm: %d/%d", a.core.Cfg.Work, a.core.Cfg.Rest)
	}
	a.Update(press("enter"))
	// step 3: accent
	before := a.core.Pal.Accent
	a.Update(press("right"))
	if a.core.Pal.Accent == before {
		t.Fatal("accent should re-tint live")
	}
	a.Update(press("enter"))
	a.Update(press("enter")) // dial
	a.Update(press("enter")) // tools -> finish
	if a.page != nil && !a.page.(Page).Done() {
		t.Fatal("wizard should be done")
	}
	a.advance(clk, 100*time.Millisecond)
	cfg, found := st.LoadConfig()
	if !found || !cfg.Onboarded || cfg.Lang != "es" || cfg.Work != 50 {
		t.Fatalf("config not saved: %+v", cfg)
	}
	if a.page != nil {
		t.Fatal("the page should close once done")
	}
}

func TestWelcomeRendersAtEverySize(t *testing.T) {
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, _ := store.Open()
	clk := &appClock{t: appT0}
	a := New(st, Options{NoSplash: true, Now: clk.now})
	for step := 0; step < welcomeSteps; step++ {
		for _, sz := range [][2]int{{24, 7}, {40, 12}, {60, 20}, {80, 24}, {160, 50}} {
			a.Update(tea.WindowSizeMsg{Width: sz[0], Height: sz[1]})
			lines := plain(a)
			if len(lines) != sz[1] {
				t.Fatalf("step %d %v: %d lines", step, sz, len(lines))
			}
			for _, l := range lines {
				if ansi.StringWidth(l) != sz[0] {
					t.Fatalf("step %d %v: bad width %d", step, sz, ansi.StringWidth(l))
				}
			}
		}
		a.Update(press("enter"))
	}
}

func BenchmarkViewWide(b *testing.B) {
	t := &testing.T{}
	_ = t
	b.ReportAllocs()
	tt := testing.TB(b)
	_ = tt
	dir := b.TempDir()
	b.Setenv("ENFO_CONFIG_DIR", dir)
	b.Setenv("ENFO_STATE_DIR", dir)
	st, _ := store.Open()
	clk := &appClock{t: appT0}
	a := New(st, Options{NoSplash: true, Now: clk.now})
	a.Update(tea.WindowSizeMsg{Width: 250, Height: 70})
	a.Update(press("space"))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		clk.t = clk.t.Add(33 * time.Millisecond)
		a.Update(tickMsg(clk.t))
		_ = a.View()
	}
}
