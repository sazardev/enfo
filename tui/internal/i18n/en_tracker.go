package i18n

func init() {
	for k, v := range map[string]string{
		"mode.tracker":      "Tracker",
		"tracker.act.work":  "Work",
		"tracker.act.meet":  "Meetings",
		"tracker.act.learn": "Learning",
		"tracker.idle":      "Nothing running",
		"tracker.today":     "Today",
		"tracker.running":   "Running",
		"tracker.timeline":  "Today's timeline",
		"tracker.range":     "Last %d days",
		"tracker.empty":     "No activities yet. Press n to add one.",
		"tracker.started":   "Tracking %s",
		"tracker.stopped":   "Stopped %s",
		"tracker.new":       "New activity",
		"tracker.rename":    "Rename",
		"tracker.name.ph":   "Activity name",
		"tracker.confirm":   "Delete “%s” and all its time?   y yes · n no",
		"tracker.k.toggle":  "start/stop",
		"tracker.k.stop":    "stop",
		"tracker.k.new":     "new",
		"tracker.k.rename":  "rename",
		"tracker.k.color":   "color",
		"tracker.k.range":   "range",
		"tracker.k.del":     "delete",
		"help.mode.tracker": `## Tracker

Time tracking by activity. One activity runs at a time and keeps counting while you use another tab or close Enfo.

| Key | Action |
| --- | --- |
| ` + "`" + `↑` + "`" + ` ` + "`" + `↓` + "`" + ` | select an activity |
| ` + "`" + `space` + "`" + ` ` + "`" + `enter` + "`" + ` | start / stop it (starting another stops the current one) |
| ` + "`" + `s` + "`" + ` | stop the running activity |
| ` + "`" + `n` + "`" + ` ` + "`" + `e` + "`" + ` | new activity / rename |
| ` + "`" + `c` + "`" + ` | next color |
| ` + "`" + `←` + "`" + ` ` + "`" + `→` + "`" + ` | chart range: 7, 14 or 30 days |
| ` + "`" + `x` + "`" + ` | delete (asks first) |
`,
	} {
		en[k] = v
	}
}
