package engine

import (
	"testing"
	"time"
)

var t0 = time.Date(2026, 10, 7, 9, 0, 0, 0, time.UTC)

func TestPomodoroRunPauseResume(t *testing.T) {
	p := NewPomodoro(DefaultPomodoro())
	p.Start(t0)
	if got := p.Remaining(t0.Add(5 * time.Minute)); got != 20*time.Minute {
		t.Fatalf("remaining = %v", got)
	}
	p.Pause(t0.Add(5 * time.Minute))
	if p.Remaining(t0.Add(time.Hour)) != 20*time.Minute {
		t.Fatal("paused phase must not lose time")
	}
	p.Start(t0.Add(time.Hour))
	if p.Remaining(t0.Add(time.Hour+time.Minute)) != 19*time.Minute {
		t.Fatal("resume should continue from 20m")
	}
	if p.Pauses != 1 || p.PausedFor < 54*time.Minute {
		t.Fatalf("pause bookkeeping: %d %v", p.Pauses, p.PausedFor)
	}
}

func TestPomodoroCompletesAndAdvances(t *testing.T) {
	p := NewPomodoro(DefaultPomodoro())
	p.Start(t0)
	if ev := p.Tick(t0.Add(24 * time.Minute)); len(ev) != 0 {
		t.Fatal("not done yet")
	}
	ev := p.Tick(t0.Add(25*time.Minute + time.Second))
	if len(ev) != 1 || !ev[0].Completed || ev[0].Kind != KindFocus || ev[0].Late {
		t.Fatalf("events: %+v", ev)
	}
	if p.Phase != Rest || p.Run != Idle || p.Done != 1 {
		t.Fatalf("state after focus: %+v", p)
	}
}

func TestPomodoroAutoChainCatchUp(t *testing.T) {
	cfg := DefaultPomodoro()
	cfg.AutoNext = true
	p := NewPomodoro(cfg)
	p.Start(t0)
	// away for 100 minutes: focus(25) rest(5) focus(25) rest(5) focus(25) rest(5) focus(25) long(15) -> 130m
	ev := p.Tick(t0.Add(100 * time.Minute))
	if len(ev) != 6 {
		t.Fatalf("want 6 finished phases, got %d", len(ev))
	}
	for _, e := range ev {
		if !e.Late {
			t.Fatal("phases finished while away must be Late")
		}
	}
	// 100m into focus,rest,focus,rest,focus,rest(=90m) then 4th focus at 90..115
	if p.Phase != Focus || p.Run != Running {
		t.Fatalf("expected a running focus phase, got %s/%s", p.Phase, p.Run)
	}
	if got := p.Remaining(t0.Add(100 * time.Minute)); got != 15*time.Minute {
		t.Fatalf("remaining = %v", got)
	}
}

func TestPomodoroLongRest(t *testing.T) {
	cfg := DefaultPomodoro()
	cfg.Cycles = 2
	p := NewPomodoro(cfg)
	now := t0
	for i := 0; i < 2; i++ {
		p.Start(now)
		now = now.Add(cfg.Work)
		p.Tick(now)
		if i == 0 && p.Phase != Rest {
			t.Fatalf("after first focus want rest, got %s", p.Phase)
		}
		if i == 0 {
			p.Start(now)
			now = now.Add(cfg.Rest)
			p.Tick(now)
		}
	}
	if p.Phase != Long {
		t.Fatalf("after 2 focus sessions want long rest, got %s", p.Phase)
	}
	p.Start(now)
	p.Tick(now.Add(cfg.Long))
	if p.Phase != Focus || p.Done != 0 {
		t.Fatalf("set should reset: %s %d", p.Phase, p.Done)
	}
}

func TestPomodoroSkipAndAbandon(t *testing.T) {
	p := NewPomodoro(DefaultPomodoro())
	p.Start(t0)
	ev := p.Skip(t0.Add(10 * time.Minute))
	if len(ev) != 1 || ev[0].Completed || ev[0].Actual != 10*time.Minute {
		t.Fatalf("abandoned event: %+v", ev)
	}
	if p.Phase != Rest || p.Run != Idle || p.Done != 0 {
		t.Fatalf("skip state: %+v", p)
	}
	if ev := p.Reset(t0); len(ev) != 0 {
		t.Fatal("reset of an idle phase logs nothing")
	}
}

func TestPomodoroAdd(t *testing.T) {
	p := NewPomodoro(DefaultPomodoro())
	p.Start(t0)
	p.Add(5*time.Minute, t0.Add(time.Minute))
	if p.Remaining(t0.Add(time.Minute)) != 29*time.Minute || p.Total != 30*time.Minute {
		t.Fatalf("add: %v %v", p.Remaining(t0.Add(time.Minute)), p.Total)
	}
	p.Add(-time.Hour, t0.Add(time.Minute))
	if p.Remaining(t0.Add(time.Minute)) != 10*time.Second {
		t.Fatal("never below ten seconds")
	}
}

func TestTimer(t *testing.T) {
	tm := NewTimer(90 * time.Second)
	tm.Begin(t0)
	if tm.Remaining(t0.Add(30*time.Second)) != 60*time.Second {
		t.Fatal("remaining")
	}
	tm.Pause(t0.Add(30 * time.Second))
	tm.Begin(t0.Add(time.Minute))
	ev := tm.Tick(t0.Add(time.Minute + 61*time.Second))
	if len(ev) != 1 || !ev[0].Completed {
		t.Fatalf("timer events: %+v", ev)
	}
	if tm.Run != Idle || tm.Left != 90*time.Second {
		t.Fatal("timer should be ready to run again")
	}
}

func TestStopwatchLaps(t *testing.T) {
	var s Stopwatch
	s.Toggle(t0)
	s.Lap(t0.Add(10 * time.Second))
	s.Lap(t0.Add(25 * time.Second))
	s.Lap(t0.Add(30 * time.Second))
	if len(s.Laps) != 3 || s.Laps[1].Split != 15*time.Second || s.Laps[2].Split != 5*time.Second {
		t.Fatalf("laps: %+v", s.Laps)
	}
	best, worst := s.Extremes()
	if best != 2 || worst != 1 {
		t.Fatalf("extremes %d %d", best, worst)
	}
	s.Toggle(t0.Add(40 * time.Second))
	if s.Elapsed(t0.Add(time.Hour)) != 40*time.Second {
		t.Fatal("paused stopwatch must hold")
	}
	s.Toggle(t0.Add(time.Hour))
	if s.Elapsed(t0.Add(time.Hour+5*time.Second)) != 45*time.Second {
		t.Fatal("resume adds to accumulated time")
	}
}

func TestAlarmNextOccurrence(t *testing.T) {
	a := Alarm{Hour: 7, Min: 30, Enabled: true}
	now := time.Date(2026, 10, 7, 8, 0, 0, 0, time.UTC) // Wednesday
	if got := a.NextOccurrence(now); got.Day() != 8 || got.Hour() != 7 {
		t.Fatalf("one-shot after 7:30 should be tomorrow: %v", got)
	}
	a.Days = Weekend
	if got := a.NextOccurrence(now); got.Weekday() != time.Saturday {
		t.Fatalf("weekend alarm: %v", got.Weekday())
	}
	a.Days = Weekdays
	if got := a.NextOccurrence(time.Date(2026, 10, 9, 8, 0, 0, 0, time.UTC)); got.Weekday() != time.Monday { // Friday 8:00 -> Monday
		t.Fatalf("weekday alarm Friday after time: %v", got.Weekday())
	}
}

func TestAlarmsTick(t *testing.T) {
	var as Alarms
	now := time.Date(2026, 10, 7, 6, 0, 0, 0, time.UTC)
	once := as.Add(Alarm{Hour: 7, Min: 0, Enabled: true}, now)
	rep := as.Add(Alarm{Hour: 7, Min: 0, Enabled: true, Days: Everyday}, now)
	if r := as.Tick(now.Add(30 * time.Minute)); len(r) != 0 {
		t.Fatal("too early")
	}
	r := as.Tick(now.Add(61 * time.Minute))
	if len(r) != 2 || r[0].Missed {
		t.Fatalf("rings: %+v", r)
	}
	if once.Enabled || !rep.Enabled || rep.NextAt.Day() != 8 {
		t.Fatalf("after ring: once=%v rep=%v next=%v", once.Enabled, rep.Enabled, rep.NextAt)
	}
	// snooze
	as.Snooze(once.ID, now.Add(61*time.Minute))
	if r := as.Tick(now.Add(63 * time.Minute)); len(r) != 0 {
		t.Fatal("snoozed")
	}
	if r := as.Tick(now.Add(67 * time.Minute)); len(r) != 1 || r[0].Alarm.ID != once.ID {
		t.Fatalf("snooze should ring again: %+v", r)
	}
}

func TestAlarmMissed(t *testing.T) {
	var as Alarms
	now := time.Date(2026, 10, 7, 6, 0, 0, 0, time.UTC)
	as.Add(Alarm{Hour: 7, Min: 0, Enabled: true, Days: Everyday}, now)
	r := as.Tick(now.Add(3 * time.Hour))
	if len(r) != 1 || !r[0].Missed {
		t.Fatalf("an alarm hours late is missed: %+v", r)
	}
}

func TestBreathe(t *testing.T) {
	p := PatternByID("box")
	if pt := p.At(0); pt.Phase != Inhale || pt.Fill != 0 {
		t.Fatalf("start: %+v", pt)
	}
	if pt := p.At(4 * time.Second); pt.Phase != HoldFull || pt.Fill != 1 {
		t.Fatalf("full: %+v", pt)
	}
	if pt := p.At(10 * time.Second); pt.Phase != Exhale || pt.Fill < 0.4 || pt.Fill > 0.6 {
		t.Fatalf("half exhale: %+v", pt)
	}
	if pt := p.At(17 * time.Second); pt.Breath != 1 || pt.Phase != Inhale {
		t.Fatalf("second breath: %+v", pt)
	}
	if PatternByID("478").Timings() != "4-7-8" {
		t.Fatal("timings")
	}
}

func TestSubSolar(t *testing.T) {
	// Solstice noon UTC: the sun is near the Tropic of Cancer, over longitude ~0.
	lat, lon := SubSolar(time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC))
	if lat < 23 || lat > 23.6 || lon < -4 || lon > 4 {
		t.Fatalf("subsolar at solstice noon: %.2f, %.2f", lat, lon)
	}
	if alt := SunAltitude(lat, lon, lat, lon); alt < 89 {
		t.Fatalf("altitude at the subsolar point: %.1f", alt)
	}
	if alt := SunAltitude(-lat, lon+180, lat, lon); alt > -89 {
		t.Fatalf("altitude at the antipode: %.1f", alt)
	}
}

func TestCitiesZones(t *testing.T) {
	for _, c := range Cities {
		if _, err := time.LoadLocation(c.Zone); err != nil {
			t.Errorf("%s: %v", c.ID, err)
		}
	}
}

func TestSummarize(t *testing.T) {
	now := time.Date(2026, 10, 7, 12, 0, 0, 0, time.UTC)
	ev := []Event{
		{Kind: KindFocus, Start: now.Add(-2 * time.Hour), Actual: 25 * time.Minute, Completed: true},
		{Kind: KindFocus, Start: now.Add(-1 * time.Hour), Actual: 10 * time.Minute},
		{Kind: KindFocus, Start: now.AddDate(0, 0, -1), Actual: 50 * time.Minute, Completed: true},
		{Kind: KindFocus, Start: now.AddDate(0, 0, -3), Actual: 25 * time.Minute, Completed: true},
	}
	s := Summarize(ev, now, 14)
	if s.Today.Focus != 35*time.Minute || s.Sessions != 3 || s.Abandoned != 1 {
		t.Fatalf("%+v", s)
	}
	if s.Streak != 2 {
		t.Fatalf("streak = %d", s.Streak)
	}
	if s.Week != 110*time.Minute {
		t.Fatalf("week = %v", s.Week)
	}
}
