// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => 'Einstellungen';

  @override
  String get tooltipStats => 'Statistiken';

  @override
  String get tooltipPin => 'Immer im Vordergrund';

  @override
  String get tooltipUnpin => 'Nicht mehr im Vordergrund';

  @override
  String get phasePaused => 'Pausiert';

  @override
  String get phaseFocus => 'Fokus';

  @override
  String get phaseRelax => 'Pause';

  @override
  String get notifRestTitle => 'Zeit für eine Pause';

  @override
  String get notifRestBody => 'Atme kurz durch.';

  @override
  String get notifWorkTitle => 'Zeit zu arbeiten';

  @override
  String get notifWorkBody => 'Weiter geht\'s!';

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get rhythmTitle => 'Fokus-Rhythmus';

  @override
  String get presetClassic => 'Klassisch';

  @override
  String get presetExtended => 'Erweitert';

  @override
  String get presetDeep => 'Tief';

  @override
  String get presetManual => 'Manuell';

  @override
  String get workLabel => 'Fokus';

  @override
  String get restLabel => 'Pause';

  @override
  String minutes(int n) {
    return '$n Min.';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest Min.';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get timersTitle => 'Zeiten';

  @override
  String timersSubtitle(int work, int rest) {
    return '$work Min. Fokus · $rest Min. Pause';
  }

  @override
  String timersCycle(int total) {
    return 'Ein ganzer Zyklus: $total Min.';
  }

  @override
  String get timersApplyHint =>
      'Läuft die Uhr, gilt die Änderung ab dem nächsten Zyklus. Ist sie pausiert, wird die Uhr zurückgesetzt.';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get appearanceLight => 'Helles Design';

  @override
  String get appearanceDark => 'Dunkles Design';

  @override
  String get darkTheme => 'Dunkles Design';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Hell';

  @override
  String get themeModeDark => 'Dunkel';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsOn => 'Ein';

  @override
  String get notificationsOff => 'Aus';

  @override
  String get notificationsToggle => 'Hinweise bei Phasenwechsel';

  @override
  String get notificationsHint =>
      'Erhalte einen Hinweis, wenn Pause oder Arbeit ansteht.';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageHint => 'Wähle die Sprache der App.';

  @override
  String get supportTitle => 'Enfo unterstützen';

  @override
  String get supportSubtitle => 'Kaffee und Werbung';

  @override
  String get supportSubtitleNoAds => 'Spendiere mir einen Kaffee';

  @override
  String get buyCoffee => 'Spendiere mir einen Kaffee';

  @override
  String get watchAd => 'Werbung ansehen und helfen';

  @override
  String get supportHint =>
      'Enfo ist kostenlos und wird von einer einzelnen Person entwickelt. Danke fürs Nutzen.';

  @override
  String get statsTitle => 'Statistiken';

  @override
  String get statsEmpty =>
      'Noch keine Sitzungen.\nStarte ein Pomodoro, dann erscheint es hier.';

  @override
  String get statsTodayPomodoros => 'Pomodoros heute';

  @override
  String get statsTodayFocus => 'Fokus heute';

  @override
  String get statsCompleted => 'Abgeschlossen';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage in Folge',
      one: 'Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => 'Letzte 7 Tage';

  @override
  String get statsTotalFocus => 'Fokuszeit gesamt';

  @override
  String get statsTotalRest => 'Pausenzeit gesamt';

  @override
  String get statsAbandoned => 'Abgebrochen';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent% abgeschlossen';
  }

  @override
  String get statsAverageFocus => 'Ø Fokus';

  @override
  String get statsLongestSession => 'Längste Sitzung';

  @override
  String get statsPauses => 'Pausen';

  @override
  String get statsAverageGap => 'Ø Abstand zwischen Sitzungen';

  @override
  String get statsLongestGap => 'Längste Zeit ohne Start';

  @override
  String get statsSinceLast => 'Seit der letzten Sitzung';

  @override
  String get statsHistory => 'Verlauf';

  @override
  String get statsClearHistory => 'Verlauf löschen';

  @override
  String get statsClearConfirm => 'Bestätigen: alle Sitzungen löschen';

  @override
  String get statsClearHint => 'Das lässt sich nicht rückgängig machen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get sessionFocus => 'Fokus';

  @override
  String get sessionRest => 'Pause';

  @override
  String sessionProgress(String done, String planned) {
    return '$done von $planned';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pausen',
      one: '1 Pause',
    );
    return '$_temp0 ($time)';
  }

  @override
  String sessionIdleBefore(String gap) {
    return 'nach $gap Leerlauf';
  }

  @override
  String get sessionCompleted => 'Abgeschlossen';

  @override
  String get sessionAbandoned => 'Abgebrochen';

  @override
  String get clockStyleTitle => 'Uhrstil';

  @override
  String get tooltipClockStyle => 'Uhrstil';

  @override
  String get clockCategoryProgress => 'Fortschritt und Zahlen';

  @override
  String get clockCategoryNumbers => 'Nur Zahlen';

  @override
  String get clockCategoryIcons => 'Nur Symbol';

  @override
  String get clockCategoryMotion => 'Nur Animation';

  @override
  String get clockUnitMinutes => 'Min.';

  @override
  String get clockUnitSeconds => 'Sek.';

  @override
  String get clockRing => 'Ring';

  @override
  String get clockWavyRing => 'Welle';

  @override
  String get clockSegments => 'Segmente';

  @override
  String get clockOrbit => 'Orbit';

  @override
  String get clockPie => 'Torte';

  @override
  String get clockKitchen => 'Küche';

  @override
  String get clockDots => 'Punkte';

  @override
  String get clockBar => 'Balken';

  @override
  String get clockWavyBar => 'Woge';

  @override
  String get clockDigits => 'Ziffern';

  @override
  String get clockMinutes => 'Minuten';

  @override
  String get clockTiles => 'Kacheln';

  @override
  String get clockStack => 'Stapel';

  @override
  String get clockTomato => 'Tomate';

  @override
  String get clockHourglass => 'Sand';

  @override
  String get clockBattery => 'Akku';

  @override
  String get clockIcon => 'Symbol';

  @override
  String get clockCookie => 'Keks';

  @override
  String get clockLiquid => 'Flüssig';

  @override
  String get clockBreathe => 'Atmen';

  @override
  String get clockEqualizer => 'Equalizer';

  @override
  String get clockRipple => 'Wellen';

  @override
  String get accentApply => 'Anwenden';

  @override
  String get accentCustom => 'Eigene Farbe';

  @override
  String get accentHue => 'Farbton';

  @override
  String get accentSaturation => 'Sättigung';

  @override
  String get accentBrightness => 'Helligkeit';

  @override
  String get accentHex => 'Hex-Code';

  @override
  String get displayTitle => 'Anzeige';

  @override
  String get displayClockShown => 'Uhrzeit sichtbar';

  @override
  String get displayClockHidden => 'Uhrzeit ausgeblendet';

  @override
  String get showClock => 'Uhrzeit anzeigen';

  @override
  String get showClockHint => 'Die kleine Uhr über dem Timer.';

  @override
  String get clockFormat => 'Zeitformat';

  @override
  String get clockFormatSystem => 'Systemstandard';

  @override
  String get clockFormat12 => '12 Stunden';

  @override
  String get clockFormat24 => '24 Stunden';

  @override
  String get behaviorTitle => 'Verhalten';

  @override
  String get autoStartNext => 'Nächste Phase automatisch starten';

  @override
  String get autoStartNextHint =>
      'Nach Fokus oder Pause beginnt die nächste Phase ohne Tippen.';

  @override
  String get hapticFeedback => 'Vibration';

  @override
  String get hapticFeedbackHint => 'Tippen, Räder, Phasenwechsel und Wecker.';

  @override
  String get clockCombosTitle => 'Kombis';

  @override
  String get clockCollapseAll => 'Alle einklappen';

  @override
  String get clockExpandAll => 'Alle ausklappen';

  @override
  String get comboDeepFocus => 'Tiefer Fokus';

  @override
  String get comboMint => 'Frische Minze';

  @override
  String get comboSunset => 'Sonnenuntergang';

  @override
  String get comboZen => 'Zen';

  @override
  String get comboTomato => 'Klassische Tomate';

  @override
  String get comboNight => 'Nachteule';

  @override
  String get comboPlayful => 'Verspielt';

  @override
  String get comboMinimal => 'Minimalistisch';

  @override
  String get uiSizeTitle => 'Oberflächengröße';

  @override
  String get uiSizeSmall => 'Klein';

  @override
  String get uiSizeNormal => 'Normal';

  @override
  String get uiSizeLarge => 'Groß';

  @override
  String get uiSizeExtraLarge => 'Extragroß';

  @override
  String get uiSizeHint =>
      'Macht Text und Bedienelemente größer oder kleiner. Praktisch für TV und Autodisplays.';

  @override
  String get clockBlob => 'Blob';

  @override
  String get clockFlower => 'Blume';

  @override
  String get clockSun => 'Sonne';

  @override
  String get clockGears => 'Zahnräder';

  @override
  String get clockBubbles => 'Blasen';

  @override
  String get clockSunflower => 'Sonnenblume';

  @override
  String get clockFireflies => 'Glühwürmchen';

  @override
  String get clockPendulum => 'Pendel';

  @override
  String get clockBounce => 'Hüpfen';

  @override
  String get clockMorph => 'Morph';

  @override
  String get dataTitle => 'Daten';

  @override
  String get dataSubtitle => 'Verlauf, Zurücksetzen und Einführung';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge gespeichert',
      one: '1 Eintrag gespeichert',
      zero: 'Keine Aktivität gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'Einführung erneut ansehen';

  @override
  String get dataIntroHint =>
      'Sieh dir den Willkommensbildschirm noch einmal an und wähle deinen Rhythmus neu. Nichts wird gelöscht.';

  @override
  String get dataClearHistoryHint =>
      'Löscht alle erfassten Aktivitäten: Pomodoros, Timer, Stoppuhren, Wecker und Uhrzeit-Nutzung. Die Einstellungen bleiben unverändert.';

  @override
  String get dataConfirmClearHistory => 'Bestätigen: Verlauf löschen';

  @override
  String get dataResetSettings => 'Einstellungen zurücksetzen';

  @override
  String get dataResetSettingsHint =>
      'Zeiten, Design, Akzentfarbe, Sprache, Modi und Anzeige gehen auf die Standardwerte zurück. Der Verlauf bleibt erhalten.';

  @override
  String get dataConfirmResetSettings =>
      'Bestätigen: Einstellungen zurücksetzen';

  @override
  String get dataEraseAll => 'Alles löschen';

  @override
  String get dataEraseAllHint =>
      'Löscht Verlauf und Einstellungen und beginnt bei null, wie beim ersten Mal.';

  @override
  String get dataConfirmEraseAll => 'Bestätigen: alles löschen';

  @override
  String get dataDoneHistory => 'Verlauf gelöscht.';

  @override
  String get dataDoneSettings => 'Einstellungen zurückgesetzt.';

  @override
  String get dataCacheNote =>
      'Enfo speichert keinen Cache: Gespeichert werden nur der Verlauf und die hier beschriebenen Einstellungen.';

  @override
  String get clockEndsAt => 'Endet';

  @override
  String get clockFill => 'Füllung';

  @override
  String get clockCapsule => 'Kapsel';

  @override
  String get clockRollers => 'Walze';

  @override
  String get clockMatrix => 'Matrix';

  @override
  String get clockSevenSeg => 'Digital';

  @override
  String get clockFlip => 'Flip';

  @override
  String get clockFine => 'Fein';

  @override
  String get clockSuperscript => 'Hochgestellt';

  @override
  String get clockPercent => 'Prozent';

  @override
  String get clockEndTime => 'Endet um';

  @override
  String get clockSeconds => 'Sekunden';

  @override
  String get clockTall => 'Hoch';

  @override
  String get clockWobble => 'Wellig';

  @override
  String get clockLabeled => 'Beschriftet';

  @override
  String get clockGauge => 'Messuhr';

  @override
  String get clockNeedle => 'Nadel';

  @override
  String get clockAnalog => 'Analog';

  @override
  String get clockRings => 'Ringe';

  @override
  String get clockSquircle => 'Quadrat';

  @override
  String get clockColumns => 'Spalten';

  @override
  String get clockVertical => 'Vertikal';

  @override
  String get clockSteps => 'Stufen';

  @override
  String get clockBlocks => 'Blöcke';

  @override
  String get clockSpiral => 'Spirale';

  @override
  String get clockSlices => 'Scheiben';

  @override
  String get clockPills => 'Pillen';

  @override
  String get clockHexagon => 'Sechseck';

  @override
  String get clockStairs => 'Treppe';

  @override
  String get clockCandle => 'Kerze';

  @override
  String get clockMoon => 'Mond';

  @override
  String get clockRuler => 'Lineal';

  @override
  String get comboArcade => 'Arcade';

  @override
  String get comboCalculator => 'Taschenrechner';

  @override
  String get comboDepartures => 'Bahnhofstafel';

  @override
  String get comboCandlelight => 'Bei Kerzenschein';

  @override
  String get comboMoonlight => 'Mondlicht';

  @override
  String get comboGarden => 'Garten';

  @override
  String get comboSummer => 'Sommer';

  @override
  String get comboWorkshop => 'Werkstatt';

  @override
  String get comboFizzy => 'Sprudelnd';

  @override
  String get comboSunfield => 'Sonnenblumenfeld';

  @override
  String get comboSummerNight => 'Sommernacht';

  @override
  String get comboHypnosis => 'Hypnose';

  @override
  String get comboBouncy => 'Hüpfend';

  @override
  String get comboShapeshifter => 'Gestaltwandler';

  @override
  String get comboLava => 'Lavalampe';

  @override
  String get comboOcean => 'Ozean';

  @override
  String get comboPulse => 'Puls';

  @override
  String get comboPond => 'Teich';

  @override
  String get comboEspresso => 'Espresso';

  @override
  String get comboSpeedometer => 'Tacho';

  @override
  String get comboCompass => 'Kompass';

  @override
  String get comboClassicClock => 'Klassische Uhr';

  @override
  String get comboConcentric => 'Konzentrisch';

  @override
  String get comboRounded => 'Abgerundet';

  @override
  String get comboSignal => 'Signal';

  @override
  String get comboThermometer => 'Thermometer';

  @override
  String get comboMilestones => 'Meilensteine';

  @override
  String get comboRetroBlocks => 'Retro-Blöcke';

  @override
  String get comboHypnoSpiral => 'Hypnose-Spirale';

  @override
  String get comboCitrus => 'Zitrus';

  @override
  String get comboChocolate => 'Schokoriegel';

  @override
  String get comboCrystal => 'Kristall';

  @override
  String get comboStaircase => 'Treppe';

  @override
  String get comboTapeMeasure => 'Maßband';

  @override
  String get comboBoldType => 'Fette Schrift';

  @override
  String get comboPill => 'Kapsel';

  @override
  String get comboSlotMachine => 'Spielautomat';

  @override
  String get comboWhisper => 'Flüstern';

  @override
  String get comboDeadline => 'Deadline';

  @override
  String get comboPercentage => 'Prozent';

  @override
  String get comboStopwatch => 'Nur Sekunden';

  @override
  String get comboSkyscraper => 'Wolkenkratzer';

  @override
  String get comboWaveText => 'Wellentext';

  @override
  String get comboDashboard => 'Dashboard';

  @override
  String get comboExponent => 'Hochgestellt';

  @override
  String get comboGrandmaKitchen => 'Omas Küche';

  @override
  String get comboCyber => 'Cyber';

  @override
  String get comboCandy => 'Bonbon';

  @override
  String get comboConfetti => 'Konfetti';

  @override
  String get comboCookieJar => 'Keksdose';

  @override
  String get comboSandbox => 'Sandkasten';

  @override
  String get comboPizzaNight => 'Pizzaabend';

  @override
  String get onbLanguageTitle => 'Deine Sprache';

  @override
  String get onbLanguageBody =>
      'Wähle deine Sprache. Alles, was du hier wählst, kannst du später in den Einstellungen ändern.';

  @override
  String get onbRhythmTitle => 'Dein Rhythmus';

  @override
  String get onbRhythmBody =>
      'Wie lange du dich fokussierst und wie lange du Pause machst.';

  @override
  String get onbLookTitle => 'Mach es zu deinem';

  @override
  String get onbLookBody =>
      'Design, Uhrstil und Farbe. Starte mit einer Kombi und passe die Farbe an.';

  @override
  String get onbClockTitle => 'Wähle eine Uhr';

  @override
  String get onbClockBody =>
      'Fertige Kombinationen: ein Uhrstil und eine Farbe mit einem Tippen.';

  @override
  String get onbAllStyles => 'Alle Stile ansehen';

  @override
  String get onbOptionsTitle => 'Letzte Details';

  @override
  String get onbOptionsBody =>
      'Anzeige und Verhalten. All das findest du auch in den Einstellungen.';

  @override
  String get onbModesTitle => 'Deine Werkzeuge';

  @override
  String get onbModesBody =>
      'Enfo ist eine Werkzeugkiste für Uhren und Timer. Aktiviere, was du brauchst; im Modi-Menü änderst du das jederzeit.';

  @override
  String get onbPreview => 'Vorschau';

  @override
  String get onbDisplayTitle => 'Anzeige';

  @override
  String get onbDisplayBody => 'Wie die Uhr aussieht und wie groß alles ist.';

  @override
  String get onbClockModeDesign => 'Design des Uhr-Modus';

  @override
  String get onbPermTitle => 'Berechtigungen';

  @override
  String get onbPermBody =>
      'Damit Timer und Wecker dich auch erreichen, wenn Enfo geschlossen ist.';

  @override
  String get onbPermNotifications => 'Benachrichtigungen';

  @override
  String get onbPermNotificationsHint =>
      'Hinweise, wenn ein Timer endet oder ein Wecker klingelt.';

  @override
  String get onbPermExact => 'Exakte Wecker';

  @override
  String get onbPermExactHint =>
      'Klingeln auf die Minute genau, auch im Energiesparmodus.';

  @override
  String get onbPermAllow => 'Erlauben';

  @override
  String get onbPermAllowed => 'Erlaubt';

  @override
  String get onbPermLater =>
      'Du kannst das jederzeit in den Systemeinstellungen ändern.';

  @override
  String get onbNext => 'Weiter';

  @override
  String get onbBack => 'Zurück';

  @override
  String get onbSkip => 'Überspringen';

  @override
  String onbStepOf(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get clockFormatAuto => 'Auto';

  @override
  String get modePomodoro => 'Pomodoro';

  @override
  String get modeClock => 'Uhr';

  @override
  String get modeTimer => 'Timer';

  @override
  String get modeStopwatch => 'Stoppuhr';

  @override
  String get modeAlarm => 'Wecker';

  @override
  String get modeWorld => 'Weltzeit';

  @override
  String get modeDescPomodoro => 'Fokus- und Pausenzyklen';

  @override
  String get modeDescClock => 'Eine schöne Uhr, immer sichtbar';

  @override
  String get modeDescTimer => 'Countdown von beliebiger Zeit';

  @override
  String get modeDescStopwatch => 'Zeit messen, mit Runden';

  @override
  String get modeDescAlarm => 'Aufwachen oder Erinnerungen erhalten';

  @override
  String get modeDescWorld => 'Die Uhrzeit in Städten weltweit';

  @override
  String get tooltipModes => 'Modi';

  @override
  String get tooltipSwitchMode => 'Nächster Modus';

  @override
  String get tooltipFullscreen => 'Vollbild';

  @override
  String get tooltipExitFullscreen => 'Vollbild beenden';

  @override
  String get tooltipDim => 'Bildschirm abdunkeln';

  @override
  String get modesTitle => 'Modi';

  @override
  String get modesHint =>
      'Wähle die Modi, die du nutzt, und ihre Reihenfolge. Zum Umordnen ziehen.';

  @override
  String get modesStart => 'Starten mit';

  @override
  String get modesStartLast => 'Zuletzt genutzter Modus';

  @override
  String get modesCustomize => 'Anpassen';

  @override
  String get modesActivity => 'Aktivitätsverlauf';

  @override
  String get modesAtLeastOne => 'Mindestens ein Modus muss aktiv bleiben.';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Modi',
      one: '1 aktiver Modus',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'Aktivitätsverlauf';

  @override
  String get activityTitle => 'Aktivität';

  @override
  String get activityEmpty =>
      'Noch nichts vorhanden.\nNutze einen Timer, eine Stoppuhr, einen Wecker oder die Uhr, dann erscheint es hier.';

  @override
  String get activityFilterAll => 'Alle';

  @override
  String get activityTimersToday => 'Timer heute';

  @override
  String get activityStopwatchToday => 'Stoppuhr heute';

  @override
  String get activityDisplayToday => 'Auf dem Display heute';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden',
      one: '1 Runde',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'Runde $n';
  }

  @override
  String get activityAlarmDismissed => 'Beendet';

  @override
  String get activityAlarmSnoozed => 'Verschoben';

  @override
  String get activityAlarmMissed => 'Verpasst';

  @override
  String activityDisplay(String mode) {
    return '$mode auf dem Display';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done von $planned';
  }

  @override
  String get faceRing => 'Ring';

  @override
  String get faceDigital => 'Digital';

  @override
  String get faceAnalog => 'Analog';

  @override
  String get faceSplit => 'Groß';

  @override
  String get faceDay => 'Tag';

  @override
  String get tooltipCustomize => 'Anpassen';

  @override
  String get clockSettingsTitle => 'Uhr anpassen';

  @override
  String get clockFaceTitle => 'Layout';

  @override
  String get clockShowSeconds => 'Sekunden anzeigen';

  @override
  String get clockShowDate => 'Datum anzeigen';

  @override
  String get clockBlinkColon => 'Blinkender Doppelpunkt';

  @override
  String get clockKeepAwake => 'Bildschirm anlassen';

  @override
  String get clockKeepAwakeHint => 'Solange die Uhr sichtbar ist.';

  @override
  String get clockFullscreenHint =>
      'Tippe auf Vollbild für eine Tischuhr, die an bleibt. Wische über die Uhr, um ihr Layout zu wechseln.';

  @override
  String clockDayPercent(int percent) {
    return '$percent% des Tages';
  }

  @override
  String get ringDismiss => 'Stopp';

  @override
  String ringSnooze(int minutes) {
    return '$minutes Min. später';
  }

  @override
  String get timerStart => 'Start';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerResume => 'Fortsetzen';

  @override
  String get timerReset => 'Zurücksetzen';

  @override
  String get timerAddMinute => '+1 Min.';

  @override
  String get timerHoursShort => 'Std.';

  @override
  String get timerMinutesShort => 'Min.';

  @override
  String get timerSecondsShort => 'Sek.';

  @override
  String get timerUpTitle => 'Zeit ist um';

  @override
  String timerUpBody(String duration) {
    return 'Der Timer über $duration ist abgelaufen.';
  }

  @override
  String get timerSavePreset => 'Diese Zeit speichern';

  @override
  String get timerPresetHint =>
      'Tippe auf +, um diese Zeit zu speichern. Halte eine Voreinstellung gedrückt, um sie zu entfernen.';

  @override
  String get stopwatchStop => 'Stopp';

  @override
  String get stopwatchLap => 'Runde';

  @override
  String get stopwatchLapBest => 'Beste';

  @override
  String get stopwatchLapWorst => 'Langsamste';

  @override
  String get worldLocal => 'Ortszeit';

  @override
  String get worldToday => 'Heute';

  @override
  String get worldTomorrow => 'Morgen';

  @override
  String get worldYesterday => 'Gestern';

  @override
  String get worldAdd => 'Stadt hinzufügen';

  @override
  String get worldSearch => 'Städte suchen';

  @override
  String get worldNoResults => 'Keine Stadt gefunden.';

  @override
  String get worldEdit => 'Liste bearbeiten';

  @override
  String get worldDone => 'Fertig';

  @override
  String get worldRemove => 'Entfernen';

  @override
  String get worldEmpty =>
      'Noch keine weiteren Städte. Tippe auf +, um eine hinzuzufügen.';

  @override
  String get worldSameTime => 'Gleiche Uhrzeit wie bei dir';

  @override
  String worldDiffAhead(String diff) {
    return '$diff vor dir';
  }

  @override
  String worldDiffBehind(String diff) {
    return '$diff hinter dir';
  }

  @override
  String alarmNext(String duration) {
    return 'Nächster Wecker in $duration';
  }

  @override
  String get alarmNone => 'Keine aktiven Wecker';

  @override
  String get alarmNew => 'Neuer Wecker';

  @override
  String get alarmEditTitle => 'Wecker bearbeiten';

  @override
  String get alarmLabel => 'Bezeichnung';

  @override
  String get alarmRepeat => 'Wiederholen';

  @override
  String get alarmSave => 'Speichern';

  @override
  String get alarmDelete => 'Wecker löschen';

  @override
  String get alarmConfirmDelete => 'Bestätigen: Wecker löschen';

  @override
  String get alarmDeleteHint => 'Dieser Wecker wird gelöscht.';

  @override
  String get alarmEmpty =>
      'Noch keine Wecker.\nTippe auf +, um einen zu erstellen.';

  @override
  String get alarmEveryDay => 'Jeden Tag';

  @override
  String get alarmWeekdays => 'Werktags';

  @override
  String get alarmWeekends => 'Am Wochenende';

  @override
  String get alarmOnce => 'Einmalig';

  @override
  String get alarmPermissionHint =>
      'Damit er bei geschlossener App klingelt, braucht Enfo die Erlaubnis für Benachrichtigungen und exakte Wecker.';

  @override
  String get alarmPermissionButton => 'Wecker erlauben';

  @override
  String get alarmDesktopHint =>
      'Auf diesem Gerät muss Enfo geöffnet sein, damit Wecker klingeln.';

  @override
  String get hapticsTitle => 'Vibration';

  @override
  String get hapticsOff => 'Aus';

  @override
  String get hapticsStrength => 'Stärke';

  @override
  String get hapticsSoft => 'Sanft';

  @override
  String get hapticsMedium => 'Mittel';

  @override
  String get hapticsStrong => 'Stark';

  @override
  String get hapticsTouch => 'Tippen';

  @override
  String get hapticsTouchHint => 'Tasten, Schalter und Auswahl.';

  @override
  String get hapticsMotion => 'Bewegung';

  @override
  String get hapticsMotionHint => 'Räder, Schieberegler, Ziehen und Übergänge.';

  @override
  String get hapticsAlerts => 'Hinweise';

  @override
  String get hapticsAlertsHint =>
      'Timer, Phasenwechsel, der letzte Countdown und Wecker.';

  @override
  String get hapticsAlarmPattern => 'Weckermuster';

  @override
  String get hapticsAlarmPatternHint =>
      'Tippe auf ein Muster, um es zu spüren. Der Weckerbildschirm pulsiert im gleichen Rhythmus.';

  @override
  String get hapticsPatternHeartbeat => 'Herzschlag';

  @override
  String get hapticsPatternPulse => 'Puls';

  @override
  String get hapticsPatternCrescendo => 'Crescendo';

  @override
  String get hapticsPatternRipple => 'Wellen';

  @override
  String get hapticsPatternBeacon => 'Leuchtfeuer';

  @override
  String get hapticsTry => 'Ausprobieren';

  @override
  String get hapticsTryTap => 'Tippen';

  @override
  String get hapticsTrySuccess => 'Erfolg';

  @override
  String get hapticsTryToRest => 'Fokus-Ende';

  @override
  String get hapticsTryToWork => 'Pausen-Ende';

  @override
  String get hapticsTryTimer => 'Timer-Ende';

  @override
  String get hapticsTryWarning => 'Warnung';

  @override
  String get hapticsUnavailable => 'Dieses Gerät hat keinen Vibrationsmotor.';

  @override
  String get hapticsWhen => 'Wann vibriert wird';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSubtitle => 'Uhren und Timer auf deinem Startbildschirm';

  @override
  String get widgetsAddHeader => 'Zum Startbildschirm hinzufügen';

  @override
  String get widgetsAdd => 'Hinzufügen';

  @override
  String get widgetsDynamicColor => 'Material-You-Farben';

  @override
  String get widgetsDynamicColorHint =>
      'Die Widgets übernehmen ihre Farben von deinem Hintergrundbild. Schalte es aus, um die Akzentfarbe von Enfo zu nutzen.';

  @override
  String get widgetsManualHint =>
      'Dein Launcher erlaubt kein Hinzufügen von Widgets an dieser Stelle. Halte den Startbildschirm gedrückt, wähle Widgets und suche Enfo.';

  @override
  String get widgetsStyleHint =>
      'Die Widgets für Pomodoro und Timer werden im gewählten Uhrstil gezeichnet. Änderst du den Stil in der App, ziehen sie mit.';

  @override
  String get widgetsTapHint =>
      'Die Tasten eines Widgets öffnen Enfo und führen die Aktion aus, so läuft die Zeit immer in der App.';

  @override
  String get shortcutsTitle => 'Tastatur und Fernbedienung';

  @override
  String get shortcutsSubtitle =>
      'Kurzbefehle für Tastatur, Maus und TV-Fernbedienung';

  @override
  String get shortcutsIntro =>
      'Mit den Pfeiltasten oder dem D-Pad der Fernbedienung navigierst du, Enter oder OK bestätigt. Diese Tasten erledigen den Rest.';

  @override
  String get shortcutKeySpace => 'Leertaste';

  @override
  String get shortcutPlayPause => 'Starten oder pausieren';

  @override
  String get shortcutReset => 'Zurücksetzen';

  @override
  String get shortcutLap => 'Runde (Stoppuhr)';

  @override
  String get shortcutJumpMode => 'Zu Modus 1–9 springen';

  @override
  String get shortcutStepMode => 'Vorheriger / nächster Modus';

  @override
  String get shortcutFullscreen => 'Vollbild';

  @override
  String get shortcutDim => 'Bildschirm abdunkeln (Vollbild)';

  @override
  String get shortcutSettings => 'Einstellungen';

  @override
  String get shortcutModes => 'Modusmenü';

  @override
  String get shortcutBack => 'Zurück / Vollbild beenden';

  @override
  String get shortcutHelp => 'Diese Liste anzeigen';

  @override
  String get onbMoreTools => 'Weitere Werkzeuge';

  @override
  String get modeEvent => 'Ereignisse';

  @override
  String get modeDescEvent => 'Zähle die Tage bis zu deinem Ziel';

  @override
  String get modeIntervals => 'Intervalle';

  @override
  String get modeDescIntervals => 'Belastungs- und Pausenrunden wie HIIT';

  @override
  String get modeBreathe => 'Atmen';

  @override
  String get modeDescBreathe => 'Geführtes Atmen zum Entspannen';

  @override
  String get modeTracker => 'Tracker';

  @override
  String get modeDescTracker => 'Zeit erfassen und Summen ansehen';

  @override
  String get modeKitchen => 'Küche';

  @override
  String get modeDescKitchen => 'Mehrere benannte Timer gleichzeitig';

  @override
  String get modeSleep => 'Schlaf';

  @override
  String get modeDescSleep => 'Schlafen und Wecken in Schlafzyklen planen';

  @override
  String get modeVersus => 'Züge';

  @override
  String get modeDescVersus => 'Zwei-Spieler-Uhr für Schach, Spiele, Debatten';

  @override
  String get modeBreaks => 'Pausen';

  @override
  String get modeDescBreaks => 'Erinnerungen für Augenpausen und Dehnen';

  @override
  String get modeAmbient => 'Ambiente';

  @override
  String get modeDescAmbient => 'Hintergrundklänge mit Einschlaftimer';

  @override
  String get intervalsPresetTabata => 'Tabata';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'Eigene';

  @override
  String get intervalsWarmUp => 'Aufwärmen';

  @override
  String get intervalsWork => 'Belastung';

  @override
  String get intervalsRest => 'Pause';

  @override
  String get intervalsRounds => 'Runden';

  @override
  String get intervalsCoolDown => 'Abkühlen';

  @override
  String get intervalsOff => 'Aus';

  @override
  String intervalsRound(int current, int total) {
    return 'Runde $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return 'Gesamt $duration';
  }

  @override
  String get intervalsSkip => 'Zur nächsten Phase springen';

  @override
  String get intervalsHint =>
      'Tippe auf eine Zeile, um sie zu ändern. Jede Änderung wird als Eigene gespeichert.';

  @override
  String get intervalsDoneTitle => 'Training geschafft';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration. Gut gemacht!';
  }

  @override
  String get kitchenPasta => 'Nudeln';

  @override
  String get kitchenEggs => 'Eier';

  @override
  String get kitchenTea => 'Tee';

  @override
  String get kitchenRice => 'Reis';

  @override
  String get kitchenOven => 'Backofen';

  @override
  String get kitchenCustom => 'Eigener';

  @override
  String get kitchenNameHint => 'Name';

  @override
  String get kitchenAdd => 'Timer starten';

  @override
  String get kitchenDelete => 'Timer löschen';

  @override
  String get kitchenEmpty =>
      'Noch keine Timer. Tippe oben auf einen, um zu starten.';

  @override
  String get kitchenDefaultName => 'Timer';

  @override
  String kitchenDoneTitle(String name) {
    return '$name ist fertig';
  }

  @override
  String kitchenDoneBody(String duration) {
    return 'Der Timer über $duration ist abgelaufen.';
  }

  @override
  String get trackerToday => 'Heute';

  @override
  String get trackerWeek => 'Letzte 7 Tage';

  @override
  String get trackerTapToStart =>
      'Tippe auf eine Aktivität, um die Zeit zu messen';

  @override
  String get trackerNoRunning => 'Nichts läuft';

  @override
  String get trackerAddActivity => 'Neue Aktivität';

  @override
  String get trackerNameHint => 'Name';

  @override
  String get trackerStudy => 'Lernen';

  @override
  String get trackerReading => 'Lesen';

  @override
  String get trackerCode => 'Programmieren';

  @override
  String get trackerExercise => 'Sport';

  @override
  String get trackerEdit => 'Aktivität bearbeiten';

  @override
  String get trackerDetails => 'Details und Diagramm';

  @override
  String get trackerColor => 'Farbe';

  @override
  String get trackerIcon => 'Symbol';

  @override
  String get trackerDelete => 'Aktivität löschen';

  @override
  String get trackerDeleteConfirm => 'Bestätigen: Aktivität löschen';

  @override
  String get trackerDeleteHint =>
      'Bereits erfasste Zeit bleibt im Verlauf erhalten.';

  @override
  String get trackerAddTime => 'Zeit manuell hinzufügen';

  @override
  String trackerAddMinutes(int minutes) {
    return '$minutes Min. hinzufügen';
  }

  @override
  String get trackerMinutesFewer => 'Weniger Minuten';

  @override
  String get trackerMinutesMore => 'Mehr Minuten';

  @override
  String get trackerStop => 'Stopp';

  @override
  String get versusDuel => 'Duell';

  @override
  String get versusSpeakers => 'Redner';

  @override
  String get versusCustom => 'Eigene';

  @override
  String get versusIncrement => 'Zuschlag';

  @override
  String get versusTapToStart =>
      'Tippe auf deine Seite, um deine Uhr zu starten';

  @override
  String get versusTimeIsUp => 'Die Zeit ist um';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '1 Zug',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => 'Partie zurücksetzen';

  @override
  String get versusConfirmReset => 'Zurücksetzen bestätigen';

  @override
  String versusSpeakerN(int n) {
    return 'Redner $n';
  }

  @override
  String get versusAddSpeaker => 'Redner hinzufügen';

  @override
  String get versusRemoveSpeaker => 'Redner entfernen';

  @override
  String get versusSpeakerName => 'Redner oder Thema';

  @override
  String get versusNext => 'Nächster Redner';

  @override
  String get versusFinish => 'Beenden';

  @override
  String get versusOvertime => 'Überzeit';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed von $planned';
  }

  @override
  String get versusAgendaDone => 'Tagesordnung beendet';

  @override
  String get versusStartAgenda => 'Tagesordnung starten';

  @override
  String get versusMinutesFewer => 'Weniger Minuten';

  @override
  String get versusMinutesMore => 'Mehr Minuten';

  @override
  String get versusTotal => 'Gesamt';

  @override
  String get breatheInhale => 'Einatmen';

  @override
  String get breatheHold => 'Halten';

  @override
  String get breatheExhale => 'Ausatmen';

  @override
  String get breatheStart => 'Atmung starten';

  @override
  String get breathePause => 'Pause';

  @override
  String get breatheResume => 'Fortsetzen';

  @override
  String get breatheReset => 'Sitzung beenden';

  @override
  String get breatheDone => 'Gut gemacht';

  @override
  String get breatheReady => 'Setz dich bequem hin';

  @override
  String get breathePatternBox => 'Box';

  @override
  String get breathePatternCoherent => 'Kohärent';

  @override
  String get breathePatternCalm => 'Ruhe';

  @override
  String get breathePatternCustom => 'Eigene';

  @override
  String get breatheSession => 'Dauer';

  @override
  String get breatheEndless => 'Endlos';

  @override
  String breatheSeconds(int n) {
    return '$n s';
  }

  @override
  String get ambientWhite => 'Weißes Rauschen';

  @override
  String get ambientPink => 'Rosa Rauschen';

  @override
  String get ambientBrown => 'Braunes Rauschen';

  @override
  String get ambientRain => 'Regen';

  @override
  String get ambientWind => 'Wind';

  @override
  String get ambientOcean => 'Meer';

  @override
  String get ambientVolume => 'Lautstärke';

  @override
  String get ambientSleepTimer => 'Einschlaftimer';

  @override
  String get ambientTimerOff => 'Aus';

  @override
  String get ambientPlay => 'Klang abspielen';

  @override
  String get ambientStop => 'Klang stoppen';

  @override
  String get ambientUnavailable => 'Ton ist auf diesem Gerät nicht verfügbar.';

  @override
  String get ambientPreparing => 'Klang wird vorbereitet …';

  @override
  String ambientTimeLeft(String time) {
    return 'Noch $time';
  }

  @override
  String get breaksStart => 'Pausen starten';

  @override
  String get breaksStop => 'Pausen beenden';

  @override
  String get breaksStatusOff => 'Pausenerinnerungen sind aus';

  @override
  String get breaksNoneEnabled => 'Aktiviere mindestens eine Erinnerung';

  @override
  String breaksNextName(String name) {
    return 'Als Nächstes: $name';
  }

  @override
  String get breaksToday => 'Heute';

  @override
  String get breaksTaken => 'Pausen gemacht';

  @override
  String get breaksSkipped => 'Übersprungen';

  @override
  String get breaksEyeName => 'Augenpause (20-20-20)';

  @override
  String get breaksEyeHint =>
      'Schau 20 Sekunden lang auf etwas in 6 m Entfernung';

  @override
  String get breaksStretchName => 'Dehnen';

  @override
  String get breaksStretchHint => 'Steh auf und dehne den ganzen Körper';

  @override
  String get breaksWaterName => 'Wasser trinken';

  @override
  String get breaksWaterHint => 'Trink ein Glas Wasser';

  @override
  String get breaksPostureName => 'Haltung prüfen';

  @override
  String get breaksPostureHint =>
      'Setz dich aufrecht hin und entspanne die Schultern';

  @override
  String get breaksCustomDefault => 'Meine Erinnerung';

  @override
  String breaksForDuration(String duration) {
    return 'Nimm dir $duration';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return 'Alle $minutes Min.';
  }

  @override
  String get breaksShorter => 'Kürzeres Intervall';

  @override
  String get breaksLonger => 'Längeres Intervall';

  @override
  String get breaksDone => 'Erledigt';

  @override
  String get breaksSkip => 'Überspringen';

  @override
  String get breaksActiveHours => 'Aktive Zeiten';

  @override
  String get breaksActiveHoursHint =>
      'Erinnerungen erscheinen nur in diesem Zeitraum';

  @override
  String get breaksFrom => 'Von';

  @override
  String get breaksTo => 'Bis';

  @override
  String get breaksLaterHour => 'Später';

  @override
  String get breaksEarlierHour => 'Früher';

  @override
  String get breaksBackground => 'Auch wenn Enfo geschlossen ist';

  @override
  String get breaksBackgroundOn =>
      'Benachrichtigungen erinnern dich auch bei geschlossener App.';

  @override
  String get breaksBackgroundOff =>
      'Erinnerungen erscheinen nur, solange Enfo geöffnet ist.';

  @override
  String get breaksDesktopNotice =>
      'Erinnerungen erscheinen, solange Enfo läuft (auch minimiert).';

  @override
  String get breaksAddCustom => 'Eigene Erinnerung hinzufügen';

  @override
  String get breaksEdit => 'Erinnerung bearbeiten';

  @override
  String get breaksName => 'Name';

  @override
  String get breaksDuration => 'Dauer';

  @override
  String get breaksIcon => 'Symbol';

  @override
  String get breaksShorterDuration => 'Kürzere Pause';

  @override
  String get breaksLongerDuration => 'Längere Pause';

  @override
  String get breaksRemove => 'Erinnerung entfernen';

  @override
  String get breaksRemoveConfirm => 'Bestätigen: Erinnerung entfernen';

  @override
  String get breaksRemoveHint => 'Es erinnert dich nicht mehr.';

  @override
  String get worldPlan => 'Meeting planen';

  @override
  String get worldPlanIntro =>
      'Verschiebe die Markierung, um eine Zeit für alle zu finden.';

  @override
  String get worldPlanNow => 'Jetzt';

  @override
  String get worldPlanEarlier => '15 Minuten früher';

  @override
  String get worldPlanLater => '15 Minuten später';

  @override
  String worldPlanSelected(String city) {
    return 'Gewählte Zeit in $city';
  }

  @override
  String get worldPlanTapCity =>
      'Tippe auf eine Stadt, um ihre Zeit als Referenz zu nutzen.';

  @override
  String get worldPlanNextDay => '+1 Tag';

  @override
  String get worldPlanPrevDay => '-1 Tag';

  @override
  String get worldPlanOverlapTitle => 'Alle sind bei der Arbeit';

  @override
  String get worldPlanNoOverlap =>
      'In den nächsten 24 Stunden passt keine Zeit für alle.';

  @override
  String worldPlanLeastBad(String time) {
    return 'Am besten noch: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$count von $total bei der Arbeit';
  }

  @override
  String get worldPlanWork => 'Arbeitszeit (09-18)';

  @override
  String get worldPlanNight => 'Nacht';

  @override
  String get worldPlanMarker => 'Gewählte Zeit';

  @override
  String get eventAdd => 'Neues Ereignis';

  @override
  String get eventEdit => 'Ereignis bearbeiten';

  @override
  String get eventName => 'Name';

  @override
  String get eventNameHint => 'Geburtstag, Reise, Start ...';

  @override
  String get eventYearly => 'Jedes Jahr wiederholen';

  @override
  String get eventYearlyHint =>
      'Für Geburtstage und Jahrestage: springt zum nächsten weiter.';

  @override
  String get eventNotify => 'Benachrichtigen';

  @override
  String get eventNotifyHint => 'Genau zum Zeitpunkt des Ereignisses.';

  @override
  String get eventDayBefore => 'Auch einen Tag vorher';

  @override
  String get eventSave => 'Speichern';

  @override
  String get eventDelete => 'Ereignis löschen';

  @override
  String get eventConfirmDelete => 'Bestätigen: Ereignis löschen';

  @override
  String get eventDeleteHint => 'Dieses Ereignis wird entfernt.';

  @override
  String get eventEmpty =>
      'Noch keine Ereignisse.\nTippe auf +, um einen Countdown zu starten.';

  @override
  String get eventToday => 'Heute!';

  @override
  String eventDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get eventDaysShort => 'T';

  @override
  String get eventUnitDays => 'Tage';

  @override
  String get eventUnitHours => 'Std.';

  @override
  String get eventUnitMinutes => 'Min.';

  @override
  String get eventRepeatsYearly => 'Jährlich';

  @override
  String get eventNotifyNow => 'Es ist so weit!';

  @override
  String get eventNotifyTomorrow => 'Morgen';

  @override
  String get sleepPlanWake => 'Aufwachen um';

  @override
  String get sleepPlanBed => 'Schlafen um';

  @override
  String get sleepPlanNow => 'Jetzt schlafen';

  @override
  String get sleepTitleWake => 'Ich möchte aufwachen um';

  @override
  String get sleepTitleBed => 'Ich gehe ins Bett um';

  @override
  String sleepTitleNow(String time) {
    return 'Wenn ich jetzt einschlafe ($time)';
  }

  @override
  String get sleepBedtimeWord => 'Schlafenszeit';

  @override
  String get sleepWakeWord => 'Aufwachen';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles Zyklen · $duration Schlaf';
  }

  @override
  String get sleepNote =>
      'Ein Zyklus dauert 90 Minuten, das Einschlafen etwa 15. Empfohlen sind fünf oder sechs Zyklen.';

  @override
  String get sleepWindDown => 'Erinnerung zum Runterkommen';

  @override
  String get sleepWindDownHint =>
      'Ein Wecker 30 Minuten vor der Schlafenszeit.';

  @override
  String get sleepWindDownPassed => 'Diese Zeit ist schon vorbei.';

  @override
  String get sleepWindDownLabel => 'Zeit zum Runterkommen';

  @override
  String get sleepAlarmLabel => 'Aufwachen';

  @override
  String get sleepSetAlarm => 'Wecker stellen';

  @override
  String get sleepRemoveAlarm => 'Wecker entfernen';

  @override
  String sleepAlarmSet(String time) {
    return 'Wecker auf $time gestellt';
  }

  @override
  String get sleepPast => 'Diese Zeit ist schon vorbei';

  @override
  String get sleepRecommended => 'Empfohlen';

  @override
  String get ambientMusicTabSounds => 'Klänge';

  @override
  String get ambientMusicTab => 'Musik';

  @override
  String get ambientMusicPlay => 'Musik abspielen';

  @override
  String get ambientMusicPause => 'Musik pausieren';

  @override
  String get ambientMusicNext => 'Nächster Titel';

  @override
  String get ambientMusicPrevious => 'Vorheriger Titel';

  @override
  String get ambientMusicShuffle => 'Zufällig';

  @override
  String get ambientMusicRepeat => 'Alle wiederholen';

  @override
  String get ambientMusicVolume => 'Musiklautstärke';

  @override
  String get ambientMusicCredits => 'Musik-Credits';

  @override
  String get ambientMusicCreditsNote =>
      'Titel von Wikimedia Commons, veröffentlicht unter CC0 oder Creative-Commons-Namensnennung.';

  @override
  String get modeMusic => 'Musik';

  @override
  String get modeDescMusic => 'Lo-fi-Musik zum Fokussieren';

  @override
  String get musicCreditsSubtitle => 'Künstler und Lizenzen';

  @override
  String get displayMenuButtons => 'Menütasten';

  @override
  String get displayMenuButtonsHint =>
      'Wähle, welche Tasten im unteren Menü erscheinen. Einstellungen bleibt immer sichtbar.';

  @override
  String get onbWelcomeTitle => 'Willkommen bei Enfo';

  @override
  String get onbWelcomeTagline => 'Fokus, ein ruhiges Zifferblatt.';

  @override
  String get timerRunningTitle => 'Timer läuft';

  @override
  String timerRunningBody(String time) {
    return 'Endet um $time';
  }

  @override
  String get timerPausedTitle => 'Timer pausiert';

  @override
  String timerPausedBody(String duration) {
    return 'Noch $duration';
  }

  @override
  String get musicActionPlay => 'Abspielen';

  @override
  String get musicActionPause => 'Pause';

  @override
  String get widgetsFocusSubtitle =>
      'Today\\\'s focus time and pomodoros at a glance.';
}
