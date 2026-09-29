// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipStats => 'Statistics';

  @override
  String get tooltipPin => 'Keep always on top';

  @override
  String get tooltipUnpin => 'Stop keeping on top';

  @override
  String get phasePaused => 'Paused';

  @override
  String get phaseFocus => 'Focus';

  @override
  String get phaseRelax => 'Relax';

  @override
  String get notifRestTitle => 'Time to rest';

  @override
  String get notifRestBody => 'Take a break.';

  @override
  String get notifWorkTitle => 'Time to work';

  @override
  String get notifWorkBody => 'Let\'s continue with the work!';

  @override
  String get onboardingStart => 'Start';

  @override
  String get rhythmTitle => 'Focus rhythm';

  @override
  String get presetClassic => 'Classic';

  @override
  String get presetExtended => 'Extended';

  @override
  String get presetDeep => 'Deep';

  @override
  String get presetManual => 'Manual';

  @override
  String get workLabel => 'Focus';

  @override
  String get restLabel => 'Rest';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest min';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get timersTitle => 'Timers';

  @override
  String timersSubtitle(int work, int rest) {
    return '$work min focus · $rest min rest';
  }

  @override
  String timersCycle(int total) {
    return 'One full cycle: $total min';
  }

  @override
  String get timersApplyHint =>
      'If the timer is running, the change applies from the next cycle. If it is paused, the timer resets.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceLight => 'Light theme';

  @override
  String get appearanceDark => 'Dark theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get accentColor => 'Accent color';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsOn => 'On';

  @override
  String get notificationsOff => 'Off';

  @override
  String get notificationsToggle => 'Phase change alerts';

  @override
  String get notificationsHint =>
      'Get notified when it is time to rest or to get back to work.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageHint => 'Choose the language of the app.';

  @override
  String get supportTitle => 'Support Enfo';

  @override
  String get supportSubtitle => 'Coffee and ads';

  @override
  String get supportSubtitleNoAds => 'Buy me a coffee';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get watchAd => 'Watch an ad to help';

  @override
  String get supportHint =>
      'Enfo is free and made by one person. Thank you for using it.';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsEmpty =>
      'No sessions yet.\nStart a pomodoro and it will show up here.';

  @override
  String get statsTodayPomodoros => 'Pomodoros today';

  @override
  String get statsTodayFocus => 'Focus today';

  @override
  String get statsCompleted => 'Completed';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Days in a row',
      one: 'Day in a row',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsTotalFocus => 'Total focus time';

  @override
  String get statsTotalRest => 'Total rest time';

  @override
  String get statsAbandoned => 'Abandoned';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent% completed';
  }

  @override
  String get statsAverageFocus => 'Average focus';

  @override
  String get statsLongestSession => 'Longest session';

  @override
  String get statsPauses => 'Pauses';

  @override
  String get statsAverageGap => 'Average wait between sessions';

  @override
  String get statsLongestGap => 'Longest time inactive';

  @override
  String get statsSinceLast => 'Since last session';

  @override
  String get statsHistory => 'History';

  @override
  String get statsClearHistory => 'Clear history';

  @override
  String get statsClearConfirm => 'Confirm: delete all sessions';

  @override
  String get statsClearHint => 'This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get sessionFocus => 'Focus';

  @override
  String get sessionRest => 'Rest';

  @override
  String sessionProgress(String done, String planned) {
    return '$done of $planned';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pauses',
      one: '1 pause',
    );
    return '$_temp0 ($time)';
  }

  @override
  String sessionIdleBefore(String gap) {
    return 'after $gap idle';
  }

  @override
  String get sessionCompleted => 'Completed';

  @override
  String get sessionAbandoned => 'Abandoned';

  @override
  String get clockStyleTitle => 'Clock style';

  @override
  String get tooltipClockStyle => 'Clock style';

  @override
  String get clockCategoryProgress => 'Progress & numbers';

  @override
  String get clockCategoryNumbers => 'Numbers only';

  @override
  String get clockCategoryIcons => 'Icon only';

  @override
  String get clockCategoryMotion => 'Animation only';

  @override
  String get clockUnitMinutes => 'min';

  @override
  String get clockUnitSeconds => 'sec';

  @override
  String get clockRing => 'Ring';

  @override
  String get clockWavyRing => 'Wave';

  @override
  String get clockSegments => 'Segments';

  @override
  String get clockOrbit => 'Orbit';

  @override
  String get clockPie => 'Pie';

  @override
  String get clockKitchen => 'Kitchen';

  @override
  String get clockDots => 'Dots';

  @override
  String get clockBar => 'Bar';

  @override
  String get clockWavyBar => 'Wavy bar';

  @override
  String get clockDigits => 'Digits';

  @override
  String get clockMinutes => 'Minutes';

  @override
  String get clockTiles => 'Tiles';

  @override
  String get clockStack => 'Stacked';

  @override
  String get clockTomato => 'Tomato';

  @override
  String get clockHourglass => 'Hourglass';

  @override
  String get clockBattery => 'Battery';

  @override
  String get clockIcon => 'Icon';

  @override
  String get clockCookie => 'Cookie';

  @override
  String get clockLiquid => 'Liquid';

  @override
  String get clockBreathe => 'Breathe';

  @override
  String get clockEqualizer => 'Equalizer';

  @override
  String get clockRipple => 'Ripples';

  @override
  String get accentApply => 'Apply';

  @override
  String get accentCustom => 'Custom color';

  @override
  String get accentHue => 'Hue';

  @override
  String get accentSaturation => 'Saturation';

  @override
  String get accentBrightness => 'Brightness';

  @override
  String get accentHex => 'Hex code';

  @override
  String get displayTitle => 'Display';

  @override
  String get displayClockShown => 'Clock visible';

  @override
  String get displayClockHidden => 'Clock hidden';

  @override
  String get showClock => 'Show the time';

  @override
  String get showClockHint => 'The small clock above the timer.';

  @override
  String get clockFormat => 'Time format';

  @override
  String get clockFormatSystem => 'System default';

  @override
  String get clockFormat12 => '12-hour';

  @override
  String get clockFormat24 => '24-hour';

  @override
  String get behaviorTitle => 'Behavior';

  @override
  String get autoStartNext => 'Start next phase automatically';

  @override
  String get autoStartNextHint =>
      'When focus or rest ends, the next one begins without tapping.';

  @override
  String get hapticFeedback => 'Vibration';

  @override
  String get hapticFeedbackHint => 'Taps, wheels, phase changes and alarms.';

  @override
  String get clockCombosTitle => 'Combos';

  @override
  String get clockCollapseAll => 'Collapse all';

  @override
  String get clockExpandAll => 'Expand all';

  @override
  String get comboDeepFocus => 'Deep focus';

  @override
  String get comboMint => 'Fresh mint';

  @override
  String get comboSunset => 'Sunset';

  @override
  String get comboZen => 'Zen';

  @override
  String get comboTomato => 'Classic tomato';

  @override
  String get comboNight => 'Night owl';

  @override
  String get comboPlayful => 'Playful';

  @override
  String get comboMinimal => 'Minimal';

  @override
  String get uiSizeTitle => 'Interface size';

  @override
  String get uiSizeSmall => 'Small';

  @override
  String get uiSizeNormal => 'Normal';

  @override
  String get uiSizeLarge => 'Large';

  @override
  String get uiSizeExtraLarge => 'Extra large';

  @override
  String get uiSizeHint =>
      'Makes text and controls bigger or smaller. Useful on TVs and car displays.';

  @override
  String get clockBlob => 'Blob';

  @override
  String get clockFlower => 'Flower';

  @override
  String get clockSun => 'Sun';

  @override
  String get clockGears => 'Gears';

  @override
  String get clockBubbles => 'Bubbles';

  @override
  String get clockSunflower => 'Sunflower';

  @override
  String get clockFireflies => 'Fireflies';

  @override
  String get clockPendulum => 'Pendulum';

  @override
  String get clockBounce => 'Bounce';

  @override
  String get clockMorph => 'Morph';

  @override
  String get dataTitle => 'Data';

  @override
  String get dataSubtitle => 'History, reset and intro';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved entries',
      one: '1 saved entry',
      zero: 'No saved activity',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'Show the intro again';

  @override
  String get dataIntroHint =>
      'Go through the welcome screen and pick your rhythm again. Nothing is deleted.';

  @override
  String get dataClearHistoryHint =>
      'Deletes all recorded activity: pomodoros, timers, stopwatch runs, alarms and clock time. Settings stay as they are.';

  @override
  String get dataConfirmClearHistory => 'Confirm: clear history';

  @override
  String get dataResetSettings => 'Reset settings';

  @override
  String get dataResetSettingsHint =>
      'Timers, theme, accent color, language, modes and display options go back to defaults. History stays.';

  @override
  String get dataConfirmResetSettings => 'Confirm: reset settings';

  @override
  String get dataEraseAll => 'Erase everything';

  @override
  String get dataEraseAllHint =>
      'Deletes history and settings and starts fresh, as on the first launch.';

  @override
  String get dataConfirmEraseAll => 'Confirm: erase everything';

  @override
  String get dataDoneHistory => 'History cleared.';

  @override
  String get dataDoneSettings => 'Settings restored to defaults.';

  @override
  String get dataCacheNote =>
      'Enfo keeps no cache: everything it stores is the history and the settings listed here.';

  @override
  String get clockEndsAt => 'Ends';

  @override
  String get clockFill => 'Fill';

  @override
  String get clockCapsule => 'Capsule';

  @override
  String get clockRollers => 'Rollers';

  @override
  String get clockMatrix => 'Matrix';

  @override
  String get clockSevenSeg => 'Digital';

  @override
  String get clockFlip => 'Flip';

  @override
  String get clockFine => 'Fine';

  @override
  String get clockSuperscript => 'Exponent';

  @override
  String get clockPercent => 'Percent';

  @override
  String get clockEndTime => 'Ends at';

  @override
  String get clockSeconds => 'Seconds';

  @override
  String get clockTall => 'Tall';

  @override
  String get clockWobble => 'Wobble';

  @override
  String get clockLabeled => 'Labeled';

  @override
  String get clockGauge => 'Gauge';

  @override
  String get clockNeedle => 'Needle';

  @override
  String get clockAnalog => 'Analog';

  @override
  String get clockRings => 'Rings';

  @override
  String get clockSquircle => 'Squircle';

  @override
  String get clockColumns => 'Columns';

  @override
  String get clockVertical => 'Vertical';

  @override
  String get clockSteps => 'Steps';

  @override
  String get clockBlocks => 'Blocks';

  @override
  String get clockSpiral => 'Spiral';

  @override
  String get clockSlices => 'Slices';

  @override
  String get clockPills => 'Pills';

  @override
  String get clockHexagon => 'Hexagon';

  @override
  String get clockStairs => 'Stairs';

  @override
  String get clockCandle => 'Candle';

  @override
  String get clockMoon => 'Moon';

  @override
  String get clockRuler => 'Ruler';

  @override
  String get comboArcade => 'Arcade';

  @override
  String get comboCalculator => 'Calculator';

  @override
  String get comboDepartures => 'Departure board';

  @override
  String get comboCandlelight => 'Candlelight';

  @override
  String get comboMoonlight => 'Moonlight';

  @override
  String get comboGarden => 'Garden';

  @override
  String get comboSummer => 'Summer';

  @override
  String get comboWorkshop => 'Workshop';

  @override
  String get comboFizzy => 'Fizzy';

  @override
  String get comboSunfield => 'Sunflower field';

  @override
  String get comboSummerNight => 'Summer night';

  @override
  String get comboHypnosis => 'Hypnosis';

  @override
  String get comboBouncy => 'Bouncy';

  @override
  String get comboShapeshifter => 'Shapeshifter';

  @override
  String get comboLava => 'Lava lamp';

  @override
  String get comboOcean => 'Ocean';

  @override
  String get comboPulse => 'Pulse';

  @override
  String get comboPond => 'Pond';

  @override
  String get comboEspresso => 'Espresso';

  @override
  String get comboSpeedometer => 'Speedometer';

  @override
  String get comboCompass => 'Compass';

  @override
  String get comboClassicClock => 'Classic clock';

  @override
  String get comboConcentric => 'Concentric';

  @override
  String get comboRounded => 'Rounded';

  @override
  String get comboSignal => 'Signal';

  @override
  String get comboThermometer => 'Thermometer';

  @override
  String get comboMilestones => 'Milestones';

  @override
  String get comboRetroBlocks => 'Retro blocks';

  @override
  String get comboHypnoSpiral => 'Hypnotic spiral';

  @override
  String get comboCitrus => 'Citrus';

  @override
  String get comboChocolate => 'Chocolate bar';

  @override
  String get comboCrystal => 'Crystal';

  @override
  String get comboStaircase => 'Staircase';

  @override
  String get comboTapeMeasure => 'Tape measure';

  @override
  String get comboBoldType => 'Bold type';

  @override
  String get comboPill => 'Capsule';

  @override
  String get comboSlotMachine => 'Slot machine';

  @override
  String get comboWhisper => 'Whisper';

  @override
  String get comboDeadline => 'Deadline';

  @override
  String get comboPercentage => 'Percent';

  @override
  String get comboStopwatch => 'Seconds only';

  @override
  String get comboSkyscraper => 'Skyscraper';

  @override
  String get comboWaveText => 'Wave text';

  @override
  String get comboDashboard => 'Dashboard';

  @override
  String get comboExponent => 'Exponent';

  @override
  String get comboGrandmaKitchen => 'Grandma\'s kitchen';

  @override
  String get comboCyber => 'Cyber';

  @override
  String get comboCandy => 'Candy';

  @override
  String get comboConfetti => 'Confetti';

  @override
  String get comboCookieJar => 'Cookie jar';

  @override
  String get comboSandbox => 'Sandbox';

  @override
  String get comboPizzaNight => 'Pizza night';

  @override
  String get onbLanguageTitle => 'Welcome to Enfo';

  @override
  String get onbLanguageBody =>
      'Pick your language. Everything you choose here can be changed later in Settings.';

  @override
  String get onbRhythmTitle => 'Your rhythm';

  @override
  String get onbRhythmBody => 'How long you focus, and how long you rest.';

  @override
  String get onbLookTitle => 'Make it yours';

  @override
  String get onbLookBody =>
      'Theme, clock style and color. Start from a combo, then tweak the color if you like.';

  @override
  String get onbClockTitle => 'Pick a clock';

  @override
  String get onbClockBody =>
      'Curated looks: a clock style and a color in one tap.';

  @override
  String get onbAllStyles => 'Browse all styles';

  @override
  String get onbOptionsTitle => 'Final touches';

  @override
  String get onbOptionsBody =>
      'Display and behavior. All of this is in Settings too.';

  @override
  String get onbModesTitle => 'Your tools';

  @override
  String get onbModesBody =>
      'Enfo is a clock and timer toolbox. Turn on what you will use; change it anytime from the modes menu.';

  @override
  String get onbPreview => 'Preview';

  @override
  String get onbDisplayTitle => 'Display';

  @override
  String get onbDisplayBody => 'How the clock looks and how big everything is.';

  @override
  String get onbClockModeDesign => 'Clock mode design';

  @override
  String get onbPermTitle => 'Permissions';

  @override
  String get onbPermBody =>
      'So timers and alarms can reach you even when Enfo is closed.';

  @override
  String get onbPermNotifications => 'Notifications';

  @override
  String get onbPermNotificationsHint =>
      'Alerts when a timer ends or an alarm rings.';

  @override
  String get onbPermExact => 'Exact alarms';

  @override
  String get onbPermExactHint =>
      'Ring at the exact minute, even in battery saver.';

  @override
  String get onbPermAllow => 'Allow';

  @override
  String get onbPermAllowed => 'Allowed';

  @override
  String get onbPermLater =>
      'You can change these anytime in the system settings.';

  @override
  String get onbNext => 'Next';

  @override
  String get onbBack => 'Back';

  @override
  String get onbSkip => 'Skip';

  @override
  String onbStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get clockFormatAuto => 'Auto';

  @override
  String get modePomodoro => 'Pomodoro';

  @override
  String get modeClock => 'Clock';

  @override
  String get modeTimer => 'Timer';

  @override
  String get modeStopwatch => 'Stopwatch';

  @override
  String get modeAlarm => 'Alarm';

  @override
  String get modeWorld => 'World clock';

  @override
  String get modeDescPomodoro => 'Focus and rest cycles';

  @override
  String get modeDescClock => 'A beautiful, always-on clock';

  @override
  String get modeDescTimer => 'Count down from any time';

  @override
  String get modeDescStopwatch => 'Measure time, with laps';

  @override
  String get modeDescAlarm => 'Wake up or get reminded';

  @override
  String get modeDescWorld => 'The time in cities around the world';

  @override
  String get tooltipModes => 'Modes';

  @override
  String get tooltipSwitchMode => 'Next mode';

  @override
  String get tooltipFullscreen => 'Full screen';

  @override
  String get tooltipExitFullscreen => 'Exit full screen';

  @override
  String get tooltipDim => 'Dim the screen';

  @override
  String get modesTitle => 'Modes';

  @override
  String get modesHint =>
      'Choose the modes you use and their order. Drag to reorder.';

  @override
  String get modesStart => 'Start with';

  @override
  String get modesStartLast => 'Last used mode';

  @override
  String get modesCustomize => 'Customize';

  @override
  String get modesActivity => 'Activity history';

  @override
  String get modesAtLeastOne => 'At least one mode has to stay on.';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modes on',
      one: '1 mode on',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'Activity history';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityEmpty =>
      'Nothing here yet.\nUse a timer, a stopwatch, an alarm or the clock and it will show up here.';

  @override
  String get activityFilterAll => 'All';

  @override
  String get activityTimersToday => 'Timers today';

  @override
  String get activityStopwatchToday => 'Stopwatch today';

  @override
  String get activityDisplayToday => 'On display today';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count laps',
      one: '1 lap',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'Lap $n';
  }

  @override
  String get activityAlarmDismissed => 'Dismissed';

  @override
  String get activityAlarmSnoozed => 'Snoozed';

  @override
  String get activityAlarmMissed => 'Missed';

  @override
  String activityDisplay(String mode) {
    return '$mode on display';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done of $planned';
  }

  @override
  String get faceRing => 'Ring';

  @override
  String get faceDigital => 'Digital';

  @override
  String get faceAnalog => 'Analog';

  @override
  String get faceSplit => 'Big';

  @override
  String get faceDay => 'Day';

  @override
  String get tooltipCustomize => 'Customize';

  @override
  String get clockSettingsTitle => 'Customize the clock';

  @override
  String get clockFaceTitle => 'Design';

  @override
  String get clockShowSeconds => 'Show seconds';

  @override
  String get clockShowDate => 'Show the date';

  @override
  String get clockBlinkColon => 'Blinking colon';

  @override
  String get clockKeepAwake => 'Keep the screen on';

  @override
  String get clockKeepAwakeHint => 'While the clock is showing.';

  @override
  String get clockFullscreenHint =>
      'Tap the full screen button for a desk clock that stays on. Swipe the clock to change its design.';

  @override
  String clockDayPercent(int percent) {
    return '$percent% of the day';
  }

  @override
  String get ringDismiss => 'Dismiss';

  @override
  String ringSnooze(int minutes) {
    return 'Snooze $minutes min';
  }

  @override
  String get timerStart => 'Start';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerResume => 'Resume';

  @override
  String get timerReset => 'Reset';

  @override
  String get timerAddMinute => '+1 min';

  @override
  String get timerHoursShort => 'h';

  @override
  String get timerMinutesShort => 'min';

  @override
  String get timerSecondsShort => 's';

  @override
  String get timerUpTitle => 'Time\'s up';

  @override
  String timerUpBody(String duration) {
    return 'The $duration timer finished.';
  }

  @override
  String get timerSavePreset => 'Save this time';

  @override
  String get timerPresetHint =>
      'Tap + to save this time. Long-press a preset to remove it.';

  @override
  String get stopwatchStop => 'Stop';

  @override
  String get stopwatchLap => 'Lap';

  @override
  String get stopwatchLapBest => 'Best';

  @override
  String get stopwatchLapWorst => 'Slowest';

  @override
  String get worldLocal => 'Local time';

  @override
  String get worldToday => 'Today';

  @override
  String get worldTomorrow => 'Tomorrow';

  @override
  String get worldYesterday => 'Yesterday';

  @override
  String get worldAdd => 'Add a city';

  @override
  String get worldSearch => 'Search cities';

  @override
  String get worldNoResults => 'No city matches that.';

  @override
  String get worldEdit => 'Edit list';

  @override
  String get worldDone => 'Done';

  @override
  String get worldRemove => 'Remove';

  @override
  String get worldEmpty => 'No other cities yet. Tap + to add one.';

  @override
  String get worldSameTime => 'Same time as you';

  @override
  String worldDiffAhead(String diff) {
    return '$diff ahead of you';
  }

  @override
  String worldDiffBehind(String diff) {
    return '$diff behind you';
  }

  @override
  String alarmNext(String duration) {
    return 'Next alarm in $duration';
  }

  @override
  String get alarmNone => 'No alarms on';

  @override
  String get alarmNew => 'New alarm';

  @override
  String get alarmEditTitle => 'Edit alarm';

  @override
  String get alarmLabel => 'Label';

  @override
  String get alarmRepeat => 'Repeat';

  @override
  String get alarmSave => 'Save';

  @override
  String get alarmDelete => 'Delete alarm';

  @override
  String get alarmConfirmDelete => 'Confirm: delete alarm';

  @override
  String get alarmDeleteHint => 'This alarm will be removed.';

  @override
  String get alarmEmpty => 'No alarms yet.\nTap + to create one.';

  @override
  String get alarmEveryDay => 'Every day';

  @override
  String get alarmWeekdays => 'Weekdays';

  @override
  String get alarmWeekends => 'Weekends';

  @override
  String get alarmOnce => 'Once';

  @override
  String get alarmPermissionHint =>
      'To ring with the app closed, Enfo needs permission to send notifications and set exact alarms.';

  @override
  String get alarmPermissionButton => 'Allow alarms';

  @override
  String get alarmDesktopHint =>
      'On this device Enfo has to be open for alarms to ring.';

  @override
  String get hapticsTitle => 'Vibration';

  @override
  String get hapticsOff => 'Off';

  @override
  String get hapticsStrength => 'Strength';

  @override
  String get hapticsSoft => 'Soft';

  @override
  String get hapticsMedium => 'Medium';

  @override
  String get hapticsStrong => 'Strong';

  @override
  String get hapticsTouch => 'Touch';

  @override
  String get hapticsTouchHint => 'Buttons, switches and selections.';

  @override
  String get hapticsMotion => 'Motion';

  @override
  String get hapticsMotionHint => 'Wheels, sliders, dragging and transitions.';

  @override
  String get hapticsAlerts => 'Alerts';

  @override
  String get hapticsAlertsHint =>
      'Timers, phase changes, the final countdown and alarms.';

  @override
  String get hapticsAlarmPattern => 'Alarm pattern';

  @override
  String get hapticsAlarmPatternHint =>
      'Tap a pattern to feel it. The ringing screen pulses to the same beat.';

  @override
  String get hapticsPatternHeartbeat => 'Heartbeat';

  @override
  String get hapticsPatternPulse => 'Pulse';

  @override
  String get hapticsPatternCrescendo => 'Crescendo';

  @override
  String get hapticsPatternRipple => 'Ripple';

  @override
  String get hapticsPatternBeacon => 'Beacon';

  @override
  String get hapticsTry => 'Try it';

  @override
  String get hapticsTryTap => 'Tap';

  @override
  String get hapticsTrySuccess => 'Success';

  @override
  String get hapticsTryToRest => 'Focus done';

  @override
  String get hapticsTryToWork => 'Rest done';

  @override
  String get hapticsTryTimer => 'Timer done';

  @override
  String get hapticsTryWarning => 'Warning';

  @override
  String get hapticsUnavailable => 'This device has no vibration motor.';

  @override
  String get hapticsWhen => 'When it vibrates';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSubtitle => 'Clocks and timers on your home screen';

  @override
  String get widgetsAddHeader => 'Add to home screen';

  @override
  String get widgetsAdd => 'Add';

  @override
  String get widgetsDynamicColor => 'Material You colors';

  @override
  String get widgetsDynamicColorHint =>
      'Widgets take their colors from your wallpaper. Turn off to use Enfo\'s accent color.';

  @override
  String get widgetsManualHint =>
      'Your launcher can\'t add widgets from here. Long-press the home screen, choose Widgets and look for Enfo.';

  @override
  String get widgetsStyleHint =>
      'The Pomodoro and timer widgets are drawn in the clock style you picked. Change the style in the app and they follow.';

  @override
  String get widgetsTapHint =>
      'Buttons on a widget open Enfo and do the action, so time is always kept by the app.';

  @override
  String get shortcutsTitle => 'Keyboard & remote';

  @override
  String get shortcutsSubtitle => 'Shortcuts for keyboard, mouse and TV remote';

  @override
  String get shortcutsIntro =>
      'Arrow keys or the remote\'s D-pad move around, Enter or OK presses. These keys do the rest.';

  @override
  String get shortcutKeySpace => 'Space';

  @override
  String get shortcutPlayPause => 'Start or pause';

  @override
  String get shortcutReset => 'Reset';

  @override
  String get shortcutLap => 'Lap (stopwatch)';

  @override
  String get shortcutJumpMode => 'Go to mode 1–9';

  @override
  String get shortcutStepMode => 'Previous / next mode';

  @override
  String get shortcutFullscreen => 'Full screen';

  @override
  String get shortcutDim => 'Dim the screen (full screen)';

  @override
  String get shortcutSettings => 'Settings';

  @override
  String get shortcutModes => 'Modes menu';

  @override
  String get shortcutBack => 'Back / leave full screen';

  @override
  String get shortcutHelp => 'Show this list';

  @override
  String get onbMoreTools => 'More tools';

  @override
  String get modeEvent => 'Events';

  @override
  String get modeDescEvent => 'Count the days to what matters';

  @override
  String get modeIntervals => 'Intervals';

  @override
  String get modeDescIntervals => 'Work and rest rounds, like HIIT';

  @override
  String get modeBreathe => 'Breathe';

  @override
  String get modeDescBreathe => 'Guided breathing to calm down';

  @override
  String get modeTracker => 'Tracker';

  @override
  String get modeDescTracker => 'Time what you do, see the totals';

  @override
  String get modeKitchen => 'Kitchen';

  @override
  String get modeDescKitchen => 'Several named timers at once';

  @override
  String get modeSleep => 'Sleep';

  @override
  String get modeDescSleep => 'Plan bedtime and wake-up in sleep cycles';

  @override
  String get modeVersus => 'Turns';

  @override
  String get modeDescVersus => 'Two-player clock for chess, games and debates';

  @override
  String get modeBreaks => 'Breaks';

  @override
  String get modeDescBreaks => 'Reminders to rest your eyes and stretch';

  @override
  String get modeAmbient => 'Ambient';

  @override
  String get modeDescAmbient => 'Background sounds with a sleep timer';

  @override
  String get intervalsPresetTabata => 'Tabata';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'Custom';

  @override
  String get intervalsWarmUp => 'Warm-up';

  @override
  String get intervalsWork => 'Work';

  @override
  String get intervalsRest => 'Rest';

  @override
  String get intervalsRounds => 'Rounds';

  @override
  String get intervalsCoolDown => 'Cool-down';

  @override
  String get intervalsOff => 'Off';

  @override
  String intervalsRound(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return 'Total $duration';
  }

  @override
  String get intervalsSkip => 'Skip to next phase';

  @override
  String get intervalsHint =>
      'Tap a row to edit it. Any change saves as Custom.';

  @override
  String get intervalsDoneTitle => 'Workout complete';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration. Great work!';
  }

  @override
  String get kitchenPasta => 'Pasta';

  @override
  String get kitchenEggs => 'Eggs';

  @override
  String get kitchenTea => 'Tea';

  @override
  String get kitchenRice => 'Rice';

  @override
  String get kitchenOven => 'Oven';

  @override
  String get kitchenCustom => 'Custom';

  @override
  String get kitchenNameHint => 'Name';

  @override
  String get kitchenAdd => 'Start timer';

  @override
  String get kitchenDelete => 'Delete timer';

  @override
  String get kitchenEmpty => 'No timers yet. Tap a chip to start one.';

  @override
  String get kitchenDefaultName => 'Timer';

  @override
  String kitchenDoneTitle(String name) {
    return '$name is ready';
  }

  @override
  String kitchenDoneBody(String duration) {
    return 'The $duration timer finished.';
  }

  @override
  String get trackerToday => 'Today';

  @override
  String get trackerWeek => 'Last 7 days';

  @override
  String get trackerTapToStart => 'Tap an activity to start timing it';

  @override
  String get trackerNoRunning => 'Nothing running';

  @override
  String get trackerAddActivity => 'New activity';

  @override
  String get trackerNameHint => 'Name';

  @override
  String get trackerStudy => 'Study';

  @override
  String get trackerReading => 'Reading';

  @override
  String get trackerCode => 'Code';

  @override
  String get trackerExercise => 'Exercise';

  @override
  String get trackerEdit => 'Edit activity';

  @override
  String get trackerDetails => 'Details and chart';

  @override
  String get trackerColor => 'Color';

  @override
  String get trackerIcon => 'Icon';

  @override
  String get trackerDelete => 'Delete activity';

  @override
  String get trackerDeleteConfirm => 'Confirm: delete this activity';

  @override
  String get trackerDeleteHint =>
      'Time already logged stays in the activity history.';

  @override
  String get trackerAddTime => 'Add time manually';

  @override
  String trackerAddMinutes(int minutes) {
    return 'Add $minutes min';
  }

  @override
  String get trackerMinutesFewer => 'Fewer minutes';

  @override
  String get trackerMinutesMore => 'More minutes';

  @override
  String get trackerStop => 'Stop';

  @override
  String get versusDuel => 'Duel';

  @override
  String get versusSpeakers => 'Speakers';

  @override
  String get versusCustom => 'Custom';

  @override
  String get versusIncrement => 'Increment';

  @override
  String get versusTapToStart => 'Tap your side to start your clock';

  @override
  String get versusTimeIsUp => 'Time is up';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => 'Reset game';

  @override
  String get versusConfirmReset => 'Confirm reset';

  @override
  String versusSpeakerN(int n) {
    return 'Speaker $n';
  }

  @override
  String get versusAddSpeaker => 'Add speaker';

  @override
  String get versusRemoveSpeaker => 'Remove speaker';

  @override
  String get versusSpeakerName => 'Speaker or topic';

  @override
  String get versusNext => 'Next speaker';

  @override
  String get versusFinish => 'Finish';

  @override
  String get versusOvertime => 'Overtime';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed of $planned';
  }

  @override
  String get versusAgendaDone => 'Agenda finished';

  @override
  String get versusStartAgenda => 'Start agenda';

  @override
  String get versusMinutesFewer => 'Fewer minutes';

  @override
  String get versusMinutesMore => 'More minutes';

  @override
  String get versusTotal => 'Total';

  @override
  String get breatheInhale => 'Inhale';

  @override
  String get breatheHold => 'Hold';

  @override
  String get breatheExhale => 'Exhale';

  @override
  String get breatheStart => 'Start breathing';

  @override
  String get breathePause => 'Pause';

  @override
  String get breatheResume => 'Resume';

  @override
  String get breatheReset => 'Stop session';

  @override
  String get breatheDone => 'Well done';

  @override
  String get breatheReady => 'Find a comfortable position';

  @override
  String get breathePatternBox => 'Box';

  @override
  String get breathePatternCoherent => 'Coherent';

  @override
  String get breathePatternCalm => 'Calm';

  @override
  String get breathePatternCustom => 'Custom';

  @override
  String get breatheSession => 'Session';

  @override
  String get breatheEndless => 'Endless';

  @override
  String breatheSeconds(int n) {
    return '${n}s';
  }

  @override
  String get ambientWhite => 'White noise';

  @override
  String get ambientPink => 'Pink noise';

  @override
  String get ambientBrown => 'Brown noise';

  @override
  String get ambientRain => 'Rain';

  @override
  String get ambientWind => 'Wind';

  @override
  String get ambientOcean => 'Ocean';

  @override
  String get ambientVolume => 'Volume';

  @override
  String get ambientSleepTimer => 'Sleep timer';

  @override
  String get ambientTimerOff => 'Off';

  @override
  String get ambientPlay => 'Play sound';

  @override
  String get ambientStop => 'Stop sound';

  @override
  String get ambientUnavailable => 'Sound is not available on this device.';

  @override
  String get ambientPreparing => 'Preparing sound…';

  @override
  String ambientTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get breaksStart => 'Start breaks';

  @override
  String get breaksStop => 'Stop breaks';

  @override
  String get breaksStatusOff => 'Break reminders are off';

  @override
  String get breaksNoneEnabled => 'Turn on at least one reminder';

  @override
  String breaksNextName(String name) {
    return 'Next: $name';
  }

  @override
  String get breaksToday => 'Today';

  @override
  String get breaksTaken => 'Breaks taken';

  @override
  String get breaksSkipped => 'Skipped';

  @override
  String get breaksEyeName => 'Eye rest (20-20-20)';

  @override
  String get breaksEyeHint =>
      'Look at something 6 m (20 ft) away for 20 seconds';

  @override
  String get breaksStretchName => 'Stretch';

  @override
  String get breaksStretchHint => 'Stand up and stretch your whole body';

  @override
  String get breaksWaterName => 'Drink water';

  @override
  String get breaksWaterHint => 'Have a glass of water';

  @override
  String get breaksPostureName => 'Posture check';

  @override
  String get breaksPostureHint => 'Sit up straight and relax your shoulders';

  @override
  String get breaksCustomDefault => 'My reminder';

  @override
  String breaksForDuration(String duration) {
    return 'Take $duration';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get breaksShorter => 'Shorter interval';

  @override
  String get breaksLonger => 'Longer interval';

  @override
  String get breaksDone => 'Done';

  @override
  String get breaksSkip => 'Skip';

  @override
  String get breaksActiveHours => 'Active hours';

  @override
  String get breaksActiveHoursHint =>
      'Reminders only appear between these times';

  @override
  String get breaksFrom => 'From';

  @override
  String get breaksTo => 'To';

  @override
  String get breaksLaterHour => 'Later';

  @override
  String get breaksEarlierHour => 'Earlier';

  @override
  String get breaksBackground => 'Also when Enfo is closed';

  @override
  String get breaksBackgroundOn =>
      'Notifications remind you even when the app is closed.';

  @override
  String get breaksBackgroundOff => 'Reminders only appear while Enfo is open.';

  @override
  String get breaksDesktopNotice =>
      'Reminders appear while Enfo is running (it can stay minimized).';

  @override
  String get breaksAddCustom => 'Add custom reminder';

  @override
  String get breaksEdit => 'Edit reminder';

  @override
  String get breaksName => 'Name';

  @override
  String get breaksDuration => 'Duration';

  @override
  String get breaksIcon => 'Icon';

  @override
  String get breaksShorterDuration => 'Shorter break';

  @override
  String get breaksLongerDuration => 'Longer break';

  @override
  String get breaksRemove => 'Remove reminder';

  @override
  String get breaksRemoveConfirm => 'Confirm: remove reminder';

  @override
  String get breaksRemoveHint => 'It will stop reminding you.';

  @override
  String get worldPlan => 'Plan a meeting';

  @override
  String get worldPlanIntro =>
      'Slide the marker to find a time that works for everyone.';

  @override
  String get worldPlanNow => 'Now';

  @override
  String get worldPlanEarlier => '15 minutes earlier';

  @override
  String get worldPlanLater => '15 minutes later';

  @override
  String worldPlanSelected(String city) {
    return 'Selected time in $city';
  }

  @override
  String get worldPlanTapCity => 'Tap a city to use its time as the reference.';

  @override
  String get worldPlanNextDay => '+1 day';

  @override
  String get worldPlanPrevDay => '-1 day';

  @override
  String get worldPlanOverlapTitle => 'Everyone is at work';

  @override
  String get worldPlanNoOverlap =>
      'No time in the next 24 hours works for everyone.';

  @override
  String worldPlanLeastBad(String time) {
    return 'Least bad: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$count of $total at work';
  }

  @override
  String get worldPlanWork => 'Working hours (09-18)';

  @override
  String get worldPlanNight => 'Night';

  @override
  String get worldPlanMarker => 'Selected time';

  @override
  String get eventAdd => 'New event';

  @override
  String get eventEdit => 'Edit event';

  @override
  String get eventName => 'Name';

  @override
  String get eventNameHint => 'Birthday, trip, launch...';

  @override
  String get eventYearly => 'Repeat every year';

  @override
  String get eventYearlyHint =>
      'For birthdays and anniversaries: it moves on to the next one.';

  @override
  String get eventNotify => 'Notify me';

  @override
  String get eventNotifyHint => 'At the moment it arrives.';

  @override
  String get eventDayBefore => 'Also the day before';

  @override
  String get eventSave => 'Save';

  @override
  String get eventDelete => 'Delete event';

  @override
  String get eventConfirmDelete => 'Confirm: delete event';

  @override
  String get eventDeleteHint => 'This event will be removed.';

  @override
  String get eventEmpty => 'No events yet.\nTap + to count down to one.';

  @override
  String get eventToday => 'Today!';

  @override
  String eventDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get eventDaysShort => 'd';

  @override
  String get eventUnitDays => 'days';

  @override
  String get eventUnitHours => 'hours';

  @override
  String get eventUnitMinutes => 'min';

  @override
  String get eventRepeatsYearly => 'Every year';

  @override
  String get eventNotifyNow => 'It\'s time!';

  @override
  String get eventNotifyTomorrow => 'Tomorrow';

  @override
  String get sleepPlanWake => 'Wake at';

  @override
  String get sleepPlanBed => 'Sleep at';

  @override
  String get sleepPlanNow => 'Sleep now';

  @override
  String get sleepTitleWake => 'I want to wake up at';

  @override
  String get sleepTitleBed => 'I go to bed at';

  @override
  String sleepTitleNow(String time) {
    return 'If I fall asleep now ($time)';
  }

  @override
  String get sleepBedtimeWord => 'Bedtime';

  @override
  String get sleepWakeWord => 'Wake up';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles cycles · $duration of sleep';
  }

  @override
  String get sleepNote =>
      'Cycles last 90 minutes and falling asleep takes about 15. Five or six cycles are recommended.';

  @override
  String get sleepWindDown => 'Wind-down reminder';

  @override
  String get sleepWindDownHint => 'An alarm 30 minutes before bedtime.';

  @override
  String get sleepWindDownPassed => 'That time has already passed.';

  @override
  String get sleepWindDownLabel => 'Time to wind down';

  @override
  String get sleepAlarmLabel => 'Wake up';

  @override
  String get sleepSetAlarm => 'Set alarm';

  @override
  String get sleepRemoveAlarm => 'Remove alarm';

  @override
  String sleepAlarmSet(String time) {
    return 'Alarm set for $time';
  }

  @override
  String get sleepPast => 'This time has already passed';

  @override
  String get sleepRecommended => 'Recommended';

  @override
  String get ambientMusicTabSounds => 'Sounds';

  @override
  String get ambientMusicTab => 'Music';

  @override
  String get ambientMusicPlay => 'Play music';

  @override
  String get ambientMusicPause => 'Pause music';

  @override
  String get ambientMusicNext => 'Next song';

  @override
  String get ambientMusicPrevious => 'Previous song';

  @override
  String get ambientMusicShuffle => 'Shuffle';

  @override
  String get ambientMusicRepeat => 'Repeat all';

  @override
  String get ambientMusicVolume => 'Music volume';

  @override
  String get ambientMusicCredits => 'Music credits';

  @override
  String get ambientMusicCreditsNote =>
      'Songs from Wikimedia Commons, released under CC0 or Creative Commons Attribution licenses.';

  @override
  String get modeMusic => 'Music';

  @override
  String get modeDescMusic => 'Lo-fi songs to focus to';

  @override
  String get musicCreditsSubtitle => 'Artists and licenses';

  @override
  String get displayMenuButtons => 'Menu buttons';

  @override
  String get displayMenuButtonsHint =>
      'Choose which buttons appear in the bottom menu. Settings is always there.';
}
