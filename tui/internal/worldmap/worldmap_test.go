package worldmap

import "testing"

func TestCoverage(t *testing.T) {
	// whole world is roughly a third land in this projection (Antarctica is big)
	all := Coverage(-180, 90, 180, -90)
	if all < 0.28 || all > 0.38 {
		t.Fatalf("total land %.3f", all)
	}
	cases := []struct {
		name     string
		lon, lat float64
		land     bool
	}{
		{"Sahara", 10, 25, true},
		{"Siberia", 100, 62, true},
		{"Amazon", -62, -5, true},
		{"Australia", 134, -25, true},
		{"Pacific", -150, 0, false},
		{"Atlantic", -30, 30, false},
		{"Indian ocean", 80, -30, false},
	}
	for _, c := range cases {
		v := Coverage(c.lon-0.4, c.lat+0.4, c.lon+0.4, c.lat-0.4)
		if c.land && v < 0.9 || !c.land && v > 0.1 {
			t.Errorf("%s: coverage %.2f", c.name, v)
		}
	}
	// a tiny box samples a pixel
	if v := Coverage(10, 25, 10.001, 24.999); v < 0.999 {
		t.Errorf("pixel sample %.2f", v)
	}
}
