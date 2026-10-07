package store

import (
	"testing"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
)

func TestRoundTrip(t *testing.T) {
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	s, err := Open()
	if err != nil {
		t.Fatal(err)
	}
	c, found := s.LoadConfig()
	if found || c.Work != 25 {
		t.Fatalf("fresh config should be defaults: %+v", c)
	}
	c.Work = 50
	c.Accent = "#ff8800"
	if err := s.SaveConfig(c); err != nil {
		t.Fatal(err)
	}
	c2, found := s.LoadConfig()
	if !found || c2.Work != 50 || c2.Accent != "#ff8800" || c2.Rest != 5 {
		t.Fatalf("reloaded: %+v", c2)
	}

	now := time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)
	p := engine.NewPomodoro(c2.Pomodoro())
	p.Start(now)
	st := State{Pomodoro: p}
	st.Alarms.Add(engine.Alarm{Hour: 7, Enabled: true}, now)
	if err := s.SaveState(st); err != nil {
		t.Fatal(err)
	}
	st2 := s.LoadState()
	if st2.Pomodoro == nil || st2.Pomodoro.Run != engine.Running || !st2.Pomodoro.EndsAt.Equal(p.EndsAt) {
		t.Fatalf("pomodoro lost: %+v", st2.Pomodoro)
	}
	if len(st2.Alarms.List) != 1 {
		t.Fatal("alarm lost")
	}

	e := engine.Event{Kind: engine.KindFocus, Start: now, Actual: time.Minute, Completed: true}
	if err := s.AppendEvents(e, e); err != nil {
		t.Fatal(err)
	}
	if got := s.Events(); len(got) != 2 || got[0].Actual != time.Minute {
		t.Fatalf("events: %+v", got)
	}
}

func TestBrokenFiles(t *testing.T) {
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	s, _ := Open()
	_ = writeAtomic(s.ConfigPath(), []byte("{not json"))
	_ = writeAtomic(s.StatePath(), []byte("garbage"))
	if c, found := s.LoadConfig(); found || c.Work != 25 {
		t.Fatal("broken config must fall back to defaults")
	}
	if st := s.LoadState(); st.Pomodoro != nil {
		t.Fatal("broken state must be empty")
	}
}

func TestNormalize(t *testing.T) {
	c := Config{Work: 9999, Motion: "warp"}
	c.Normalize()
	if c.Work != 25 || c.Motion != "full" || len(c.Modes) == 0 {
		t.Fatalf("%+v", c)
	}
}
