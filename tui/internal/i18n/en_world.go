package i18n

func init() {
	for k, v := range map[string]string{
		"world.cities":         "Cities",
		"world.add":            "add",
		"world.remove":         "remove",
		"world.move":           "move",
		"world.plan":           "planner",
		"world.yes":            "yes",
		"world.no":             "no",
		"world.hour":           "hour",
		"world.now":            "now",
		"world.empty":          "No cities yet. Press a to add one.",
		"world.last":           "Keep at least one city",
		"world.added":          "%s added",
		"world.exists":         "%s is already in your list",
		"world.removed":        "%s removed",
		"world.remove.confirm": "Remove %s?",
		"world.add.title":      "Add a city",
		"world.add.search":     "Search a city…",
		"world.add.hint":       "type to filter · ↑↓ choose · enter add · esc cancel",
		"world.add.none":       "No cities match",
		"world.sunat":          "Sun over %s",
		"world.dst":            "DST",
		"world.polar.day":      "Midnight sun",
		"world.polar.night":    "Polar night",
		"world.daylight":       "%s of daylight",
		"world.plan.title":     "Meeting planner",
		"world.plan.overlap":   "Overlap",
		"world.plan.best":      "Best window: %s – %s (%s)",
		"world.plan.none":      "No hour where everyone is at work",
		"world.work":           "work",
		"world.awake":          "awake",
		"world.sleep":          "sleep",
		"help.mode.world":      helpWorldEN,
	} {
		en[k] = v
	}
}

const helpWorldEN = `## World

A day/night map of the Earth with the time in every city you follow. The
first city is home: the offsets are measured from it.

| Key | Action |
| --- | --- |
| ` + "`↑` `↓`" + ` | select a city (also click, or the wheel) |
| ` + "`a`" + ` | add a city: type to filter, ` + "`enter`" + ` adds |
| ` + "`x`" + ` | remove the selected city |
| ` + "`J` `K`" + ` | move it down / up (` + "`H`" + ` makes it home) |
| ` + "`m`" + ` | meeting planner: when is everyone at work? (` + "`←` `→`" + ` moves the hour) |
| ` + "`t`" + ` | switch 12 h / 24 h |
`
