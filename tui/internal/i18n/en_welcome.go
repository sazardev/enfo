package i18n

func init() {
	for k, v := range map[string]string{
		"welcome.title":       "Welcome to enfo",
		"welcome.lang":        "Language",
		"welcome.lang.hint":   "You can change it any time in settings",
		"welcome.lang.names":  "",
		"welcome.rhythm":      "Your rhythm",
		"welcome.rhythm.hint": "How long you focus, and how long you rest",
		"welcome.accent":      "Pick your color",
		"welcome.accent.hint": "Everything re-tints as you move",
		"welcome.dial":        "Choose a face",
		"welcome.dial.hint":   "How the timer looks (d changes it any time)",
		"welcome.tools":       "Your tools",
		"welcome.tools.hint":  "Space switches a mode on or off",
		"welcome.next":        "next",
		"welcome.start":       "start",
		"welcome.skip":        "skip",
		"welcome.toggle":      "toggle",
	} {
		en[k] = v
	}
}
