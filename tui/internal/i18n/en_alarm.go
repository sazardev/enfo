package i18n

func init() {
	for k, v := range map[string]string{
		"alarm.header":           "ALARMS",
		"alarm.next":             "NEXT",
		"alarm.in":               "in %s",
		"alarm.off":              "off",
		"alarm.snoozed":          "snoozed · %s",
		"alarm.days":             "MTWTFSS",
		"alarm.weekdays":         "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday",
		"alarm.once":             "once",
		"alarm.d.weekdays":       "weekdays",
		"alarm.d.weekend":        "weekend",
		"alarm.d.everyday":       "every day",
		"alarm.label":            "Label",
		"alarm.label.hint":       "Label (optional)",
		"alarm.title.new":        "NEW ALARM",
		"alarm.title.edit":       "EDIT ALARM",
		"alarm.empty.title":      "No alarms yet",
		"alarm.empty.hint":       "Press n to set your first one",
		"alarm.none.armed":       "Nothing armed",
		"alarm.preview.today":    "Rings today at %s (in %s)",
		"alarm.preview.tomorrow": "Rings tomorrow at %s (in %s)",
		"alarm.preview.day":      "Rings on %[3]s at %[1]s (in %[2]s)",
		"alarm.confirm":          "Delete %s?",
		"alarm.confirm.hint":     "enter confirm · esc cancel",
		"alarm.on.toast":         "Alarm on · rings in %s",
		"alarm.off.toast":        "Alarm off",
		"alarm.saved":            "Alarm saved · rings in %s",
		"alarm.deleted":          "Alarm deleted",
		"alarm.more":             "%d more",
		"alarm.k.move":           "move",
		"alarm.k.toggle":         "on/off",
		"alarm.k.new":            "new",
		"alarm.k.edit":           "edit",
		"alarm.k.delete":         "delete",
		"alarm.k.field":          "field",
		"alarm.k.change":         "change",
		"alarm.k.day":            "day",
		"alarm.k.days":           "days",
		"alarm.k.save":           "save",
		"help.mode.alarm":        helpAlarmEN,
	} {
		en[k] = v
	}
}

const helpAlarmEN = `## Alarm

| Key | Action |
| --- | --- |
| ` + "`↑` `↓`" + ` | move between alarms |
| ` + "`space`" + ` | turn the alarm on / off |
| ` + "`n`" + ` | new alarm |
| ` + "`e` `enter`" + ` | edit |
| ` + "`x`" + ` | delete (asks first) |

Editing: ` + "`←` `→`" + ` or ` + "`tab`" + ` move between hour, minute, days and label; ` + "`↑` `↓`" + ` change the
value (` + "`shift`" + ` for bigger steps; you can also type the digits); ` + "`space`" + ` toggles a day;
` + "`w`" + ` weekdays, ` + "`e`" + ` weekend, ` + "`a`" + ` every day, ` + "`o`" + ` once; ` + "`enter`" + ` saves, ` + "`esc`" + ` cancels.
When an alarm rings: ` + "`enter`" + ` dismisses it, ` + "`z`" + ` snoozes it for 5 minutes.
`
