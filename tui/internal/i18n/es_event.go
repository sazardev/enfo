package i18n

func init() {
	for k, v := range map[string]string{
		"mode.event": "Eventos",
		"mode.sleep": "Sueño",

		"event.new":           "nuevo",
		"event.edit":          "editar",
		"event.delete":        "borrar",
		"event.color":         "color",
		"event.save":          "guardar",
		"event.field":         "campo",
		"event.adjust":        "cambiar",
		"event.yes":           "sí",
		"event.no":            "no",
		"event.arrived":       "¡Llegó %s!",
		"event.reminder":      "Mañana: %s",
		"event.reminder.body": "Mañana a las %s",
		"event.now":           "ahora",
		"event.days":          "DÍAS",
		"event.day":           "DÍA",
		"event.default":       "Evento",
		"event.name":          "Nombre",
		"event.name.hint":     "¿Qué estás esperando?",
		"event.date":          "Fecha",
		"event.time":          "Hora",
		"event.yearly":        "Se repite cada año",
		"event.saved":         "Guardado: %s",
		"event.in":            "en %s",
		"event.ago":           "hace %s",
		"event.u.day":         "%d día",
		"event.u.days":        "%d días",
		"event.u.h":           "%d h",
		"event.u.min":         "%d min",
		"event.u.s":           "%d s",
		"event.confirm":       "¿Borrar “%s”?",
		"event.confirm.keys":  "y sí · n no",
		"event.form.hint":     "tab siguiente · ↑↓ cambiar · enter guardar · esc cancelar",
		"event.empty.title":   "Aún no hay eventos",
		"event.empty.body":    "Pulsa n para contar los días hasta algo que esperas",

		"sleep.min5":            "±5 min",
		"sleep.hour1":           "±1 h",
		"sleep.mode":            "modo",
		"sleep.option":          "elegir",
		"sleep.winddown":        "relajación",
		"sleep.setalarm":        "poner alarma",
		"sleep.alarm.wake":      "Despertar",
		"sleep.alarm.wind":      "A relajarse",
		"sleep.alarm.wind.at":   "relajación a las %s",
		"sleep.already":         "Esa alarma ya está puesta",
		"sleep.set":             "Alarma puesta a las %s",
		"sleep.set.only":        "La alarma de despertar ya estaba puesta%s",
		"sleep.mode.wake":       "Despertar a las %s",
		"sleep.mode.wake.short": "Despertar a las…",
		"sleep.mode.bed":        "Dormir a las %s",
		"sleep.mode.bed.short":  "Me voy a dormir ya…",
		"sleep.wind.label":      "Recordatorio para relajarte %d min antes de dormir (w)",
		"sleep.fall":            "Contando %d min para quedarte dormido",
		"sleep.cycles":          "%d ciclos",
		"sleep.recommended":     "recomendado",
		"sleep.minimum":         "mínimo",
		"sleep.bed.in":          "dormir en %s",
		"sleep.wake.in":         "despertar en %s",
		"sleep.passed":          "ya pasó",

		"help.mode.event": helpEventES,
		"help.mode.sleep": helpSleepES,
	} {
		es[k] = v
	}
}

const helpEventES = `## Eventos

Cuenta los días hasta fechas que esperas. Los eventos anuales (cumpleaños) se renuevan solos.
Te avisamos el día antes y celebramos cuando llega.

| Tecla | Acción |
| --- | --- |
| ` + "`↑` `↓`" + ` | elegir un evento |
| ` + "`n`" + ` | evento nuevo |
| ` + "`e`" + ` ` + "`enter`" + ` | editar |
| ` + "`x`" + ` | borrar (pregunta antes) |
| ` + "`c`" + ` | cambiar su color |

En el editor: ` + "`tab`" + ` pasa de un campo a otro, ` + "`↑` `↓`" + ` cambian el valor, ` + "`enter`" + ` guarda.
`

const helpSleepES = `## Sueño

Un planificador de ciclos de sueño: una noche son ciclos de unos 90 minutos y despertar al final de uno cuesta menos.
Suma 15 minutos para quedarte dormido y sugiere 6, 5 o 4 ciclos.

| Tecla | Acción |
| --- | --- |
| ` + "`↑` `↓`" + ` | ±5 minutos |
| ` + "`←` `→`" + ` | ±1 hora |
| ` + "`m`" + ` | cambiar: despertar a las… / me voy a dormir ya |
| ` + "`c`" + ` | elegir una sugerencia |
| ` + "`w`" + ` | recordatorio de relajación sí/no |
| ` + "`a`" + ` ` + "`enter`" + ` | poner la(s) alarma(s) de la sugerencia elegida |
`
