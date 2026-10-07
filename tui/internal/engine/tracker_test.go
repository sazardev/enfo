package engine

import (
	"testing"
	"time"
)

func TestTrackerStartStopAndSwitch(t *testing.T) {
	tr := NewTracker("Work", "Study")
	now := time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)
	tr.Start(1, now)
	if tr.Elapsed(now.Add(90*time.Second)) != 90*time.Second {
		t.Fatal("elapsed")
	}
	s, ok := tr.Start(2, now.Add(10*time.Minute)) // switching stops the first
	if !ok || s.Act != 1 || s.End.Sub(s.Start) != 10*time.Minute {
		t.Fatalf("switch span: %+v %v", s, ok)
	}
	if tr.Running != 2 {
		t.Fatal("second activity should run")
	}
	if _, ok := tr.Stop(now.Add(10*time.Minute + time.Second)); ok {
		t.Fatal("a one-second tap is dropped")
	}
	tot := tr.DayTotals(now, now.Add(time.Hour))
	if tot[1] != 10*time.Minute || tot[2] != 0 {
		t.Fatalf("totals: %v", tot)
	}
}

func TestTrackerSpanAcrossMidnightIsClipped(t *testing.T) {
	tr := NewTracker("Night")
	start := time.Date(2026, 10, 6, 23, 0, 0, 0, time.UTC)
	end := time.Date(2026, 10, 7, 1, 30, 0, 0, time.UTC)
	tr.Start(1, start)
	tr.Stop(end)
	if d := tr.DayTotals(start, end)[1]; d != time.Hour {
		t.Fatalf("yesterday: %v", d)
	}
	if d := tr.DayTotals(end, end)[1]; d != 90*time.Minute {
		t.Fatalf("today: %v", d)
	}
	segs := tr.Segments(end, end)
	if len(segs) != 1 || segs[0].From != 0 || segs[0].To != 90*time.Minute {
		t.Fatalf("segments: %+v", segs)
	}
}

func TestTrackerRunningCountsInTotalsAndSurvivesReload(t *testing.T) {
	tr := NewTracker("A")
	now := time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)
	tr.Start(1, now)
	later := now.Add(3 * time.Hour) // as if the app was closed for hours
	if d := tr.DayTotals(later, later)[1]; d != 3*time.Hour {
		t.Fatalf("running activity should keep counting: %v", d)
	}
	segs := tr.Segments(later, later)
	if len(segs) != 1 || !segs[0].Live {
		t.Fatalf("live segment: %+v", segs)
	}
}

func TestTrackerDeleteRemovesSpansAndStopsRunning(t *testing.T) {
	tr := NewTracker("A", "B")
	now := time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)
	tr.Start(1, now)
	tr.Stop(now.Add(time.Hour))
	tr.Start(1, now.Add(2*time.Hour))
	tr.Delete(1)
	if tr.Running != 0 || len(tr.Spans) != 0 || len(tr.Acts) != 1 {
		t.Fatalf("%+v", tr)
	}
}
