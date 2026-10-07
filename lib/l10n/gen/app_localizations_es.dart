// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => 'Ajustes';

  @override
  String get tooltipStats => 'Estadísticas';

  @override
  String get tooltipPin => 'Mantener siempre visible';

  @override
  String get tooltipUnpin => 'Quitar de siempre visible';

  @override
  String get phasePaused => 'En pausa';

  @override
  String get phaseFocus => 'Enfoque';

  @override
  String get phaseRelax => 'Descanso';

  @override
  String get notifRestTitle => 'Hora de descansar';

  @override
  String get notifRestBody => 'Toma un respiro.';

  @override
  String get notifWorkTitle => 'Hora de trabajar';

  @override
  String get notifWorkBody => '¡Sigamos con el trabajo!';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get rhythmTitle => 'Ritmo de enfoque';

  @override
  String get presetClassic => 'Clásico';

  @override
  String get presetExtended => 'Extendido';

  @override
  String get presetDeep => 'Profundo';

  @override
  String get presetManual => 'Manual';

  @override
  String get workLabel => 'Enfoque';

  @override
  String get restLabel => 'Descanso';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest min';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get timersTitle => 'Tiempos';

  @override
  String timersSubtitle(int work, int rest) {
    return '$work min enfoque · $rest min descanso';
  }

  @override
  String timersCycle(int total) {
    return 'Un ciclo completo: $total min';
  }

  @override
  String get timersApplyHint =>
      'Si el reloj está en marcha, el cambio se aplica desde el siguiente ciclo. Si está en pausa, el reloj se reinicia.';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceLight => 'Tema claro';

  @override
  String get appearanceDark => 'Tema oscuro';

  @override
  String get darkTheme => 'Tema oscuro';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsOn => 'Activadas';

  @override
  String get notificationsOff => 'Desactivadas';

  @override
  String get notificationsToggle => 'Avisos al cambiar de fase';

  @override
  String get notificationsHint =>
      'Recibe un aviso cuando toque descansar o volver al trabajo.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageHint => 'Elige el idioma de la app.';

  @override
  String get supportTitle => 'Apoya a Enfo';

  @override
  String get supportSubtitleNoAds => 'Donaciones y café';

  @override
  String get buyCoffee => 'Invítame un café';

  @override
  String get supportHint =>
      'Enfo es gratis y lo hace una sola persona. Gracias por usarlo.';

  @override
  String get rateApp => 'Califica Enfo';

  @override
  String get shareApp => 'Comparte Enfo';

  @override
  String shareMessage(String url) {
    return 'Enfo, una caja de herramientas de relojes y temporizadores para Android: $url';
  }

  @override
  String get donateTitle => 'Donar';

  @override
  String get donateSubtitle => 'Pago único, con Google Play';

  @override
  String get donateHint =>
      'Enfo es gratis y sin anuncios. Si quieres apoyarlo, puedes dejar una donación única con Google Play. ¡Gracias!';

  @override
  String get donateUnavailable =>
      'Las donaciones no están disponibles ahora mismo. Puedes invitarme a un café.';

  @override
  String get donateThanks => '¡Gracias por apoyar a Enfo!';

  @override
  String get donatePending => 'Compra pendiente…';

  @override
  String get donateError =>
      'No se pudo completar la compra. No se te cobró nada.';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsEmpty =>
      'Aún no hay sesiones.\nInicia un pomodoro y aparecerá aquí.';

  @override
  String get statsTodayPomodoros => 'Pomodoros hoy';

  @override
  String get statsTodayFocus => 'Enfoque hoy';

  @override
  String get statsCompleted => 'Completados';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Días seguidos',
      one: 'Día seguido',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => 'Últimos 7 días';

  @override
  String get statsTotalFocus => 'Tiempo total de enfoque';

  @override
  String get statsTotalRest => 'Tiempo total de descanso';

  @override
  String get statsAbandoned => 'Abandonados';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent% completados';
  }

  @override
  String get statsAverageFocus => 'Enfoque promedio';

  @override
  String get statsLongestSession => 'Sesión más larga';

  @override
  String get statsPauses => 'Pausas';

  @override
  String get statsAverageGap => 'Espera promedio entre sesiones';

  @override
  String get statsLongestGap => 'Mayor tiempo sin activar';

  @override
  String get statsSinceLast => 'Desde la última sesión';

  @override
  String get statsHistory => 'Historial';

  @override
  String get statsClearHistory => 'Borrar historial';

  @override
  String get statsClearConfirm => 'Confirmar: borrar todas las sesiones';

  @override
  String get statsClearHint => 'Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get sessionFocus => 'Enfoque';

  @override
  String get sessionRest => 'Descanso';

  @override
  String sessionProgress(String done, String planned) {
    return '$done de $planned';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pausas',
      one: '1 pausa',
    );
    return '$_temp0 ($time)';
  }

  @override
  String sessionIdleBefore(String gap) {
    return 'tras $gap inactivo';
  }

  @override
  String get sessionCompleted => 'Completado';

  @override
  String get sessionAbandoned => 'Abandonado';

  @override
  String get clockStyleTitle => 'Estilo de reloj';

  @override
  String get tooltipClockStyle => 'Estilo de reloj';

  @override
  String get clockCategoryProgress => 'Progreso y números';

  @override
  String get clockCategoryNumbers => 'Solo números';

  @override
  String get clockCategoryIcons => 'Solo icono';

  @override
  String get clockCategoryMotion => 'Solo animación';

  @override
  String get clockUnitMinutes => 'min';

  @override
  String get clockUnitSeconds => 'seg';

  @override
  String get clockRing => 'Anillo';

  @override
  String get clockWavyRing => 'Onda';

  @override
  String get clockSegments => 'Segmentos';

  @override
  String get clockOrbit => 'Órbita';

  @override
  String get clockPie => 'Tarta';

  @override
  String get clockKitchen => 'Cocina';

  @override
  String get clockDots => 'Puntos';

  @override
  String get clockBar => 'Barra';

  @override
  String get clockWavyBar => 'Ola';

  @override
  String get clockDigits => 'Dígitos';

  @override
  String get clockMinutes => 'Minutos';

  @override
  String get clockTiles => 'Fichas';

  @override
  String get clockStack => 'Apilado';

  @override
  String get clockTomato => 'Tomate';

  @override
  String get clockHourglass => 'Arena';

  @override
  String get clockBattery => 'Batería';

  @override
  String get clockIcon => 'Icono';

  @override
  String get clockCookie => 'Galleta';

  @override
  String get clockLiquid => 'Líquido';

  @override
  String get clockBreathe => 'Respira';

  @override
  String get clockEqualizer => 'Ecualizador';

  @override
  String get clockRipple => 'Ondas';

  @override
  String get accentApply => 'Aplicar';

  @override
  String get accentCustom => 'Color personalizado';

  @override
  String get accentHue => 'Tono';

  @override
  String get accentSaturation => 'Saturación';

  @override
  String get accentBrightness => 'Brillo';

  @override
  String get accentHex => 'Código hex';

  @override
  String get displayTitle => 'Pantalla';

  @override
  String get displayClockShown => 'Hora visible';

  @override
  String get displayClockHidden => 'Hora oculta';

  @override
  String get showClock => 'Mostrar la hora';

  @override
  String get showClockHint => 'El reloj pequeño sobre el temporizador.';

  @override
  String get clockFormat => 'Formato de hora';

  @override
  String get clockFormatSystem => 'Predeterminado del sistema';

  @override
  String get clockFormat12 => '12 horas';

  @override
  String get clockFormat24 => '24 horas';

  @override
  String get behaviorTitle => 'Comportamiento';

  @override
  String get autoStartNext => 'Iniciar la siguiente fase automáticamente';

  @override
  String get autoStartNextHint =>
      'Al terminar el enfoque o el descanso, empieza el siguiente sin tocar.';

  @override
  String get hapticFeedback => 'Vibración';

  @override
  String get hapticFeedbackHint => 'Toques, ruedas, cambios de fase y alarmas.';

  @override
  String get clockCombosTitle => 'Combos';

  @override
  String get clockCollapseAll => 'Contraer todo';

  @override
  String get clockExpandAll => 'Expandir todo';

  @override
  String get comboDeepFocus => 'Enfoque profundo';

  @override
  String get comboMint => 'Menta fresca';

  @override
  String get comboSunset => 'Atardecer';

  @override
  String get comboZen => 'Zen';

  @override
  String get comboTomato => 'Tomate clásico';

  @override
  String get comboNight => 'Búho nocturno';

  @override
  String get comboPlayful => 'Juguetón';

  @override
  String get comboMinimal => 'Minimalista';

  @override
  String get uiSizeTitle => 'Tamaño de la interfaz';

  @override
  String get uiSizeSmall => 'Pequeño';

  @override
  String get uiSizeNormal => 'Normal';

  @override
  String get uiSizeLarge => 'Grande';

  @override
  String get uiSizeExtraLarge => 'Extra grande';

  @override
  String get uiSizeHint =>
      'Hace el texto y los controles más grandes o pequeños. Útil en TV y pantallas de auto.';

  @override
  String get clockBlob => 'Blob';

  @override
  String get clockFlower => 'Flor';

  @override
  String get clockSun => 'Sol';

  @override
  String get clockGears => 'Engranes';

  @override
  String get clockBubbles => 'Burbujas';

  @override
  String get clockSunflower => 'Girasol';

  @override
  String get clockFireflies => 'Luciérnagas';

  @override
  String get clockPendulum => 'Péndulo';

  @override
  String get clockBounce => 'Rebote';

  @override
  String get clockMorph => 'Morfo';

  @override
  String get dataTitle => 'Datos';

  @override
  String get dataSubtitle => 'Historial, restablecer e introducción';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros guardados',
      one: '1 registro guardado',
      zero: 'Sin actividad guardada',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'Ver la introducción de nuevo';

  @override
  String get dataIntroHint =>
      'Repasa la pantalla de bienvenida y elige tu ritmo otra vez. No se borra nada.';

  @override
  String get dataClearHistoryHint =>
      'Elimina toda la actividad registrada: pomodoros, temporizadores, cronómetros, alarmas y tiempo de reloj. Los ajustes no cambian.';

  @override
  String get dataConfirmClearHistory => 'Confirmar: borrar historial';

  @override
  String get dataResetSettings => 'Restablecer ajustes';

  @override
  String get dataResetSettingsHint =>
      'Tiempos, tema, color de acento, idioma, modos y pantalla vuelven a los valores originales. El historial se conserva.';

  @override
  String get dataConfirmResetSettings => 'Confirmar: restablecer ajustes';

  @override
  String get dataEraseAll => 'Borrar todo';

  @override
  String get dataEraseAllHint =>
      'Elimina historial y ajustes y empieza de cero, como la primera vez.';

  @override
  String get dataConfirmEraseAll => 'Confirmar: borrar todo';

  @override
  String get dataDoneHistory => 'Historial borrado.';

  @override
  String get dataDoneSettings => 'Ajustes restablecidos.';

  @override
  String get dataCacheNote =>
      'Enfo no guarda caché: todo lo que almacena es el historial y los ajustes descritos aquí.';

  @override
  String get clockEndsAt => 'Termina';

  @override
  String get clockFill => 'Relleno';

  @override
  String get clockCapsule => 'Cápsula';

  @override
  String get clockRollers => 'Rodillo';

  @override
  String get clockMatrix => 'Matriz';

  @override
  String get clockSevenSeg => 'Digital';

  @override
  String get clockFlip => 'Flip';

  @override
  String get clockFine => 'Fino';

  @override
  String get clockSuperscript => 'Exponente';

  @override
  String get clockPercent => 'Porcentaje';

  @override
  String get clockEndTime => 'Termina a las';

  @override
  String get clockSeconds => 'Segundos';

  @override
  String get clockTall => 'Alto';

  @override
  String get clockWobble => 'Ondulado';

  @override
  String get clockLabeled => 'Etiquetado';

  @override
  String get clockGauge => 'Medidor';

  @override
  String get clockNeedle => 'Aguja';

  @override
  String get clockAnalog => 'Analógico';

  @override
  String get clockRings => 'Anillos';

  @override
  String get clockSquircle => 'Cuadrado';

  @override
  String get clockColumns => 'Columnas';

  @override
  String get clockVertical => 'Vertical';

  @override
  String get clockSteps => 'Pasos';

  @override
  String get clockBlocks => 'Bloques';

  @override
  String get clockSpiral => 'Espiral';

  @override
  String get clockSlices => 'Gajos';

  @override
  String get clockPills => 'Píldoras';

  @override
  String get clockHexagon => 'Hexágono';

  @override
  String get clockStairs => 'Escalera';

  @override
  String get clockCandle => 'Vela';

  @override
  String get clockMoon => 'Luna';

  @override
  String get clockRuler => 'Regla';

  @override
  String get comboArcade => 'Arcade';

  @override
  String get comboCalculator => 'Calculadora';

  @override
  String get comboDepartures => 'Estación de trenes';

  @override
  String get comboCandlelight => 'A la luz de una vela';

  @override
  String get comboMoonlight => 'Luz de luna';

  @override
  String get comboGarden => 'Jardín';

  @override
  String get comboSummer => 'Verano';

  @override
  String get comboWorkshop => 'Taller';

  @override
  String get comboFizzy => 'Burbujeante';

  @override
  String get comboSunfield => 'Campo de girasoles';

  @override
  String get comboSummerNight => 'Noche de verano';

  @override
  String get comboHypnosis => 'Hipnosis';

  @override
  String get comboBouncy => 'Saltarín';

  @override
  String get comboShapeshifter => 'Cambiaformas';

  @override
  String get comboLava => 'Lámpara de lava';

  @override
  String get comboOcean => 'Océano';

  @override
  String get comboPulse => 'Pulso';

  @override
  String get comboPond => 'Estanque';

  @override
  String get comboEspresso => 'Espresso';

  @override
  String get comboSpeedometer => 'Velocímetro';

  @override
  String get comboCompass => 'Brújula';

  @override
  String get comboClassicClock => 'Reloj clásico';

  @override
  String get comboConcentric => 'Concéntrico';

  @override
  String get comboRounded => 'Redondeado';

  @override
  String get comboSignal => 'Señal';

  @override
  String get comboThermometer => 'Termómetro';

  @override
  String get comboMilestones => 'Hitos';

  @override
  String get comboRetroBlocks => 'Bloques retro';

  @override
  String get comboHypnoSpiral => 'Espiral hipnótica';

  @override
  String get comboCitrus => 'Cítrico';

  @override
  String get comboChocolate => 'Barra de chocolate';

  @override
  String get comboCrystal => 'Cristal';

  @override
  String get comboStaircase => 'Escalera';

  @override
  String get comboTapeMeasure => 'Cinta métrica';

  @override
  String get comboBoldType => 'Tipografía audaz';

  @override
  String get comboPill => 'Cápsula';

  @override
  String get comboSlotMachine => 'Tragamonedas';

  @override
  String get comboWhisper => 'Susurro';

  @override
  String get comboDeadline => 'Fecha límite';

  @override
  String get comboPercentage => 'Porcentaje';

  @override
  String get comboStopwatch => 'Solo segundos';

  @override
  String get comboSkyscraper => 'Rascacielos';

  @override
  String get comboWaveText => 'Texto ondulado';

  @override
  String get comboDashboard => 'Panel';

  @override
  String get comboExponent => 'Exponente';

  @override
  String get comboGrandmaKitchen => 'Cocina de la abuela';

  @override
  String get comboCyber => 'Cyber';

  @override
  String get comboCandy => 'Caramelo';

  @override
  String get comboConfetti => 'Confeti';

  @override
  String get comboCookieJar => 'Galletero';

  @override
  String get comboSandbox => 'Arenero';

  @override
  String get comboPizzaNight => 'Noche de pizza';

  @override
  String get onbLanguageTitle => 'Tu idioma';

  @override
  String get onbLanguageBody =>
      'Elige tu idioma. Todo lo que elijas aquí se puede cambiar después en Ajustes.';

  @override
  String get onbRhythmTitle => 'Tu ritmo';

  @override
  String get onbRhythmBody => 'Cuánto tiempo te enfocas y cuánto descansas.';

  @override
  String get onbLookTitle => 'Hazlo tuyo';

  @override
  String get onbLookBody =>
      'Tema, estilo de reloj y color. Empieza con un combo y ajusta el color si quieres.';

  @override
  String get onbClockTitle => 'Elige un reloj';

  @override
  String get onbClockBody =>
      'Combinaciones listas: un estilo de reloj y un color con un toque.';

  @override
  String get onbAllStyles => 'Ver todos los estilos';

  @override
  String get onbOptionsTitle => 'Últimos detalles';

  @override
  String get onbOptionsBody =>
      'Pantalla y comportamiento. Todo esto también está en Ajustes.';

  @override
  String get onbModesTitle => 'Tus herramientas';

  @override
  String get onbModesBody =>
      'Enfo es una caja de herramientas de relojes y temporizadores. Activa lo que vas a usar; puedes cambiarlo cuando quieras desde el menú de modos.';

  @override
  String get onbPreview => 'Vista previa';

  @override
  String get onbDisplayTitle => 'Pantalla';

  @override
  String get onbDisplayBody => 'Cómo se ve el reloj y qué tan grande es todo.';

  @override
  String get onbClockModeDesign => 'Diseño del modo Reloj';

  @override
  String get onbPermTitle => 'Permisos';

  @override
  String get onbPermBody =>
      'Para que temporizadores y alarmas te avisen aunque Enfo esté cerrado.';

  @override
  String get onbPermNotifications => 'Notificaciones';

  @override
  String get onbPermNotificationsHint =>
      'Avisos cuando termina un temporizador o suena una alarma.';

  @override
  String get onbPermExact => 'Alarmas exactas';

  @override
  String get onbPermExactHint =>
      'Suenan en el minuto exacto, incluso con ahorro de batería.';

  @override
  String get onbPermAllow => 'Permitir';

  @override
  String get onbPermAllowed => 'Permitido';

  @override
  String get onbPermLater =>
      'Puedes cambiarlo cuando quieras en los ajustes del sistema.';

  @override
  String get onbNext => 'Siguiente';

  @override
  String get onbBack => 'Atrás';

  @override
  String get onbSkip => 'Omitir';

  @override
  String onbStepOf(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get clockFormatAuto => 'Auto';

  @override
  String get modePomodoro => 'Pomodoro';

  @override
  String get modeClock => 'Reloj';

  @override
  String get modeTimer => 'Temporizador';

  @override
  String get modeStopwatch => 'Cronómetro';

  @override
  String get modeAlarm => 'Alarma';

  @override
  String get modeWorld => 'Hora mundial';

  @override
  String get modeDescPomodoro => 'Ciclos de enfoque y descanso';

  @override
  String get modeDescClock => 'Un reloj hermoso, siempre visible';

  @override
  String get modeDescTimer => 'Cuenta regresiva desde cualquier tiempo';

  @override
  String get modeDescStopwatch => 'Mide el tiempo, con vueltas';

  @override
  String get modeDescAlarm => 'Despierta o recibe recordatorios';

  @override
  String get modeDescWorld => 'La hora en ciudades del mundo';

  @override
  String get tooltipModes => 'Modos';

  @override
  String get tooltipSwitchMode => 'Siguiente modo';

  @override
  String get tooltipFullscreen => 'Pantalla completa';

  @override
  String get tooltipExitFullscreen => 'Salir de pantalla completa';

  @override
  String get tooltipDim => 'Atenuar la pantalla';

  @override
  String get modesTitle => 'Modos';

  @override
  String get modesHint =>
      'Elige los modos que usas y su orden. Arrastra para reordenar.';

  @override
  String get modesStart => 'Iniciar con';

  @override
  String get modesStartLast => 'Último modo usado';

  @override
  String get modesCustomize => 'Personalizar';

  @override
  String get modesActivity => 'Historial de actividad';

  @override
  String get modesAtLeastOne => 'Debe quedar al menos un modo activo.';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modos activos',
      one: '1 modo activo',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'Historial de actividad';

  @override
  String get activityTitle => 'Actividad';

  @override
  String get activityEmpty =>
      'Aún no hay nada.\nUsa un temporizador, un cronómetro, una alarma o el reloj y aparecerá aquí.';

  @override
  String get activityFilterAll => 'Todo';

  @override
  String get activityTimersToday => 'Temporizadores hoy';

  @override
  String get activityStopwatchToday => 'Cronómetro hoy';

  @override
  String get activityDisplayToday => 'En pantalla hoy';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vueltas',
      one: '1 vuelta',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'Vuelta $n';
  }

  @override
  String get activityAlarmDismissed => 'Detenida';

  @override
  String get activityAlarmSnoozed => 'Pospuesta';

  @override
  String get activityAlarmMissed => 'Perdida';

  @override
  String activityDisplay(String mode) {
    return '$mode en pantalla';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done de $planned';
  }

  @override
  String get faceRing => 'Anillo';

  @override
  String get faceDigital => 'Digital';

  @override
  String get faceAnalog => 'Analógico';

  @override
  String get faceSplit => 'Grande';

  @override
  String get faceDay => 'Día';

  @override
  String get tooltipCustomize => 'Personalizar';

  @override
  String get clockSettingsTitle => 'Personalizar el reloj';

  @override
  String get clockFaceTitle => 'Diseño';

  @override
  String get clockShowSeconds => 'Mostrar segundos';

  @override
  String get clockShowDate => 'Mostrar la fecha';

  @override
  String get clockBlinkColon => 'Dos puntos parpadeantes';

  @override
  String get clockKeepAwake => 'Mantener la pantalla encendida';

  @override
  String get clockKeepAwakeHint => 'Mientras el reloj está visible.';

  @override
  String get clockFullscreenHint =>
      'Toca pantalla completa para un reloj de escritorio que se queda encendido. Desliza el reloj para cambiar su diseño.';

  @override
  String clockDayPercent(int percent) {
    return '$percent% del día';
  }

  @override
  String get ringDismiss => 'Detener';

  @override
  String ringSnooze(int minutes) {
    return 'Posponer $minutes min';
  }

  @override
  String get timerStart => 'Iniciar';

  @override
  String get timerPause => 'Pausar';

  @override
  String get timerResume => 'Reanudar';

  @override
  String get timerReset => 'Reiniciar';

  @override
  String get timerAddMinute => '+1 min';

  @override
  String get timerHoursShort => 'h';

  @override
  String get timerMinutesShort => 'min';

  @override
  String get timerSecondsShort => 's';

  @override
  String get timerUpTitle => 'Se acabó el tiempo';

  @override
  String timerUpBody(String duration) {
    return 'Terminó el temporizador de $duration.';
  }

  @override
  String get timerSavePreset => 'Guardar este tiempo';

  @override
  String get timerPresetHint =>
      'Toca + para guardar este tiempo. Mantén presionado un preajuste para quitarlo.';

  @override
  String get stopwatchStop => 'Parar';

  @override
  String get stopwatchLap => 'Vuelta';

  @override
  String get stopwatchLapBest => 'Mejor';

  @override
  String get stopwatchLapWorst => 'Más lenta';

  @override
  String get worldLocal => 'Hora local';

  @override
  String get worldToday => 'Hoy';

  @override
  String get worldTomorrow => 'Mañana';

  @override
  String get worldYesterday => 'Ayer';

  @override
  String get worldAdd => 'Agregar una ciudad';

  @override
  String get worldSearch => 'Buscar ciudades';

  @override
  String get worldNoResults => 'Ninguna ciudad coincide.';

  @override
  String get worldEdit => 'Editar lista';

  @override
  String get worldDone => 'Listo';

  @override
  String get worldRemove => 'Quitar';

  @override
  String get worldEmpty =>
      'Aún no hay otras ciudades. Toca + para agregar una.';

  @override
  String get worldSameTime => 'Misma hora que tú';

  @override
  String worldDiffAhead(String diff) {
    return '$diff por delante de ti';
  }

  @override
  String worldDiffBehind(String diff) {
    return '$diff por detrás de ti';
  }

  @override
  String alarmNext(String duration) {
    return 'Próxima alarma en $duration';
  }

  @override
  String get alarmNone => 'Sin alarmas activas';

  @override
  String get alarmNew => 'Nueva alarma';

  @override
  String get alarmEditTitle => 'Editar alarma';

  @override
  String get alarmLabel => 'Etiqueta';

  @override
  String get alarmRepeat => 'Repetir';

  @override
  String get alarmSave => 'Guardar';

  @override
  String get alarmDelete => 'Eliminar alarma';

  @override
  String get alarmConfirmDelete => 'Confirmar: eliminar alarma';

  @override
  String get alarmDeleteHint => 'Esta alarma se eliminará.';

  @override
  String get alarmEmpty => 'Aún no hay alarmas.\nToca + para crear una.';

  @override
  String get alarmEveryDay => 'Todos los días';

  @override
  String get alarmWeekdays => 'Entre semana';

  @override
  String get alarmWeekends => 'Fines de semana';

  @override
  String get alarmOnce => 'Una vez';

  @override
  String get alarmPermissionHint =>
      'Para sonar con la app cerrada, Enfo necesita permiso para notificaciones y alarmas exactas.';

  @override
  String get alarmPermissionButton => 'Permitir alarmas';

  @override
  String get alarmDesktopHint =>
      'En este dispositivo Enfo debe estar abierto para que suenen las alarmas.';

  @override
  String get hapticsTitle => 'Vibración';

  @override
  String get hapticsOff => 'Desactivada';

  @override
  String get hapticsStrength => 'Intensidad';

  @override
  String get hapticsSoft => 'Suave';

  @override
  String get hapticsMedium => 'Media';

  @override
  String get hapticsStrong => 'Fuerte';

  @override
  String get hapticsTouch => 'Toque';

  @override
  String get hapticsTouchHint => 'Botones, interruptores y selecciones.';

  @override
  String get hapticsMotion => 'Movimiento';

  @override
  String get hapticsMotionHint =>
      'Ruedas, deslizadores, arrastre y transiciones.';

  @override
  String get hapticsAlerts => 'Alertas';

  @override
  String get hapticsAlertsHint =>
      'Temporizadores, cambios de fase, la cuenta final y alarmas.';

  @override
  String get hapticsAlarmPattern => 'Patrón de la alarma';

  @override
  String get hapticsAlarmPatternHint =>
      'Toca un patrón para sentirlo. La pantalla de la alarma late con el mismo ritmo.';

  @override
  String get hapticsPatternHeartbeat => 'Latido';

  @override
  String get hapticsPatternPulse => 'Pulso';

  @override
  String get hapticsPatternCrescendo => 'Crescendo';

  @override
  String get hapticsPatternRipple => 'Ondas';

  @override
  String get hapticsPatternBeacon => 'Faro';

  @override
  String get hapticsTry => 'Pruébalo';

  @override
  String get hapticsTryTap => 'Toque';

  @override
  String get hapticsTrySuccess => 'Éxito';

  @override
  String get hapticsTryToRest => 'Fin del enfoque';

  @override
  String get hapticsTryToWork => 'Fin del descanso';

  @override
  String get hapticsTryTimer => 'Fin del temporizador';

  @override
  String get hapticsTryWarning => 'Aviso';

  @override
  String get hapticsUnavailable =>
      'Este dispositivo no tiene motor de vibración.';

  @override
  String get hapticsWhen => 'Cuándo vibra';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSubtitle =>
      'Relojes y temporizadores en tu pantalla de inicio';

  @override
  String get widgetsAddHeader => 'Añadir a la pantalla de inicio';

  @override
  String get widgetsAdd => 'Añadir';

  @override
  String get widgetsDynamicColor => 'Colores Material You';

  @override
  String get widgetsDynamicColorHint =>
      'Los widgets toman sus colores de tu fondo de pantalla. Desactívalo para usar el color de acento de Enfo.';

  @override
  String get widgetsManualHint =>
      'Tu launcher no permite añadir widgets desde aquí. Mantén pulsada la pantalla de inicio, elige Widgets y busca Enfo.';

  @override
  String get widgetsStyleHint =>
      'Los widgets de Pomodoro y temporizador se dibujan con el estilo de reloj que elegiste. Cambia el estilo en la app y lo siguen.';

  @override
  String get widgetsTapHint =>
      'Los botones de un widget abren Enfo y hacen la acción, así el tiempo siempre lo lleva la app.';

  @override
  String get shortcutsTitle => 'Teclado y control remoto';

  @override
  String get shortcutsSubtitle =>
      'Atajos para teclado, mouse y control de la tele';

  @override
  String get shortcutsIntro =>
      'Las flechas o el D-pad del control se mueven, Enter u OK presiona. Estas teclas hacen el resto.';

  @override
  String get shortcutKeySpace => 'Espacio';

  @override
  String get shortcutPlayPause => 'Iniciar o pausar';

  @override
  String get shortcutReset => 'Reiniciar';

  @override
  String get shortcutLap => 'Vuelta (cronómetro)';

  @override
  String get shortcutJumpMode => 'Ir al modo 1–9';

  @override
  String get shortcutStepMode => 'Modo anterior / siguiente';

  @override
  String get shortcutFullscreen => 'Pantalla completa';

  @override
  String get shortcutDim => 'Atenuar la pantalla (pantalla completa)';

  @override
  String get shortcutSettings => 'Ajustes';

  @override
  String get shortcutModes => 'Menú de modos';

  @override
  String get shortcutBack => 'Atrás / salir de pantalla completa';

  @override
  String get shortcutHelp => 'Mostrar esta lista';

  @override
  String get onbMoreTools => 'Más herramientas';

  @override
  String get modeEvent => 'Eventos';

  @override
  String get modeDescEvent => 'Cuenta los días hasta lo importante';

  @override
  String get modeIntervals => 'Intervalos';

  @override
  String get modeDescIntervals => 'Rondas de trabajo y descanso, como HIIT';

  @override
  String get modeBreathe => 'Respirar';

  @override
  String get modeDescBreathe => 'Respiración guiada para calmarte';

  @override
  String get modeTracker => 'Registro';

  @override
  String get modeDescTracker => 'Mide lo que haces y mira los totales';

  @override
  String get modeKitchen => 'Cocina';

  @override
  String get modeDescKitchen => 'Varios temporizadores con nombre a la vez';

  @override
  String get modeSleep => 'Sueño';

  @override
  String get modeDescSleep => 'Planea dormir y despertar por ciclos de sueño';

  @override
  String get modeVersus => 'Turnos';

  @override
  String get modeDescVersus => 'Reloj de dos para ajedrez, juegos y debates';

  @override
  String get modeBreaks => 'Pausas';

  @override
  String get modeDescBreaks =>
      'Recordatorios para descansar la vista y estirarte';

  @override
  String get modeAmbient => 'Ambiente';

  @override
  String get modeDescAmbient => 'Sonidos de fondo con temporizador de apagado';

  @override
  String get intervalsPresetTabata => 'Tabata';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'Personalizado';

  @override
  String get intervalsWarmUp => 'Calentamiento';

  @override
  String get intervalsWork => 'Trabajo';

  @override
  String get intervalsRest => 'Descanso';

  @override
  String get intervalsRounds => 'Rondas';

  @override
  String get intervalsCoolDown => 'Enfriamiento';

  @override
  String get intervalsOff => 'No';

  @override
  String intervalsRound(int current, int total) {
    return 'Ronda $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return 'Total $duration';
  }

  @override
  String get intervalsSkip => 'Saltar a la siguiente fase';

  @override
  String get intervalsHint =>
      'Toca una fila para editarla. Cualquier cambio se guarda como Personalizado.';

  @override
  String get intervalsDoneTitle => 'Entrenamiento completado';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration. ¡Buen trabajo!';
  }

  @override
  String get kitchenPasta => 'Pasta';

  @override
  String get kitchenEggs => 'Huevos';

  @override
  String get kitchenTea => 'Té';

  @override
  String get kitchenRice => 'Arroz';

  @override
  String get kitchenOven => 'Horno';

  @override
  String get kitchenCustom => 'Otro';

  @override
  String get kitchenNameHint => 'Nombre';

  @override
  String get kitchenAdd => 'Iniciar temporizador';

  @override
  String get kitchenDelete => 'Eliminar temporizador';

  @override
  String get kitchenEmpty =>
      'Aún no hay temporizadores. Toca uno de arriba para empezar.';

  @override
  String get kitchenDefaultName => 'Temporizador';

  @override
  String kitchenDoneTitle(String name) {
    return '$name está listo';
  }

  @override
  String kitchenDoneBody(String duration) {
    return 'El temporizador de $duration terminó.';
  }

  @override
  String get trackerToday => 'Hoy';

  @override
  String get trackerWeek => 'Últimos 7 días';

  @override
  String get trackerTapToStart => 'Toca una actividad para empezar a medirla';

  @override
  String get trackerNoRunning => 'Nada en marcha';

  @override
  String get trackerAddActivity => 'Nueva actividad';

  @override
  String get trackerNameHint => 'Nombre';

  @override
  String get trackerStudy => 'Estudio';

  @override
  String get trackerReading => 'Lectura';

  @override
  String get trackerCode => 'Código';

  @override
  String get trackerExercise => 'Ejercicio';

  @override
  String get trackerEdit => 'Editar actividad';

  @override
  String get trackerDetails => 'Detalles y gráfica';

  @override
  String get trackerColor => 'Color';

  @override
  String get trackerIcon => 'Icono';

  @override
  String get trackerDelete => 'Eliminar actividad';

  @override
  String get trackerDeleteConfirm => 'Confirmar: eliminar esta actividad';

  @override
  String get trackerDeleteHint =>
      'El tiempo ya registrado se conserva en el historial.';

  @override
  String get trackerAddTime => 'Añadir tiempo manualmente';

  @override
  String trackerAddMinutes(int minutes) {
    return 'Añadir $minutes min';
  }

  @override
  String get trackerMinutesFewer => 'Menos minutos';

  @override
  String get trackerMinutesMore => 'Más minutos';

  @override
  String get trackerStop => 'Detener';

  @override
  String get versusDuel => 'Duelo';

  @override
  String get versusSpeakers => 'Oradores';

  @override
  String get versusCustom => 'Personalizado';

  @override
  String get versusIncrement => 'Incremento';

  @override
  String get versusTapToStart => 'Toca tu lado para iniciar tu reloj';

  @override
  String get versusTimeIsUp => 'Se acabó el tiempo';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadas',
      one: '1 jugada',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => 'Reiniciar partida';

  @override
  String get versusConfirmReset => 'Confirmar reinicio';

  @override
  String versusSpeakerN(int n) {
    return 'Orador $n';
  }

  @override
  String get versusAddSpeaker => 'Añadir orador';

  @override
  String get versusRemoveSpeaker => 'Quitar orador';

  @override
  String get versusSpeakerName => 'Orador o tema';

  @override
  String get versusNext => 'Siguiente orador';

  @override
  String get versusFinish => 'Terminar';

  @override
  String get versusOvertime => 'Tiempo extra';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed de $planned';
  }

  @override
  String get versusAgendaDone => 'Agenda terminada';

  @override
  String get versusStartAgenda => 'Iniciar agenda';

  @override
  String get versusMinutesFewer => 'Menos minutos';

  @override
  String get versusMinutesMore => 'Más minutos';

  @override
  String get versusTotal => 'Total';

  @override
  String get breatheInhale => 'Inhala';

  @override
  String get breatheHold => 'Sostén';

  @override
  String get breatheExhale => 'Exhala';

  @override
  String get breatheStart => 'Empezar a respirar';

  @override
  String get breathePause => 'Pausar';

  @override
  String get breatheResume => 'Reanudar';

  @override
  String get breatheReset => 'Terminar sesión';

  @override
  String get breatheDone => 'Muy bien';

  @override
  String get breatheReady => 'Ponte cómodo';

  @override
  String get breathePatternBox => 'Caja';

  @override
  String get breathePatternCoherent => 'Coherente';

  @override
  String get breathePatternCalm => 'Calma';

  @override
  String get breathePatternCustom => 'Personal';

  @override
  String get breatheSession => 'Sesión';

  @override
  String get breatheEndless => 'Sin fin';

  @override
  String breatheSeconds(int n) {
    return '$n s';
  }

  @override
  String get ambientWhite => 'Ruido blanco';

  @override
  String get ambientPink => 'Ruido rosa';

  @override
  String get ambientBrown => 'Ruido marrón';

  @override
  String get ambientRain => 'Lluvia';

  @override
  String get ambientWind => 'Viento';

  @override
  String get ambientOcean => 'Océano';

  @override
  String get ambientVolume => 'Volumen';

  @override
  String get ambientSleepTimer => 'Temporizador de sueño';

  @override
  String get ambientTimerOff => 'Apagado';

  @override
  String get ambientPlay => 'Reproducir sonido';

  @override
  String get ambientStop => 'Detener sonido';

  @override
  String get ambientUnavailable =>
      'El sonido no está disponible en este dispositivo.';

  @override
  String get ambientPreparing => 'Preparando sonido…';

  @override
  String ambientTimeLeft(String time) {
    return 'Quedan $time';
  }

  @override
  String get breaksStart => 'Iniciar descansos';

  @override
  String get breaksStop => 'Detener descansos';

  @override
  String get breaksStatusOff => 'Los recordatorios están apagados';

  @override
  String get breaksNoneEnabled => 'Activa al menos un recordatorio';

  @override
  String breaksNextName(String name) {
    return 'Siguiente: $name';
  }

  @override
  String get breaksToday => 'Hoy';

  @override
  String get breaksTaken => 'Descansos hechos';

  @override
  String get breaksSkipped => 'Omitidos';

  @override
  String get breaksEyeName => 'Descanso visual (20-20-20)';

  @override
  String get breaksEyeHint =>
      'Mira algo a 6 m de distancia durante 20 segundos';

  @override
  String get breaksStretchName => 'Estirar';

  @override
  String get breaksStretchHint => 'Levántate y estira todo el cuerpo';

  @override
  String get breaksWaterName => 'Beber agua';

  @override
  String get breaksWaterHint => 'Toma un vaso de agua';

  @override
  String get breaksPostureName => 'Revisar postura';

  @override
  String get breaksPostureHint => 'Siéntate derecho y relaja los hombros';

  @override
  String get breaksCustomDefault => 'Mi recordatorio';

  @override
  String breaksForDuration(String duration) {
    return 'Tómate $duration';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return 'Cada $minutes min';
  }

  @override
  String get breaksShorter => 'Intervalo más corto';

  @override
  String get breaksLonger => 'Intervalo más largo';

  @override
  String get breaksDone => 'Hecho';

  @override
  String get breaksSkip => 'Omitir';

  @override
  String get breaksActiveHours => 'Horario activo';

  @override
  String get breaksActiveHoursHint =>
      'Los recordatorios solo aparecen dentro de este horario';

  @override
  String get breaksFrom => 'Desde';

  @override
  String get breaksTo => 'Hasta';

  @override
  String get breaksLaterHour => 'Más tarde';

  @override
  String get breaksEarlierHour => 'Más temprano';

  @override
  String get breaksBackground => 'También con Enfo cerrado';

  @override
  String get breaksBackgroundOn =>
      'Las notificaciones te avisan aunque la app esté cerrada.';

  @override
  String get breaksBackgroundOff =>
      'Los recordatorios solo aparecen con Enfo abierto.';

  @override
  String get breaksDesktopNotice =>
      'Los recordatorios aparecen mientras Enfo esté en ejecución (puede estar minimizado).';

  @override
  String get breaksAddCustom => 'Añadir recordatorio propio';

  @override
  String get breaksEdit => 'Editar recordatorio';

  @override
  String get breaksName => 'Nombre';

  @override
  String get breaksDuration => 'Duración';

  @override
  String get breaksIcon => 'Icono';

  @override
  String get breaksShorterDuration => 'Descanso más corto';

  @override
  String get breaksLongerDuration => 'Descanso más largo';

  @override
  String get breaksRemove => 'Eliminar recordatorio';

  @override
  String get breaksRemoveConfirm => 'Confirmar: eliminar recordatorio';

  @override
  String get breaksRemoveHint => 'Dejará de avisarte.';

  @override
  String get worldPlan => 'Planear una reunión';

  @override
  String get worldPlanIntro =>
      'Mueve el marcador para encontrar una hora que le vaya bien a todos.';

  @override
  String get worldPlanNow => 'Ahora';

  @override
  String get worldPlanEarlier => '15 minutos antes';

  @override
  String get worldPlanLater => '15 minutos después';

  @override
  String worldPlanSelected(String city) {
    return 'Hora elegida en $city';
  }

  @override
  String get worldPlanTapCity =>
      'Toca una ciudad para usar su hora como referencia.';

  @override
  String get worldPlanNextDay => '+1 día';

  @override
  String get worldPlanPrevDay => '-1 día';

  @override
  String get worldPlanOverlapTitle => 'Todos están en horario laboral';

  @override
  String get worldPlanNoOverlap =>
      'Ninguna hora de las próximas 24 horas les sirve a todos.';

  @override
  String worldPlanLeastBad(String time) {
    return 'Lo menos malo: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$count de $total en horario laboral';
  }

  @override
  String get worldPlanWork => 'Horario laboral (09-18)';

  @override
  String get worldPlanNight => 'Noche';

  @override
  String get worldPlanMarker => 'Hora elegida';

  @override
  String get eventAdd => 'Nuevo evento';

  @override
  String get eventEdit => 'Editar evento';

  @override
  String get eventName => 'Nombre';

  @override
  String get eventNameHint => 'Cumpleaños, viaje, estreno...';

  @override
  String get eventYearly => 'Repetir cada año';

  @override
  String get eventYearlyHint =>
      'Para cumpleaños y aniversarios: pasa al siguiente automáticamente.';

  @override
  String get eventNotify => 'Avisarme';

  @override
  String get eventNotifyHint => 'En el momento en que llegue.';

  @override
  String get eventDayBefore => 'También el día anterior';

  @override
  String get eventSave => 'Guardar';

  @override
  String get eventDelete => 'Eliminar evento';

  @override
  String get eventConfirmDelete => 'Confirmar: eliminar evento';

  @override
  String get eventDeleteHint => 'Este evento se eliminará.';

  @override
  String get eventEmpty =>
      'Aún no hay eventos.\nToca + para crear una cuenta atrás.';

  @override
  String get eventToday => '¡Hoy!';

  @override
  String eventDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get eventDaysShort => 'd';

  @override
  String get eventUnitDays => 'días';

  @override
  String get eventUnitHours => 'horas';

  @override
  String get eventUnitMinutes => 'min';

  @override
  String get eventRepeatsYearly => 'Cada año';

  @override
  String get eventNotifyNow => '¡Es el momento!';

  @override
  String get eventNotifyTomorrow => 'Mañana';

  @override
  String get sleepPlanWake => 'Despertar a las';

  @override
  String get sleepPlanBed => 'Dormir a las';

  @override
  String get sleepPlanNow => 'Dormir ya';

  @override
  String get sleepTitleWake => 'Quiero despertar a las';

  @override
  String get sleepTitleBed => 'Me acuesto a las';

  @override
  String sleepTitleNow(String time) {
    return 'Si me duermo ahora ($time)';
  }

  @override
  String get sleepBedtimeWord => 'Acostarse';

  @override
  String get sleepWakeWord => 'Despertar';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles ciclos · $duration de sueño';
  }

  @override
  String get sleepNote =>
      'Cada ciclo dura 90 minutos y dormirse toma unos 15. Se recomiendan cinco o seis ciclos.';

  @override
  String get sleepWindDown => 'Aviso para relajarme';

  @override
  String get sleepWindDownHint => 'Una alarma 30 minutos antes de acostarte.';

  @override
  String get sleepWindDownPassed => 'Esa hora ya pasó.';

  @override
  String get sleepWindDownLabel => 'Hora de relajarse';

  @override
  String get sleepAlarmLabel => 'Despertar';

  @override
  String get sleepSetAlarm => 'Poner alarma';

  @override
  String get sleepRemoveAlarm => 'Quitar alarma';

  @override
  String sleepAlarmSet(String time) {
    return 'Alarma puesta a las $time';
  }

  @override
  String get sleepPast => 'Esta hora ya pasó';

  @override
  String get sleepRecommended => 'Recomendado';

  @override
  String get ambientMusicTabSounds => 'Sonidos';

  @override
  String get ambientMusicTab => 'Música';

  @override
  String get ambientMusicPlay => 'Reproducir música';

  @override
  String get ambientMusicPause => 'Pausar música';

  @override
  String get ambientMusicNext => 'Siguiente canción';

  @override
  String get ambientMusicPrevious => 'Canción anterior';

  @override
  String get ambientMusicShuffle => 'Aleatorio';

  @override
  String get ambientMusicRepeat => 'Repetir todo';

  @override
  String get ambientMusicVolume => 'Volumen de la música';

  @override
  String get ambientMusicCredits => 'Créditos de la música';

  @override
  String get ambientMusicCreditsNote =>
      'Canciones de Wikimedia Commons, publicadas bajo licencias CC0 o Creative Commons Atribución.';

  @override
  String get modeMusic => 'Música';

  @override
  String get modeDescMusic => 'Canciones lo-fi para concentrarte';

  @override
  String get musicCreditsSubtitle => 'Artistas y licencias';

  @override
  String get displayMenuButtons => 'Botones del menú';

  @override
  String get displayMenuButtonsHint =>
      'Elige qué botones aparecen en el menú inferior. Ajustes siempre está disponible.';

  @override
  String get onbWelcomeTitle => 'Bienvenido a Enfo';

  @override
  String get onbWelcomeTagline => 'Enfoque, en un solo dial tranquilo.';

  @override
  String get timerRunningTitle => 'Temporizador en marcha';

  @override
  String timerRunningBody(String time) {
    return 'Termina a las $time';
  }

  @override
  String get timerPausedTitle => 'Temporizador en pausa';

  @override
  String timerPausedBody(String duration) {
    return 'Quedan $duration';
  }

  @override
  String get musicActionPlay => 'Reproducir';

  @override
  String get musicActionPause => 'Pausar';

  @override
  String get widgetsFocusSubtitle =>
      'Tu tiempo de enfoque y pomodoros de hoy de un vistazo.';
}
