package i18n

func init() {
	for k, v := range map[string]string{
		"mode.tracker":      "Tiempo",
		"tracker.act.work":  "Trabajo",
		"tracker.act.meet":  "Reuniones",
		"tracker.act.learn": "Estudio",
		"tracker.idle":      "Nada en curso",
		"tracker.today":     "Hoy",
		"tracker.running":   "En curso",
		"tracker.timeline":  "Línea de tiempo de hoy",
		"tracker.range":     "Últimos %d días",
		"tracker.empty":     "Aún no hay actividades. Pulsa n para añadir una.",
		"tracker.started":   "Registrando %s",
		"tracker.stopped":   "Detenido %s",
		"tracker.new":       "Nueva actividad",
		"tracker.rename":    "Renombrar",
		"tracker.name.ph":   "Nombre de la actividad",
		"tracker.confirm":   "¿Borrar «%s» y todo su tiempo?   y sí · n no",
		"tracker.k.toggle":  "iniciar/parar",
		"tracker.k.stop":    "parar",
		"tracker.k.new":     "nueva",
		"tracker.k.rename":  "renombrar",
		"tracker.k.color":   "color",
		"tracker.k.range":   "rango",
		"tracker.k.del":     "borrar",
		"help.mode.tracker": `## Tiempo

Registro de tiempo por actividad. Una actividad corre a la vez y sigue contando mientras usas otra pestaña o cierras Enfo.

| Tecla | Acción |
| --- | --- |
| ` + "`" + `↑` + "`" + ` ` + "`" + `↓` + "`" + ` | elegir una actividad |
| ` + "`" + `espacio` + "`" + ` ` + "`" + `enter` + "`" + ` | iniciarla / pararla (iniciar otra detiene la actual) |
| ` + "`" + `s` + "`" + ` | parar la actividad en curso |
| ` + "`" + `n` + "`" + ` ` + "`" + `e` + "`" + ` | nueva actividad / renombrar |
| ` + "`" + `c` + "`" + ` | siguiente color |
| ` + "`" + `←` + "`" + ` ` + "`" + `→` + "`" + ` | rango del gráfico: 7, 14 o 30 días |
| ` + "`" + `x` + "`" + ` | borrar (pregunta antes) |
`,
	} {
		es[k] = v
	}
}
