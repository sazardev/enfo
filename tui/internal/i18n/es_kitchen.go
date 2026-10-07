package i18n

func init() {
	for k, v := range map[string]string{
		"mode.kitchen": "Cocina",
		"mode.versus":  "Duelo",

		"kitchen.input.presets": "atajos",
		"kitchen.title":         "COCINA",
		"kitchen.count":         "%d temporizadores",
		"kitchen.count.1":       "1 temporizador",
		"kitchen.running":       "%d en marcha",
		"kitchen.empty":         "Aún no hay temporizadores",
		"kitchen.empty.hint":    "Pulsa n y escribe algo como  10m pasta",
		"kitchen.add":           "nuevo",
		"kitchen.select":        "elegir",
		"kitchen.toggle":        "pausar/iniciar",
		"kitchen.reset":         "reiniciar",
		"kitchen.delete":        "borrar",
		"kitchen.time":          "±1 min",
		"kitchen.input.prompt":  "Nuevo temporizador ",
		"kitchen.input.place":   "10m pasta",
		"kitchen.input.hint":    "enter añadir · esc cancelar · ←→ atajos",
		"kitchen.confirm":       "¿Borrar «%s»?  s / n",
		"kitchen.paused":        "EN PAUSA",
		"kitchen.done":          "LISTO",
		"kitchen.ready":         "PREPARADO",
		"kitchen.ends":          "termina %s",
		"kitchen.invalid":       "Prueba algo como  10m pasta",
		"kitchen.default":       "Temporizador",
		"kitchen.done.body":     "¡Ya está!",
		"kitchen.more":          "+%d más",
		"kitchen.added":         "Iniciado: %s",

		"versus.setup":      "Reloj de dos jugadores",
		"versus.start":      "iniciar",
		"versus.switch":     "cambiar turno",
		"versus.pause":      "pausar",
		"versus.resume":     "continuar",
		"versus.reset":      "reiniciar",
		"versus.flip":       "girar",
		"versus.edit":       "personalizar",
		"versus.first":      "empieza",
		"versus.preset":     "tiempo",
		"versus.flag":       "¡Tiempo!",
		"versus.flag.body":  "Al jugador %d se le acabó el tiempo",
		"versus.moves":      "jugadas",
		"versus.minutes":    "minutos",
		"versus.inc":        "incremento",
		"versus.delay":      "retraso",
		"versus.press":      "pulsa espacio para empezar",
		"versus.custom":     "Personalizado",
		"versus.paused":     "EN PAUSA",
		"versus.starts":     "Empieza el jugador %d",
		"versus.over":       "FIN DE LA PARTIDA",
		"versus.adjust":     "ajustar",
		"versus.field":      "campo",
		"versus.done":       "listo",
		"versus.secs":       "%ds",
		"versus.none":       "no",
		"versus.p":          "Jugador %d",
		"help.mode.kitchen": helpKitchenES,
		"help.mode.versus":  helpVersusES,
	} {
		es[k] = v
	}
}

const helpKitchenES = `## Cocina

Varios temporizadores con nombre a la vez. Siguen corriendo mientras estás en otro modo.

| Tecla | Acción |
| --- | --- |
| ` + "`n`" + ` | nuevo temporizador: ` + "`10m pasta`" + `, ` + "`1h30 asado`" + `, ` + "`90 té`" + ` (un número solo son minutos) |
| ` + "`←` `→`" + ` | en la entrada: elegir un atajo (1-60 min) |
| ` + "`↑` `↓`" + ` | elegir temporizador |
| ` + "`espacio`" + ` | pausar / continuar / iniciar |
| ` + "`r`" + ` | reiniciar el seleccionado |
| ` + "`+` `-`" + ` | sumar / restar un minuto |
| ` + "`x`" + ` | borrar (luego ` + "`s`" + ` para confirmar) |
`

const helpVersusES = `## Duelo

Reloj de ajedrez para dos jugadores, con incremento y retraso.

| Tecla | Acción |
| --- | --- |
| ` + "`←` `→`" + ` | preparación: elegir el control de tiempo |
| ` + "`e`" + ` | preparación: editar uno personalizado (` + "`↑` `↓`" + ` ajustan, ` + "`←` `→`" + ` campo) |
| ` + "`s`" + ` | preparación: quién mueve primero |
| ` + "`espacio` `enter`" + ` | iniciar / cambiar turno (también con clic en tu mitad) |
| ` + "`p`" + ` | pausar / continuar |
| ` + "`v`" + ` | girar 180° la mitad de arriba para jugar cara a cara |
| ` + "`r`" + ` | volver a la preparación |
`
