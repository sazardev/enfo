package engine

import (
	"testing"
	"time"
)

func TestKitchenParse(t *testing.T) {
	cases := []struct {
		in    string
		d     time.Duration
		label string
		ok    bool
	}{
		{"10m pasta", 10 * time.Minute, "pasta", true},
		{"pasta 10m", 10 * time.Minute, "pasta", true},
		{"1h30 roast", 90 * time.Minute, "roast", true},
		{"90 tea", 90 * time.Minute, "tea", true},
		{"45s egg", 45 * time.Second, "egg", true},
		{"5:30", 5*time.Minute + 30*time.Second, "", true},
		{"1:05:00 stew", time.Hour + 5*time.Minute, "stew", true},
		{"1.5h", 90 * time.Minute, "", true},
		{"2m30s", 2*time.Minute + 30*time.Second, "", true},
		{"just words", 0, "just words", false},
		{"0", 0, "0", false},
	}
	for _, c := range cases {
		d, l, ok := KitchenParse(c.in)
		if d != c.d || l != c.label || ok != c.ok {
			t.Errorf("%q -> %v %q %v", c.in, d, l, ok)
		}
	}
}

func TestKitchenLifecycle(t *testing.T) {
	var k Kitchen
	now := time.Date(2026, 10, 7, 12, 0, 0, 0, time.UTC)
	a := k.Add("pasta", 10*time.Minute, now)
	b := k.Add("tea", 3*time.Minute, now)
	if ord := k.Order(now); ord[0].ID != b.ID {
		t.Fatal("soonest first")
	}
	k.Toggle(b.ID, now.Add(time.Minute)) // pause tea with 2m left
	if b.Remaining(now.Add(time.Hour)) != 2*time.Minute {
		t.Fatal("paused holds time")
	}
	if ord := k.Order(now); ord[0].ID != a.ID {
		t.Fatal("running before paused")
	}
	fin := k.Tick(now.Add(10*time.Minute + time.Second))
	if len(fin) != 1 || fin[0].Timer.ID != a.ID || fin[0].Late {
		t.Fatalf("finish: %+v", fin)
	}
	if !a.Done || a.Remaining(now.Add(time.Hour)) != 0 {
		t.Fatal("done state")
	}
	late := k.Add("old", time.Minute, now)
	if f := k.Tick(now.Add(time.Hour)); len(f) != 1 || !f[0].Late || f[0].Timer.ID != late.ID {
		t.Fatalf("late: %+v", f)
	}
	k.AddTime(a.ID, 5*time.Minute, now.Add(time.Hour)) // revive
	if a.Done || a.Run != Running || a.Remaining(now.Add(time.Hour)) != 5*time.Minute {
		t.Fatalf("revive: %+v", a)
	}
	k.Reset(a.ID, now.Add(time.Hour+time.Minute))
	if a.Run != Idle || a.Left != a.Total {
		t.Fatal("reset")
	}
	k.Delete(a.ID)
	if k.Get(a.ID) != nil {
		t.Fatal("delete")
	}
}

func TestVersusClock(t *testing.T) {
	now := time.Date(2026, 10, 7, 12, 0, 0, 0, time.UTC)
	g := NewVersus(5*time.Minute, 2*time.Second, 0)
	g.Begin(0, now)
	if g.Remaining(0, now.Add(10*time.Second)) != 290*time.Second || g.Remaining(1, now.Add(10*time.Second)) != 300*time.Second {
		t.Fatal("only the active clock runs")
	}
	g.Press(now.Add(10 * time.Second))
	if g.Left[0] != 292*time.Second || g.Active != 1 || g.Moves[0] != 1 {
		t.Fatalf("press: %+v", g)
	}
	g.Pause(now.Add(20 * time.Second))
	if g.Remaining(1, now.Add(time.Hour)) != 290*time.Second {
		t.Fatal("pause holds")
	}
	g.Resume(now.Add(time.Hour))
	if f, p := g.Tick(now.Add(time.Hour + 291*time.Second)); !f || p != 1 || g.State != VersusFlag {
		t.Fatal("flag")
	}
}

func TestVersusDelay(t *testing.T) {
	now := time.Date(2026, 10, 7, 12, 0, 0, 0, time.UTC)
	g := NewVersus(time.Minute, 0, 5*time.Second)
	g.Begin(1, now)
	if g.Remaining(1, now.Add(4*time.Second)) != time.Minute {
		t.Fatal("clock must not move inside the delay")
	}
	if in, left := g.InDelay(now.Add(2 * time.Second)); !in || left != 3*time.Second {
		t.Fatal("delay window")
	}
	if g.Remaining(1, now.Add(15*time.Second)) != 50*time.Second {
		t.Fatal("after the delay it counts")
	}
}
