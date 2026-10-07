package i18n

func init() {
	for k, v := range map[string]string{
		"mode.kitchen": "Kitchen",
		"mode.versus":  "Versus",

		"kitchen.input.presets": "presets",
		"kitchen.title":         "KITCHEN",
		"kitchen.count":         "%d timers",
		"kitchen.count.1":       "1 timer",
		"kitchen.running":       "%d running",
		"kitchen.empty":         "No timers yet",
		"kitchen.empty.hint":    "Press n and type something like  10m pasta",
		"kitchen.add":           "new",
		"kitchen.select":        "select",
		"kitchen.toggle":        "pause/start",
		"kitchen.reset":         "reset",
		"kitchen.delete":        "delete",
		"kitchen.time":          "±1 min",
		"kitchen.input.prompt":  "New timer ",
		"kitchen.input.place":   "10m pasta",
		"kitchen.input.hint":    "enter add · esc cancel · ←→ presets",
		"kitchen.confirm":       "Delete “%s”?  y / n",
		"kitchen.paused":        "PAUSED",
		"kitchen.done":          "DONE",
		"kitchen.ready":         "READY",
		"kitchen.ends":          "ends %s",
		"kitchen.invalid":       "Try something like  10m pasta",
		"kitchen.default":       "Timer",
		"kitchen.done.body":     "It's ready!",
		"kitchen.more":          "+%d more",
		"kitchen.added":         "Started %s",

		"versus.setup":      "Two-player clock",
		"versus.start":      "start",
		"versus.switch":     "switch turn",
		"versus.pause":      "pause",
		"versus.resume":     "resume",
		"versus.reset":      "reset",
		"versus.flip":       "flip",
		"versus.edit":       "custom",
		"versus.first":      "first",
		"versus.preset":     "time",
		"versus.flag":       "Time!",
		"versus.flag.body":  "Player %d ran out of time",
		"versus.moves":      "moves",
		"versus.minutes":    "minutes",
		"versus.inc":        "increment",
		"versus.delay":      "delay",
		"versus.press":      "press space to start",
		"versus.custom":     "Custom",
		"versus.paused":     "PAUSED",
		"versus.starts":     "Player %d starts",
		"versus.over":       "GAME OVER",
		"versus.adjust":     "adjust",
		"versus.field":      "field",
		"versus.done":       "done",
		"versus.secs":       "%ds",
		"versus.none":       "off",
		"versus.p":          "Player %d",
		"help.mode.kitchen": helpKitchenEN,
		"help.mode.versus":  helpVersusEN,
	} {
		en[k] = v
	}
}

const helpKitchenEN = `## Kitchen

Several named timers at once. They keep running while you are in another mode.

| Key | Action |
| --- | --- |
| ` + "`n`" + ` | new timer: ` + "`10m pasta`" + `, ` + "`1h30 roast`" + `, ` + "`90 tea`" + ` (a bare number is minutes) |
| ` + "`←` `→`" + ` | in the input: pick a preset (1-60 min) |
| ` + "`↑` `↓`" + ` | select a timer |
| ` + "`space`" + ` | pause / resume / start |
| ` + "`r`" + ` | reset the selected timer |
| ` + "`+` `-`" + ` | add / remove a minute |
| ` + "`x`" + ` | delete (then ` + "`y`" + ` to confirm) |
`

const helpVersusEN = `## Versus

A two-player chess clock with increment and delay.

| Key | Action |
| --- | --- |
| ` + "`←` `→`" + ` | setup: choose the time control |
| ` + "`e`" + ` | setup: edit a custom control (` + "`↑` `↓`" + ` adjust, ` + "`←` `→`" + ` field) |
| ` + "`s`" + ` | setup: who moves first |
| ` + "`space` `enter`" + ` | start / switch turn (click your half too) |
| ` + "`p`" + ` | pause / resume |
| ` + "`v`" + ` | flip the top half 180° for a face-to-face game |
| ` + "`r`" + ` | back to setup |
`
