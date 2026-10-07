// Package ui is the Bubble Tea application: a header of animated tabs, one
// screen per mode, overlays (help, toasts, the ringer) and the plumbing that
// keeps every engine ticking whichever mode is on screen.
package ui

import (
	"fmt"
	"time"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/notify"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// Announce is something that finished and wants the user's attention.
type Announce struct {
	Kind  engine.Kind
	Title string
	Body  string
	Ring  bool // takes over the screen until dismissed (alarms, timers)
	Rest  bool // the phase that just *started* is a rest (colors the toast)
	Alarm *engine.Alarm
	Away  bool // happened while Enfo was closed
}

// Core is the state shared by every mode: configuration, the engines, the
// clock and the palette. Modes hold a *Core and call its methods; nothing in
// here knows about drawing.
type Core struct {
	Cfg   store.Config
	Store *store.Store
	Pal   theme.Palette

	Pomo   *engine.Pomodoro
	Timer  *engine.Timer
	SW     *engine.Stopwatch
	Alarms *engine.Alarms

	Now   time.Time // the frame's clock
	Dt    time.Duration
	Anim  float64 // continuous seconds since start, for visuals
	Frame uint64

	events   []engine.Event // history cache (newest last)
	dirty    bool
	saved    time.Time
	announce []Announce
	W, H     int
	LastMode string // the mode on screen when Enfo was last closed
	bell     bool   // a bell was requested (the app turns it into tea.Raw)
	cfgGen   int    // bumped when the configuration changed (modes reload)
	bg       braille.RGB
	dark     bool
}

// NewCore loads settings and state from disk and catches the engines up with
// the time that passed while Enfo was closed.
func NewCore(st *store.Store, now time.Time) *Core {
	cfg, _ := st.LoadConfig()
	c := &Core{Cfg: cfg, Store: st, Now: now}
	i18n.Set(cfg.Lang)
	c.bg, c.dark = braille.Hex("16141a"), true
	c.Pal = theme.New(theme.Resolve(cfg.Accent), c.bg, c.dark)

	s := st.LoadState()
	c.Pomo, c.Timer, c.SW = s.Pomodoro, s.Timer, s.Stopwatch
	c.LastMode = s.LastMode
	c.Alarms = &s.Alarms
	if c.Pomo == nil {
		c.Pomo = engine.NewPomodoro(cfg.Pomodoro())
	} else {
		c.Pomo.SetConfig(cfg.Pomodoro())
	}
	if c.Timer == nil {
		c.Timer = engine.NewTimer(5 * time.Minute)
	}
	if c.SW == nil {
		c.SW = &engine.Stopwatch{}
	}
	c.events = st.Events()
	// Anything that finished while we were away is logged and summarised, not
	// rung one by one.
	c.catchUp(now)
	return c
}

func (c *Core) catchUp(now time.Time) {
	var away []engine.Event
	away = append(away, c.Pomo.Tick(now)...)
	away = append(away, c.Timer.Tick(now)...)
	for _, r := range c.Alarms.Tick(now) {
		away = append(away, engine.Event{Kind: engine.KindAlarm, Label: r.Alarm.Label, Start: r.At, Completed: !r.Missed, Late: true})
	}
	if len(away) == 0 {
		return
	}
	c.Log(away...)
	last := away[len(away)-1]
	c.announce = append(c.announce, Announce{
		Kind: last.Kind, Away: true,
		Title: i18n.T("away.title"),
		Body:  i18n.T("away.body", len(away), last.Start.Add(last.Actual).Format("15:04")),
	})
}

// Log records events in the history (memory and disk).
func (c *Core) Log(evs ...engine.Event) {
	if len(evs) == 0 {
		return
	}
	c.events = append(c.events, evs...)
	_ = c.Store.AppendEvents(evs...)
	c.dirty = true
}

func (c *Core) Events() []engine.Event { return c.events }

// MarkDirty asks for the state to be written soon.
func (c *Core) MarkDirty() { c.dirty = true }

// Save writes the live state of every mode.
func (c *Core) Save() {
	_ = c.Store.SaveState(store.State{
		Pomodoro: c.Pomo, Timer: c.Timer, Stopwatch: c.SW, Alarms: *c.Alarms, LastMode: c.LastMode,
	})
	c.dirty = false
	c.saved = c.Now
}

// Step advances the clock one frame and ticks every engine. What finished is
// queued; the app drains it with Announcements.
func (c *Core) Step(now time.Time, dt time.Duration) {
	c.Now, c.Dt = now, dt
	c.Anim += dt.Seconds()
	c.Frame++

	for _, e := range c.Pomo.Tick(now) {
		c.Log(e)
		if e.Late {
			continue
		}
		next := c.Pomo.Phase
		a := Announce{Kind: e.Kind, Rest: next.IsRest()}
		switch e.Kind {
		case engine.KindFocus:
			a.Title = i18n.T("done.focus")
			if next == engine.Long {
				a.Body = i18n.T("done.focus.long", fmtDur(c.Pomo.Cfg.Long))
			} else {
				a.Body = i18n.T("done.focus.rest", fmtDur(c.Pomo.Cfg.Rest))
			}
		default:
			a.Title = i18n.T("done.rest")
			a.Body = i18n.T("done.rest.body")
		}
		c.announce = append(c.announce, a)
	}
	for _, e := range c.Timer.Tick(now) {
		c.Log(e)
		if e.Late {
			continue
		}
		body := fmtDur(e.Planned)
		if e.Label != "" {
			body = e.Label + " · " + body
		}
		c.announce = append(c.announce, Announce{Kind: engine.KindTimer, Title: i18n.T("done.timer"), Body: body, Ring: true})
	}
	for _, r := range c.Alarms.Tick(now) {
		alarm := r.Alarm
		c.Log(engine.Event{Kind: engine.KindAlarm, Label: alarm.Label, Start: r.At, Completed: !r.Missed, Late: r.Missed})
		c.dirty = true
		if r.Missed {
			continue
		}
		title := alarm.Label
		if title == "" {
			title = i18n.T("alarm.default")
		}
		c.announce = append(c.announce, Announce{
			Kind: engine.KindAlarm, Title: title, Body: fmt.Sprintf("%02d:%02d", alarm.Hour, alarm.Min),
			Ring: true, Alarm: &alarm,
		})
	}
	if c.dirty && now.Sub(c.saved) > 2*time.Second {
		c.Save()
	}
}

// Announcements drains what finished since the last call.
func (c *Core) Announcements() []Announce {
	a := c.announce
	c.announce = nil
	return a
}

// Anything running that the footer should show while another mode is open.
type Running struct {
	Mode   string // mode id
	Icon   string
	Text   string
	Rest   bool
	Paused bool
}

// Runners lists the active timers (for the footer chips).
func (c *Core) Runners() []Running {
	var out []Running
	now := c.Now
	if c.Pomo.Active() {
		ph := i18n.T("phase." + string(c.Pomo.Phase))
		out = append(out, Running{Mode: "pomodoro", Icon: iconPomodoro, Text: ph + " " + clockText(c.Pomo.Remaining(now)),
			Rest: c.Pomo.Phase.IsRest(), Paused: c.Pomo.Run == engine.Paused})
	}
	if c.Timer.Active() {
		out = append(out, Running{Mode: "timer", Icon: iconTimer, Text: clockText(c.Timer.Remaining(now)), Paused: c.Timer.Run == engine.Paused})
	}
	if c.SW.Run == engine.Running {
		out = append(out, Running{Mode: "stopwatch", Icon: iconStopwatch, Text: swText(c.SW.Elapsed(now), false)})
	}
	if a, at := c.Alarms.Next(); a != nil && at.Sub(now) < 12*time.Hour {
		out = append(out, Running{Mode: "alarm", Icon: iconAlarm, Text: at.In(now.Location()).Format("15:04")})
	}
	return out
}

// Beep plays a sound, and asks the app for the terminal bell when there is no
// sound player. Safe to call from anywhere (modes' Step included).
func (c *Core) Beep(name string) {
	if c.Sound(name) {
		c.bell = true
	}
}

// Sound plays a sound and rings the terminal bell if there is no player.
// It reports whether the bell should be rung by the caller.
func (c *Core) Sound(name string) (bell bool) {
	if c.Cfg.Sound && notify.Play(name) {
		return false
	}
	return c.Cfg.Bell
}

// ------------------------------------------------------------- formatting

func ceilSecs(d time.Duration) int {
	if d < 0 {
		d = 0
	}
	return int((d + time.Second - 1) / time.Second)
}

// clockText formats a countdown: 24:13, or 1:05:00 from an hour up.
func clockText(d time.Duration) string {
	s := ceilSecs(d)
	h, m, sec := s/3600, s%3600/60, s%60
	if h > 0 {
		return fmt.Sprintf("%d:%02d:%02d", h, m, sec)
	}
	return fmt.Sprintf("%02d:%02d", m, sec)
}

// swText formats a stopwatch reading (hundredths when withCS).
func swText(d time.Duration, withCS bool) string {
	if d < 0 {
		d = 0
	}
	cs := int(d/(10*time.Millisecond)) % 100
	s := int(d / time.Second)
	h, m, sec := s/3600, s%3600/60, s%60
	var out string
	if h > 0 {
		out = fmt.Sprintf("%d:%02d:%02d", h, m, sec)
	} else {
		out = fmt.Sprintf("%02d:%02d", m, sec)
	}
	if withCS {
		out += fmt.Sprintf(".%02d", cs)
	}
	return out
}

// fmtDur is a human duration: 25m, 1h 05m, 45s.
func fmtDur(d time.Duration) string {
	s := int(d.Round(time.Second) / time.Second)
	h, m, sec := s/3600, s%3600/60, s%60
	switch {
	case h > 0 && m > 0:
		return fmt.Sprintf("%dh %02dm", h, m)
	case h > 0:
		return fmt.Sprintf("%dh", h)
	case m > 0 && sec > 0:
		return fmt.Sprintf("%dm %02ds", m, sec)
	case m > 0:
		return fmt.Sprintf("%dm", m)
	}
	return fmt.Sprintf("%ds", sec)
}

// ApplyConfig makes a changed Cfg take effect everywhere (language, palette,
// rhythm, enabled modes) and writes it to disk. Call it after editing c.Cfg.
func (c *Core) ApplyConfig() {
	c.Cfg.Normalize()
	i18n.Set(c.Cfg.Lang)
	dark := c.dark
	switch c.Cfg.Theme {
	case "dark":
		dark = true
	case "light":
		dark = false
	}
	c.Pal = theme.New(theme.Resolve(c.Cfg.Accent), c.bg, dark)
	c.Pomo.SetConfig(c.Cfg.Pomodoro())
	_ = c.Store.SaveConfig(c.Cfg)
	c.cfgGen++
	c.dirty = true
}
