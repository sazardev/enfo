package i18n

func init() {
	for k, v := range map[string]string{
		"world.cities":         "Ciudades",
		"world.add":            "añadir",
		"world.remove":         "quitar",
		"world.move":           "mover",
		"world.plan":           "planificar",
		"world.yes":            "sí",
		"world.no":             "no",
		"world.hour":           "hora",
		"world.now":            "ahora",
		"world.empty":          "Aún no hay ciudades. Pulsa a para añadir una.",
		"world.last":           "Deja al menos una ciudad",
		"world.added":          "%s añadida",
		"world.exists":         "%s ya está en tu lista",
		"world.removed":        "%s quitada",
		"world.remove.confirm": "¿Quitar %s?",
		"world.add.title":      "Añadir una ciudad",
		"world.add.search":     "Busca una ciudad…",
		"world.add.hint":       "escribe para filtrar · ↑↓ elegir · enter añade · esc cancela",
		"world.add.none":       "Ninguna ciudad coincide",
		"world.sunat":          "Sol sobre %s",
		"world.dst":            "horario de verano",
		"world.polar.day":      "Sol de medianoche",
		"world.polar.night":    "Noche polar",
		"world.daylight":       "%s de luz",
		"world.plan.title":     "Planificador de reuniones",
		"world.plan.overlap":   "Coinciden",
		"world.plan.best":      "Mejor ventana: %s – %s (%s)",
		"world.plan.none":      "No hay hora en que todos estén trabajando",
		"world.work":           "trabajo",
		"world.awake":          "despierto",
		"world.sleep":          "sueño",
		"help.mode.world":      helpWorldES,
	} {
		es[k] = v
	}
}

const helpWorldES = `## Mundo

Un mapa de día y noche de la Tierra con la hora de cada ciudad que sigues. La
primera ciudad es tu casa: las diferencias se miden desde ella.

| Tecla | Acción |
| --- | --- |
| ` + "`↑` `↓`" + ` | elegir ciudad (también clic o la rueda) |
| ` + "`a`" + ` | añadir ciudad: escribe para filtrar, ` + "`enter`" + ` la añade |
| ` + "`x`" + ` | quitar la ciudad elegida |
| ` + "`J` `K`" + ` | bajarla / subirla (` + "`H`" + ` la hace tu casa) |
| ` + "`m`" + ` | planificador: ¿cuándo trabaja todo el mundo? (` + "`←` `→`" + ` mueve la hora) |
| ` + "`t`" + ` | cambia 12 h / 24 h |
`
