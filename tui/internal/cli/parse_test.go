package cli

import (
	"testing"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
)

func TestParseDuration(t *testing.T) {
	ok := map[string]time.Duration{
		"10m": 10 * time.Minute, "90s": 90 * time.Second, "1h30": 90 * time.Minute, "1h30m": 90 * time.Minute,
		"5": 5 * time.Minute, "1.5": 90 * time.Second, "25:00": 25 * time.Minute, "1:30:00": 90 * time.Minute,
		" 2H ": 2 * time.Hour, "0:45": 45 * time.Second,
	}
	for in, want := range ok {
		got, err := ParseDuration(in)
		if err != nil || got != want {
			t.Errorf("ParseDuration(%q) = %v, %v; want %v", in, got, err, want)
		}
	}
	for _, in := range []string{"", "abc", "0", "-5m", "500h", "m"} {
		if d, err := ParseDuration(in); err == nil {
			t.Errorf("ParseDuration(%q) = %v, want error", in, d)
		}
	}
}

func TestParseDays(t *testing.T) {
	cases := map[string]engine.Days{
		"": 0, "once": 0, "weekdays": engine.Weekdays, "weekend": engine.Weekend, "daily": engine.Everyday,
		"mon,wed,fri": 0b0010101, "lun,mié": 0b0000101, "mon-fri": engine.Weekdays, "sat sun": engine.Weekend,
		"fri-mon": 0b1110001,
	}
	for in, want := range cases {
		got, err := ParseDays(in)
		if err != nil || got != want {
			t.Errorf("ParseDays(%q) = %07b, %v; want %07b", in, got, err, want)
		}
	}
	if _, err := ParseDays("funday"); err == nil {
		t.Error("funday should fail")
	}
}

func TestParseClock(t *testing.T) {
	cases := map[string][2]int{"07:30": {7, 30}, "7:30pm": {19, 30}, "12am": {0, 0}, "12pm": {12, 0}, "19": {19, 0}, "7 pm": {19, 0}}
	for in, want := range cases {
		h, m, err := ParseClock(in)
		if err != nil || h != want[0] || m != want[1] {
			t.Errorf("ParseClock(%q) = %d:%d, %v; want %v", in, h, m, err, want)
		}
	}
	for _, in := range []string{"25:00", "7:60", "13pm", "x", ""} {
		if _, _, err := ParseClock(in); err == nil {
			t.Errorf("ParseClock(%q) should fail", in)
		}
	}
}
