package i18n

func init() {
	for k, v := range map[string]string{
		"mode.intervals": "Intervals",

		"intervals.phase.warm":  "WARM UP",
		"intervals.phase.work":  "WORK",
		"intervals.phase.rest":  "REST",
		"intervals.phase.cool":  "COOL DOWN",
		"intervals.phase.ready": "DONE",

		"intervals.preset.tabata":  "Tabata",
		"intervals.preset.hiit":    "HIIT",
		"intervals.preset.emom":    "EMOM",
		"intervals.preset.pyramid": "Pyramid",
		"intervals.preset.custom":  "Custom",
		"intervals.preset.set":     "Workout: %s",

		"intervals.f.warm":     "Warm-up",
		"intervals.f.work":     "Work",
		"intervals.f.rest":     "Rest",
		"intervals.f.rounds":   "Rounds",
		"intervals.f.cool":     "Cool-down",
		"intervals.f.ramp":     "Ramp per round",
		"intervals.off":        "off",
		"intervals.field":      "field",
		"intervals.value":      "value",
		"intervals.plan":       "Plan",
		"intervals.round":      "Round %d/%d",
		"intervals.next":       "Next: %s %s",
		"intervals.last":       "Last one!",
		"intervals.total":      "Total %s",
		"intervals.busy":       "Reset the workout to change the plan",
		"intervals.done":       "Workout complete",
		"intervals.done.body":  "%d rounds · %s",
		"intervals.style.ring": "ring",
		"intervals.style.hex":  "hexagon",

		"help.mode.intervals": helpIntervalsEN,
	} {
		en[k] = v
	}
}

const helpIntervalsEN = `## Intervals

Interval training: warm-up, rounds of work and rest, cool-down. The outer ring
shows the whole workout filling up; the inner one is the current segment (work
drains, rest fills). The last three seconds tick, and every phase change sweeps
a wave of color across the dial.

| Key | Action |
| --- | --- |
| ` + "`space`" + ` | start / pause / resume |
| ` + "`r`" + ` | reset (logs the workout if it ran 20 s or more) |
| ` + "`s`" + ` | skip to the next segment |
| ` + "`p`" + ` ` + "`P`" + ` | next / previous preset (Tabata, HIIT, EMOM, Pyramid, Custom) |
| ` + "`←`" + ` ` + "`→`" + ` | choose a field (warm-up, work, rest, rounds, cool-down, ramp) |
| ` + "`↑`" + ` ` + "`↓`" + ` ` + "`+`" + ` ` + "`-`" + ` | change it (` + "`K`" + ` ` + "`J`" + `: bigger steps) |
| ` + "`d`" + ` | ring or hexagon face |
`
