package ui

import (
	"strings"
	"testing"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/store"
)

func worldTestCore(t *testing.T) *Core {
	t.Helper()
	t.Setenv("ENFO_CONFIG_DIR", t.TempDir())
	t.Setenv("ENFO_STATE_DIR", t.TempDir())
	st, err := store.Open()
	if err != nil {
		t.Fatal(err)
	}
	c := NewCore(st, time.Date(2026, 10, 7, 14, 30, 0, 0, time.UTC))
	c.Cfg.Cities = []string{"Europe/Madrid", "America/New_York", "Asia/Tokyo", "Australia/Sydney", "America/Mexico_City"}
	return c
}

func worldCheck(t *testing.T, m *worldMode, state string) {
	t.Helper()
	sizes := [][2]int{{1, 1}, {2, 2}, {10, 3}, {24, 7}, {30, 10}, {39, 13}, {40, 14}, {55, 16}, {60, 20}, {76, 22}, {80, 24}, {99, 19}, {100, 20}, {120, 30}, {160, 40}, {250, 70}, {251, 21}, {101, 69}}
	for _, s := range sizes {
		w, h := s[0], s[1]
		out := m.View(w, h)
		lines := strings.Split(out, "\n")
		if len(lines) != h {
			t.Fatalf("%s %dx%d: %d lines", state, w, h, len(lines))
		}
		for i, l := range lines {
			if got := ansi.StringWidth(l); got != w {
				t.Fatalf("%s %dx%d: line %d is %d wide: %q", state, w, h, i, got, ansi.Strip(l))
			}
		}
	}
}

func TestWorldRendersEverywhere(t *testing.T) {
	c := worldTestCore(t)
	m := newWorld(c, func(string) {})
	c.Step(c.Now, 33*time.Millisecond)
	worldCheck(t, m, "browse")

	m.Update(tea.KeyPressMsg{Code: 'a', Text: "a"})
	if !m.Capturing() {
		t.Fatal("picker must capture keys")
	}
	worldCheck(t, m, "picker")
	m.Update(tea.KeyPressMsg{Code: tea.KeyEscape})
	if m.Capturing() {
		t.Fatal("esc leaves the picker")
	}

	m.Update(tea.KeyPressMsg{Code: 'm', Text: "m"})
	if m.state != worldPlan || !m.Capturing() {
		t.Fatal("planner should open")
	}
	worldCheck(t, m, "planner")
	m.Update(tea.KeyPressMsg{Code: tea.KeyRight})
	if m.planHour != 15 {
		t.Fatalf("planner hour %d", m.planHour)
	}
	m.Update(tea.KeyPressMsg{Code: tea.KeyEscape})

	m.Update(tea.KeyPressMsg{Code: 'x', Text: "x"})
	if m.state != worldConfirm {
		t.Fatal("x asks to confirm")
	}
	worldCheck(t, m, "confirm")
	m.Update(tea.KeyPressMsg{Code: 'n', Text: "n"})
	if len(c.Cfg.Cities) != 5 {
		t.Fatal("n must keep the city")
	}
}

func TestWorldEmptyAndStill(t *testing.T) {
	c := worldTestCore(t)
	c.Cfg.Motion = "still"
	m := newWorld(c, func(string) {})
	c.Cfg.Cities = []string{"nowhere/atlantis"}
	worldCheck(t, m, "empty")
}

func TestWorldPickerAddAndRemove(t *testing.T) {
	c := worldTestCore(t)
	var said []string
	m := newWorld(c, func(s string) { said = append(said, s) })

	m.Update(tea.KeyPressMsg{Code: 'a', Text: "a"})
	for _, r := range "bogota" {
		m.Update(tea.KeyPressMsg{Code: r, Text: string(r)})
	}
	if len(m.pick) == 0 || m.pick[0].ID != "America/Bogota" {
		t.Fatalf("filter: %+v", m.pick)
	}
	m.Update(tea.KeyPressMsg{Code: tea.KeyEnter})
	if got := c.Cfg.Cities[len(c.Cfg.Cities)-1]; got != "America/Bogota" {
		t.Fatalf("not added: %v", c.Cfg.Cities)
	}
	if m.sel != len(c.Cfg.Cities)-1 {
		t.Fatal("new city should be selected")
	}
	// remove it again
	m.Update(tea.KeyPressMsg{Code: 'x', Text: "x"})
	m.Update(tea.KeyPressMsg{Code: 'y', Text: "y"})
	if len(c.Cfg.Cities) != 5 || m.sel != 4 {
		t.Fatalf("remove: %v sel=%d", c.Cfg.Cities, m.sel)
	}
	if len(said) < 2 {
		t.Fatalf("toasts: %v", said)
	}
}

func TestWorldReorderKeepsSelection(t *testing.T) {
	c := worldTestCore(t)
	m := newWorld(c, func(string) {})
	m.Update(tea.KeyPressMsg{Code: tea.KeyDown})
	m.Update(tea.KeyPressMsg{Code: 'K', Text: "K"})
	if c.Cfg.Cities[0] != "America/New_York" || m.sel != 0 {
		t.Fatalf("K: %v sel=%d", c.Cfg.Cities, m.sel)
	}
	m.Update(tea.KeyPressMsg{Code: 'J', Text: "J"})
	if c.Cfg.Cities[1] != "America/New_York" || m.sel != 1 {
		t.Fatalf("J: %v sel=%d", c.Cfg.Cities, m.sel)
	}
}

func TestWorldFilterIsAccentAndLanguageBlind(t *testing.T) {
	for _, q := range []string{"mexico", "méxico", "Ciudad de Mex", "mexico city"} {
		got := worldFilter(q, "es")
		if len(got) == 0 || got[0].ID != "America/Mexico_City" {
			t.Errorf("%q -> %v", q, got)
		}
	}
	if n := len(worldFilter("", "en")); n != len(engine.Cities) {
		t.Errorf("empty query lists %d of %d", n, len(engine.Cities))
	}
	if got := worldFilter("zzzz", "en"); len(got) != 0 {
		t.Errorf("zzzz matched %v", got)
	}
}

func TestWorldOffsetText(t *testing.T) {
	cases := map[int]string{0: "·", 3 * 3600: "+3h", -5 * 3600: "-5h", 5*3600 + 1800: "+5:30", -(9*3600 + 1800): "-9:30"}
	for in, want := range cases {
		if got := worldOffset(in); got != want {
			t.Errorf("worldOffset(%d) = %q, want %q", in, got, want)
		}
	}
}

func TestWorldSunTimes(t *testing.T) {
	madrid, _ := engine.CityByID("Europe/Madrid")
	loc := madrid.Loc()
	day := time.Date(2026, 6, 21, 12, 0, 0, 0, loc)
	rise, set, polar := worldSunTimes(madrid.Lat, madrid.Lon, day)
	if polar != 0 {
		t.Fatal("no polar day in Madrid")
	}
	near := func(got time.Time, h, m int) {
		t.Helper()
		want := time.Date(2026, 6, 21, h, m, 0, 0, loc)
		if d := got.Sub(want); d < -12*time.Minute || d > 12*time.Minute {
			t.Errorf("got %s, want about %02d:%02d", got.Format("15:04"), h, m)
		}
	}
	near(rise, 6, 47)
	near(set, 21, 42)

	// midnight sun / polar night in Reykjavik-ish and far north
	if _, _, p := worldSunTimes(78, 15, time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC)); p != 1 {
		t.Errorf("Svalbard in June: %d", p)
	}
	if _, _, p := worldSunTimes(78, 15, time.Date(2026, 12, 21, 12, 0, 0, 0, time.UTC)); p != -1 {
		t.Errorf("Svalbard in December: %d", p)
	}
	// near the equinox every place has about 12 hours of light
	quito, _ := engine.CityByID("America/Guayaquil")
	r, s, _ := worldSunTimes(quito.Lat, quito.Lon, time.Date(2026, 3, 20, 12, 0, 0, 0, quito.Loc()))
	if d := s.Sub(r); d < 11*time.Hour+40*time.Minute || d > 12*time.Hour+30*time.Minute {
		t.Errorf("Quito equinox daylight %v", d)
	}
}

func TestWorldMapMarksCities(t *testing.T) {
	c := worldTestCore(t)
	m := newWorld(c, func(string) {})
	cities := m.cities()
	block := m.mapBlock(cities, 100, worldIdealRows(100))
	if len(block) != worldIdealRows(100) {
		t.Fatalf("rows %d", len(block))
	}
	if len(m.mapv.marks) != len(cities) {
		t.Fatalf("marks %d for %d cities", len(m.mapv.marks), len(cities))
	}
	// a map of a few dozen columns still has land
	m.mapBlock(cities, 24, worldIdealRows(24))
	lit := 0
	for _, b := range m.mapv.landBits {
		if b != 0 {
			lit++
		}
	}
	if lit == 0 {
		t.Fatal("no land at small size")
	}
}

func TestWorldFrameCostIsSmall(t *testing.T) {
	c := worldTestCore(t)
	m := newWorld(c, func(string) {})
	m.View(160, 45) // builds the sampled mask
	start := time.Now()
	const n = 60
	for i := 0; i < n; i++ {
		c.Step(c.Now.Add(33*time.Millisecond), 33*time.Millisecond)
		m.Frame(33 * time.Millisecond)
		m.View(160, 45)
	}
	per := time.Since(start) / n
	t.Logf("world frame at 160x45: %v", per)
	if per > 15*time.Millisecond {
		t.Errorf("a frame costs %v; the 30 fps budget is 33 ms", per)
	}
}
