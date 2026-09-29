import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Enfo'**
  String get appTitle;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tooltipStats;

  /// No description provided for @tooltipPin.
  ///
  /// In en, this message translates to:
  /// **'Keep always on top'**
  String get tooltipPin;

  /// No description provided for @tooltipUnpin.
  ///
  /// In en, this message translates to:
  /// **'Stop keeping on top'**
  String get tooltipUnpin;

  /// No description provided for @phasePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get phasePaused;

  /// No description provided for @phaseFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get phaseFocus;

  /// No description provided for @phaseRelax.
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get phaseRelax;

  /// No description provided for @notifRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to rest'**
  String get notifRestTitle;

  /// No description provided for @notifRestBody.
  ///
  /// In en, this message translates to:
  /// **'Take a break.'**
  String get notifRestBody;

  /// No description provided for @notifWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to work'**
  String get notifWorkTitle;

  /// No description provided for @notifWorkBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s continue with the work!'**
  String get notifWorkBody;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @rhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus rhythm'**
  String get rhythmTitle;

  /// No description provided for @presetClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get presetClassic;

  /// No description provided for @presetExtended.
  ///
  /// In en, this message translates to:
  /// **'Extended'**
  String get presetExtended;

  /// No description provided for @presetDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get presetDeep;

  /// No description provided for @presetManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get presetManual;

  /// No description provided for @workLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get workLabel;

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restLabel;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutes(int n);

  /// No description provided for @presetSummary.
  ///
  /// In en, this message translates to:
  /// **'{work}/{rest} min'**
  String presetSummary(int work, int rest);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @timersTitle.
  ///
  /// In en, this message translates to:
  /// **'Timers'**
  String get timersTitle;

  /// No description provided for @timersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{work} min focus · {rest} min rest'**
  String timersSubtitle(int work, int rest);

  /// No description provided for @timersCycle.
  ///
  /// In en, this message translates to:
  /// **'One full cycle: {total} min'**
  String timersCycle(int total);

  /// No description provided for @timersApplyHint.
  ///
  /// In en, this message translates to:
  /// **'If the timer is running, the change applies from the next cycle. If it is paused, the timer resets.'**
  String get timersApplyHint;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get appearanceDark;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationsOff;

  /// No description provided for @notificationsToggle.
  ///
  /// In en, this message translates to:
  /// **'Phase change alerts'**
  String get notificationsToggle;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Get notified when it is time to rest or to get back to work.'**
  String get notificationsHint;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language of the app.'**
  String get languageHint;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Enfo'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coffee and ads'**
  String get supportSubtitle;

  /// No description provided for @supportSubtitleNoAds.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get supportSubtitleNoAds;

  /// No description provided for @buyCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyCoffee;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to help'**
  String get watchAd;

  /// No description provided for @supportHint.
  ///
  /// In en, this message translates to:
  /// **'Enfo is free and made by one person. Thank you for using it.'**
  String get supportHint;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet.\nStart a pomodoro and it will show up here.'**
  String get statsEmpty;

  /// No description provided for @statsTodayPomodoros.
  ///
  /// In en, this message translates to:
  /// **'Pomodoros today'**
  String get statsTodayPomodoros;

  /// No description provided for @statsTodayFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus today'**
  String get statsTodayFocus;

  /// No description provided for @statsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statsCompleted;

  /// No description provided for @statsStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Day in a row} other{Days in a row}}'**
  String statsStreak(int count);

  /// No description provided for @statsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get statsLast7Days;

  /// No description provided for @statsTotalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total focus time'**
  String get statsTotalFocus;

  /// No description provided for @statsTotalRest.
  ///
  /// In en, this message translates to:
  /// **'Total rest time'**
  String get statsTotalRest;

  /// No description provided for @statsAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get statsAbandoned;

  /// No description provided for @statsAbandonedValue.
  ///
  /// In en, this message translates to:
  /// **'{count}  ·  {percent}% completed'**
  String statsAbandonedValue(int count, int percent);

  /// No description provided for @statsAverageFocus.
  ///
  /// In en, this message translates to:
  /// **'Average focus'**
  String get statsAverageFocus;

  /// No description provided for @statsLongestSession.
  ///
  /// In en, this message translates to:
  /// **'Longest session'**
  String get statsLongestSession;

  /// No description provided for @statsPauses.
  ///
  /// In en, this message translates to:
  /// **'Pauses'**
  String get statsPauses;

  /// No description provided for @statsAverageGap.
  ///
  /// In en, this message translates to:
  /// **'Average wait between sessions'**
  String get statsAverageGap;

  /// No description provided for @statsLongestGap.
  ///
  /// In en, this message translates to:
  /// **'Longest time inactive'**
  String get statsLongestGap;

  /// No description provided for @statsSinceLast.
  ///
  /// In en, this message translates to:
  /// **'Since last session'**
  String get statsSinceLast;

  /// No description provided for @statsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get statsHistory;

  /// No description provided for @statsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get statsClearHistory;

  /// No description provided for @statsClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm: delete all sessions'**
  String get statsClearConfirm;

  /// No description provided for @statsClearHint.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get statsClearHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sessionFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get sessionFocus;

  /// No description provided for @sessionRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get sessionRest;

  /// No description provided for @sessionProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {planned}'**
  String sessionProgress(String done, String planned);

  /// No description provided for @sessionPauses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pause} other{{count} pauses}} ({time})'**
  String sessionPauses(int count, String time);

  /// No description provided for @sessionIdleBefore.
  ///
  /// In en, this message translates to:
  /// **'after {gap} idle'**
  String sessionIdleBefore(String gap);

  /// No description provided for @sessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sessionCompleted;

  /// No description provided for @sessionAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get sessionAbandoned;

  /// No description provided for @clockStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Clock style'**
  String get clockStyleTitle;

  /// No description provided for @tooltipClockStyle.
  ///
  /// In en, this message translates to:
  /// **'Clock style'**
  String get tooltipClockStyle;

  /// No description provided for @clockCategoryProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress & numbers'**
  String get clockCategoryProgress;

  /// No description provided for @clockCategoryNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers only'**
  String get clockCategoryNumbers;

  /// No description provided for @clockCategoryIcons.
  ///
  /// In en, this message translates to:
  /// **'Icon only'**
  String get clockCategoryIcons;

  /// No description provided for @clockCategoryMotion.
  ///
  /// In en, this message translates to:
  /// **'Animation only'**
  String get clockCategoryMotion;

  /// No description provided for @clockUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get clockUnitMinutes;

  /// No description provided for @clockUnitSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get clockUnitSeconds;

  /// No description provided for @clockRing.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get clockRing;

  /// No description provided for @clockWavyRing.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get clockWavyRing;

  /// No description provided for @clockSegments.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get clockSegments;

  /// No description provided for @clockOrbit.
  ///
  /// In en, this message translates to:
  /// **'Orbit'**
  String get clockOrbit;

  /// No description provided for @clockPie.
  ///
  /// In en, this message translates to:
  /// **'Pie'**
  String get clockPie;

  /// No description provided for @clockKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get clockKitchen;

  /// No description provided for @clockDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get clockDots;

  /// No description provided for @clockBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get clockBar;

  /// No description provided for @clockWavyBar.
  ///
  /// In en, this message translates to:
  /// **'Wavy bar'**
  String get clockWavyBar;

  /// No description provided for @clockDigits.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get clockDigits;

  /// No description provided for @clockMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get clockMinutes;

  /// No description provided for @clockTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get clockTiles;

  /// No description provided for @clockStack.
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get clockStack;

  /// No description provided for @clockTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get clockTomato;

  /// No description provided for @clockHourglass.
  ///
  /// In en, this message translates to:
  /// **'Hourglass'**
  String get clockHourglass;

  /// No description provided for @clockBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get clockBattery;

  /// No description provided for @clockIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get clockIcon;

  /// No description provided for @clockCookie.
  ///
  /// In en, this message translates to:
  /// **'Cookie'**
  String get clockCookie;

  /// No description provided for @clockLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get clockLiquid;

  /// No description provided for @clockBreathe.
  ///
  /// In en, this message translates to:
  /// **'Breathe'**
  String get clockBreathe;

  /// No description provided for @clockEqualizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get clockEqualizer;

  /// No description provided for @clockRipple.
  ///
  /// In en, this message translates to:
  /// **'Ripples'**
  String get clockRipple;

  /// No description provided for @accentApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get accentApply;

  /// No description provided for @accentCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get accentCustom;

  /// No description provided for @accentHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get accentHue;

  /// No description provided for @accentSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get accentSaturation;

  /// No description provided for @accentBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get accentBrightness;

  /// No description provided for @accentHex.
  ///
  /// In en, this message translates to:
  /// **'Hex code'**
  String get accentHex;

  /// No description provided for @displayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displayTitle;

  /// No description provided for @displayClockShown.
  ///
  /// In en, this message translates to:
  /// **'Clock visible'**
  String get displayClockShown;

  /// No description provided for @displayClockHidden.
  ///
  /// In en, this message translates to:
  /// **'Clock hidden'**
  String get displayClockHidden;

  /// No description provided for @showClock.
  ///
  /// In en, this message translates to:
  /// **'Show the time'**
  String get showClock;

  /// No description provided for @showClockHint.
  ///
  /// In en, this message translates to:
  /// **'The small clock above the timer.'**
  String get showClockHint;

  /// No description provided for @clockFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get clockFormat;

  /// No description provided for @clockFormatSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get clockFormatSystem;

  /// No description provided for @clockFormat12.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get clockFormat12;

  /// No description provided for @clockFormat24.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get clockFormat24;

  /// No description provided for @behaviorTitle.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get behaviorTitle;

  /// No description provided for @autoStartNext.
  ///
  /// In en, this message translates to:
  /// **'Start next phase automatically'**
  String get autoStartNext;

  /// No description provided for @autoStartNextHint.
  ///
  /// In en, this message translates to:
  /// **'When focus or rest ends, the next one begins without tapping.'**
  String get autoStartNextHint;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when a phase ends'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'A short vibration on your phone.'**
  String get hapticFeedbackHint;

  /// No description provided for @clockCombosTitle.
  ///
  /// In en, this message translates to:
  /// **'Combos'**
  String get clockCombosTitle;

  /// No description provided for @clockCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get clockCollapseAll;

  /// No description provided for @clockExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get clockExpandAll;

  /// No description provided for @comboDeepFocus.
  ///
  /// In en, this message translates to:
  /// **'Deep focus'**
  String get comboDeepFocus;

  /// No description provided for @comboMint.
  ///
  /// In en, this message translates to:
  /// **'Fresh mint'**
  String get comboMint;

  /// No description provided for @comboSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get comboSunset;

  /// No description provided for @comboZen.
  ///
  /// In en, this message translates to:
  /// **'Zen'**
  String get comboZen;

  /// No description provided for @comboTomato.
  ///
  /// In en, this message translates to:
  /// **'Classic tomato'**
  String get comboTomato;

  /// No description provided for @comboNight.
  ///
  /// In en, this message translates to:
  /// **'Night owl'**
  String get comboNight;

  /// No description provided for @comboPlayful.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get comboPlayful;

  /// No description provided for @comboMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get comboMinimal;

  /// No description provided for @uiSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface size'**
  String get uiSizeTitle;

  /// No description provided for @uiSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get uiSizeSmall;

  /// No description provided for @uiSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get uiSizeNormal;

  /// No description provided for @uiSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get uiSizeLarge;

  /// No description provided for @uiSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get uiSizeExtraLarge;

  /// No description provided for @uiSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Makes text and controls bigger or smaller. Useful on TVs and car displays.'**
  String get uiSizeHint;

  /// No description provided for @clockBlob.
  ///
  /// In en, this message translates to:
  /// **'Blob'**
  String get clockBlob;

  /// No description provided for @clockFlower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get clockFlower;

  /// No description provided for @clockSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get clockSun;

  /// No description provided for @clockGears.
  ///
  /// In en, this message translates to:
  /// **'Gears'**
  String get clockGears;

  /// No description provided for @clockBubbles.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get clockBubbles;

  /// No description provided for @clockSunflower.
  ///
  /// In en, this message translates to:
  /// **'Sunflower'**
  String get clockSunflower;

  /// No description provided for @clockFireflies.
  ///
  /// In en, this message translates to:
  /// **'Fireflies'**
  String get clockFireflies;

  /// No description provided for @clockPendulum.
  ///
  /// In en, this message translates to:
  /// **'Pendulum'**
  String get clockPendulum;

  /// No description provided for @clockBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get clockBounce;

  /// No description provided for @clockMorph.
  ///
  /// In en, this message translates to:
  /// **'Morph'**
  String get clockMorph;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataTitle;

  /// No description provided for @dataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'History, reset and intro'**
  String get dataSubtitle;

  /// No description provided for @dataSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved activity} =1{1 saved entry} other{{count} saved entries}}'**
  String dataSessions(int count);

  /// No description provided for @dataIntro.
  ///
  /// In en, this message translates to:
  /// **'Show the intro again'**
  String get dataIntro;

  /// No description provided for @dataIntroHint.
  ///
  /// In en, this message translates to:
  /// **'Go through the welcome screen and pick your rhythm again. Nothing is deleted.'**
  String get dataIntroHint;

  /// No description provided for @dataClearHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Deletes all recorded activity: pomodoros, timers, stopwatch runs, alarms and clock time. Settings stay as they are.'**
  String get dataClearHistoryHint;

  /// No description provided for @dataConfirmClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Confirm: clear history'**
  String get dataConfirmClearHistory;

  /// No description provided for @dataResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get dataResetSettings;

  /// No description provided for @dataResetSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Timers, theme, accent color, language, modes and display options go back to defaults. History stays.'**
  String get dataResetSettingsHint;

  /// No description provided for @dataConfirmResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Confirm: reset settings'**
  String get dataConfirmResetSettings;

  /// No description provided for @dataEraseAll.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get dataEraseAll;

  /// No description provided for @dataEraseAllHint.
  ///
  /// In en, this message translates to:
  /// **'Deletes history and settings and starts fresh, as on the first launch.'**
  String get dataEraseAllHint;

  /// No description provided for @dataConfirmEraseAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm: erase everything'**
  String get dataConfirmEraseAll;

  /// No description provided for @dataDoneHistory.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get dataDoneHistory;

  /// No description provided for @dataDoneSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings restored to defaults.'**
  String get dataDoneSettings;

  /// No description provided for @dataCacheNote.
  ///
  /// In en, this message translates to:
  /// **'Enfo keeps no cache: everything it stores is the history and the settings listed here.'**
  String get dataCacheNote;

  /// No description provided for @clockEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get clockEndsAt;

  /// No description provided for @clockFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get clockFill;

  /// No description provided for @clockCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get clockCapsule;

  /// No description provided for @clockRollers.
  ///
  /// In en, this message translates to:
  /// **'Rollers'**
  String get clockRollers;

  /// No description provided for @clockMatrix.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get clockMatrix;

  /// No description provided for @clockSevenSeg.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get clockSevenSeg;

  /// No description provided for @clockFlip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get clockFlip;

  /// No description provided for @clockFine.
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get clockFine;

  /// No description provided for @clockSuperscript.
  ///
  /// In en, this message translates to:
  /// **'Exponent'**
  String get clockSuperscript;

  /// No description provided for @clockPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get clockPercent;

  /// No description provided for @clockEndTime.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get clockEndTime;

  /// No description provided for @clockSeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get clockSeconds;

  /// No description provided for @clockTall.
  ///
  /// In en, this message translates to:
  /// **'Tall'**
  String get clockTall;

  /// No description provided for @clockWobble.
  ///
  /// In en, this message translates to:
  /// **'Wobble'**
  String get clockWobble;

  /// No description provided for @clockLabeled.
  ///
  /// In en, this message translates to:
  /// **'Labeled'**
  String get clockLabeled;

  /// No description provided for @clockGauge.
  ///
  /// In en, this message translates to:
  /// **'Gauge'**
  String get clockGauge;

  /// No description provided for @clockNeedle.
  ///
  /// In en, this message translates to:
  /// **'Needle'**
  String get clockNeedle;

  /// No description provided for @clockAnalog.
  ///
  /// In en, this message translates to:
  /// **'Analog'**
  String get clockAnalog;

  /// No description provided for @clockRings.
  ///
  /// In en, this message translates to:
  /// **'Rings'**
  String get clockRings;

  /// No description provided for @clockSquircle.
  ///
  /// In en, this message translates to:
  /// **'Squircle'**
  String get clockSquircle;

  /// No description provided for @clockColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get clockColumns;

  /// No description provided for @clockVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get clockVertical;

  /// No description provided for @clockSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get clockSteps;

  /// No description provided for @clockBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get clockBlocks;

  /// No description provided for @clockSpiral.
  ///
  /// In en, this message translates to:
  /// **'Spiral'**
  String get clockSpiral;

  /// No description provided for @clockSlices.
  ///
  /// In en, this message translates to:
  /// **'Slices'**
  String get clockSlices;

  /// No description provided for @clockPills.
  ///
  /// In en, this message translates to:
  /// **'Pills'**
  String get clockPills;

  /// No description provided for @clockHexagon.
  ///
  /// In en, this message translates to:
  /// **'Hexagon'**
  String get clockHexagon;

  /// No description provided for @clockStairs.
  ///
  /// In en, this message translates to:
  /// **'Stairs'**
  String get clockStairs;

  /// No description provided for @clockCandle.
  ///
  /// In en, this message translates to:
  /// **'Candle'**
  String get clockCandle;

  /// No description provided for @clockMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get clockMoon;

  /// No description provided for @clockRuler.
  ///
  /// In en, this message translates to:
  /// **'Ruler'**
  String get clockRuler;

  /// No description provided for @comboArcade.
  ///
  /// In en, this message translates to:
  /// **'Arcade'**
  String get comboArcade;

  /// No description provided for @comboCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get comboCalculator;

  /// No description provided for @comboDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departure board'**
  String get comboDepartures;

  /// No description provided for @comboCandlelight.
  ///
  /// In en, this message translates to:
  /// **'Candlelight'**
  String get comboCandlelight;

  /// No description provided for @comboMoonlight.
  ///
  /// In en, this message translates to:
  /// **'Moonlight'**
  String get comboMoonlight;

  /// No description provided for @comboGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get comboGarden;

  /// No description provided for @comboSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get comboSummer;

  /// No description provided for @comboWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get comboWorkshop;

  /// No description provided for @comboFizzy.
  ///
  /// In en, this message translates to:
  /// **'Fizzy'**
  String get comboFizzy;

  /// No description provided for @comboSunfield.
  ///
  /// In en, this message translates to:
  /// **'Sunflower field'**
  String get comboSunfield;

  /// No description provided for @comboSummerNight.
  ///
  /// In en, this message translates to:
  /// **'Summer night'**
  String get comboSummerNight;

  /// No description provided for @comboHypnosis.
  ///
  /// In en, this message translates to:
  /// **'Hypnosis'**
  String get comboHypnosis;

  /// No description provided for @comboBouncy.
  ///
  /// In en, this message translates to:
  /// **'Bouncy'**
  String get comboBouncy;

  /// No description provided for @comboShapeshifter.
  ///
  /// In en, this message translates to:
  /// **'Shapeshifter'**
  String get comboShapeshifter;

  /// No description provided for @comboLava.
  ///
  /// In en, this message translates to:
  /// **'Lava lamp'**
  String get comboLava;

  /// No description provided for @comboOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get comboOcean;

  /// No description provided for @comboPulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get comboPulse;

  /// No description provided for @comboPond.
  ///
  /// In en, this message translates to:
  /// **'Pond'**
  String get comboPond;

  /// No description provided for @comboEspresso.
  ///
  /// In en, this message translates to:
  /// **'Espresso'**
  String get comboEspresso;

  /// No description provided for @comboSpeedometer.
  ///
  /// In en, this message translates to:
  /// **'Speedometer'**
  String get comboSpeedometer;

  /// No description provided for @comboCompass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get comboCompass;

  /// No description provided for @comboClassicClock.
  ///
  /// In en, this message translates to:
  /// **'Classic clock'**
  String get comboClassicClock;

  /// No description provided for @comboConcentric.
  ///
  /// In en, this message translates to:
  /// **'Concentric'**
  String get comboConcentric;

  /// No description provided for @comboRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get comboRounded;

  /// No description provided for @comboSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get comboSignal;

  /// No description provided for @comboThermometer.
  ///
  /// In en, this message translates to:
  /// **'Thermometer'**
  String get comboThermometer;

  /// No description provided for @comboMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get comboMilestones;

  /// No description provided for @comboRetroBlocks.
  ///
  /// In en, this message translates to:
  /// **'Retro blocks'**
  String get comboRetroBlocks;

  /// No description provided for @comboHypnoSpiral.
  ///
  /// In en, this message translates to:
  /// **'Hypnotic spiral'**
  String get comboHypnoSpiral;

  /// No description provided for @comboCitrus.
  ///
  /// In en, this message translates to:
  /// **'Citrus'**
  String get comboCitrus;

  /// No description provided for @comboChocolate.
  ///
  /// In en, this message translates to:
  /// **'Chocolate bar'**
  String get comboChocolate;

  /// No description provided for @comboCrystal.
  ///
  /// In en, this message translates to:
  /// **'Crystal'**
  String get comboCrystal;

  /// No description provided for @comboStaircase.
  ///
  /// In en, this message translates to:
  /// **'Staircase'**
  String get comboStaircase;

  /// No description provided for @comboTapeMeasure.
  ///
  /// In en, this message translates to:
  /// **'Tape measure'**
  String get comboTapeMeasure;

  /// No description provided for @comboBoldType.
  ///
  /// In en, this message translates to:
  /// **'Bold type'**
  String get comboBoldType;

  /// No description provided for @comboPill.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get comboPill;

  /// No description provided for @comboSlotMachine.
  ///
  /// In en, this message translates to:
  /// **'Slot machine'**
  String get comboSlotMachine;

  /// No description provided for @comboWhisper.
  ///
  /// In en, this message translates to:
  /// **'Whisper'**
  String get comboWhisper;

  /// No description provided for @comboDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get comboDeadline;

  /// No description provided for @comboPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get comboPercentage;

  /// No description provided for @comboStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Seconds only'**
  String get comboStopwatch;

  /// No description provided for @comboSkyscraper.
  ///
  /// In en, this message translates to:
  /// **'Skyscraper'**
  String get comboSkyscraper;

  /// No description provided for @comboWaveText.
  ///
  /// In en, this message translates to:
  /// **'Wave text'**
  String get comboWaveText;

  /// No description provided for @comboDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get comboDashboard;

  /// No description provided for @comboExponent.
  ///
  /// In en, this message translates to:
  /// **'Exponent'**
  String get comboExponent;

  /// No description provided for @comboGrandmaKitchen.
  ///
  /// In en, this message translates to:
  /// **'Grandma\'s kitchen'**
  String get comboGrandmaKitchen;

  /// No description provided for @comboCyber.
  ///
  /// In en, this message translates to:
  /// **'Cyber'**
  String get comboCyber;

  /// No description provided for @comboCandy.
  ///
  /// In en, this message translates to:
  /// **'Candy'**
  String get comboCandy;

  /// No description provided for @comboConfetti.
  ///
  /// In en, this message translates to:
  /// **'Confetti'**
  String get comboConfetti;

  /// No description provided for @comboCookieJar.
  ///
  /// In en, this message translates to:
  /// **'Cookie jar'**
  String get comboCookieJar;

  /// No description provided for @comboSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox'**
  String get comboSandbox;

  /// No description provided for @comboPizzaNight.
  ///
  /// In en, this message translates to:
  /// **'Pizza night'**
  String get comboPizzaNight;

  /// No description provided for @onbLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Enfo'**
  String get onbLanguageTitle;

  /// No description provided for @onbLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'Pick your language. Everything you choose here can be changed later in Settings.'**
  String get onbLanguageBody;

  /// No description provided for @onbRhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm'**
  String get onbRhythmTitle;

  /// No description provided for @onbRhythmBody.
  ///
  /// In en, this message translates to:
  /// **'How long you focus, and how long you rest.'**
  String get onbRhythmBody;

  /// No description provided for @onbLookTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onbLookTitle;

  /// No description provided for @onbLookBody.
  ///
  /// In en, this message translates to:
  /// **'Theme and accent color. The screen updates as you choose.'**
  String get onbLookBody;

  /// No description provided for @onbClockTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a clock'**
  String get onbClockTitle;

  /// No description provided for @onbClockBody.
  ///
  /// In en, this message translates to:
  /// **'Curated looks: a clock style and a color in one tap.'**
  String get onbClockBody;

  /// No description provided for @onbAllStyles.
  ///
  /// In en, this message translates to:
  /// **'Browse all styles'**
  String get onbAllStyles;

  /// No description provided for @onbOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Final touches'**
  String get onbOptionsTitle;

  /// No description provided for @onbOptionsBody.
  ///
  /// In en, this message translates to:
  /// **'Display and behavior. All of this is in Settings too.'**
  String get onbOptionsBody;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onbStepOf(int step, int total);

  /// No description provided for @clockFormatAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get clockFormatAuto;

  /// No description provided for @modePomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get modePomodoro;

  /// No description provided for @modeClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get modeClock;

  /// No description provided for @modeTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get modeTimer;

  /// No description provided for @modeStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get modeStopwatch;

  /// No description provided for @modeAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get modeAlarm;

  /// No description provided for @modeWorld.
  ///
  /// In en, this message translates to:
  /// **'World clock'**
  String get modeWorld;

  /// No description provided for @modeDescPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Focus and rest cycles'**
  String get modeDescPomodoro;

  /// No description provided for @modeDescClock.
  ///
  /// In en, this message translates to:
  /// **'A beautiful, always-on clock'**
  String get modeDescClock;

  /// No description provided for @modeDescTimer.
  ///
  /// In en, this message translates to:
  /// **'Count down from any time'**
  String get modeDescTimer;

  /// No description provided for @modeDescStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Measure time, with laps'**
  String get modeDescStopwatch;

  /// No description provided for @modeDescAlarm.
  ///
  /// In en, this message translates to:
  /// **'Wake up or get reminded'**
  String get modeDescAlarm;

  /// No description provided for @modeDescWorld.
  ///
  /// In en, this message translates to:
  /// **'The time in cities around the world'**
  String get modeDescWorld;

  /// No description provided for @tooltipModes.
  ///
  /// In en, this message translates to:
  /// **'Modes'**
  String get tooltipModes;

  /// No description provided for @tooltipSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Next mode'**
  String get tooltipSwitchMode;

  /// No description provided for @tooltipFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get tooltipFullscreen;

  /// No description provided for @tooltipExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get tooltipExitFullscreen;

  /// No description provided for @tooltipDim.
  ///
  /// In en, this message translates to:
  /// **'Dim the screen'**
  String get tooltipDim;

  /// No description provided for @modesTitle.
  ///
  /// In en, this message translates to:
  /// **'Modes'**
  String get modesTitle;

  /// No description provided for @modesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the modes you use and their order. Drag to reorder.'**
  String get modesHint;

  /// No description provided for @modesStart.
  ///
  /// In en, this message translates to:
  /// **'Start with'**
  String get modesStart;

  /// No description provided for @modesStartLast.
  ///
  /// In en, this message translates to:
  /// **'Last used mode'**
  String get modesStartLast;

  /// No description provided for @modesCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get modesCustomize;

  /// No description provided for @modesActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity history'**
  String get modesActivity;

  /// No description provided for @modesAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'At least one mode has to stay on.'**
  String get modesAtLeastOne;

  /// No description provided for @modesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mode on} other{{count} modes on}}'**
  String modesSubtitle(int count);

  /// No description provided for @tooltipActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity history'**
  String get tooltipActivity;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.\nUse a timer, a stopwatch, an alarm or the clock and it will show up here.'**
  String get activityEmpty;

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @activityTimersToday.
  ///
  /// In en, this message translates to:
  /// **'Timers today'**
  String get activityTimersToday;

  /// No description provided for @activityStopwatchToday.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch today'**
  String get activityStopwatchToday;

  /// No description provided for @activityDisplayToday.
  ///
  /// In en, this message translates to:
  /// **'On display today'**
  String get activityDisplayToday;

  /// No description provided for @activityLaps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lap} other{{count} laps}}'**
  String activityLaps(int count);

  /// No description provided for @activityLap.
  ///
  /// In en, this message translates to:
  /// **'Lap {n}'**
  String activityLap(int n);

  /// No description provided for @activityAlarmDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get activityAlarmDismissed;

  /// No description provided for @activityAlarmSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get activityAlarmSnoozed;

  /// No description provided for @activityAlarmMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get activityAlarmMissed;

  /// No description provided for @activityDisplay.
  ///
  /// In en, this message translates to:
  /// **'{mode} on display'**
  String activityDisplay(String mode);

  /// No description provided for @activityRan.
  ///
  /// In en, this message translates to:
  /// **'{done} of {planned}'**
  String activityRan(String done, String planned);

  /// No description provided for @faceRing.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get faceRing;

  /// No description provided for @faceDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get faceDigital;

  /// No description provided for @faceAnalog.
  ///
  /// In en, this message translates to:
  /// **'Analog'**
  String get faceAnalog;

  /// No description provided for @faceSplit.
  ///
  /// In en, this message translates to:
  /// **'Big'**
  String get faceSplit;

  /// No description provided for @faceDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get faceDay;

  /// No description provided for @tooltipCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get tooltipCustomize;

  /// No description provided for @clockSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize the clock'**
  String get clockSettingsTitle;

  /// No description provided for @clockFaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get clockFaceTitle;

  /// No description provided for @clockShowSeconds.
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get clockShowSeconds;

  /// No description provided for @clockShowDate.
  ///
  /// In en, this message translates to:
  /// **'Show the date'**
  String get clockShowDate;

  /// No description provided for @clockBlinkColon.
  ///
  /// In en, this message translates to:
  /// **'Blinking colon'**
  String get clockBlinkColon;

  /// No description provided for @clockKeepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on'**
  String get clockKeepAwake;

  /// No description provided for @clockKeepAwakeHint.
  ///
  /// In en, this message translates to:
  /// **'While the clock is showing.'**
  String get clockKeepAwakeHint;

  /// No description provided for @clockFullscreenHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the full screen button for a desk clock that stays on. Swipe the clock to change its design.'**
  String get clockFullscreenHint;

  /// No description provided for @clockDayPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the day'**
  String clockDayPercent(int percent);

  /// No description provided for @ringDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get ringDismiss;

  /// No description provided for @ringSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze {minutes} min'**
  String ringSnooze(int minutes);

  /// No description provided for @timerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStart;

  /// No description provided for @timerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPause;

  /// No description provided for @timerResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get timerResume;

  /// No description provided for @timerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get timerReset;

  /// No description provided for @timerAddMinute.
  ///
  /// In en, this message translates to:
  /// **'+1 min'**
  String get timerAddMinute;

  /// No description provided for @timerHoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get timerHoursShort;

  /// No description provided for @timerMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get timerMinutesShort;

  /// No description provided for @timerSecondsShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get timerSecondsShort;

  /// No description provided for @timerUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get timerUpTitle;

  /// No description provided for @timerUpBody.
  ///
  /// In en, this message translates to:
  /// **'The {duration} timer finished.'**
  String timerUpBody(String duration);

  /// No description provided for @timerSavePreset.
  ///
  /// In en, this message translates to:
  /// **'Save this time'**
  String get timerSavePreset;

  /// No description provided for @timerPresetHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to save this time. Long-press a preset to remove it.'**
  String get timerPresetHint;

  /// No description provided for @stopwatchStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopwatchStop;

  /// No description provided for @stopwatchLap.
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get stopwatchLap;

  /// No description provided for @stopwatchLapBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get stopwatchLapBest;

  /// No description provided for @stopwatchLapWorst.
  ///
  /// In en, this message translates to:
  /// **'Slowest'**
  String get stopwatchLapWorst;

  /// No description provided for @worldLocal.
  ///
  /// In en, this message translates to:
  /// **'Local time'**
  String get worldLocal;

  /// No description provided for @worldToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get worldToday;

  /// No description provided for @worldTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get worldTomorrow;

  /// No description provided for @worldYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get worldYesterday;

  /// No description provided for @worldAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a city'**
  String get worldAdd;

  /// No description provided for @worldSearch.
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get worldSearch;

  /// No description provided for @worldNoResults.
  ///
  /// In en, this message translates to:
  /// **'No city matches that.'**
  String get worldNoResults;

  /// No description provided for @worldEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get worldEdit;

  /// No description provided for @worldDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get worldDone;

  /// No description provided for @worldRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get worldRemove;

  /// No description provided for @worldEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other cities yet. Tap + to add one.'**
  String get worldEmpty;

  /// No description provided for @worldSameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time as you'**
  String get worldSameTime;

  /// No description provided for @worldDiffAhead.
  ///
  /// In en, this message translates to:
  /// **'{diff} ahead of you'**
  String worldDiffAhead(String diff);

  /// No description provided for @worldDiffBehind.
  ///
  /// In en, this message translates to:
  /// **'{diff} behind you'**
  String worldDiffBehind(String diff);

  /// No description provided for @alarmNext.
  ///
  /// In en, this message translates to:
  /// **'Next alarm in {duration}'**
  String alarmNext(String duration);

  /// No description provided for @alarmNone.
  ///
  /// In en, this message translates to:
  /// **'No alarms on'**
  String get alarmNone;

  /// No description provided for @alarmNew.
  ///
  /// In en, this message translates to:
  /// **'New alarm'**
  String get alarmNew;

  /// No description provided for @alarmEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit alarm'**
  String get alarmEditTitle;

  /// No description provided for @alarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get alarmLabel;

  /// No description provided for @alarmRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get alarmRepeat;

  /// No description provided for @alarmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get alarmSave;

  /// No description provided for @alarmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete alarm'**
  String get alarmDelete;

  /// No description provided for @alarmConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm: delete alarm'**
  String get alarmConfirmDelete;

  /// No description provided for @alarmDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'This alarm will be removed.'**
  String get alarmDeleteHint;

  /// No description provided for @alarmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet.\nTap + to create one.'**
  String get alarmEmpty;

  /// No description provided for @alarmEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get alarmEveryDay;

  /// No description provided for @alarmWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get alarmWeekdays;

  /// No description provided for @alarmWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get alarmWeekends;

  /// No description provided for @alarmOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get alarmOnce;

  /// No description provided for @alarmPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'To ring with the app closed, Enfo needs permission to send notifications and set exact alarms.'**
  String get alarmPermissionHint;

  /// No description provided for @alarmPermissionButton.
  ///
  /// In en, this message translates to:
  /// **'Allow alarms'**
  String get alarmPermissionButton;

  /// No description provided for @alarmDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'On this device Enfo has to be open for alarms to ring.'**
  String get alarmDesktopHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
