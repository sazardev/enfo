package i18n

func init() {
	for k, v := range map[string]string{
		"timer.title":         "TEMPORIZADOR",
		"timer.start":         "iniciar",
		"timer.pause":         "pausar",
		"timer.resume":        "continuar",
		"timer.reset":         "reiniciar",
		"timer.field":         "campo",
		"timer.adjust":        "ajustar",
		"timer.add":           "±1 min",
		"timer.preset":        "preajuste",
		"timer.save":          "guardar",
		"timer.del":           "quitar",
		"timer.label":         "nombre",
		"timer.dial":          "reloj",
		"timer.font":          "dígitos",
		"timer.ends":          "Termina a las %s",
		"timer.press":         "pulsa espacio",
		"timer.set":           "Elige un tiempo primero",
		"timer.h":             "horas",
		"timer.m":             "min",
		"timer.s":             "seg",
		"timer.presets":       "Preajustes",
		"timer.recent":        "Recientes",
		"timer.none":          "Aún nada",
		"timer.ph":            "¿Para qué es? (p. ej. Té)",
		"timer.saved":         "Preajuste guardado: %s",
		"timer.removed":       "Preajuste quitado",
		"timer.exists":        "Ese preajuste ya existe",
		"timer.keep":          "Deja al menos un preajuste",
		"timer.full":          "Demasiados preajustes",
		"timer.nopreset":      "Elige primero el preajuste a quitar",
		"timer.busy":          "Reinicia el temporizador primero",
		"stopwatch.start":     "iniciar",
		"stopwatch.pause":     "pausar",
		"stopwatch.resume":    "continuar",
		"stopwatch.lap":       "vuelta",
		"stopwatch.reset":     "reiniciar",
		"stopwatch.scroll":    "desplazar",
		"stopwatch.font":      "dígitos",
		"stopwatch.n":         "#",
		"stopwatch.split":     "Parcial",
		"stopwatch.total":     "Total",
		"stopwatch.delta":     "vs mejor",
		"stopwatch.best":      "mejor",
		"stopwatch.worst":     "más lenta",
		"stopwatch.nolaps":    "Pulsa l para marcar una vuelta",
		"stopwatch.ready":     "LISTO",
		"stopwatch.running":   "EN MARCHA",
		"stopwatch.laps":      "Vueltas",
		"stopwatch.press":     "pulsa espacio",
		"stopwatch.toast":     "Vuelta %d · %s",
		"stopwatch.more":      "%d más",
		"help.mode.timer":     helpTimerES,
		"help.mode.stopwatch": helpStopwatchES,
	} {
		es[k] = v
	}
}

const helpTimerES = `## Temporizador

| Tecla | Acción |
| --- | --- |
| ` + "`espacio`" + ` | iniciar / pausar / continuar |
| ` + "`←` `→`" + ` (` + "`h` `l`" + `) | elegir horas, minutos o segundos |
| ` + "`↑` `↓`" + ` (` + "`k` `j`" + `, rueda) | cambiar el campo (` + "`K` `J`" + `: de cinco en cinco) |
| ` + "`+` `-`" + ` | sumar / restar un minuto (también en marcha) |
| ` + "`p` `P`" + ` | preajuste siguiente / anterior |
| ` + "`a` `x`" + ` | guardar el tiempo como preajuste / quitar el preajuste |
| ` + "`e`" + ` | ponerle nombre |
| ` + "`r`" + ` | reiniciar |
| ` + "`d` `t`" + ` | estilo de reloj / tipo de dígitos |
`

const helpStopwatchES = `## Cronómetro

| Tecla | Acción |
| --- | --- |
| ` + "`espacio`" + ` | iniciar / pausar |
| ` + "`l`" + ` ` + "`enter`" + ` | marcar una vuelta |
| ` + "`r`" + ` | reiniciar (la sesión se guarda en el historial) |
| ` + "`↑` `↓`" + ` (rueda) | desplazar las vueltas |
| ` + "`t`" + ` | tipo de dígitos |
`
