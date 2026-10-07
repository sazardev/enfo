package ui

import (
	"math"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

// ringer is the full-screen takeover for alarms and timers: ripples spread
// from a pulsing centre until the user dismisses it (or two minutes pass).
type ringer struct {
	ann    Announce
	born   time.Time
	canvas *braille.Canvas
	last   time.Time
}

const ringTimeout = 2 * time.Minute

func newRinger(a Announce, now time.Time) *ringer { return &ringer{ann: a, born: now} }

func (r *ringer) kind() string {
	if r.ann.Kind == engine.KindAlarm {
		return "alarm"
	}
	return "timer"
}

func (r *ringer) expired(now time.Time) bool { return now.Sub(r.born) > ringTimeout }

func (r *ringer) View(a *App, w, h int) []string {
	pal := a.core.Pal
	if r.canvas == nil || r.canvas.Cols != w || r.canvas.Rows != h {
		r.canvas = braille.New(w, h)
	} else {
		r.canvas.Clear()
	}
	c := r.canvas
	t := a.core.Now.Sub(r.born).Seconds()
	cx, cy := float64(c.W)/2, float64(c.H)/2
	maxR := math.Hypot(cx, cy) * 0.8
	hot := pal.Accent
	if r.ann.Kind == engine.KindTimer || r.ann.Rest {
		hot = pal.Rest
	}
	// ripples
	const n = 6
	for i := 0; i < n; i++ {
		ph := math.Mod(t*0.55+float64(i)/n, 1)
		rad := ph * maxR
		fade := math.Pow(1-ph, 1.4)
		col := pal.Bg.Mix(hot, 0.15+0.85*fade)
		th := 2.2 * (1 - ph*0.6)
		c.Ring(cx, cy, rad, th, braille.Solid(col))
	}
	// the centre breathes in time with the buzz
	beat := math.Pow(0.5+0.5*math.Sin(t*2*math.Pi*1.4), 3)
	core := math.Min(cx, cy) * (0.22 + 0.04*beat)
	c.Disc(cx, cy, core, braille.Solid(pal.Bg.Mix(hot, 0.22+0.2*beat)))
	c.Ring(cx, cy, core, 2.2, braille.Solid(pal.PhaseHi(r.ann.Kind == engine.KindTimer || r.ann.Rest)))
	lines := c.Lines()

	// a bell in the middle: shaken left and right
	shake := 0
	if math.Mod(t, 1.2) < 0.5 {
		shake = int(math.Round(math.Sin(t*38) * 1.2))
	}
	title := bold(pal.Text, strings.ToUpper(r.ann.Title))
	body := paint(pal.Muted, r.ann.Body)
	icon := bold(hot, infoFor(string(r.ann.Kind)).Icon)
	if r.ann.Kind == engine.KindTimer {
		icon = bold(hot, iconTimer)
	}
	mid := h / 2
	put := func(row int, s string) {
		if row < 0 || row >= len(lines) {
			return
		}
		col := (w-width(s))/2 + shake
		lines[row] = stamp(lines[row], col, s)
	}
	put(mid-1, icon)
	put(mid, title)
	put(mid+1, body)
	var hint string
	if r.ann.Kind == engine.KindAlarm {
		hint = paint(pal.Muted, "enter ") + paint(pal.Text, i18n.T("ring.dismiss")) + paint(pal.Faint, "   ·   ") +
			paint(pal.Muted, "z ") + paint(pal.Text, i18n.T("ring.snooze"))
	} else if r.ann.Kind == engine.KindTimer {
		hint = paint(pal.Muted, "enter ") + paint(pal.Text, i18n.T("ring.dismiss")) + paint(pal.Faint, "   ·   ") +
			paint(pal.Muted, "r ") + paint(pal.Text, i18n.T("ring.again"))
	} else {
		hint = paint(pal.Muted, "enter ") + paint(pal.Text, i18n.T("ring.dismiss"))
	}
	put(h-3, hint)
	return lines
}

// handle returns true when the ringer should close.
func (r *ringer) handle(a *App, msg tea.Msg) (close bool) {
	k, ok := msg.(tea.KeyPressMsg)
	if !ok {
		if _, isClick := msg.(tea.MouseClickMsg); isClick {
			return true
		}
		return false
	}
	switch k.String() {
	case "z", "s":
		if r.ann.Alarm != nil {
			a.core.Alarms.Snooze(r.ann.Alarm.ID, a.core.Now)
			a.core.MarkDirty()
			a.say(i18n.T("ring.snoozed", int(engine.SnoozeFor.Minutes())))
			return true
		}
	case "r":
		if r.ann.Kind == engine.KindTimer {
			a.core.Timer.Begin(a.core.Now)
			a.core.MarkDirty()
			return true
		}
	case "enter", "space", "esc", "q":
		return true
	}
	return false
}
