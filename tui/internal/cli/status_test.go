package cli

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/ui"
	"github.com/sazardev/enfo/tui/internal/wake"
)

var t0 = time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)

func tempStore(t *testing.T) *store.Store {
	t.Helper()
	t.Cleanup(func() { i18n.Set("en") })
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	cfg, _ := st.LoadConfig()
	cfg.Lang = "en"
	if err := st.SaveConfig(cfg); err != nil {
		t.Fatal(err)
	}
	return st
}

func TestStatusIdle(t *testing.T) {
	st := tempStore(t)
	s := BuildSnapshot(st, t0)
	if s.Text != "idle" || s.State != "idle" || s.Class != "idle" || len(s.Items) != 0 {
		t.Fatalf("%+v", s)
	}
	if wb := s.Waybar(); wb.Class != "idle" || wb.Text == "" {
		t.Fatalf("waybar: %+v", wb)
	}
}

func TestStatusPomodoroRunningFromStaleState(t *testing.T) {
	st := tempStore(t)
	p := engine.NewPomodoro(store.DefaultConfig().Pomodoro())
	p.Start(t0)
	if err := st.SaveState(store.State{Pomodoro: p}); err != nil {
		t.Fatal(err)
	}
	// asked 9 minutes later, regardless of when the file was written
	s := BuildSnapshot(st, t0.Add(9*time.Minute))
	if s.Text != "● focus 16:00" || s.Remaining != 960 || s.State != "running" || s.Class != "focus" {
		t.Fatalf("%+v", s)
	}
	if s.Progress < 0.35 || s.Progress > 0.37 {
		t.Fatalf("progress %v", s.Progress)
	}
	wb := s.Waybar()
	if wb.Percentage != 36 || wb.Class != "focus" || wb.Alt != "pomodoro" || !strings.Contains(wb.Tooltip, "focus 16:00") {
		t.Fatalf("waybar: %+v", wb)
	}
	var back map[string]any
	b, _ := json.Marshal(wb)
	if err := json.Unmarshal(b, &back); err != nil || back["text"] != "● focus 16:00" {
		t.Fatalf("waybar json: %s", b)
	}
	if got := s.Tmux(); got != "#[fg="+s.Color+"]● focus 16:00#[default]" {
		t.Fatalf("tmux: %q", got)
	}
	if got := s.Polybar(); got != "%{F"+s.Color+"}● focus 16:00%{F-}" {
		t.Fatalf("polybar: %q", got)
	}
	if r, err := s.Render("{{.State}}/{{.Remaining}}"); err != nil || r != "running/960" {
		t.Fatalf("template: %q %v", r, err)
	}
}

func TestStatusPhaseAlreadyEnded(t *testing.T) {
	st := tempStore(t)
	p := engine.NewPomodoro(store.DefaultConfig().Pomodoro())
	p.Start(t0)
	_ = st.SaveState(store.State{Pomodoro: p})
	s := BuildSnapshot(st, t0.Add(3*time.Hour))
	if s.State != "finished" || s.Class != "done" || !strings.Contains(s.Text, "done") || s.Remaining != 0 || s.Progress != 1 {
		t.Fatalf("%+v", s)
	}
	if !strings.Contains(s.Items[0].Label, "ended 2h35m ago") {
		t.Fatalf("label: %q", s.Items[0].Label)
	}
}

func TestStatusPausedTimerAndPriority(t *testing.T) {
	st := tempStore(t)
	tm := engine.NewTimer(10 * time.Minute)
	tm.Begin(t0)
	tm.Pause(t0.Add(4 * time.Minute))
	sw := &engine.Stopwatch{}
	sw.Toggle(t0)
	_ = st.SaveState(store.State{Timer: tm, Stopwatch: sw})
	s := BuildSnapshot(st, t0.Add(time.Hour))
	if s.Mode != "timer" || s.State != "paused" || s.Remaining != 360 || s.Class != "paused" {
		t.Fatalf("%+v", s)
	}
	if len(s.Items) != 2 || s.Items[1].Mode != "stopwatch" || s.Items[1].ElapsedSec != 3600 {
		t.Fatalf("items: %+v", s.Items)
	}
	if !strings.Contains(s.Tooltip, "⏲ 06:00") {
		t.Fatalf("tooltip: %q", s.Tooltip)
	}
}

func TestStatusNextAlarm(t *testing.T) {
	st := tempStore(t)
	var as engine.Alarms
	now := time.Date(2026, 10, 7, 6, 0, 0, 0, time.Local)
	as.Add(engine.Alarm{Hour: 7, Min: 30, Enabled: true, Label: "gym"}, now)
	_ = st.SaveState(store.State{Alarms: as})
	s := BuildSnapshot(st, now)
	if s.Mode != "alarm" || s.Text != "⏰ 07:30" || s.NextAlarm == nil || s.NextAlarm.InSec != 5400 {
		t.Fatalf("%+v", s)
	}
	// far away alarms do not take over the headline
	s = BuildSnapshot(st, now.Add(-20*time.Hour))
	if s.Mode != "idle" {
		t.Fatalf("far alarm should leave idle: %+v", s)
	}
}

func TestWaybarEscapes(t *testing.T) {
	s := Snapshot{Text: "a<b>&c", Tooltip: "x<y", State: "running"}
	wb := s.Waybar()
	if wb.Text != "a&lt;b&gt;&amp;c" || wb.Tooltip != "x&lt;y" {
		t.Fatalf("%+v", wb)
	}
}

func TestSpanishStatus(t *testing.T) {
	st := tempStore(t)
	cfg, _ := st.LoadConfig()
	cfg.Lang = "es"
	_ = st.SaveConfig(cfg)
	p := engine.NewPomodoro(store.DefaultConfig().Pomodoro())
	p.Start(t0)
	_ = st.SaveState(store.State{Pomodoro: p})
	if s := BuildSnapshot(st, t0.Add(time.Minute)); s.Text != "● enfoque 24:00" {
		t.Fatalf("%q", s.Text)
	}
}

func TestDistroFrom(t *testing.T) {
	cases := map[string]distro{
		"NAME=\"CachyOS Linux\"\nID=cachyos\nID_LIKE=arch\n": distroArch,
		"ID=ubuntu\nID_LIKE=debian\n":                        distroDebian,
		"ID=fedora\n":                                        distroFedora,
		"ID=nixos\n":                                         distroOther,
		"PRETTY_NAME=\"Arch-based thing\"\nID=weird\nID_LIKE=arch": distroArch,
	}
	for in, want := range cases {
		if got := distroFrom(in); got != want {
			t.Errorf("%q: got %v want %v", in, got, want)
		}
	}
	if !strings.Contains(installHint(distroArch, "libnotify", "libnotify-bin", "libnotify"), "pacman -S libnotify") {
		t.Error("arch hint")
	}
}

func TestStatsJSONAndRender(t *testing.T) {
	st := tempStore(t)
	now := time.Date(2026, 10, 7, 12, 0, 0, 0, time.Local)
	_ = st.AppendEvents(
		engine.Event{Kind: engine.KindFocus, Start: now.Add(-2 * time.Hour), Actual: 25 * time.Minute, Completed: true},
		engine.Event{Kind: engine.KindFocus, Start: now.AddDate(0, 0, -1), Actual: 50 * time.Minute, Completed: true},
	)
	sum := engine.Summarize(st.Events(), now, 14)
	j := statsJSON(sum, 14)
	if j.TodayMin != 25 || j.Sessions != 2 || j.Streak != 2 || len(j.PerDay) != 14 || j.Completion != 1 {
		t.Fatalf("%+v", j)
	}
	i18n.Set("en")
	out := ansi.Strip(renderStats(st, st.Events(), now, 14, 80))
	for _, want := range []string{"enfo", "STREAK", "LAST 14 DAYS", "16 WEEKS", "focus"} {
		if !strings.Contains(out, want) {
			t.Errorf("stats output missing %q:\n%s", want, out)
		}
	}
}

func TestWakeJobs(t *testing.T) {
	st := tempStore(t)
	now := time.Now()
	c := ui.NewCore(st, now)
	i18n.Set("en")
	c.Pomo.Cfg.AutoNext = true
	c.Pomo.Start(now)
	c.Timer.Set(90*time.Second, "tea")
	c.Timer.Begin(now)
	c.Alarms.Add(engine.Alarm{Hour: 7, Min: 0, Enabled: true, Label: "gym", Days: engine.Everyday}, now)
	jobs := wakeJobs(c, now)
	// 4 chained pomodoro phases + the timer + the alarm
	if len(jobs) != 6 {
		t.Fatalf("want 6 jobs, got %d: %+v", len(jobs), jobs)
	}
	if !jobs[0].At.Equal(c.Pomo.EndsAt) || jobs[0].Title != "Focus complete" || !strings.Contains(jobs[0].Body, "5m") {
		t.Fatalf("first job: %+v", jobs[0])
	}
	if jobs[1].Title != "Back to focus" || !jobs[1].At.Equal(c.Pomo.EndsAt.Add(5*time.Minute)) {
		t.Fatalf("second job: %+v", jobs[1])
	}
	var timer, alarm *wake.Job
	for i := range jobs {
		switch jobs[i].Title {
		case "Timer finished":
			timer = &jobs[i]
		case "gym":
			alarm = &jobs[i]
		}
	}
	if timer == nil || !strings.Contains(timer.Body, "tea") || alarm == nil || alarm.Body != "07:00" {
		t.Fatalf("timer=%v alarm=%v", timer, alarm)
	}
	// nothing running, nothing to hand over
	c2 := ui.NewCore(tempStore(t), now)
	if j := wakeJobs(c2, now); len(j) != 0 {
		t.Fatalf("idle jobs: %+v", j)
	}
}
