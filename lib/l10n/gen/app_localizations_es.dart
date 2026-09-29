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
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHint => 'Elige el idioma de la app.';

  @override
  String get supportTitle => 'Apoya a Enfo';

  @override
  String get supportSubtitle => 'Café y anuncios';

  @override
  String get supportSubtitleNoAds => 'Invítame un café';

  @override
  String get buyCoffee => 'Invítame un café';

  @override
  String get watchAd => 'Ver un anuncio para ayudar';

  @override
  String get supportHint =>
      'Enfo es gratis y lo hace una sola persona. Gracias por usarlo.';

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
  String get hapticFeedback => 'Vibrar al terminar una fase';

  @override
  String get hapticFeedbackHint => 'Una vibración corta en el teléfono.';

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
  String get onbLanguageTitle => 'Bienvenido a Enfo';

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
      'Tema y color de acento. La pantalla se actualiza mientras eliges.';

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
}
