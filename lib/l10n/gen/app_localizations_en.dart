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
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

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
  String get hapticFeedback => 'Vibrate when a phase ends';

  @override
  String get hapticFeedbackHint => 'A short vibration on your phone.';

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
      'Theme and accent color. The screen updates as you choose.';

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
}
