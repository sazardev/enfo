package cli

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
)

var (
	reHM    = regexp.MustCompile(`^(\d+)h(\d+)$`)                    // 1h30
	reClock = regexp.MustCompile(`^(\d{1,2}):(\d{2})(?::(\d{2}))?$`) // 1:30, 1:30:00 (as a duration)
)

// ParseDuration reads a countdown length: Go durations (90s, 1h30m, 25m),
// the shorthand 1h30 (hours and minutes), h:mm[:ss], and a bare number, which
// means minutes ("5" = 5 minutes, "1.5" = 90 seconds).
func ParseDuration(s string) (time.Duration, error) {
	s = strings.ToLower(strings.TrimSpace(s))
	if s == "" {
		return 0, fmt.Errorf("empty duration")
	}
	var d time.Duration
	switch {
	case reHM.MatchString(s):
		m := reHM.FindStringSubmatch(s)
		h, _ := strconv.Atoi(m[1])
		mm, _ := strconv.Atoi(m[2])
		d = time.Duration(h)*time.Hour + time.Duration(mm)*time.Minute
	case reClock.MatchString(s):
		m := reClock.FindStringSubmatch(s)
		a, _ := strconv.Atoi(m[1])
		b, _ := strconv.Atoi(m[2])
		if m[3] != "" { // h:mm:ss
			c, _ := strconv.Atoi(m[3])
			d = time.Duration(a)*time.Hour + time.Duration(b)*time.Minute + time.Duration(c)*time.Second
		} else { // m:ss
			d = time.Duration(a)*time.Minute + time.Duration(b)*time.Second
		}
	default:
		if f, err := strconv.ParseFloat(s, 64); err == nil {
			d = time.Duration(f * float64(time.Minute))
		} else if pd, err := time.ParseDuration(s); err == nil {
			d = pd
		} else {
			return 0, fmt.Errorf("can't read %q as a duration (try 25m, 90s, 1h30, 5)", s)
		}
	}
	if d <= 0 {
		return 0, fmt.Errorf("duration must be positive, got %q", s)
	}
	if d > 99*time.Hour {
		return 0, fmt.Errorf("duration %q is too long (max 99h)", s)
	}
	return d, nil
}

var dayNames = map[string]int{
	"mon": 0, "monday": 0, "lun": 0, "lunes": 0,
	"tue": 1, "tues": 1, "tuesday": 1, "mar": 1, "martes": 1,
	"wed": 2, "wednesday": 2, "mie": 2, "mié": 2, "miercoles": 2, "miércoles": 2,
	"thu": 3, "thur": 3, "thurs": 3, "thursday": 3, "jue": 3, "jueves": 3,
	"fri": 4, "friday": 4, "vie": 4, "viernes": 4,
	"sat": 5, "saturday": 5, "sab": 5, "sáb": 5, "sabado": 5, "sábado": 5,
	"sun": 6, "sunday": 6, "dom": 6, "domingo": 6,
}

// ParseDays reads a weekday list: "mon,wed,fri", "weekdays", "weekend",
// "daily"/"everyday", or "" / "once" for a one-shot alarm. Spanish names work.
func ParseDays(s string) (engine.Days, error) {
	s = strings.ToLower(strings.TrimSpace(s))
	switch s {
	case "", "once", "una", "una vez":
		return 0, nil
	case "weekdays", "weekday", "laborales", "semana":
		return engine.Weekdays, nil
	case "weekend", "weekends", "finde", "fin de semana":
		return engine.Weekend, nil
	case "daily", "everyday", "every", "diario", "todos":
		return engine.Everyday, nil
	}
	var d engine.Days
	for _, part := range strings.FieldsFunc(s, func(r rune) bool { return r == ',' || r == ' ' || r == '+' }) {
		if a, b, ok := strings.Cut(part, "-"); ok { // mon-fri
			i, ok1 := dayNames[a]
			j, ok2 := dayNames[b]
			if !ok1 || !ok2 {
				return 0, fmt.Errorf("unknown day range %q", part)
			}
			for k := i; ; k = (k + 1) % 7 {
				d |= 1 << uint(k)
				if k == j {
					break
				}
			}
			continue
		}
		i, ok := dayNames[part]
		if !ok {
			return 0, fmt.Errorf("unknown day %q (use mon,tue,... weekdays, weekend or daily)", part)
		}
		d |= 1 << uint(i)
	}
	return d, nil
}

var reTime = regexp.MustCompile(`^(\d{1,2})(?::(\d{2}))?\s*(am|pm|a|p)?$`)

// ParseClock reads a time of day: 07:30, 7:30pm, 19, 7pm.
func ParseClock(s string) (hour, min int, err error) {
	m := reTime.FindStringSubmatch(strings.ToLower(strings.TrimSpace(s)))
	if m == nil {
		return 0, 0, fmt.Errorf("can't read %q as a time (try 07:30 or 7:30pm)", s)
	}
	hour, _ = strconv.Atoi(m[1])
	if m[2] != "" {
		min, _ = strconv.Atoi(m[2])
	}
	switch m[3] {
	case "am", "a":
		if hour < 1 || hour > 12 {
			return 0, 0, fmt.Errorf("%q: hour must be 1-12 with am/pm", s)
		}
		if hour == 12 {
			hour = 0
		}
	case "pm", "p":
		if hour < 1 || hour > 12 {
			return 0, 0, fmt.Errorf("%q: hour must be 1-12 with am/pm", s)
		}
		if hour != 12 {
			hour += 12
		}
	}
	if hour > 23 || min > 59 {
		return 0, 0, fmt.Errorf("%q is not a valid time of day", s)
	}
	return hour, min, nil
}

// DaysLabel is a short human label for a weekday set.
func DaysLabel(d engine.Days) string {
	switch d {
	case 0:
		return "once"
	case engine.Weekdays:
		return "weekdays"
	case engine.Weekend:
		return "weekend"
	case engine.Everyday:
		return "daily"
	}
	names := []string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	var out []string
	for i, n := range names {
		if d&(1<<uint(i)) != 0 {
			out = append(out, n)
		}
	}
	return strings.Join(out, ",")
}
