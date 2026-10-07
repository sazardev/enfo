package i18n

func init() {
	for k, v := range map[string]string{
		"mode.intervals": "Intervalos",

		"intervals.phase.warm":  "CALENTAR",
		"intervals.phase.work":  "TRABAJO",
		"intervals.phase.rest":  "DESCANSO",
		"intervals.phase.cool":  "ENFRIAR",
		"intervals.phase.ready": "LISTO",

		"intervals.preset.tabata":  "Tabata",
		"intervals.preset.hiit":    "HIIT",
		"intervals.preset.emom":    "EMOM",
		"intervals.preset.pyramid": "Pirámide",
		"intervals.preset.custom":  "Personal",
		"intervals.preset.set":     "Entrenamiento: %s",

		"intervals.f.warm":     "Calentamiento",
		"intervals.f.work":     "Trabajo",
		"intervals.f.rest":     "Descanso",
		"intervals.f.rounds":   "Rondas",
		"intervals.f.cool":     "Enfriamiento",
		"intervals.f.ramp":     "Aumento por ronda",
		"intervals.off":        "no",
		"intervals.field":      "campo",
		"intervals.value":      "valor",
		"intervals.plan":       "Plan",
		"intervals.round":      "Ronda %d/%d",
		"intervals.next":       "Sigue: %s %s",
		"intervals.last":       "¡La última!",
		"intervals.total":      "Total %s",
		"intervals.busy":       "Reinicia el entrenamiento para cambiar el plan",
		"intervals.done":       "Entrenamiento completo",
		"intervals.done.body":  "%d rondas · %s",
		"intervals.style.ring": "anillo",
		"intervals.style.hex":  "hexágono",

		"help.mode.intervals": helpIntervalsES,
	} {
		es[k] = v
	}
}

const helpIntervalsES = `## Intervalos

Entrenamiento por intervalos: calentamiento, rondas de trabajo y descanso,
enfriamiento. El anillo exterior muestra todo el entrenamiento llenándose; el
interior es el tramo actual (el trabajo se vacía, el descanso se llena). Los
últimos tres segundos hacen tic y cada cambio de fase lanza una ola de color.

| Tecla | Acción |
| --- | --- |
| ` + "`espacio`" + ` | iniciar / pausar / continuar |
| ` + "`r`" + ` | reiniciar (registra el entrenamiento si duró 20 s o más) |
| ` + "`s`" + ` | saltar al siguiente tramo |
| ` + "`p`" + ` ` + "`P`" + ` | siguiente / anterior (Tabata, HIIT, EMOM, Pirámide, Personal) |
| ` + "`←`" + ` ` + "`→`" + ` | elegir campo (calentamiento, trabajo, descanso, rondas, enfriamiento, aumento) |
| ` + "`↑`" + ` ` + "`↓`" + ` ` + "`+`" + ` ` + "`-`" + ` | cambiarlo (` + "`K`" + ` ` + "`J`" + `: pasos grandes) |
| ` + "`d`" + ` | cara de anillo o hexágono |
`
