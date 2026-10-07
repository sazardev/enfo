package i18n

var en = map[string]string{
	// modes
	"mode.pomodoro":  "Pomodoro",
	"mode.clock":     "Clock",
	"mode.timer":     "Timer",
	"mode.stopwatch": "Stopwatch",
	"mode.alarm":     "Alarm",
	"mode.world":     "World",
	"mode.breathe":   "Breathe",
	"mode.stats":     "Stats",
	"mode.settings":  "Settings",

	// phases and states
	"phase.focus":  "FOCUS",
	"phase.rest":   "REST",
	"phase.long":   "LONG REST",
	"state.paused": "PAUSED",
	"state.ready":  "READY",
	"state.done":   "DONE",

	// generic
	"app.tagline":     "focus, in the terminal",
	"key.quit":        "quit",
	"key.help":        "help",
	"key.back":        "back",
	"key.modes":       "modes",
	"key.select":      "select",
	"key.confirm":     "confirm",
	"key.cancel":      "cancel",
	"key.zen":         "zen",
	"key.stats":       "stats",
	"key.settings":    "settings",
	"too.small.short": "Too small",
	"too.small":       "Make the terminal a bit bigger",

	// away / done
	"away.title":      "Welcome back",
	"away.body":       "%d finished while you were away (last at %s)",
	"done.focus":      "Focus complete",
	"done.focus.rest": "Time for a %s break",
	"done.focus.long": "Great set! Take a long %s break",
	"done.rest":       "Back to focus",
	"done.rest.body":  "The break is over",
	"done.timer":      "Timer finished",
	"alarm.default":   "Alarm",

	// pomodoro
	"pomo.start":           "start",
	"pomo.pause":           "pause",
	"pomo.resume":          "resume",
	"pomo.reset":           "reset",
	"pomo.skip":            "skip",
	"pomo.dial":            "dial",
	"pomo.font":            "digits",
	"pomo.preset":          "preset",
	"pomo.time":            "±1 min",
	"pomo.session":         "Session %d of %d",
	"pomo.session.n":       "Session %d",
	"pomo.next":            "Next",
	"pomo.ends":            "Ends at %s",
	"pomo.today":           "Today",
	"pomo.last":            "Last %d days",
	"pomo.week":            "Last 7 days",
	"pomo.streak":          "Streak",
	"pomo.streak.d":        "%d days",
	"pomo.streak.1":        "1 day",
	"pomo.sessions":        "%d sessions",
	"pomo.session.1":       "1 session",
	"pomo.presets":         "Rhythm",
	"pomo.preset.classic":  "Classic",
	"pomo.preset.extended": "Extended",
	"pomo.preset.deep":     "Deep work",
	"pomo.preset.custom":   "Custom",
	"pomo.busy":            "Finish or reset the phase first",
	"pomo.preset.set":      "Rhythm: %s",
	"pomo.press":           "press space",
}

func init() {
	for k, v := range map[string]string{
		"mode.help":          "Help",
		"ring.dismiss":       "dismiss",
		"ring.snooze":        "snooze",
		"ring.again":         "again",
		"ring.snoozed":       "Snoozed for %d min",
		"help.md":            helpEN,
		"help.mode.pomodoro": helpPomoEN,
	} {
		en[k] = v
	}
}

const helpEN = `# enfo

**Focus, in the terminal.** Pomodoro, clock, timer, stopwatch, alarms, world
clock and breathing, all drawn with braille dots.

## Everywhere

| Key | Action |
| --- | --- |
| ` + "`tab`" + ` ` + "`]`" + ` / ` + "`shift+tab`" + ` ` + "`[`" + ` | next / previous mode |
| ` + "`1`" + `-` + "`9`" + ` | jump to a mode |
| ` + "`f`" + ` | zen: only the face, nothing else |
| ` + "`g`" + ` | statistics |
| ` + "`,`" + ` | settings |
| ` + "`?`" + ` | this help |
| ` + "`q`" + ` ` + "`ctrl+c`" + ` | quit (timers keep their time) |

`

const helpPomoEN = `## Pomodoro

| Key | Action |
| --- | --- |
| ` + "`space`" + ` | start / pause / resume |
| ` + "`r`" + ` | reset the phase |
| ` + "`s`" + ` | skip to the next phase |
| ` + "`+`" + ` ` + "`-`" + ` | add / remove a minute (` + "`↑`" + ` ` + "`↓`" + `: five) |
| ` + "`d`" + ` | next dial style |
| ` + "`t`" + ` | next digit font |
| ` + "`p`" + ` | next rhythm preset |
`
