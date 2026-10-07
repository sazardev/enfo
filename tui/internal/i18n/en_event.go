package i18n

func init() {
	for k, v := range map[string]string{
		"mode.event": "Events",
		"mode.sleep": "Sleep",

		"event.new":           "new",
		"event.edit":          "edit",
		"event.delete":        "delete",
		"event.color":         "color",
		"event.save":          "save",
		"event.field":         "field",
		"event.adjust":        "adjust",
		"event.yes":           "yes",
		"event.no":            "no",
		"event.arrived":       "%s is here!",
		"event.reminder":      "Tomorrow: %s",
		"event.reminder.body": "Tomorrow at %s",
		"event.now":           "now",
		"event.days":          "DAYS",
		"event.day":           "DAY",
		"event.default":       "Event",
		"event.name":          "Name",
		"event.name.hint":     "What are you waiting for?",
		"event.date":          "Date",
		"event.time":          "Time",
		"event.yearly":        "Repeats every year",
		"event.saved":         "Saved: %s",
		"event.in":            "in %s",
		"event.ago":           "%s ago",
		"event.u.day":         "%d day",
		"event.u.days":        "%d days",
		"event.u.h":           "%d h",
		"event.u.min":         "%d min",
		"event.u.s":           "%d s",
		"event.confirm":       "Delete “%s”?",
		"event.confirm.keys":  "y yes · n no",
		"event.form.hint":     "tab next · ↑↓ change · enter save · esc cancel",
		"event.empty.title":   "No events yet",
		"event.empty.body":    "Press n to count down to something you look forward to",

		"sleep.min5":            "±5 min",
		"sleep.hour1":           "±1 h",
		"sleep.mode":            "mode",
		"sleep.option":          "choose",
		"sleep.winddown":        "wind-down",
		"sleep.setalarm":        "set alarm",
		"sleep.alarm.wake":      "Wake up",
		"sleep.alarm.wind":      "Wind down",
		"sleep.alarm.wind.at":   "wind-down at %s",
		"sleep.already":         "That alarm is already set",
		"sleep.set":             "Alarm set for %s",
		"sleep.set.only":        "Wake-up alarm was already set%s",
		"sleep.mode.wake":       "Wake up at %s",
		"sleep.mode.wake.short": "Wake up at…",
		"sleep.mode.bed":        "Going to bed at %s",
		"sleep.mode.bed.short":  "Going to bed now…",
		"sleep.wind.label":      "Wind-down reminder %d min before bed (w)",
		"sleep.fall":            "Counting %d min to fall asleep",
		"sleep.cycles":          "%d cycles",
		"sleep.recommended":     "recommended",
		"sleep.minimum":         "minimum",
		"sleep.bed.in":          "bed in %s",
		"sleep.wake.in":         "wake up in %s",
		"sleep.passed":          "already past",

		"help.mode.event": helpEventEN,
		"help.mode.sleep": helpSleepEN,
	} {
		en[k] = v
	}
}

const helpEventEN = `## Events

Count down to dates you look forward to. Yearly events (birthdays) roll over by themselves.
You get a reminder the day before and a celebration when it arrives.

| Key | Action |
| --- | --- |
| ` + "`↑` `↓`" + ` | select an event |
| ` + "`n`" + ` | new event |
| ` + "`e`" + ` ` + "`enter`" + ` | edit |
| ` + "`x`" + ` | delete (asks first) |
| ` + "`c`" + ` | change its color |

In the editor: ` + "`tab`" + ` moves between fields, ` + "`↑` `↓`" + ` change the value, ` + "`enter`" + ` saves.
`

const helpSleepEN = `## Sleep

A sleep-cycle planner: a night is about 90-minute cycles, and waking at the end of one feels easier.
It adds 15 minutes to fall asleep and suggests 6, 5 or 4 cycles.

| Key | Action |
| --- | --- |
| ` + "`↑` `↓`" + ` | ±5 minutes |
| ` + "`←` `→`" + ` | ±1 hour |
| ` + "`m`" + ` | switch: wake up at… / going to bed now |
| ` + "`c`" + ` | choose a suggestion |
| ` + "`w`" + ` | wind-down reminder on/off |
| ` + "`a`" + ` ` + "`enter`" + ` | set the alarm(s) for the chosen suggestion |
`
