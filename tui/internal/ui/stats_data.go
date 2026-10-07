package ui

import (
	"time"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// statsWindow is how far back the heat map and every aggregate can look.
const statsWindow = 26 * 7

// statsData is everything the page shows, computed once per change.
type statsData struct {
	events  []engine.Event
	ghost   bool
	all     engine.Summary // the whole 26-week window
	rng     engine.Summary // the selected range
	hourly  [24]time.Duration
	weekday [7]time.Duration
	kinds   []engine.StatsKind
	comp    float64
	hasComp bool
	best    int
	hasBest bool
}

func statsCompute(events []engine.Event, now time.Time, rng int, ghost bool) *statsData {
	d := &statsData{events: events, ghost: ghost}
	d.all = engine.Summarize(events, now, statsWindow)
	d.rng = engine.Summarize(events, now, rng)
	d.hourly = engine.StatsHourly(events, now, rng)
	d.weekday = engine.StatsWeekdays(events, now, rng)
	d.kinds = engine.StatsKinds(events, now, rng)
	d.comp, d.hasComp = engine.StatsCompletion(d.rng)
	d.best, d.hasBest = engine.StatsBestHour(d.hourly)
	return d
}

// statsGhostEvents invents a believable month of focus so an empty page can
// still show what it will look like. Deterministic, never saved.
func statsGhostEvents(now time.Time) []engine.Event {
	var out []engine.Event
	day := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	for i := 0; i < 120; i++ {
		d := day.AddDate(0, 0, -i)
		wd := int(d.Weekday())
		r := anim.Hash01(uint32(i*7 + 3))
		if (wd == 0 || wd == 6) && r < 0.6 {
			continue
		}
		if r < 0.12 {
			continue
		}
		n := 1 + int(anim.Hash01(uint32(i*13+5))*5)
		if i > 60 {
			n = (n + 1) / 2
		}
		hour := 8 + int(anim.Hash01(uint32(i*3+1))*3)
		t := d.Add(time.Duration(hour) * time.Hour)
		for k := 0; k < n; k++ {
			ok := anim.Hash01(uint32(i*31+k)) > 0.15
			out = append(out, engine.Event{Kind: engine.KindFocus, Start: t, Planned: 25 * time.Minute,
				Actual: 25 * time.Minute, Completed: ok})
			t = t.Add(30*time.Minute + time.Duration(k/3)*20*time.Minute)
			if k == 2 {
				t = t.Add(time.Hour)
			}
		}
	}
	return out
}

// ------------------------------------------------------------- formatting

// statsDur is a duration for a card: 1h 05m, 25m, <1m, 0m.
func statsDur(d time.Duration) string {
	switch {
	case d <= 0:
		return "0m"
	case d < time.Minute:
		return "<1m"
	}
	return fmtDur(d.Round(time.Minute))
}

func statsDate(t time.Time) string {
	if i18n.Lang() == "es" {
		return spanishDate(t)
	}
	return t.Format("Mon 2 Jan")
}

func statsWeekdayName(wd time.Weekday) string {
	if i18n.Lang() == "es" {
		return esDays[wd]
	}
	return wd.String()[:3]
}

func statsMonthName(m time.Month) string {
	if i18n.Lang() == "es" {
		return esMonths[m-1]
	}
	return m.String()[:3]
}

func statsPlural(n int, one, many string) string {
	if n == 1 {
		return i18n.T(one)
	}
	return i18n.T(many, n)
}

// statsKindIcon / statsKindColor give each tool its glyph and tint.
func statsKindIcon(k engine.Kind) string {
	switch k {
	case engine.KindFocus:
		return "◔"
	case engine.KindRest:
		return "◡"
	case engine.KindLong:
		return "◠"
	case engine.KindTimer:
		return "⏲"
	case engine.KindStopwatch:
		return "⏱"
	case engine.KindAlarm:
		return "⏰"
	case engine.KindBreathe:
		return "❋"
	}
	return "•"
}

func statsKindColor(p theme.Palette, k engine.Kind) braille.RGB {
	switch k {
	case engine.KindFocus:
		return p.Accent
	case engine.KindRest, engine.KindLong:
		return p.Rest
	case engine.KindTimer:
		return p.Warn
	case engine.KindStopwatch:
		return p.Sun
	case engine.KindAlarm:
		return p.Bad
	case engine.KindBreathe:
		return p.Good
	}
	return p.Muted
}

// statsDim washes a palette toward the background (the ghost preview).
func statsDim(p theme.Palette, k float64) theme.Palette {
	m := func(c braille.RGB) braille.RGB { return p.Bg.Mix(c, k) }
	p.Accent, p.Bright, p.Soft = m(p.Accent), m(p.Bright), m(p.Soft)
	p.Rest, p.RestHi = m(p.Rest), m(p.RestHi)
	p.Text, p.Muted, p.Good, p.Warn, p.Bad, p.Sun, p.Moon = m(p.Text), m(p.Muted), m(p.Good), m(p.Warn), m(p.Bad), m(p.Sun), m(p.Moon)
	p.Gradient = braille.Gradient{p.Accent, p.Bright}
	return p
}

// statsHBar draws a horizontal bar of w cells at half-cell resolution over a
// faint track.
func statsHBar(frac float64, w int, col, track braille.RGB) string {
	if w <= 0 {
		return ""
	}
	frac = anim.Clamp01(frac)
	halves := int(frac*float64(w*2) + 0.5)
	if frac > 0 && halves == 0 {
		halves = 1
	}
	out := ""
	for i := 0; i < w; i++ {
		switch {
		case halves >= 2:
			out += paint(col, "⣿")
			halves -= 2
		case halves == 1:
			out += paint(col, "⡇")
			halves = 0
		default:
			out += paint(track, "⣀")
		}
	}
	return out
}

// statsBlank is blank that tolerates negative sizes.
func statsBlank(w, h int) []string {
	if h < 0 {
		h = 0
	}
	if w < 0 {
		w = 0
	}
	return blank(w, h)
}
