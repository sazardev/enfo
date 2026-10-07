package engine

import (
	"testing"
	"time"
)

func TestStatsExtra(t *testing.T) {
	now := time.Date(2026, 10, 7, 12, 0, 0, 0, time.UTC)
	ev := []Event{
		{Kind: KindFocus, Start: time.Date(2026, 10, 7, 9, 40, 0, 0, time.UTC), Actual: 50 * time.Minute, Completed: true},
		{Kind: KindFocus, Start: time.Date(2026, 10, 6, 15, 0, 0, 0, time.UTC), Actual: 25 * time.Minute, Completed: true},
		{Kind: KindRest, Start: time.Date(2026, 10, 7, 10, 30, 0, 0, time.UTC), Actual: 5 * time.Minute, Completed: true},
	}
	h := StatsHourly(ev, now, 7)
	if h[9] != 20*time.Minute || h[10] != 30*time.Minute || h[15] != 25*time.Minute {
		t.Fatalf("hourly split: %v", h)
	}
	if b, ok := StatsBestHour(h); !ok || b != 10 {
		t.Fatalf("best hour %d", b)
	}
	k := StatsKinds(ev, now, 7)
	if k[0].Count != 2 || k[1].Dur != 5*time.Minute {
		t.Fatalf("kinds: %+v", k)
	}
	w := StatsWeekdays(ev, now, 7) // 7 Oct 2026 is a Wednesday
	if w[2] != 50*time.Minute || w[1] != 25*time.Minute {
		t.Fatalf("weekdays: %v", w)
	}
	s := Summarize(ev, now, 14)
	if r, ok := StatsCompletion(s); !ok || r != 1 {
		t.Fatalf("completion %v", r)
	}
}
