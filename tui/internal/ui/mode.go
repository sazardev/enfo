package ui

import (
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
)

// Mode is one screen of the toolbox (Pomodoro, Clock, Timer ...).
type Mode interface {
	ID() string
	// Update receives key and mouse messages while the mode is on screen.
	// Mouse coordinates are relative to the mode's body.
	Update(msg tea.Msg) tea.Cmd
	// Frame advances the animation by dt; called every frame while visible.
	Frame(dt time.Duration)
	// View draws the body in w x h cells.
	View(w, h int) string
	// Help lists the mode's keys for the footer.
	Help() []key.Binding
	// Animated reports whether the screen needs smooth frames right now; a
	// still screen is redrawn only once per second.
	Animated() bool
}

// Announcer is implemented by modes that react when something finishes
// (confetti on the Pomodoro dial).
type Announcer interface {
	Celebrate(a Announce)
}

// Background is implemented by modes whose timers keep running while another
// tab is on screen (kitchen timers, intervals, break reminders...). Step runs
// every frame for every enabled mode, visible or not; whatever it returns is
// announced (toast, notification, sound, full-screen ringer when Ring is set).
// Runner is the chip shown in the footer while another mode is open (nil when
// the mode has nothing running).
type Background interface {
	Step(now time.Time, dt time.Duration) []Announce
	Runner() *Running
}

// Titled lets a mode put live info in the window title.
type Titled interface {
	Title() string
}

// Capturer is implemented by modes with a text field or an open editor: while
// Capturing is true every key goes to the mode (no global shortcuts, not even
// q, a digit or esc).
type Capturer interface {
	Capturing() bool
}

// Page is a screen that is not a tab (stats, settings): it replaces the body
// until it reports Done.
type Page interface {
	Mode
	Done() bool
}

// ModeFactory builds a mode. say shows a one-line toast.
type ModeFactory func(c *Core, say func(string)) Mode

var (
	modeFactories = map[string]ModeFactory{}
	pageFactories = map[string]ModeFactory{}
)

// registerMode makes a mode available under its id (call from init()).
func registerMode(id string, f ModeFactory) { modeFactories[id] = f }

// registerPage makes a page available under its id (call from init()).
func registerPage(id string, f ModeFactory) { pageFactories[id] = f }

// ModeInfo is the static description of a mode.
type ModeInfo struct {
	ID   string
	Icon string
	Key  string // jump key
}

// Mode icons. All are single-width, text-presentation glyphs: the emoji-style
// ones (clocks, bells) are measured as one thing and drawn as another by many
// terminals, which shears the layout.
const (
	iconPomodoro  = "◔"
	iconClock     = "◷"
	iconTimer     = "⧖"
	iconStopwatch = "◴"
	iconAlarm     = "♪"
	iconWorld     = "⊕"
	iconBreathe   = "❋"
	iconIntervals = "⟳"
	iconKitchen   = "≋"
	iconEvent     = "⚑"
	iconBreaks    = "◐"
	iconSleep     = "☾"
	iconTracker   = "▤"
)

// Infos lists the known modes in their default order.
var Infos = []ModeInfo{
	{"pomodoro", iconPomodoro, "1"},
	{"clock", iconClock, "2"},
	{"timer", iconTimer, "3"},
	{"stopwatch", iconStopwatch, "4"},
	{"alarm", iconAlarm, "5"},
	{"world", iconWorld, "6"},
	{"breathe", iconBreathe, "7"},
	{"intervals", iconIntervals, ""},
	{"kitchen", iconKitchen, ""},
	{"event", iconEvent, ""},
	{"breaks", iconBreaks, ""},
	{"sleep", iconSleep, ""},
	{"tracker", iconTracker, ""},
	{"versus", versusIcon, ""},
}

func infoFor(id string) ModeInfo {
	for _, i := range Infos {
		if i.ID == id {
			return i
		}
	}
	return ModeInfo{ID: id, Icon: "•"}
}

func kb(keys, help, desc string) key.Binding {
	return key.NewBinding(key.WithKeys(splitKeys(keys)...), key.WithHelp(help, desc))
}

func splitKeys(s string) []string {
	var out []string
	cur := ""
	for _, r := range s {
		if r == '|' {
			out = append(out, cur)
			cur = ""
			continue
		}
		cur += string(r)
	}
	return append(out, cur)
}

// matches reports whether a key press hits a binding.
func matches(msg tea.KeyPressMsg, b key.Binding) bool { return key.Matches(msg, b) }
