package engine

import (
	"math"
	"testing"
	"time"
)

func TestClockSunTimesLondonSolstice(t *testing.T) {
	loc, _ := time.LoadLocation("Europe/London")
	rise, set, polar := ClockSunTimes(time.Date(2026, 6, 21, 12, 0, 0, 0, loc), 51.51, -0.13)
	if polar != 0 {
		t.Fatalf("polar = %d", polar)
	}
	// sunrise ~04:43 BST, sunset ~21:21 BST
	hr := func(x time.Time) float64 { return float64(x.Hour()) + float64(x.Minute())/60 }
	if math.Abs(hr(rise)-4.72) > 0.2 || math.Abs(hr(set)-21.35) > 0.2 {
		t.Fatalf("rise %v set %v", rise.Format("15:04"), set.Format("15:04"))
	}
}

func TestClockSunTimesPolar(t *testing.T) {
	_, _, p := ClockSunTimes(time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC), 78, 15)
	if p != 1 {
		t.Fatalf("Svalbard in June should be polar day, got %d", p)
	}
	_, _, p = ClockSunTimes(time.Date(2026, 12, 21, 12, 0, 0, 0, time.UTC), 78, 15)
	if p != -1 {
		t.Fatalf("Svalbard in December should be polar night, got %d", p)
	}
}

func TestClockMoonPhase(t *testing.T) {
	// full moon on 2026-06-29/30 ~ phase near 0.5
	p := ClockMoonPhase(time.Date(2026, 6, 29, 23, 0, 0, 0, time.UTC))
	if p < 0.42 || p > 0.58 {
		t.Fatalf("phase %.2f", p)
	}
}

func TestClockSunTimesFarEast(t *testing.T) {
	loc, _ := time.LoadLocation("Asia/Tokyo")
	rise, set, _ := ClockSunTimes(time.Date(2026, 6, 21, 12, 0, 0, 0, loc), 35.68, 139.69)
	hr := func(x time.Time) float64 { return float64(x.Hour()) + float64(x.Minute())/60 }
	// Tokyo, June solstice: sunrise ~04:25 JST, sunset ~19:00 JST
	if math.Abs(hr(rise)-4.42) > 0.25 || math.Abs(hr(set)-19.0) > 0.25 {
		t.Fatalf("rise %v set %v", rise.Format("15:04"), set.Format("15:04"))
	}
}

func TestClockSunTimesWest(t *testing.T) {
	loc, _ := time.LoadLocation("America/Mexico_City")
	rise, set, _ := ClockSunTimes(time.Date(2026, 10, 7, 12, 0, 0, 0, loc), 19.43, -99.13)
	hr := func(x time.Time) float64 { return float64(x.Hour()) + float64(x.Minute())/60 }
	// Mexico City, early October: ~06:35 and ~18:25 local
	if math.Abs(hr(rise)-6.58) > 0.3 || math.Abs(hr(set)-18.4) > 0.3 {
		t.Fatalf("rise %v set %v", rise.Format("15:04"), set.Format("15:04"))
	}
}
