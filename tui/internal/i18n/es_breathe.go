package i18n

func init() {
	for k, v := range map[string]string{
		"breathe.inhale":           "INHALA",
		"breathe.exhale":           "EXHALA",
		"breathe.hold.full":        "RETÉN",
		"breathe.hold.empty":       "RETÉN",
		"breathe.start":            "comenzar",
		"breathe.stop":             "detener",
		"breathe.pattern":          "ritmo",
		"breathe.style":            "estilo",
		"breathe.goal":             "meta",
		"breathe.free":             "sesión libre",
		"breathe.goal.is":          "meta: %s",
		"breathe.breath":           "respiración %d",
		"breathe.press":            "pulsa espacio para comenzar",
		"breathe.done":             "Sesión completa",
		"breathe.done.body":        "%s · %d respiraciones. Bien hecho",
		"breathe.pattern.box":      "Cuadrada",
		"breathe.pattern.478":      "Relajante",
		"breathe.pattern.coherent": "Coherente",
		"breathe.pattern.calm":     "Calma",
		"breathe.style.orb":        "esfera",
		"breathe.style.flower":     "flor",
		"breathe.style.waves":      "olas",
		"breathe.style.box":        "cuadro",
		"help.mode.breathe":        helpBreatheES,
	} {
		es[k] = v
	}
}

const helpBreatheES = `## Respira

Sigue la forma: crece cuando inhalas, descansa mientras retienes y se serena al exhalar.

| Tecla | Acción |
| --- | --- |
| ` + "`espacio`" + ` | comenzar / detener la sesión |
| ` + "`p`" + ` | siguiente ritmo: cuadrada 4-4-4-4, relajante 4-7-8, coherente 5-5, calma 4-6 |
| ` + "`d`" + ` | siguiente visual: esfera, flor, olas, cuadro |
| ` + "`+`" + ` ` + "`-`" + ` | meta de la sesión: libre, 1, 3, 5, 10 minutos |

Las sesiones de 30 segundos o más se guardan en tu historial. Pulsa ` + "`f`" + ` para el modo zen: solo el arte.
`
