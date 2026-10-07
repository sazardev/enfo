package i18n

func init() {
	for k, v := range map[string]string{
		"mode.breaks":          "Breaks",
		"breaks.eyes.name":     "Eyes",
		"breaks.eyes.title":    "Rest your eyes",
		"breaks.eyes.body":     "Look at something 20 ft (6 m) away for 20 seconds",
		"breaks.eyes.cue":      "Look left… right… now far away",
		"breaks.stretch.name":  "Stretch",
		"breaks.stretch.title": "Time to stretch",
		"breaks.stretch.body":  "Stand up and stretch your arms, neck and back",
		"breaks.stretch.cue":   "Reach up, lean side to side, breathe",
		"breaks.water.name":    "Water",
		"breaks.water.title":   "Drink some water",
		"breaks.water.body":    "A glass of water keeps you sharp",
		"breaks.water.cue":     "Fill your glass and drink slowly",
		"breaks.posture.name":  "Posture",
		"breaks.posture.title": "Check your posture",
		"breaks.posture.body":  "Back straight, shoulders relaxed, feet flat",
		"breaks.posture.cue":   "Lengthen your spine, drop your shoulders",
		"breaks.custom.body":   "Take a moment for this one",
		"breaks.custom.cue":    "Take your time",
		"breaks.every":         "every %d min",
		"breaks.every.short":   "every %dm",
		"breaks.left":          "left",
		"breaks.due":           "due now",
		"breaks.on":            "on",
		"breaks.off":           "off",
		"breaks.paused":        "paused",
		"breaks.today":         "today",
		"breaks.taken":         "taken",
		"breaks.skipped":       "%d skipped",
		"breaks.streak":        "%d-day streak",
		"breaks.last":          "Last %d days",
		"breaks.tip":           "Short, regular breaks beat one long one: your eyes, back and focus all recover faster.",
		"breaks.empty":         "No reminders yet. Press a to add one.",
		"breaks.snoozed":       "Snoozed for %d min",
		"breaks.builtin":       "Built-in reminders can be switched off, not deleted",
		"breaks.builtin.edit":  "Built-in reminders only have their interval to change (+ / -)",
		"breaks.confirm":       "Delete “%s”?   y yes · n no",
		"breaks.guide.done":    "Done!",
		"breaks.guide.next":    "Next one in %d min",
		"breaks.k.toggle":      "on/off",
		"breaks.k.every":       "interval",
		"breaks.k.doit":        "do it",
		"breaks.k.done":        "done",
		"breaks.k.snooze":      "snooze",
		"breaks.k.add":         "add",
		"breaks.k.pause":       "pause all",
		"breaks.k.resume":      "resume all",
		"breaks.k.field":       "next field",
		"breaks.k.save":        "save",
		"breaks.edit.new":      "New reminder",
		"breaks.edit.edit":     "Edit reminder",
		"breaks.edit.name":     "Name",
		"breaks.edit.name.ph":  "e.g. Call mum",
		"breaks.edit.every":    "Every (minutes)",
		"breaks.edit.hint":     "tab next field · enter save · esc cancel",
		"breaks.edit.err":      "Give it a name",
		"help.mode.breaks": `## Breaks

Healthy-habit reminders: eyes (20-20-20), stretch, water, posture and your own. They keep counting while you use another tab and take over the screen when due.

| Key | Action |
| --- | --- |
| ` + "`" + `↑` + "`" + ` ` + "`" + `↓` + "`" + ` | select a reminder |
| ` + "`" + `space` + "`" + ` | switch it on / off |
| ` + "`" + `enter` + "`" + ` | do it now (guided exercise) |
| ` + "`" + `+` + "`" + ` ` + "`" + `-` + "`" + ` | interval ±5 minutes |
| ` + "`" + `s` + "`" + ` | snooze 5 minutes |
| ` + "`" + `k` + "`" + ` | skip this one |
| ` + "`" + `p` + "`" + ` | pause / resume all |
| ` + "`" + `a` + "`" + ` ` + "`" + `e` + "`" + ` ` + "`" + `x` + "`" + ` | add / edit / delete a custom one |
`,
	} {
		en[k] = v
	}
}
