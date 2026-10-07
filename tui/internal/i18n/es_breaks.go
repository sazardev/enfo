package i18n

func init() {
	for k, v := range map[string]string{
		"mode.breaks":          "Pausas",
		"breaks.eyes.name":     "Ojos",
		"breaks.eyes.title":    "Descansa la vista",
		"breaks.eyes.body":     "Mira algo a 6 m de distancia durante 20 segundos",
		"breaks.eyes.cue":      "Mira a la izquierda… a la derecha… y ahora lejos",
		"breaks.stretch.name":  "Estirar",
		"breaks.stretch.title": "Hora de estirarte",
		"breaks.stretch.body":  "Ponte de pie y estira brazos, cuello y espalda",
		"breaks.stretch.cue":   "Estira hacia arriba, inclínate a los lados y respira",
		"breaks.water.name":    "Agua",
		"breaks.water.title":   "Toma agua",
		"breaks.water.body":    "Un vaso de agua te mantiene alerta",
		"breaks.water.cue":     "Llena tu vaso y bebe despacio",
		"breaks.posture.name":  "Postura",
		"breaks.posture.title": "Revisa tu postura",
		"breaks.posture.body":  "Espalda recta, hombros relajados, pies en el suelo",
		"breaks.posture.cue":   "Alarga la columna y relaja los hombros",
		"breaks.custom.body":   "Tómate un momento para esto",
		"breaks.custom.cue":    "Sin prisa",
		"breaks.every":         "cada %d min",
		"breaks.every.short":   "cada %dm",
		"breaks.left":          "restantes",
		"breaks.due":           "toca ahora",
		"breaks.on":            "activa",
		"breaks.off":           "apagada",
		"breaks.paused":        "en pausa",
		"breaks.today":         "hoy",
		"breaks.taken":         "hechas",
		"breaks.skipped":       "%d omitidas",
		"breaks.streak":        "racha de %d días",
		"breaks.last":          "Últimos %d días",
		"breaks.tip":           "Pausas cortas y frecuentes ganan a una sola larga: la vista, la espalda y el enfoque se recuperan más rápido.",
		"breaks.empty":         "Aún no hay recordatorios. Pulsa a para añadir uno.",
		"breaks.snoozed":       "Pospuesto %d min",
		"breaks.builtin":       "Los recordatorios incluidos se pueden apagar, no borrar",
		"breaks.builtin.edit":  "En los incluidos solo cambia el intervalo (+ / -)",
		"breaks.confirm":       "¿Borrar «%s»?   y sí · n no",
		"breaks.guide.done":    "¡Listo!",
		"breaks.guide.next":    "El siguiente en %d min",
		"breaks.k.toggle":      "activar",
		"breaks.k.every":       "intervalo",
		"breaks.k.doit":        "hacerlo",
		"breaks.k.done":        "listo",
		"breaks.k.snooze":      "posponer",
		"breaks.k.add":         "añadir",
		"breaks.k.pause":       "pausar todo",
		"breaks.k.resume":      "reanudar todo",
		"breaks.k.field":       "siguiente campo",
		"breaks.k.save":        "guardar",
		"breaks.edit.new":      "Nuevo recordatorio",
		"breaks.edit.edit":     "Editar recordatorio",
		"breaks.edit.name":     "Nombre",
		"breaks.edit.name.ph":  "p. ej. Llamar a mamá",
		"breaks.edit.every":    "Cada (minutos)",
		"breaks.edit.hint":     "tab siguiente campo · enter guardar · esc cancelar",
		"breaks.edit.err":      "Ponle un nombre",
		"help.mode.breaks": `## Pausas

Recordatorios de hábitos sanos: vista (20-20-20), estirar, agua, postura y los tuyos. Siguen contando mientras usas otra pestaña y toman la pantalla cuando toca.

| Tecla | Acción |
| --- | --- |
| ` + "`" + `↑` + "`" + ` ` + "`" + `↓` + "`" + ` | elegir un recordatorio |
| ` + "`" + `espacio` + "`" + ` | activarlo / apagarlo |
| ` + "`" + `enter` + "`" + ` | hacerlo ahora (ejercicio guiado) |
| ` + "`" + `+` + "`" + ` ` + "`" + `-` + "`" + ` | intervalo ±5 minutos |
| ` + "`" + `s` + "`" + ` | posponer 5 minutos |
| ` + "`" + `k` + "`" + ` | omitir este |
| ` + "`" + `p` + "`" + ` | pausar / reanudar todo |
| ` + "`" + `a` + "`" + ` ` + "`" + `e` + "`" + ` ` + "`" + `x` + "`" + ` | añadir / editar / borrar uno propio |
`,
	} {
		es[k] = v
	}
}
