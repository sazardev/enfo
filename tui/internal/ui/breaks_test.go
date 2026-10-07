package ui

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/store"
)

func breaksTestCore(t *testing.T) (*Core, *appClock) {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	t.Setenv("ENFO_QUIET", "1")
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	clk := &appClock{t: appT0}
	return NewCore(st, clk.now()), clk
}

func breaksCheckSizes(t *testing.T, name string, view func(w, h int) string) {
	t.Helper()
	sizes := [][2]int{{1, 1}, {2, 2}, {8, 3}, {20, 5}, {24, 5}, {30, 8}, {40, 12}, {60, 20}, {80, 24}, {99, 30}, {100, 16}, {121, 37}, {200, 60}, {250, 70}, {33, 9}}
	for _, sz := range sizes {
		lines := strings.Split(view(sz[0], sz[1]), "\n")
		if len(lines) != sz[1] {
			t.Fatalf("%s %v: %d lines", name, sz, len(lines))
		}
		for i, l := range lines {
			if w := ansi.StringWidth(l); w != sz[0] {
				t.Fatalf("%s %v: line %d width %d: %q", name, sz, i, w, ansi.Strip(l))
			}
		}
	}
}

func TestBreaksEngineSchedule(t *testing.T) {
	now := appT0
	b := engine.BreaksDefaults(now)
	if d := b.Tick(now.Add(19 * time.Minute)); len(d) != 0 {
		t.Fatal("eyes not due before 20 min")
	}
	d := b.Tick(now.Add(20*time.Minute + time.Second))
	if len(d) != 1 || d[0].R.ID != "eyes" {
		t.Fatalf("due: %+v", d)
	}
	if d := b.Tick(now.Add(25 * time.Minute)); len(d) != 0 {
		t.Fatal("a pending reminder is announced once")
	}
	at := now.Add(26 * time.Minute)
	b.Complete("eyes", at)
	e := b.Get("eyes")
	if e.Pending || e.Done != 1 || !e.NextAt.Equal(at.Add(20*time.Minute)) {
		t.Fatalf("after complete: %+v", e)
	}
	if done, _ := b.DoneToday(at); done != 1 || b.Streak(at) != 1 {
		t.Fatal("counters")
	}
	b.Snooze("stretch", at)
	if !b.Get("stretch").NextAt.Equal(at.Add(engine.BreaksSnooze)) {
		t.Fatal("snooze")
	}
	b.Skip("water", at)
	if _, sk := b.DoneToday(at); sk != 1 {
		t.Fatal("skip counter")
	}
}

func TestBreaksPauseShiftsSchedule(t *testing.T) {
	now := appT0
	b := engine.BreaksDefaults(now)
	b.SetPaused(true, now.Add(5*time.Minute))
	if d := b.Tick(now.Add(time.Hour)); len(d) != 0 {
		t.Fatal("paused reminders do not fire")
	}
	b.SetPaused(false, now.Add(35*time.Minute)) // 30 min paused
	if got := b.Get("eyes").NextAt; !got.Equal(now.Add(50 * time.Minute)) {
		t.Fatalf("eyes next %v", got)
	}
}

func TestBreaksCatchUpDoesNotRing(t *testing.T) {
	now := appT0
	b := engine.BreaksDefaults(now)
	later := now.Add(5 * time.Hour)
	b.CatchUp(later)
	if d := b.Tick(later); len(d) != 0 {
		t.Fatal("what came due while away must not ring")
	}
	if !b.Get("eyes").NextAt.Equal(later.Add(20 * time.Minute)) {
		t.Fatal("rescheduled from now")
	}
}

func TestBreaksStreakAndAddDelete(t *testing.T) {
	now := appT0
	b := engine.BreaksDefaults(now)
	for i := 0; i < 3; i++ {
		b.Complete("eyes", now.AddDate(0, 0, -i))
	}
	if b.Streak(now) != 3 {
		t.Fatalf("streak %d", b.Streak(now))
	}
	r := b.Add("Call mum", 3, now)
	if r.Min != 5 {
		t.Fatal("interval is clamped to 5")
	}
	b.Delete("eyes")
	if b.Get("eyes") == nil {
		t.Fatal("built-in reminders cannot be deleted")
	}
	b.Delete(r.ID)
	if b.Get(r.ID) != nil {
		t.Fatal("custom reminder should be deleted")
	}
}

func TestBreaksModeAnnouncesRunsInBackgroundAndPersists(t *testing.T) {
	c, clk := breaksTestCore(t)
	m := newBreaks(c, func(string) {})
	var got []Announce
	for i := 0; i < 20*60+5; i++ { // one tick per second
		clk.t = clk.t.Add(time.Second)
		c.Step(clk.t, time.Second)
		got = append(got, m.Step(clk.t, time.Second)...)
	}
	if len(got) != 1 || got[0].Kind != engine.KindBreaks || !got[0].Ring || got[0].Title == "" {
		t.Fatalf("announcements: %+v", got)
	}
	if r := m.Runner(); r == nil || r.Icon != iconBreaks || r.Text != "now" {
		t.Fatalf("runner: %+v", r)
	}
	// do it: enter opens the guide, enter finishes it early
	m.Update(tea.KeyPressMsg{Code: tea.KeyEnter})
	if m.guide == nil || !m.Capturing() {
		t.Fatal("enter should open the guide")
	}
	clk.t = clk.t.Add(7 * time.Second)
	c.Step(clk.t, time.Second)
	m.Update(tea.KeyPressMsg{Code: tea.KeyEnter})
	if m.b.Get("eyes").Done != 1 {
		t.Fatal("finishing the guide counts the break")
	}
	if ev := c.Events(); len(ev) != 1 || ev[0].Kind != engine.KindBreaks || !ev[0].Completed {
		t.Fatalf("history: %+v", ev)
	}
	clk.t = clk.t.Add(3 * time.Second)
	m.Step(clk.t, time.Second) // writes the file, closes the guide
	if m.guide != nil {
		t.Fatal("the guide closes itself after the cheer")
	}
	if _, err := os.Stat(filepath.Join(c.Store.StateDir, "breaks.json")); err != nil {
		t.Fatal("breaks.json should be written")
	}
	m2 := newBreaks(c, func(string) {})
	if m2.b.Get("eyes").Done != 1 {
		t.Fatal("state should be restored")
	}
}

func TestBreaksEditorAddsCustomReminder(t *testing.T) {
	c, _ := breaksTestCore(t)
	m := newBreaks(c, func(string) {})
	m.Update(press("a"))
	if m.edit == nil || !m.Capturing() {
		t.Fatal("a opens the editor and captures keys")
	}
	for _, r := range "Walk" {
		m.Update(press(string(r)))
	}
	m.Update(press("tab"))
	for i := 0; i < 2; i++ {
		m.Update(tea.KeyPressMsg{Code: tea.KeyBackspace})
	}
	m.Update(press("x")) // not a digit: ignored
	m.Update(press("4"))
	m.Update(press("5"))
	m.Update(press("enter"))
	if m.edit != nil {
		t.Fatalf("editor should close, err=%q", m.edit.err)
	}
	last := m.b.List[len(m.b.List)-1]
	if !last.Custom || last.Label != "Walk" || last.Min != 45 {
		t.Fatalf("custom reminder: %+v", last)
	}
	// delete with inline confirmation
	m.sel = len(m.b.List) - 1
	m.Update(press("x"))
	if !m.confirmDel {
		t.Fatal("x asks for confirmation")
	}
	m.Update(press("y"))
	if len(m.b.List) != 4 {
		t.Fatal("custom reminder should be gone")
	}
}

func TestBreaksRendersAtEverySize(t *testing.T) {
	c, clk := breaksTestCore(t)
	m := newBreaks(c, func(string) {})
	m.b.Add("A really long custom reminder name that must be cut", 15, clk.t)
	breaksCheckSizes(t, "list", m.View)
	m.listKey(press("s"), clk.t)
	m.b.SetPaused(true, clk.t)
	breaksCheckSizes(t, "paused", m.View)
	m.b.SetPaused(false, clk.t)
	for _, id := range []string{"eyes", "stretch", "water", "posture", m.b.List[len(m.b.List)-1].ID} {
		m.startGuide(m.b.Get(id), clk.t)
		c.Anim = 3.3
		breaksCheckSizes(t, "guide "+id, m.View)
		m.guide.doneAt = clk.t
		breaksCheckSizes(t, "guide done "+id, m.View)
		m.guide = nil
	}
	m.openEditor("")
	breaksCheckSizes(t, "editor", m.View)
	m.edit = nil
	m.confirmDel = true
	breaksCheckSizes(t, "confirm", m.View)
}

func trackerTestMode(t *testing.T) (*trackerMode, *Core, *appClock) {
	c, clk := breaksTestCore(t)
	return newTracker(c, func(string) {}), c, clk
}

func TestTrackerFlowLogsSpansAndPersists(t *testing.T) {
	m, c, clk := trackerTestMode(t)
	if len(m.t.Acts) != 3 {
		t.Fatalf("starter activities: %d", len(m.t.Acts))
	}
	m.Update(press("space")) // start Work
	if m.t.Running != m.t.Acts[0].ID {
		t.Fatal("space starts the selected activity")
	}
	if r := m.Runner(); r == nil || r.Icon != iconTracker {
		t.Fatal("running activity should have a footer chip")
	}
	clk.t = clk.t.Add(10 * time.Minute)
	c.Step(clk.t, time.Second)
	if r := m.Runner(); !strings.Contains(r.Text, "10:00") || !strings.Contains(r.Text, m.t.Acts[0].Name) {
		t.Fatalf("chip text %q", r.Text)
	}
	m.Update(press("j"))
	m.Update(press("enter")) // starting another stops the first and logs it
	ev := c.Events()
	if len(ev) != 1 || ev[0].Kind != engine.KindTracker || ev[0].Actual != 10*time.Minute || ev[0].Label != m.t.Acts[0].Name {
		t.Fatalf("history: %+v", ev)
	}
	clk.t = clk.t.Add(2 * time.Minute)
	m.Step(clk.t, time.Second)
	m2 := newTracker(c, func(string) {})
	if m2.t.Running != m.t.Acts[1].ID || len(m2.t.Spans) != 1 {
		t.Fatalf("tracker.json should restore a running activity: %+v", m2.t)
	}
}

func TestTrackerEditorNewRenameDelete(t *testing.T) {
	m, _, _ := trackerTestMode(t)
	m.Update(press("n"))
	if !m.Capturing() {
		t.Fatal("n opens a text field")
	}
	for _, r := range "Gym" {
		m.Update(press(string(r)))
	}
	m.Update(press("enter"))
	if last := m.t.Acts[len(m.t.Acts)-1]; last.Name != "Gym" || m.sel != len(m.t.Acts)-1 {
		t.Fatalf("new activity: %+v sel=%d", last, m.sel)
	}
	m.Update(press("e"))
	for i := 0; i < 3; i++ {
		m.Update(tea.KeyPressMsg{Code: tea.KeyBackspace})
	}
	for _, r := range "Run" {
		m.Update(press(string(r)))
	}
	m.Update(press("enter"))
	if m.t.Acts[m.sel].Name != "Run" {
		t.Fatalf("rename: %q", m.t.Acts[m.sel].Name)
	}
	m.Update(press("x"))
	if !m.confirmDel {
		t.Fatal("x asks first")
	}
	m.Update(press("y"))
	if len(m.t.Acts) != 3 {
		t.Fatal("activity deleted")
	}
	m.Update(press("l"))
	m.Update(press("l"))
	m.Update(press("l"))
	if m.rng != 2 {
		t.Fatal("range clamps at 30 days")
	}
}

func TestTrackerRendersAtEverySize(t *testing.T) {
	m, c, clk := trackerTestMode(t)
	// a few days of data
	for i := 0; i < 9; i++ {
		d := clk.t.AddDate(0, 0, -i)
		a := m.t.Acts[i%3]
		m.t.Start(a.ID, d.Add(-3*time.Hour))
		m.t.Stop(d.Add(-time.Duration(30+10*i) * time.Minute))
	}
	m.t.Start(m.t.Acts[1].ID, clk.t.Add(-25*time.Minute))
	c.Anim = 2.2
	breaksCheckSizes(t, "tracker", m.View)
	for rng := 0; rng < 3; rng++ {
		m.rng = rng
		breaksCheckSizes(t, "tracker range", m.View)
	}
	m.Update(press("n"))
	breaksCheckSizes(t, "tracker edit", m.View)
	m.edit = nil
	m.confirmDel = true
	breaksCheckSizes(t, "tracker confirm", m.View)
	m.confirmDel = false
	m.t.Acts = nil
	m.t.Running = 0
	breaksCheckSizes(t, "tracker empty", m.View)
}
