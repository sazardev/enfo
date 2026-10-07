package ui

import (
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/engine"
)

func TestSleepPlanWakeAt(t *testing.T) {
	now := time.Date(2026, 10, 7, 22, 0, 0, 0, time.UTC)
	opts, anchor := sleepPlan(now, 0, 7*60, 0)
	if anchor.Day() != 8 || anchor.Hour() != 7 {
		t.Fatalf("wake target should be tomorrow 07:00: %v", anchor)
	}
	// 6 cycles: 9h + 15m before 07:00 -> 21:45
	if got := opts[0].bed.Format("15:04"); got != "21:45" {
		t.Fatalf("6 cycles bedtime %s", got)
	}
	if got := opts[1].bed.Format("15:04"); got != "23:15" {
		t.Fatalf("5 cycles bedtime %s", got)
	}
	if got := opts[2].bed.Format("15:04"); got != "00:45" {
		t.Fatalf("4 cycles bedtime %s", got)
	}
}

func TestSleepPlanBedNow(t *testing.T) {
	now := time.Date(2026, 10, 7, 23, 0, 20, 0, time.UTC)
	opts, anchor := sleepPlan(now, 1, 0, 10)
	if anchor.Format("15:04") != "23:10" {
		t.Fatalf("anchor %v", anchor)
	}
	// 23:10 + 15m + 6*90m = 08:25
	if got := opts[0].wake.Format("15:04"); got != "08:25" {
		t.Fatalf("6 cycles wake %s", got)
	}
}

func TestSleepAlarms(t *testing.T) {
	c := eventTestCore(t)
	c.Now = time.Date(2026, 10, 7, 18, 0, 0, 0, time.UTC)
	var said []string
	m := newSleepMode(c, func(s string) { said = append(said, s) })
	m.Update(tea.KeyPressMsg{Code: 'a', Text: "a"})
	if len(c.Alarms.List) != 2 {
		t.Fatalf("expected a wake alarm and a wind-down alarm, got %d", len(c.Alarms.List))
	}
	var wake, wind *engine.Alarm
	for _, a := range c.Alarms.List {
		if a.Label == "Wake up" {
			wake = a
		} else {
			wind = a
		}
	}
	if wake == nil || wind == nil || wake.Hour != 7 || !wake.Enabled || wake.Days != 0 {
		t.Fatalf("alarms: %+v %+v", wake, wind)
	}
	// bed for 6 cycles is 21:45, wind-down 30 min earlier
	if wind.Hour != 21 || wind.Min != 15 {
		t.Fatalf("wind-down at %02d:%02d", wind.Hour, wind.Min)
	}
	m.Update(tea.KeyPressMsg{Code: 'a', Text: "a"})
	if len(c.Alarms.List) != 2 || !strings.Contains(said[len(said)-1], "already") {
		t.Fatalf("a second press must not duplicate: %d %v", len(c.Alarms.List), said)
	}
}

func TestSleepKeysAndPersistence(t *testing.T) {
	c := eventTestCore(t)
	m := newSleepMode(c, func(string) {})
	m.Update(tea.KeyPressMsg{Code: tea.KeyUp})
	m.Update(tea.KeyPressMsg{Code: tea.KeyRight})
	if m.wake != 7*60+5+60 {
		t.Fatalf("wake %d", m.wake)
	}
	m.Update(tea.KeyPressMsg{Code: 'm', Text: "m"})
	m.Update(tea.KeyPressMsg{Code: tea.KeyDown})
	if m.mode != 1 || m.offset != -5 {
		t.Fatalf("mode %d offset %d", m.mode, m.offset)
	}
	m2 := newSleepMode(c, func(string) {})
	if m2.wake != 7*60+65 || m2.mode != 1 {
		t.Fatalf("not persisted: %+v", m2)
	}
	// wrap around midnight
	m.mode = 0
	m.wake = 0
	m.adjust(-5)
	if m.wake != 1435 {
		t.Fatalf("wrap: %d", m.wake)
	}
}

func TestSleepRendersAtEverySize(t *testing.T) {
	c := eventTestCore(t)
	m := newSleepMode(c, func(string) {})
	for mode := 0; mode < 2; mode++ {
		m.mode = mode
		for i := 0; i < 20; i++ {
			m.Frame(33 * time.Millisecond)
		}
		eventCheckSizes(t, "sleep", m)
	}
}
