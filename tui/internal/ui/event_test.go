package ui

import (
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/store"
)

var eventT0 = time.Date(2026, 10, 7, 9, 30, 0, 0, time.UTC)

func eventTestCore(t *testing.T) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	t.Setenv("ENFO_QUIET", "1")
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	return NewCore(st, eventT0)
}

func TestEventOccurrences(t *testing.T) {
	it := &eventItem{At: time.Date(1990, 12, 25, 8, 0, 0, 0, time.UTC), Yearly: true, Created: eventT0}
	next, ok := eventNext(it, eventT0)
	if !ok || next.Year() != 2026 || next.Month() != 12 || next.Day() != 25 {
		t.Fatalf("next: %v", next)
	}
	after := time.Date(2026, 12, 26, 0, 0, 0, 0, time.UTC)
	if next, _ = eventNext(it, after); next.Year() != 2027 {
		t.Fatalf("a yearly event rolls forward: %v", next)
	}
	if last, ok := eventLast(it, after); !ok || last.Year() != 2026 {
		t.Fatalf("last: %v", last)
	}
	once := &eventItem{At: time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC), Created: eventT0.AddDate(0, -1, 0)}
	if _, ok := eventNext(once, eventT0); ok {
		t.Fatal("a one-off past event has no next occurrence")
	}
	if v := eventResolve(once, eventT0); !v.Past || v.Left >= 0 || v.Progress != 1 {
		t.Fatalf("past view: %+v", v)
	}
}

func TestEventProgressAndOrder(t *testing.T) {
	items := []eventItem{
		{ID: 1, Name: "far", At: eventT0.AddDate(0, 0, 40), Created: eventT0.AddDate(0, 0, -10)},
		{ID: 2, Name: "near", At: eventT0.AddDate(0, 0, 3), Created: eventT0.AddDate(0, 0, -3)},
		{ID: 3, Name: "gone", At: eventT0.AddDate(0, 0, -5), Created: eventT0.AddDate(0, 0, -30)},
		{ID: 4, Name: "gone2", At: eventT0.AddDate(0, 0, -1), Created: eventT0.AddDate(0, 0, -30)},
	}
	vs := eventSorted(items, eventT0)
	got := []string{vs[0].Item.Name, vs[1].Item.Name, vs[2].Item.Name, vs[3].Item.Name}
	if strings.Join(got, ",") != "near,far,gone2,gone" {
		t.Fatalf("order %v", got)
	}
	if p := vs[0].Progress; p < 0.49 || p > 0.51 {
		t.Fatalf("progress %.2f", p)
	}
}

func TestEventCheckArrivalAndReminder(t *testing.T) {
	items := []eventItem{{ID: 1, Name: "trip", At: eventT0.Add(36 * time.Hour), Created: eventT0.Add(-48 * time.Hour)}}
	if n, ch := eventCheck(items, eventT0); len(n) != 0 || ch {
		t.Fatalf("nothing yet: %v %v", n, ch)
	}
	// 12h before the day-before mark
	n, _ := eventCheck(items, eventT0.Add(12*time.Hour+time.Second))
	if len(n) != 1 || n[0].Arrived {
		t.Fatalf("expected the day-before reminder: %+v", n)
	}
	if n, _ = eventCheck(items, eventT0.Add(13*time.Hour)); len(n) != 0 {
		t.Fatal("reminder must fire once")
	}
	n, _ = eventCheck(items, eventT0.Add(36*time.Hour+time.Second))
	if len(n) != 1 || !n[0].Arrived {
		t.Fatalf("expected the arrival: %+v", n)
	}
	if n, _ = eventCheck(items, eventT0.Add(36*time.Hour+3*time.Second)); len(n) != 0 {
		t.Fatal("arrival must fire once")
	}
}

func TestEventAwayIsSilent(t *testing.T) {
	items := []eventItem{{ID: 1, Name: "x", At: eventT0.Add(time.Hour), Created: eventT0.Add(-72 * time.Hour)}}
	n, ch := eventCheck(items, eventT0.Add(5*time.Hour))
	if len(n) != 0 || !ch || items[0].Fired.IsZero() {
		t.Fatalf("an arrival missed while closed is marked, not announced: %v", n)
	}
}

func TestEventModeFormAndPersistence(t *testing.T) {
	c := eventTestCore(t)
	m := newEventMode(c, func(string) {})
	m.Update(tea.KeyPressMsg{Code: 'n', Text: "n"})
	if m.form == nil || !m.Capturing() {
		t.Fatal("n opens the editor, which captures keys")
	}
	for _, r := range "Launch" {
		m.Update(tea.KeyPressMsg{Code: r, Text: string(r)})
	}
	m.Update(tea.KeyPressMsg{Code: tea.KeyTab}) // year
	m.Update(tea.KeyPressMsg{Code: tea.KeyUp})  // 2027
	m.Update(tea.KeyPressMsg{Code: tea.KeyEnter})
	if m.form != nil {
		t.Fatal("enter saves")
	}
	if len(m.st.data.Items) != 1 {
		t.Fatalf("items: %+v", m.st.data.Items)
	}
	it := m.st.data.Items[0]
	if it.Name != "Launch" || it.At.Year() != 2027 || it.At.Hour() != 9 {
		t.Fatalf("saved: %+v", it)
	}
	// reload from disk
	m2 := newEventMode(c, func(string) {})
	if len(m2.st.data.Items) != 1 || m2.selID == 0 {
		t.Fatal("event.json should persist")
	}
	// delete with confirmation
	m2.Update(tea.KeyPressMsg{Code: 'x', Text: "x"})
	if m2.confirmDel == 0 {
		t.Fatal("x asks first")
	}
	m2.Update(tea.KeyPressMsg{Code: 'n', Text: "n"})
	if len(m2.st.data.Items) != 1 {
		t.Fatal("n keeps it")
	}
	m2.Update(tea.KeyPressMsg{Code: 'x', Text: "x"})
	m2.Update(tea.KeyPressMsg{Code: 'y', Text: "y"})
	if len(m2.st.data.Items) != 0 {
		t.Fatal("y deletes")
	}
}

func TestEventDayClamp(t *testing.T) {
	f := &eventForm{at: time.Date(2026, 1, 31, 9, 0, 0, 0, time.UTC), focus: 2}
	f.adjust(1)
	if f.at.Month() != 2 || f.at.Day() != 28 {
		t.Fatalf("31 Jan + 1 month should clamp to 28 Feb: %v", f.at)
	}
}

func TestEventStepAnnouncesAndRunner(t *testing.T) {
	c := eventTestCore(t)
	m := newEventMode(c, func(string) {})
	m.st.add(eventItem{Name: "Party", At: eventT0.Add(2 * time.Hour), Created: eventT0.Add(-time.Hour)})
	c.Now = eventT0
	if r := m.Runner(); r == nil || !strings.Contains(r.Text, "2h") {
		t.Fatalf("runner: %+v", r)
	}
	if an := m.Step(eventT0.Add(2*time.Hour+time.Second), time.Second); len(an) != 1 || an[0].Ring {
		t.Fatalf("arrival announce: %+v", an)
	}
	c.Now = eventT0.Add(2*time.Hour + time.Second)
	if r := m.Runner(); r == nil || r.Text != "now" {
		t.Fatalf("runner when it is here: %+v", r)
	}
	if len(c.Events()) != 1 {
		t.Fatal("arrival is logged")
	}
}

func eventCheckSizes(t *testing.T, name string, m Mode) {
	t.Helper()
	for _, sz := range [][2]int{{1, 1}, {2, 2}, {8, 3}, {20, 6}, {24, 5}, {30, 9}, {40, 12}, {40, 16}, {59, 14}, {60, 20}, {80, 24}, {95, 17}, {96, 18},
		{100, 30}, {120, 36}, {160, 50}, {250, 70}, {33, 70}, {250, 7}} {
		out := m.View(sz[0], sz[1])
		lines := strings.Split(out, "\n")
		if len(lines) != sz[1] {
			t.Fatalf("%s %v: %d lines", name, sz, len(lines))
		}
		for i, l := range lines {
			if w := ansi.StringWidth(l); w != sz[0] {
				t.Fatalf("%s %v: line %d is %d wide: %q", name, sz, i, w, ansi.Strip(l))
			}
		}
	}
}

func TestEventRendersAtEverySize(t *testing.T) {
	c := eventTestCore(t)
	m := newEventMode(c, func(string) {})
	eventCheckSizes(t, "empty", m)
	m.st.add(eventItem{Name: "A very long event name that will not fit anywhere at all", At: eventT0.AddDate(0, 0, 23), Created: eventT0.AddDate(0, 0, -2), Yearly: true})
	m.st.add(eventItem{Name: "Soon", At: eventT0.Add(3 * time.Hour), Created: eventT0.Add(-time.Hour)})
	m.st.add(eventItem{Name: "Old", At: eventT0.AddDate(0, 0, -9), Created: eventT0.AddDate(0, -1, 0)})
	m.selectNear()
	for i := 0; i < 5; i++ {
		m.Frame(33 * time.Millisecond)
	}
	eventCheckSizes(t, "list", m)
	m.Update(tea.KeyPressMsg{Code: 'e', Text: "e"})
	eventCheckSizes(t, "form", m)
	m.Update(tea.KeyPressMsg{Code: tea.KeyEscape})
	m.Update(tea.KeyPressMsg{Code: 'x', Text: "x"})
	eventCheckSizes(t, "confirm", m)
}

func TestEventShortAndLong(t *testing.T) {
	cases := map[time.Duration]string{23 * 24 * time.Hour: "23d", 30 * time.Hour: "1d 06h", 5*time.Hour + 12*time.Minute: "5h 12m", 12 * time.Minute: "12m", 40 * time.Second: "40s"}
	for d, want := range cases {
		if got := eventShort(d); got != want {
			t.Errorf("eventShort(%v) = %q want %q", d, got, want)
		}
	}
	if got := eventLong(23 * 24 * time.Hour); got != "23 days" {
		t.Errorf("long: %q", got)
	}
}
