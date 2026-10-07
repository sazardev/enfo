package i18n

var es = map[string]string{
	"mode.pomodoro":  "Pomodoro",
	"mode.clock":     "Reloj",
	"mode.timer":     "Temporizador",
	"mode.stopwatch": "Cronómetro",
	"mode.alarm":     "Alarma",
	"mode.world":     "Mundo",
	"mode.breathe":   "Respira",
	"mode.stats":     "Estadísticas",
	"mode.settings":  "Ajustes",

	"phase.focus":  "ENFOQUE",
	"phase.rest":   "DESCANSO",
	"phase.long":   "DESCANSO LARGO",
	"state.paused": "EN PAUSA",
	"state.ready":  "LISTO",
	"state.done":   "HECHO",

	"app.tagline":     "enfoque, en la terminal",
	"key.quit":        "salir",
	"key.help":        "ayuda",
	"key.back":        "volver",
	"key.modes":       "modos",
	"key.select":      "elegir",
	"key.confirm":     "confirmar",
	"key.cancel":      "cancelar",
	"key.zen":         "zen",
	"key.stats":       "estadísticas",
	"key.settings":    "ajustes",
	"too.small.short": "Muy chica",
	"too.small":       "Agranda un poco la terminal",

	"away.title":      "Bienvenido de vuelta",
	"away.body":       "%d terminaron mientras no estabas (el último a las %s)",
	"done.focus":      "Enfoque completado",
	"done.focus.rest": "Hora de un descanso de %s",
	"done.focus.long": "¡Gran serie! Toma un descanso largo de %s",
	"done.rest":       "De vuelta al enfoque",
	"done.rest.body":  "El descanso terminó",
	"done.timer":      "Temporizador terminado",
	"alarm.default":   "Alarma",

	"pomo.start":           "iniciar",
	"pomo.pause":           "pausar",
	"pomo.resume":          "continuar",
	"pomo.reset":           "reiniciar",
	"pomo.skip":            "saltar",
	"pomo.dial":            "reloj",
	"pomo.font":            "dígitos",
	"pomo.preset":          "ritmo",
	"pomo.time":            "±1 min",
	"pomo.session":         "Sesión %d de %d",
	"pomo.session.n":       "Sesión %d",
	"pomo.next":            "Siguiente",
	"pomo.ends":            "Termina a las %s",
	"pomo.today":           "Hoy",
	"pomo.last":            "Últimos %d días",
	"pomo.week":            "Últimos 7 días",
	"pomo.streak":          "Racha",
	"pomo.streak.d":        "%d días",
	"pomo.streak.1":        "1 día",
	"pomo.sessions":        "%d sesiones",
	"pomo.session.1":       "1 sesión",
	"pomo.presets":         "Ritmo",
	"pomo.preset.classic":  "Clásico",
	"pomo.preset.extended": "Extendido",
	"pomo.preset.deep":     "Profundo",
	"pomo.preset.custom":   "Personalizado",
	"pomo.busy":            "Termina o reinicia la fase primero",
	"pomo.preset.set":      "Ritmo: %s",
	"pomo.press":           "pulsa espacio",
}

func init() {
	for k, v := range map[string]string{
		"mode.help":          "Ayuda",
		"ring.dismiss":       "silenciar",
		"ring.snooze":        "posponer",
		"ring.again":         "otra vez",
		"ring.snoozed":       "Pospuesta %d min",
		"help.md":            helpES,
		"help.mode.pomodoro": helpPomoES,
	} {
		es[k] = v
	}
}

const helpES = `# enfo

**Enfoque, en la terminal.** Pomodoro, reloj, temporizador, cronómetro,
alarmas, hora mundial y respiración, todo dibujado con puntos braille.

## En todas partes

| Tecla | Acción |
| --- | --- |
| ` + "`tab`" + ` ` + "`]`" + ` / ` + "`shift+tab`" + ` ` + "`[`" + ` | modo siguiente / anterior |
| ` + "`1`" + `-` + "`9`" + ` | saltar a un modo |
| ` + "`f`" + ` | zen: solo la esfera, nada más |
| ` + "`g`" + ` | estadísticas |
| ` + "`,`" + ` | ajustes |
| ` + "`?`" + ` | esta ayuda |
| ` + "`q`" + ` ` + "`ctrl+c`" + ` | salir (los temporizadores conservan su tiempo) |

`

const helpPomoES = `## Pomodoro

| Tecla | Acción |
| --- | --- |
| ` + "`espacio`" + ` | iniciar / pausar / continuar |
| ` + "`r`" + ` | reiniciar la fase |
| ` + "`s`" + ` | saltar a la siguiente fase |
| ` + "`+`" + ` ` + "`-`" + ` | sumar / restar un minuto (` + "`↑`" + ` ` + "`↓`" + `: cinco) |
| ` + "`d`" + ` | siguiente estilo de reloj |
| ` + "`t`" + ` | siguiente tipo de dígitos |
| ` + "`p`" + ` | siguiente ritmo |
`
