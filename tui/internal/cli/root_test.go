package cli

import (
	"bytes"
	"strings"
	"testing"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/store"
)

func run(t *testing.T, args ...string) (string, error) {
	t.Helper()
	root := NewRoot()
	var out bytes.Buffer
	root.SetOut(&out)
	root.SetErr(&out)
	root.SetArgs(args)
	err := root.Execute()
	return out.String(), err
}

func TestCommandTree(t *testing.T) {
	root := NewRoot()
	want := []string{"pomodoro", "clock", "timer", "stopwatch", "alarm", "world", "breathe", "status", "stats", "config", "doctor", "wake", "serve", "version"}
	have := map[string]bool{}
	for _, c := range root.Commands() {
		have[c.Name()] = true
		if c.Short == "" {
			t.Errorf("%s has no short description", c.Name())
		}
	}
	for _, w := range want {
		if !have[w] {
			t.Errorf("missing command %s", w)
		}
	}
}

func TestBadArgsFailBeforeOpeningTheTUI(t *testing.T) {
	tempStore(t)
	if _, err := run(t, "timer", "banana"); err == nil || !strings.Contains(err.Error(), "banana") {
		t.Fatalf("timer banana: %v", err)
	}
	if _, err := run(t, "alarm", "add", "25:99", "-q"); err == nil {
		t.Fatal("bad alarm time should fail")
	}
	if _, err := run(t, "alarm", "add", "07:00", "--days", "funday", "-q"); err == nil {
		t.Fatal("bad days should fail")
	}
	if _, err := run(t, "status", "--json", "--waybar"); err == nil {
		t.Fatal("conflicting formats should fail")
	}
}

func TestAlarmAddQuietAndList(t *testing.T) {
	st := tempStore(t)
	t.Setenv("ENFO_QUIET", "1") // no wakers in tests
	out, err := run(t, "alarm", "add", "7:30pm", "--days", "mon-fri", "--label", "standup", "-q")
	if err != nil || !strings.Contains(out, "19:30") || !strings.Contains(out, "weekdays") {
		t.Fatalf("add: %q %v", out, err)
	}
	s := st.LoadState()
	if len(s.Alarms.List) != 1 {
		t.Fatalf("alarms: %+v", s.Alarms.List)
	}
	a := s.Alarms.List[0]
	if a.Hour != 19 || a.Min != 30 || a.Days != engine.Weekdays || a.Label != "standup" || !a.Enabled || a.NextAt.IsZero() {
		t.Fatalf("alarm: %+v", a)
	}
	out, err = run(t, "alarm", "list")
	if err != nil || !strings.Contains(out, "19:30") || !strings.Contains(out, "standup") {
		t.Fatalf("list: %q %v", out, err)
	}
}

func TestStatusCommandJSON(t *testing.T) {
	st := tempStore(t)
	p := engine.NewPomodoro(store.DefaultConfig().Pomodoro())
	p.Start(time.Now())
	_ = st.SaveState(store.State{Pomodoro: p})
	out, err := run(t, "status", "--format", "{{.Mode}} {{.State}}")
	if err != nil || strings.TrimSpace(out) != "pomodoro running" {
		t.Fatalf("%q %v", out, err)
	}
	out, _ = run(t, "status", "--waybar")
	if !strings.Contains(out, `"class":"focus"`) {
		t.Fatalf("waybar: %q", out)
	}
}

func TestConfigShowAndPath(t *testing.T) {
	tempStore(t)
	out, err := run(t, "config", "show")
	if err != nil || !strings.Contains(out, `"work": 25`) {
		t.Fatalf("%q %v", out, err)
	}
	out, _ = run(t, "config", "path")
	if !strings.Contains(out, "config.json") || !strings.Contains(out, "history.jsonl") {
		t.Fatalf("%q", out)
	}
	if out, err = run(t, "config", "reset", "--yes"); err != nil || !strings.Contains(out, "done") {
		t.Fatalf("%q %v", out, err)
	}
}
