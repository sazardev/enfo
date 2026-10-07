package ui

import (
	"fmt"
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/store"
)

func alarmTestCore(t *testing.T) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 10, 7, 9, 30, 0, 0, time.Local)
	c := NewCore(st, now)
	i18n.Set("en")
	return c
}

func alarmKey(s string) tea.KeyPressMsg {
	switch s {
	case "enter":
		return tea.KeyPressMsg{Code: tea.KeyEnter}
	case "esc":
		return tea.KeyPressMsg{Code: tea.KeyEscape}
	case "up":
		return tea.KeyPressMsg{Code: tea.KeyUp}
	case "down":
		return tea.KeyPressMsg{Code: tea.KeyDown}
	case "right":
		return tea.KeyPressMsg{Code: tea.KeyRight}
	case "left":
		return tea.KeyPressMsg{Code: tea.KeyLeft}
	case "tab":
		return tea.KeyPressMsg{Code: tea.KeyTab}
	case "space":
		return tea.KeyPressMsg{Code: ' ', Text: " "}
	}
	r := []rune(s)
	return tea.KeyPressMsg{Code: r[0], Text: s}
}

func alarmSend(m *alarmMode, keys ...string) {
	for _, k := range keys {
		m.Update(alarmKey(k))
	}
}

func TestAlarmDur(t *testing.T) {
	cases := map[time.Duration]string{
		30 * time.Second:                "30 s",
		12*time.Minute + 10*time.Second: "13 min",
		7*time.Hour + 32*time.Minute:    "7 h 32 min",
		3 * time.Hour:                   "3 h",
		51 * time.Hour:                  "2 d 3 h",
	}
	for d, want := range cases {
		if got := alarmDur(d); got != want {
			t.Errorf("alarmDur(%v) = %q, want %q", d, got, want)
		}
	}
}

func TestAlarmCreateEditDelete(t *testing.T) {
	c := alarmTestCore(t)
	m := newAlarmMode(c, func(string) {})
	if m.Capturing() {
		t.Fatal("not capturing at start")
	}
	alarmSend(m, "n")
	if !m.Capturing() {
		t.Fatal("editor must capture keys")
	}
	// new alarm defaults to the next whole hour (10:00); type 0 7 into the hour,
	// move to minutes, type 3 0
	alarmSend(m, "0", "7", "right", "3", "0", "w", "tab")
	// now on Monday chip; jump to label with tab x8 is long: use right arrows
	for m.ed.pos != alarmPosLabel {
		alarmSend(m, "right")
	}
	for _, r := range "Gym" {
		m.Update(alarmKey(string(r)))
	}
	alarmSend(m, "enter")
	if m.Capturing() {
		t.Fatal("editor should close on enter")
	}
	l := c.Alarms.List
	if len(l) != 1 {
		t.Fatalf("alarms: %d", len(l))
	}
	a := l[0]
	if a.Hour != 7 || a.Min != 30 || a.Days != engine.Weekdays || a.Label != "Gym" || !a.Enabled {
		t.Fatalf("saved alarm: %+v", a)
	}
	if a.NextAt.IsZero() {
		t.Fatal("alarm must be armed")
	}

	// toggle off / on
	alarmSend(m, "space")
	if c.Alarms.List[0].Enabled {
		t.Fatal("space should switch it off")
	}
	alarmSend(m, "space")
	if !c.Alarms.List[0].Enabled {
		t.Fatal("space should switch it on again")
	}

	// edit: change the hour with arrows, escape cancels
	alarmSend(m, "e", "up", "esc")
	if c.Alarms.List[0].Hour != 7 {
		t.Fatal("esc must cancel the edit")
	}
	alarmSend(m, "e", "up", "enter")
	if c.Alarms.List[0].Hour != 8 {
		t.Fatalf("hour = %d, want 8", c.Alarms.List[0].Hour)
	}

	// delete asks first
	alarmSend(m, "x")
	if !m.Capturing() {
		t.Fatal("delete confirmation must capture")
	}
	alarmSend(m, "esc")
	if len(c.Alarms.List) != 1 {
		t.Fatal("esc must keep the alarm")
	}
	alarmSend(m, "x", "enter")
	if len(c.Alarms.List) != 0 {
		t.Fatal("enter must delete")
	}
}

func TestAlarmPreview(t *testing.T) {
	c := alarmTestCore(t) // Wednesday 09:30
	m := newAlarmMode(c, nil)
	if p := m.alarmPreviewText(10, 0, 0); !strings.Contains(p, "today") {
		t.Errorf("10:00 should ring today: %q", p)
	}
	if p := m.alarmPreviewText(7, 30, 0); !strings.Contains(p, "tomorrow") {
		t.Errorf("07:30 should ring tomorrow: %q", p)
	}
	if p := m.alarmPreviewText(7, 30, engine.Weekend); !strings.Contains(p, "Saturday") {
		t.Errorf("weekend alarm should name Saturday: %q", p)
	}
	i18n.Set("es")
	defer i18n.Set("en")
	if p := m.alarmPreviewText(7, 30, 0); !strings.Contains(p, "mañana") {
		t.Errorf("es preview: %q", p)
	}
	if p := m.alarmPreviewText(7, 30, engine.Weekend); !strings.Contains(p, "sábado") {
		t.Errorf("es weekday preview: %q", p)
	}
}

func TestAlarmRenderSizes(t *testing.T) {
	c := alarmTestCore(t)
	m := newAlarmMode(c, func(string) {})
	check := func(label string) {
		for _, sz := range [][2]int{{1, 1}, {2, 2}, {10, 3}, {24, 7}, {30, 9}, {40, 12}, {61, 13}, {80, 24}, {100, 30}, {104, 18}, {120, 40}, {250, 70}, {37, 50}} {
			w, h := sz[0], sz[1]
			m.Frame(33 * time.Millisecond)
			out := m.View(w, h)
			lines := strings.Split(out, "\n")
			if len(lines) != h {
				t.Fatalf("%s %dx%d: %d lines", label, w, h, len(lines))
			}
			for i, l := range lines {
				if got := ansi.StringWidth(l); got != w {
					t.Fatalf("%s %dx%d line %d: width %d: %q", label, w, h, i, got, ansi.Strip(l))
				}
			}
		}
	}
	check("empty")
	for i, hm := range [][2]int{{7, 30}, {8, 0}, {22, 45}, {6, 15}, {13, 5}, {9, 40}} {
		c.Alarms.Add(engine.Alarm{Hour: hm[0], Min: hm[1], Enabled: i%4 != 3, Days: engine.Days(i * 9 % 128), Label: fmt.Sprintf("Alarm number %d with a long label", i)}, c.Now)
	}
	check("list")
	m.sel = 3
	check("list sel")
	m.Update(alarmKey("x"))
	check("confirm")
	m.Update(alarmKey("esc"))
	m.Update(alarmKey("e"))
	check("editor")
	for _, k := range []string{"right", "right", "right", "space", "tab"} {
		m.Update(alarmKey(k))
	}
	check("editor days")
	for m.ed.pos != alarmPosLabel {
		m.Update(alarmKey("right"))
	}
	check("editor label")
	m.Update(alarmKey("esc"))
	i18n.Set("es")
	check("es list")
	i18n.Set("en")
	c.Cfg.Motion = "still"
	check("still")
}

func TestAlarmTitleAndHits(t *testing.T) {
	c := alarmTestCore(t)
	m := newAlarmMode(c, func(string) {})
	if m.Title() != "" {
		t.Fatal("no title without alarms")
	}
	c.Alarms.Add(engine.Alarm{Hour: 10, Min: 5, Enabled: true}, c.Now)
	if m.Title() != iconAlarm+" 10:05" {
		t.Fatalf("title = %q", m.Title())
	}
	m.View(100, 30)
	if len(m.hits) == 0 {
		t.Fatal("rows must register hit areas")
	}
	// clicking the toggle area switches the alarm off
	for _, h := range m.hits {
		if h.kind == alarmHitToggle {
			m.Update(tea.MouseClickMsg{X: h.x0, Y: h.y0, Button: tea.MouseLeft})
			break
		}
	}
	if c.Alarms.List[0].Enabled {
		t.Fatal("click on the switch should turn it off")
	}
}

func TestAlarmI18nParity(t *testing.T) {
	n := 0
	for k := range i18n.Table("en") {
		if !strings.HasPrefix(k, "alarm.") && k != "help.mode.alarm" {
			continue
		}
		n++
		if !i18n.Has("es", k) {
			t.Errorf("missing Spanish string for %q", k)
		}
	}
	if n < 30 {
		t.Fatalf("only %d alarm keys found", n)
	}
	for _, lang := range []string{"en", "es"} {
		if got := len([]rune(i18n.Table(lang)["alarm.days"])); got != 7 {
			t.Errorf("%s alarm.days must have 7 letters, has %d", lang, got)
		}
		if got := len(strings.Split(i18n.Table(lang)["alarm.weekdays"], ",")); got != 7 {
			t.Errorf("%s alarm.weekdays must list 7 names, has %d", lang, got)
		}
	}
}
