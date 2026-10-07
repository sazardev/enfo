package i18n

func init() {
	for k, v := range map[string]string{
		"welcome.title":       "Bienvenido a enfo",
		"welcome.lang":        "Idioma",
		"welcome.lang.hint":   "Puedes cambiarlo cuando quieras en ajustes",
		"welcome.lang.names":  "",
		"welcome.rhythm":      "Tu ritmo",
		"welcome.rhythm.hint": "Cuánto te enfocas y cuánto descansas",
		"welcome.accent":      "Elige tu color",
		"welcome.accent.hint": "Todo cambia de color mientras te mueves",
		"welcome.dial":        "Elige una esfera",
		"welcome.dial.hint":   "Cómo se ve el temporizador (d lo cambia cuando quieras)",
		"welcome.tools":       "Tus herramientas",
		"welcome.tools.hint":  "Espacio activa o desactiva un modo",
		"welcome.next":        "siguiente",
		"welcome.start":       "empezar",
		"welcome.skip":        "omitir",
		"welcome.toggle":      "activar",
	} {
		es[k] = v
	}
}
