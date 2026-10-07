package i18n

func init() {
	for k, v := range map[string]string{
		"alarm.header":           "ALARMAS",
		"alarm.next":             "SIGUIENTE",
		"alarm.in":               "en %s",
		"alarm.off":              "apagada",
		"alarm.snoozed":          "pospuesta · %s",
		"alarm.days":             "LMXJVSD",
		"alarm.weekdays":         "domingo,lunes,martes,miércoles,jueves,viernes,sábado",
		"alarm.once":             "una vez",
		"alarm.d.weekdays":       "entre semana",
		"alarm.d.weekend":        "fin de semana",
		"alarm.d.everyday":       "todos los días",
		"alarm.label":            "Etiqueta",
		"alarm.label.hint":       "Etiqueta (opcional)",
		"alarm.title.new":        "NUEVA ALARMA",
		"alarm.title.edit":       "EDITAR ALARMA",
		"alarm.empty.title":      "Aún no hay alarmas",
		"alarm.empty.hint":       "Pulsa n para crear la primera",
		"alarm.none.armed":       "Nada programado",
		"alarm.preview.today":    "Sonará hoy a las %s (en %s)",
		"alarm.preview.tomorrow": "Sonará mañana a las %s (en %s)",
		"alarm.preview.day":      "Sonará el %[3]s a las %[1]s (en %[2]s)",
		"alarm.confirm":          "¿Borrar %s?",
		"alarm.confirm.hint":     "enter confirmar · esc cancelar",
		"alarm.on.toast":         "Alarma activada · sonará en %s",
		"alarm.off.toast":        "Alarma apagada",
		"alarm.saved":            "Alarma guardada · sonará en %s",
		"alarm.deleted":          "Alarma borrada",
		"alarm.more":             "%d más",
		"alarm.k.move":           "mover",
		"alarm.k.toggle":         "activar",
		"alarm.k.new":            "nueva",
		"alarm.k.edit":           "editar",
		"alarm.k.delete":         "borrar",
		"alarm.k.field":          "campo",
		"alarm.k.change":         "cambiar",
		"alarm.k.day":            "día",
		"alarm.k.days":           "días",
		"alarm.k.save":           "guardar",
		"help.mode.alarm":        helpAlarmES,
	} {
		es[k] = v
	}
}

const helpAlarmES = `## Alarma

| Tecla | Acción |
| --- | --- |
| ` + "`↑` `↓`" + ` | moverte entre alarmas |
| ` + "`espacio`" + ` | activar / apagar la alarma |
| ` + "`n`" + ` | nueva alarma |
| ` + "`e` `enter`" + ` | editar |
| ` + "`x`" + ` | borrar (pregunta antes) |

Al editar: ` + "`←` `→`" + ` o ` + "`tab`" + ` te mueven entre hora, minuto, días y etiqueta; ` + "`↑` `↓`" + ` cambian el
valor (con ` + "`shift`" + ` saltos más grandes; también puedes teclear los dígitos); ` + "`espacio`" + ` marca un día;
` + "`w`" + ` entre semana, ` + "`e`" + ` fin de semana, ` + "`a`" + ` todos los días, ` + "`o`" + ` una vez; ` + "`enter`" + ` guarda, ` + "`esc`" + ` cancela.
Cuando suena una alarma: ` + "`enter`" + ` la silencia, ` + "`z`" + ` la pospone 5 minutos.
`
