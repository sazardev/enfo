package engine

import (
	"testing"
	"time"
)

func TestIntervalsTabataTimeline(t *testing.T) {
	p := IntervalsPresets[0].Plan
	// 8 work + 7 rests (none after the last round)
	if got, want := p.Total(), 8*20*time.Second+7*10*time.Second; got != want {
		t.Fatalf("total %v want %v", got, want)
	}
	pt := p.At(25 * time.Second)
	if pt.Seg.Phase != IntervalsRest || pt.Seg.Round != 1 || pt.Left != 5*time.Second {
		t.Fatalf("at 25s: %+v", pt)
	}
	if pt.Next == nil || pt.Next.Phase != IntervalsWork || pt.Next.Round != 2 {
		t.Fatalf("next: %+v", pt.Next)
	}
	last := p.At(p.Total() - time.Second)
	if last.Seg.Phase != IntervalsWork || last.Seg.Round != 8 || last.Next != nil {
		t.Fatalf("last: %+v", last)
	}
	if !p.At(p.Total()).Done {
		t.Fatal("done at total")
	}
}

func TestIntervalsWarmCoolAndRamp(t *testing.T) {
	p := IntervalsPlan{Warm: 10 * time.Second, Work: 10 * time.Second, Rest: 5 * time.Second, Rounds: 3, Cool: 20 * time.Second, Ramp: 5 * time.Second}
	segs := p.Segments()
	// warm, w1, r1, w2, r2, w3, cool
	if len(segs) != 7 || segs[0].Phase != IntervalsWarm || segs[6].Phase != IntervalsCool {
		t.Fatalf("segments: %+v", segs)
	}
	if segs[3].Len != 15*time.Second || segs[5].Len != 20*time.Second {
		t.Fatalf("ramp: %v %v", segs[3].Len, segs[5].Len)
	}
	if p.Total() != 10+10+5+15+5+20+20 {
		// seconds
		if p.Total() != 85*time.Second {
			t.Fatalf("total %v", p.Total())
		}
	}
}

func TestIntervalsEMOMHasNoRest(t *testing.T) {
	p := IntervalsPresets[2].Plan
	for _, s := range p.Segments() {
		if s.Phase == IntervalsRest {
			t.Fatal("emom has no rest segments")
		}
	}
}

func TestIntervalsRunPauseSkipTick(t *testing.T) {
	r := &IntervalsRun{Plan: IntervalsPresets[0].Plan}
	r.Toggle(t0)
	if pt := r.Point(t0.Add(5 * time.Second)); pt.Seg.Phase != IntervalsWork || pt.Left != 15*time.Second {
		t.Fatalf("%+v", pt)
	}
	r.Toggle(t0.Add(5 * time.Second)) // pause
	if r.Elapsed(t0.Add(time.Hour)) != 5*time.Second {
		t.Fatal("paused workout must hold")
	}
	r.Toggle(t0.Add(time.Hour)) // resume
	r.Skip(t0.Add(time.Hour))   // jumps to the rest after round 1
	if pt := r.Point(t0.Add(time.Hour)); pt.Seg.Phase != IntervalsRest || pt.Into != 0 {
		t.Fatalf("skip: %+v", pt)
	}
	now := t0.Add(time.Hour)
	ev := r.Tick(now.Add(r.Plan.Total()))
	if len(ev) != 1 || !ev[0].Completed || ev[0].Kind != IntervalsKind || !ev[0].Late {
		t.Fatalf("tick: %+v", ev)
	}
	if r.Run != Idle {
		t.Fatal("finished workout goes idle")
	}
}

func TestIntervalsResetLogsAbandoned(t *testing.T) {
	r := &IntervalsRun{Plan: IntervalsPresets[1].Plan}
	r.Toggle(t0)
	if ev := r.Reset(t0.Add(10 * time.Second)); len(ev) != 0 {
		t.Fatal("under 20s is not logged")
	}
	r.Toggle(t0)
	ev := r.Reset(t0.Add(45 * time.Second))
	if len(ev) != 1 || ev[0].Completed || ev[0].Actual != 45*time.Second {
		t.Fatalf("%+v", ev)
	}
}

func TestIntervalsNormalize(t *testing.T) {
	p := IntervalsPlan{Work: time.Second, Rounds: 0, Rest: -time.Second}
	p.Normalize()
	if p.Work != 5*time.Second || p.Rounds != 1 || p.Rest != 0 {
		t.Fatalf("%+v", p)
	}
}
