package i18n

func init() {
	for k, v := range map[string]string{
		"timer.title":         "TIMER",
		"timer.start":         "start",
		"timer.pause":         "pause",
		"timer.resume":        "resume",
		"timer.reset":         "reset",
		"timer.field":         "field",
		"timer.adjust":        "adjust",
		"timer.add":           "±1 min",
		"timer.preset":        "preset",
		"timer.save":          "save",
		"timer.del":           "remove",
		"timer.label":         "label",
		"timer.dial":          "dial",
		"timer.font":          "digits",
		"timer.ends":          "Ends at %s",
		"timer.press":         "press space",
		"timer.set":           "Set a time first",
		"timer.h":             "hours",
		"timer.m":             "min",
		"timer.s":             "sec",
		"timer.presets":       "Presets",
		"timer.recent":        "Recent",
		"timer.none":          "Nothing yet",
		"timer.ph":            "What is it for? (e.g. Tea)",
		"timer.saved":         "Preset saved: %s",
		"timer.removed":       "Preset removed",
		"timer.exists":        "That preset already exists",
		"timer.keep":          "Keep at least one preset",
		"timer.full":          "Too many presets",
		"timer.nopreset":      "Pick a preset to remove first",
		"timer.busy":          "Reset the timer first",
		"stopwatch.start":     "start",
		"stopwatch.pause":     "pause",
		"stopwatch.resume":    "resume",
		"stopwatch.lap":       "lap",
		"stopwatch.reset":     "reset",
		"stopwatch.scroll":    "scroll",
		"stopwatch.font":      "digits",
		"stopwatch.n":         "#",
		"stopwatch.split":     "Split",
		"stopwatch.total":     "Total",
		"stopwatch.delta":     "vs best",
		"stopwatch.best":      "best",
		"stopwatch.worst":     "slowest",
		"stopwatch.nolaps":    "Press l to mark a lap",
		"stopwatch.ready":     "READY",
		"stopwatch.running":   "RUNNING",
		"stopwatch.laps":      "Laps",
		"stopwatch.press":     "press space",
		"stopwatch.toast":     "Lap %d · %s",
		"stopwatch.more":      "%d more",
		"help.mode.timer":     helpTimerEN,
		"help.mode.stopwatch": helpStopwatchEN,
	} {
		en[k] = v
	}
}

const helpTimerEN = `## Timer

| Key | Action |
| --- | --- |
| ` + "`space`" + ` | start / pause / resume |
| ` + "`←` `→`" + ` (` + "`h` `l`" + `) | pick hours, minutes or seconds |
| ` + "`↑` `↓`" + ` (` + "`k` `j`" + `, wheel) | change the field (` + "`K` `J`" + `: by five) |
| ` + "`+` `-`" + ` | add / remove a minute (also while running) |
| ` + "`p` `P`" + ` | next / previous preset |
| ` + "`a` `x`" + ` | save the time as a preset / remove the preset |
| ` + "`e`" + ` | name the timer |
| ` + "`r`" + ` | reset |
| ` + "`d` `t`" + ` | dial style / digit font |
`

const helpStopwatchEN = `## Stopwatch

| Key | Action |
| --- | --- |
| ` + "`space`" + ` | start / pause |
| ` + "`l`" + ` ` + "`enter`" + ` | mark a lap |
| ` + "`r`" + ` | reset (the run is saved to the history) |
| ` + "`↑` `↓`" + ` (wheel) | scroll the laps |
| ` + "`t`" + ` | digit font |
`
