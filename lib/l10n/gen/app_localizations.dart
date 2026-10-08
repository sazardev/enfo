import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh')
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

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

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

  /// No description provided for @supportSubtitleNoAds.
  ///
  /// In en, this message translates to:
  /// **'Donations and coffee'**
  String get supportSubtitleNoAds;

  /// No description provided for @buyCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyCoffee;

  /// No description provided for @supportHint.
  ///
  /// In en, this message translates to:
  /// **'Enfo is free and made by one person. Thank you for using it.'**
  String get supportHint;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Enfo'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share Enfo'**
  String get shareApp;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Enfo, a calm clock and timer toolbox for Android: {url}'**
  String shareMessage(String url);

  /// No description provided for @donateTitle.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donateTitle;

  /// No description provided for @donateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time, through Google Play'**
  String get donateSubtitle;

  /// No description provided for @donateHint.
  ///
  /// In en, this message translates to:
  /// **'Enfo is free and ad-free. If you want to support it, you can leave a one-time donation through Google Play. Thank you!'**
  String get donateHint;

  /// No description provided for @donateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Donations are not available right now. You can still buy me a coffee.'**
  String get donateUnavailable;

  /// No description provided for @donateThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Enfo!'**
  String get donateThanks;

  /// No description provided for @donatePending.
  ///
  /// In en, this message translates to:
  /// **'Purchase pending…'**
  String get donatePending;

  /// No description provided for @donateError.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed. Nothing was charged.'**
  String get donateError;

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
  /// **'Vibration'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Taps, wheels, phase changes and alarms.'**
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
  /// **'Your language'**
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
  /// **'Theme, clock style and color. Start from a combo, then tweak the color if you like.'**
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

  /// No description provided for @onbModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your tools'**
  String get onbModesTitle;

  /// No description provided for @onbModesBody.
  ///
  /// In en, this message translates to:
  /// **'Enfo is a clock and timer toolbox. Turn on what you will use; change it anytime from the modes menu.'**
  String get onbModesBody;

  /// No description provided for @onbPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get onbPreview;

  /// No description provided for @onbDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get onbDisplayTitle;

  /// No description provided for @onbDisplayBody.
  ///
  /// In en, this message translates to:
  /// **'How the clock looks and how big everything is.'**
  String get onbDisplayBody;

  /// No description provided for @onbClockModeDesign.
  ///
  /// In en, this message translates to:
  /// **'Clock mode design'**
  String get onbClockModeDesign;

  /// No description provided for @onbPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onbPermTitle;

  /// No description provided for @onbPermBody.
  ///
  /// In en, this message translates to:
  /// **'So timers and alarms can reach you even when Enfo is closed.'**
  String get onbPermBody;

  /// No description provided for @onbPermNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onbPermNotifications;

  /// No description provided for @onbPermNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Alerts when a timer ends or an alarm rings.'**
  String get onbPermNotificationsHint;

  /// No description provided for @onbPermExact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms'**
  String get onbPermExact;

  /// No description provided for @onbPermExactHint.
  ///
  /// In en, this message translates to:
  /// **'Ring at the exact minute, even in battery saver.'**
  String get onbPermExactHint;

  /// No description provided for @onbPermAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get onbPermAllow;

  /// No description provided for @onbPermAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get onbPermAllowed;

  /// No description provided for @onbPermLater.
  ///
  /// In en, this message translates to:
  /// **'You can change these anytime in the system settings.'**
  String get onbPermLater;

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

  /// No description provided for @hapticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get hapticsTitle;

  /// No description provided for @hapticsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get hapticsOff;

  /// No description provided for @hapticsStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get hapticsStrength;

  /// No description provided for @hapticsSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get hapticsSoft;

  /// No description provided for @hapticsMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get hapticsMedium;

  /// No description provided for @hapticsStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get hapticsStrong;

  /// No description provided for @hapticsTouch.
  ///
  /// In en, this message translates to:
  /// **'Touch'**
  String get hapticsTouch;

  /// No description provided for @hapticsTouchHint.
  ///
  /// In en, this message translates to:
  /// **'Buttons, switches and selections.'**
  String get hapticsTouchHint;

  /// No description provided for @hapticsMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get hapticsMotion;

  /// No description provided for @hapticsMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Wheels, sliders, dragging and transitions.'**
  String get hapticsMotionHint;

  /// No description provided for @hapticsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get hapticsAlerts;

  /// No description provided for @hapticsAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Timers, phase changes, the final countdown and alarms.'**
  String get hapticsAlertsHint;

  /// No description provided for @hapticsAlarmPattern.
  ///
  /// In en, this message translates to:
  /// **'Alarm pattern'**
  String get hapticsAlarmPattern;

  /// No description provided for @hapticsAlarmPatternHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a pattern to feel it. The ringing screen pulses to the same beat.'**
  String get hapticsAlarmPatternHint;

  /// No description provided for @hapticsPatternHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'Heartbeat'**
  String get hapticsPatternHeartbeat;

  /// No description provided for @hapticsPatternPulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get hapticsPatternPulse;

  /// No description provided for @hapticsPatternCrescendo.
  ///
  /// In en, this message translates to:
  /// **'Crescendo'**
  String get hapticsPatternCrescendo;

  /// No description provided for @hapticsPatternRipple.
  ///
  /// In en, this message translates to:
  /// **'Ripple'**
  String get hapticsPatternRipple;

  /// No description provided for @hapticsPatternBeacon.
  ///
  /// In en, this message translates to:
  /// **'Beacon'**
  String get hapticsPatternBeacon;

  /// No description provided for @hapticsTry.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get hapticsTry;

  /// No description provided for @hapticsTryTap.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get hapticsTryTap;

  /// No description provided for @hapticsTrySuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get hapticsTrySuccess;

  /// No description provided for @hapticsTryToRest.
  ///
  /// In en, this message translates to:
  /// **'Focus done'**
  String get hapticsTryToRest;

  /// No description provided for @hapticsTryToWork.
  ///
  /// In en, this message translates to:
  /// **'Rest done'**
  String get hapticsTryToWork;

  /// No description provided for @hapticsTryTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer done'**
  String get hapticsTryTimer;

  /// No description provided for @hapticsTryWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get hapticsTryWarning;

  /// No description provided for @hapticsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no vibration motor.'**
  String get hapticsUnavailable;

  /// No description provided for @hapticsWhen.
  ///
  /// In en, this message translates to:
  /// **'When it vibrates'**
  String get hapticsWhen;

  /// No description provided for @widgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgetsTitle;

  /// No description provided for @widgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clocks and timers on your home screen'**
  String get widgetsSubtitle;

  /// No description provided for @widgetsAddHeader.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get widgetsAddHeader;

  /// No description provided for @widgetsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get widgetsAdd;

  /// No description provided for @widgetsDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Material You colors'**
  String get widgetsDynamicColor;

  /// No description provided for @widgetsDynamicColorHint.
  ///
  /// In en, this message translates to:
  /// **'Widgets take their colors from your wallpaper. Turn off to use Enfo\'s accent color.'**
  String get widgetsDynamicColorHint;

  /// No description provided for @widgetsManualHint.
  ///
  /// In en, this message translates to:
  /// **'Your launcher can\'t add widgets from here. Long-press the home screen, choose Widgets and look for Enfo.'**
  String get widgetsManualHint;

  /// No description provided for @widgetsStyleHint.
  ///
  /// In en, this message translates to:
  /// **'The Pomodoro and timer widgets are drawn in the clock style you picked. Change the style in the app and they follow.'**
  String get widgetsStyleHint;

  /// No description provided for @widgetsTapHint.
  ///
  /// In en, this message translates to:
  /// **'Buttons on a widget open Enfo and do the action, so time is always kept by the app.'**
  String get widgetsTapHint;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard & remote'**
  String get shortcutsTitle;

  /// No description provided for @shortcutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts for keyboard, mouse and TV remote'**
  String get shortcutsSubtitle;

  /// No description provided for @shortcutsIntro.
  ///
  /// In en, this message translates to:
  /// **'Arrow keys or the remote\'s D-pad move around, Enter or OK presses. These keys do the rest.'**
  String get shortcutsIntro;

  /// No description provided for @shortcutKeySpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get shortcutKeySpace;

  /// No description provided for @shortcutPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Start or pause'**
  String get shortcutPlayPause;

  /// No description provided for @shortcutReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get shortcutReset;

  /// No description provided for @shortcutLap.
  ///
  /// In en, this message translates to:
  /// **'Lap (stopwatch)'**
  String get shortcutLap;

  /// No description provided for @shortcutJumpMode.
  ///
  /// In en, this message translates to:
  /// **'Go to mode 1–9'**
  String get shortcutJumpMode;

  /// No description provided for @shortcutStepMode.
  ///
  /// In en, this message translates to:
  /// **'Previous / next mode'**
  String get shortcutStepMode;

  /// No description provided for @shortcutFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get shortcutFullscreen;

  /// No description provided for @shortcutDim.
  ///
  /// In en, this message translates to:
  /// **'Dim the screen (full screen)'**
  String get shortcutDim;

  /// No description provided for @shortcutSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shortcutSettings;

  /// No description provided for @shortcutModes.
  ///
  /// In en, this message translates to:
  /// **'Modes menu'**
  String get shortcutModes;

  /// No description provided for @shortcutBack.
  ///
  /// In en, this message translates to:
  /// **'Back / leave full screen'**
  String get shortcutBack;

  /// No description provided for @shortcutHelp.
  ///
  /// In en, this message translates to:
  /// **'Show this list'**
  String get shortcutHelp;

  /// No description provided for @onbMoreTools.
  ///
  /// In en, this message translates to:
  /// **'More tools'**
  String get onbMoreTools;

  /// No description provided for @modeEvent.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get modeEvent;

  /// No description provided for @modeDescEvent.
  ///
  /// In en, this message translates to:
  /// **'Count the days to what matters'**
  String get modeDescEvent;

  /// No description provided for @modeIntervals.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get modeIntervals;

  /// No description provided for @modeDescIntervals.
  ///
  /// In en, this message translates to:
  /// **'Work and rest rounds, like HIIT'**
  String get modeDescIntervals;

  /// No description provided for @modeBreathe.
  ///
  /// In en, this message translates to:
  /// **'Breathe'**
  String get modeBreathe;

  /// No description provided for @modeDescBreathe.
  ///
  /// In en, this message translates to:
  /// **'Guided breathing to calm down'**
  String get modeDescBreathe;

  /// No description provided for @modeTracker.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get modeTracker;

  /// No description provided for @modeDescTracker.
  ///
  /// In en, this message translates to:
  /// **'Time what you do, see the totals'**
  String get modeDescTracker;

  /// No description provided for @modeKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get modeKitchen;

  /// No description provided for @modeDescKitchen.
  ///
  /// In en, this message translates to:
  /// **'Several named timers at once'**
  String get modeDescKitchen;

  /// No description provided for @modeSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get modeSleep;

  /// No description provided for @modeDescSleep.
  ///
  /// In en, this message translates to:
  /// **'Plan bedtime and wake-up in sleep cycles'**
  String get modeDescSleep;

  /// No description provided for @modeVersus.
  ///
  /// In en, this message translates to:
  /// **'Turns'**
  String get modeVersus;

  /// No description provided for @modeDescVersus.
  ///
  /// In en, this message translates to:
  /// **'Two-player clock for chess, games and debates'**
  String get modeDescVersus;

  /// No description provided for @modeBreaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get modeBreaks;

  /// No description provided for @modeDescBreaks.
  ///
  /// In en, this message translates to:
  /// **'Reminders to rest your eyes and stretch'**
  String get modeDescBreaks;

  /// No description provided for @modeAmbient.
  ///
  /// In en, this message translates to:
  /// **'Ambient'**
  String get modeAmbient;

  /// No description provided for @modeDescAmbient.
  ///
  /// In en, this message translates to:
  /// **'Background sounds with a sleep timer'**
  String get modeDescAmbient;

  /// No description provided for @intervalsPresetTabata.
  ///
  /// In en, this message translates to:
  /// **'Tabata'**
  String get intervalsPresetTabata;

  /// No description provided for @intervalsPresetHiit.
  ///
  /// In en, this message translates to:
  /// **'HIIT'**
  String get intervalsPresetHiit;

  /// No description provided for @intervalsPresetEmom.
  ///
  /// In en, this message translates to:
  /// **'EMOM'**
  String get intervalsPresetEmom;

  /// No description provided for @intervalsPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get intervalsPresetCustom;

  /// No description provided for @intervalsWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get intervalsWarmUp;

  /// No description provided for @intervalsWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get intervalsWork;

  /// No description provided for @intervalsRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get intervalsRest;

  /// No description provided for @intervalsRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get intervalsRounds;

  /// No description provided for @intervalsCoolDown.
  ///
  /// In en, this message translates to:
  /// **'Cool-down'**
  String get intervalsCoolDown;

  /// No description provided for @intervalsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get intervalsOff;

  /// No description provided for @intervalsRound.
  ///
  /// In en, this message translates to:
  /// **'Round {current}/{total}'**
  String intervalsRound(int current, int total);

  /// No description provided for @intervalsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {duration}'**
  String intervalsTotal(String duration);

  /// No description provided for @intervalsSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip to next phase'**
  String get intervalsSkip;

  /// No description provided for @intervalsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to edit it. Any change saves as Custom.'**
  String get intervalsHint;

  /// No description provided for @intervalsDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get intervalsDoneTitle;

  /// No description provided for @intervalsDoneBody.
  ///
  /// In en, this message translates to:
  /// **'{name} · {duration}. Great work!'**
  String intervalsDoneBody(String name, String duration);

  /// No description provided for @kitchenPasta.
  ///
  /// In en, this message translates to:
  /// **'Pasta'**
  String get kitchenPasta;

  /// No description provided for @kitchenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get kitchenEggs;

  /// No description provided for @kitchenTea.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get kitchenTea;

  /// No description provided for @kitchenRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get kitchenRice;

  /// No description provided for @kitchenOven.
  ///
  /// In en, this message translates to:
  /// **'Oven'**
  String get kitchenOven;

  /// No description provided for @kitchenCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get kitchenCustom;

  /// No description provided for @kitchenNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get kitchenNameHint;

  /// No description provided for @kitchenAdd.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get kitchenAdd;

  /// No description provided for @kitchenDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete timer'**
  String get kitchenDelete;

  /// No description provided for @kitchenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timers yet. Tap a chip to start one.'**
  String get kitchenEmpty;

  /// No description provided for @kitchenDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get kitchenDefaultName;

  /// No description provided for @kitchenDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready'**
  String kitchenDoneTitle(String name);

  /// No description provided for @kitchenDoneBody.
  ///
  /// In en, this message translates to:
  /// **'The {duration} timer finished.'**
  String kitchenDoneBody(String duration);

  /// No description provided for @trackerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get trackerToday;

  /// No description provided for @trackerWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get trackerWeek;

  /// No description provided for @trackerTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap an activity to start timing it'**
  String get trackerTapToStart;

  /// No description provided for @trackerNoRunning.
  ///
  /// In en, this message translates to:
  /// **'Nothing running'**
  String get trackerNoRunning;

  /// No description provided for @trackerAddActivity.
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get trackerAddActivity;

  /// No description provided for @trackerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get trackerNameHint;

  /// No description provided for @trackerStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get trackerStudy;

  /// No description provided for @trackerReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get trackerReading;

  /// No description provided for @trackerCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get trackerCode;

  /// No description provided for @trackerExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get trackerExercise;

  /// No description provided for @trackerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit activity'**
  String get trackerEdit;

  /// No description provided for @trackerDetails.
  ///
  /// In en, this message translates to:
  /// **'Details and chart'**
  String get trackerDetails;

  /// No description provided for @trackerColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get trackerColor;

  /// No description provided for @trackerIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get trackerIcon;

  /// No description provided for @trackerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete activity'**
  String get trackerDelete;

  /// No description provided for @trackerDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm: delete this activity'**
  String get trackerDeleteConfirm;

  /// No description provided for @trackerDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Time already logged stays in the activity history.'**
  String get trackerDeleteHint;

  /// No description provided for @trackerAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time manually'**
  String get trackerAddTime;

  /// No description provided for @trackerAddMinutes.
  ///
  /// In en, this message translates to:
  /// **'Add {minutes} min'**
  String trackerAddMinutes(int minutes);

  /// No description provided for @trackerMinutesFewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer minutes'**
  String get trackerMinutesFewer;

  /// No description provided for @trackerMinutesMore.
  ///
  /// In en, this message translates to:
  /// **'More minutes'**
  String get trackerMinutesMore;

  /// No description provided for @trackerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get trackerStop;

  /// No description provided for @versusDuel.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get versusDuel;

  /// No description provided for @versusSpeakers.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get versusSpeakers;

  /// No description provided for @versusCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get versusCustom;

  /// No description provided for @versusIncrement.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get versusIncrement;

  /// No description provided for @versusTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap your side to start your clock'**
  String get versusTapToStart;

  /// No description provided for @versusTimeIsUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up'**
  String get versusTimeIsUp;

  /// No description provided for @versusMoves.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 move} other{{count} moves}}'**
  String versusMoves(int count);

  /// No description provided for @versusResetGame.
  ///
  /// In en, this message translates to:
  /// **'Reset game'**
  String get versusResetGame;

  /// No description provided for @versusConfirmReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm reset'**
  String get versusConfirmReset;

  /// No description provided for @versusSpeakerN.
  ///
  /// In en, this message translates to:
  /// **'Speaker {n}'**
  String versusSpeakerN(int n);

  /// No description provided for @versusAddSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Add speaker'**
  String get versusAddSpeaker;

  /// No description provided for @versusRemoveSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Remove speaker'**
  String get versusRemoveSpeaker;

  /// No description provided for @versusSpeakerName.
  ///
  /// In en, this message translates to:
  /// **'Speaker or topic'**
  String get versusSpeakerName;

  /// No description provided for @versusNext.
  ///
  /// In en, this message translates to:
  /// **'Next speaker'**
  String get versusNext;

  /// No description provided for @versusFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get versusFinish;

  /// No description provided for @versusOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get versusOvertime;

  /// No description provided for @versusElapsedOfPlanned.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} of {planned}'**
  String versusElapsedOfPlanned(String elapsed, String planned);

  /// No description provided for @versusAgendaDone.
  ///
  /// In en, this message translates to:
  /// **'Agenda finished'**
  String get versusAgendaDone;

  /// No description provided for @versusStartAgenda.
  ///
  /// In en, this message translates to:
  /// **'Start agenda'**
  String get versusStartAgenda;

  /// No description provided for @versusMinutesFewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer minutes'**
  String get versusMinutesFewer;

  /// No description provided for @versusMinutesMore.
  ///
  /// In en, this message translates to:
  /// **'More minutes'**
  String get versusMinutesMore;

  /// No description provided for @versusTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get versusTotal;

  /// No description provided for @breatheInhale.
  ///
  /// In en, this message translates to:
  /// **'Inhale'**
  String get breatheInhale;

  /// No description provided for @breatheHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get breatheHold;

  /// No description provided for @breatheExhale.
  ///
  /// In en, this message translates to:
  /// **'Exhale'**
  String get breatheExhale;

  /// No description provided for @breatheStart.
  ///
  /// In en, this message translates to:
  /// **'Start breathing'**
  String get breatheStart;

  /// No description provided for @breathePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get breathePause;

  /// No description provided for @breatheResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get breatheResume;

  /// No description provided for @breatheReset.
  ///
  /// In en, this message translates to:
  /// **'Stop session'**
  String get breatheReset;

  /// No description provided for @breatheDone.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get breatheDone;

  /// No description provided for @breatheReady.
  ///
  /// In en, this message translates to:
  /// **'Find a comfortable position'**
  String get breatheReady;

  /// No description provided for @breathePatternBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get breathePatternBox;

  /// No description provided for @breathePatternCoherent.
  ///
  /// In en, this message translates to:
  /// **'Coherent'**
  String get breathePatternCoherent;

  /// No description provided for @breathePatternCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get breathePatternCalm;

  /// No description provided for @breathePatternCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get breathePatternCustom;

  /// No description provided for @breatheSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get breatheSession;

  /// No description provided for @breatheEndless.
  ///
  /// In en, this message translates to:
  /// **'Endless'**
  String get breatheEndless;

  /// No description provided for @breatheSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n}s'**
  String breatheSeconds(int n);

  /// No description provided for @ambientWhite.
  ///
  /// In en, this message translates to:
  /// **'White noise'**
  String get ambientWhite;

  /// No description provided for @ambientPink.
  ///
  /// In en, this message translates to:
  /// **'Pink noise'**
  String get ambientPink;

  /// No description provided for @ambientBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown noise'**
  String get ambientBrown;

  /// No description provided for @ambientRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get ambientRain;

  /// No description provided for @ambientWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get ambientWind;

  /// No description provided for @ambientOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get ambientOcean;

  /// No description provided for @ambientVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get ambientVolume;

  /// No description provided for @ambientSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get ambientSleepTimer;

  /// No description provided for @ambientTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get ambientTimerOff;

  /// No description provided for @ambientPlay.
  ///
  /// In en, this message translates to:
  /// **'Play sound'**
  String get ambientPlay;

  /// No description provided for @ambientStop.
  ///
  /// In en, this message translates to:
  /// **'Stop sound'**
  String get ambientStop;

  /// No description provided for @ambientUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sound is not available on this device.'**
  String get ambientUnavailable;

  /// No description provided for @ambientPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing sound…'**
  String get ambientPreparing;

  /// No description provided for @ambientTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String ambientTimeLeft(String time);

  /// No description provided for @breaksStart.
  ///
  /// In en, this message translates to:
  /// **'Start breaks'**
  String get breaksStart;

  /// No description provided for @breaksStop.
  ///
  /// In en, this message translates to:
  /// **'Stop breaks'**
  String get breaksStop;

  /// No description provided for @breaksStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Break reminders are off'**
  String get breaksStatusOff;

  /// No description provided for @breaksNoneEnabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on at least one reminder'**
  String get breaksNoneEnabled;

  /// No description provided for @breaksNextName.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String breaksNextName(String name);

  /// No description provided for @breaksToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get breaksToday;

  /// No description provided for @breaksTaken.
  ///
  /// In en, this message translates to:
  /// **'Breaks taken'**
  String get breaksTaken;

  /// No description provided for @breaksSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get breaksSkipped;

  /// No description provided for @breaksEyeName.
  ///
  /// In en, this message translates to:
  /// **'Eye rest (20-20-20)'**
  String get breaksEyeName;

  /// No description provided for @breaksEyeHint.
  ///
  /// In en, this message translates to:
  /// **'Look at something 6 m (20 ft) away for 20 seconds'**
  String get breaksEyeHint;

  /// No description provided for @breaksStretchName.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get breaksStretchName;

  /// No description provided for @breaksStretchHint.
  ///
  /// In en, this message translates to:
  /// **'Stand up and stretch your whole body'**
  String get breaksStretchHint;

  /// No description provided for @breaksWaterName.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get breaksWaterName;

  /// No description provided for @breaksWaterHint.
  ///
  /// In en, this message translates to:
  /// **'Have a glass of water'**
  String get breaksWaterHint;

  /// No description provided for @breaksPostureName.
  ///
  /// In en, this message translates to:
  /// **'Posture check'**
  String get breaksPostureName;

  /// No description provided for @breaksPostureHint.
  ///
  /// In en, this message translates to:
  /// **'Sit up straight and relax your shoulders'**
  String get breaksPostureHint;

  /// No description provided for @breaksCustomDefault.
  ///
  /// In en, this message translates to:
  /// **'My reminder'**
  String get breaksCustomDefault;

  /// No description provided for @breaksForDuration.
  ///
  /// In en, this message translates to:
  /// **'Take {duration}'**
  String breaksForDuration(String duration);

  /// No description provided for @breaksEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min'**
  String breaksEveryMinutes(int minutes);

  /// No description provided for @breaksShorter.
  ///
  /// In en, this message translates to:
  /// **'Shorter interval'**
  String get breaksShorter;

  /// No description provided for @breaksLonger.
  ///
  /// In en, this message translates to:
  /// **'Longer interval'**
  String get breaksLonger;

  /// No description provided for @breaksDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get breaksDone;

  /// No description provided for @breaksSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get breaksSkip;

  /// No description provided for @breaksActiveHours.
  ///
  /// In en, this message translates to:
  /// **'Active hours'**
  String get breaksActiveHours;

  /// No description provided for @breaksActiveHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders only appear between these times'**
  String get breaksActiveHoursHint;

  /// No description provided for @breaksFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get breaksFrom;

  /// No description provided for @breaksTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get breaksTo;

  /// No description provided for @breaksLaterHour.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get breaksLaterHour;

  /// No description provided for @breaksEarlierHour.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get breaksEarlierHour;

  /// No description provided for @breaksBackground.
  ///
  /// In en, this message translates to:
  /// **'Also when Enfo is closed'**
  String get breaksBackground;

  /// No description provided for @breaksBackgroundOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications remind you even when the app is closed.'**
  String get breaksBackgroundOn;

  /// No description provided for @breaksBackgroundOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders only appear while Enfo is open.'**
  String get breaksBackgroundOff;

  /// No description provided for @breaksDesktopNotice.
  ///
  /// In en, this message translates to:
  /// **'Reminders appear while Enfo is running (it can stay minimized).'**
  String get breaksDesktopNotice;

  /// No description provided for @breaksAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom reminder'**
  String get breaksAddCustom;

  /// No description provided for @breaksEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get breaksEdit;

  /// No description provided for @breaksName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get breaksName;

  /// No description provided for @breaksDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get breaksDuration;

  /// No description provided for @breaksIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get breaksIcon;

  /// No description provided for @breaksShorterDuration.
  ///
  /// In en, this message translates to:
  /// **'Shorter break'**
  String get breaksShorterDuration;

  /// No description provided for @breaksLongerDuration.
  ///
  /// In en, this message translates to:
  /// **'Longer break'**
  String get breaksLongerDuration;

  /// No description provided for @breaksRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get breaksRemove;

  /// No description provided for @breaksRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm: remove reminder'**
  String get breaksRemoveConfirm;

  /// No description provided for @breaksRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'It will stop reminding you.'**
  String get breaksRemoveHint;

  /// No description provided for @worldPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan a meeting'**
  String get worldPlan;

  /// No description provided for @worldPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'Slide the marker to find a time that works for everyone.'**
  String get worldPlanIntro;

  /// No description provided for @worldPlanNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get worldPlanNow;

  /// No description provided for @worldPlanEarlier.
  ///
  /// In en, this message translates to:
  /// **'15 minutes earlier'**
  String get worldPlanEarlier;

  /// No description provided for @worldPlanLater.
  ///
  /// In en, this message translates to:
  /// **'15 minutes later'**
  String get worldPlanLater;

  /// No description provided for @worldPlanSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected time in {city}'**
  String worldPlanSelected(String city);

  /// No description provided for @worldPlanTapCity.
  ///
  /// In en, this message translates to:
  /// **'Tap a city to use its time as the reference.'**
  String get worldPlanTapCity;

  /// No description provided for @worldPlanNextDay.
  ///
  /// In en, this message translates to:
  /// **'+1 day'**
  String get worldPlanNextDay;

  /// No description provided for @worldPlanPrevDay.
  ///
  /// In en, this message translates to:
  /// **'-1 day'**
  String get worldPlanPrevDay;

  /// No description provided for @worldPlanOverlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone is at work'**
  String get worldPlanOverlapTitle;

  /// No description provided for @worldPlanNoOverlap.
  ///
  /// In en, this message translates to:
  /// **'No time in the next 24 hours works for everyone.'**
  String get worldPlanNoOverlap;

  /// No description provided for @worldPlanLeastBad.
  ///
  /// In en, this message translates to:
  /// **'Least bad: {time}'**
  String worldPlanLeastBad(String time);

  /// No description provided for @worldPlanAtWork.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} at work'**
  String worldPlanAtWork(int count, int total);

  /// No description provided for @worldPlanWork.
  ///
  /// In en, this message translates to:
  /// **'Working hours (09-18)'**
  String get worldPlanWork;

  /// No description provided for @worldPlanNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get worldPlanNight;

  /// No description provided for @worldPlanMarker.
  ///
  /// In en, this message translates to:
  /// **'Selected time'**
  String get worldPlanMarker;

  /// No description provided for @eventAdd.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventAdd;

  /// No description provided for @eventEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventEdit;

  /// No description provided for @eventName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get eventName;

  /// No description provided for @eventNameHint.
  ///
  /// In en, this message translates to:
  /// **'Birthday, trip, launch...'**
  String get eventNameHint;

  /// No description provided for @eventYearly.
  ///
  /// In en, this message translates to:
  /// **'Repeat every year'**
  String get eventYearly;

  /// No description provided for @eventYearlyHint.
  ///
  /// In en, this message translates to:
  /// **'For birthdays and anniversaries: it moves on to the next one.'**
  String get eventYearlyHint;

  /// No description provided for @eventNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get eventNotify;

  /// No description provided for @eventNotifyHint.
  ///
  /// In en, this message translates to:
  /// **'At the moment it arrives.'**
  String get eventNotifyHint;

  /// No description provided for @eventDayBefore.
  ///
  /// In en, this message translates to:
  /// **'Also the day before'**
  String get eventDayBefore;

  /// No description provided for @eventSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventSave;

  /// No description provided for @eventDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get eventDelete;

  /// No description provided for @eventConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm: delete event'**
  String get eventConfirmDelete;

  /// No description provided for @eventDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'This event will be removed.'**
  String get eventDeleteHint;

  /// No description provided for @eventEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events yet.\nTap + to count down to one.'**
  String get eventEmpty;

  /// No description provided for @eventToday.
  ///
  /// In en, this message translates to:
  /// **'Today!'**
  String get eventToday;

  /// No description provided for @eventDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String eventDaysAgo(int count);

  /// No description provided for @eventDaysShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get eventDaysShort;

  /// No description provided for @eventUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get eventUnitDays;

  /// No description provided for @eventUnitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get eventUnitHours;

  /// No description provided for @eventUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get eventUnitMinutes;

  /// No description provided for @eventRepeatsYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get eventRepeatsYearly;

  /// No description provided for @eventNotifyNow.
  ///
  /// In en, this message translates to:
  /// **'It\'s time!'**
  String get eventNotifyNow;

  /// No description provided for @eventNotifyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get eventNotifyTomorrow;

  /// No description provided for @sleepPlanWake.
  ///
  /// In en, this message translates to:
  /// **'Wake at'**
  String get sleepPlanWake;

  /// No description provided for @sleepPlanBed.
  ///
  /// In en, this message translates to:
  /// **'Sleep at'**
  String get sleepPlanBed;

  /// No description provided for @sleepPlanNow.
  ///
  /// In en, this message translates to:
  /// **'Sleep now'**
  String get sleepPlanNow;

  /// No description provided for @sleepTitleWake.
  ///
  /// In en, this message translates to:
  /// **'I want to wake up at'**
  String get sleepTitleWake;

  /// No description provided for @sleepTitleBed.
  ///
  /// In en, this message translates to:
  /// **'I go to bed at'**
  String get sleepTitleBed;

  /// No description provided for @sleepTitleNow.
  ///
  /// In en, this message translates to:
  /// **'If I fall asleep now ({time})'**
  String sleepTitleNow(String time);

  /// No description provided for @sleepBedtimeWord.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get sleepBedtimeWord;

  /// No description provided for @sleepWakeWord.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get sleepWakeWord;

  /// No description provided for @sleepCyclesLine.
  ///
  /// In en, this message translates to:
  /// **'{cycles} cycles · {duration} of sleep'**
  String sleepCyclesLine(int cycles, String duration);

  /// No description provided for @sleepNote.
  ///
  /// In en, this message translates to:
  /// **'Cycles last 90 minutes and falling asleep takes about 15. Five or six cycles are recommended.'**
  String get sleepNote;

  /// No description provided for @sleepWindDown.
  ///
  /// In en, this message translates to:
  /// **'Wind-down reminder'**
  String get sleepWindDown;

  /// No description provided for @sleepWindDownHint.
  ///
  /// In en, this message translates to:
  /// **'An alarm 30 minutes before bedtime.'**
  String get sleepWindDownHint;

  /// No description provided for @sleepWindDownPassed.
  ///
  /// In en, this message translates to:
  /// **'That time has already passed.'**
  String get sleepWindDownPassed;

  /// No description provided for @sleepWindDownLabel.
  ///
  /// In en, this message translates to:
  /// **'Time to wind down'**
  String get sleepWindDownLabel;

  /// No description provided for @sleepAlarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get sleepAlarmLabel;

  /// No description provided for @sleepSetAlarm.
  ///
  /// In en, this message translates to:
  /// **'Set alarm'**
  String get sleepSetAlarm;

  /// No description provided for @sleepRemoveAlarm.
  ///
  /// In en, this message translates to:
  /// **'Remove alarm'**
  String get sleepRemoveAlarm;

  /// No description provided for @sleepAlarmSet.
  ///
  /// In en, this message translates to:
  /// **'Alarm set for {time}'**
  String sleepAlarmSet(String time);

  /// No description provided for @sleepPast.
  ///
  /// In en, this message translates to:
  /// **'This time has already passed'**
  String get sleepPast;

  /// No description provided for @sleepRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sleepRecommended;

  /// No description provided for @ambientMusicTabSounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get ambientMusicTabSounds;

  /// No description provided for @ambientMusicTab.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get ambientMusicTab;

  /// No description provided for @ambientMusicPlay.
  ///
  /// In en, this message translates to:
  /// **'Play music'**
  String get ambientMusicPlay;

  /// No description provided for @ambientMusicPause.
  ///
  /// In en, this message translates to:
  /// **'Pause music'**
  String get ambientMusicPause;

  /// No description provided for @ambientMusicNext.
  ///
  /// In en, this message translates to:
  /// **'Next song'**
  String get ambientMusicNext;

  /// No description provided for @ambientMusicPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous song'**
  String get ambientMusicPrevious;

  /// No description provided for @ambientMusicShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get ambientMusicShuffle;

  /// No description provided for @ambientMusicRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get ambientMusicRepeat;

  /// No description provided for @ambientMusicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get ambientMusicVolume;

  /// No description provided for @ambientMusicCredits.
  ///
  /// In en, this message translates to:
  /// **'Music and ambience credits'**
  String get ambientMusicCredits;

  /// No description provided for @ambientMusicCreditsNote.
  ///
  /// In en, this message translates to:
  /// **'Songs from Wikimedia Commons and the Open Lo-Fi collection, and ambience loops from Wikimedia Commons, released under CC0, public domain or Creative Commons Attribution licenses.'**
  String get ambientMusicCreditsNote;

  /// No description provided for @modeMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get modeMusic;

  /// No description provided for @modeDescMusic.
  ///
  /// In en, this message translates to:
  /// **'Lo-fi songs to focus to'**
  String get modeDescMusic;

  /// No description provided for @musicCreditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Artists and licenses'**
  String get musicCreditsSubtitle;

  /// No description provided for @displayMenuButtons.
  ///
  /// In en, this message translates to:
  /// **'Menu buttons'**
  String get displayMenuButtons;

  /// No description provided for @displayMenuButtonsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which buttons appear in the bottom menu. Settings is always there.'**
  String get displayMenuButtonsHint;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Enfo'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Focus, one calm dial.'**
  String get onbWelcomeTagline;

  /// No description provided for @timerRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer running'**
  String get timerRunningTitle;

  /// No description provided for @timerRunningBody.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String timerRunningBody(String time);

  /// No description provided for @timerPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer paused'**
  String get timerPausedTitle;

  /// No description provided for @timerPausedBody.
  ///
  /// In en, this message translates to:
  /// **'{duration} left'**
  String timerPausedBody(String duration);

  /// No description provided for @musicActionPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get musicActionPlay;

  /// No description provided for @musicActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get musicActionPause;

  /// No description provided for @widgetsFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Today\\\'s focus time and pomodoros at a glance.'**
  String get widgetsFocusSubtitle;

  /// No description provided for @ambienceStream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get ambienceStream;

  /// No description provided for @ambienceSnowmelt.
  ///
  /// In en, this message translates to:
  /// **'Snowmelt'**
  String get ambienceSnowmelt;

  /// No description provided for @ambienceRivulet.
  ///
  /// In en, this message translates to:
  /// **'Rivulet'**
  String get ambienceRivulet;

  /// No description provided for @ambienceFountain.
  ///
  /// In en, this message translates to:
  /// **'Fountain'**
  String get ambienceFountain;

  /// No description provided for @ambiencePlazaFountain.
  ///
  /// In en, this message translates to:
  /// **'Plaza fountain'**
  String get ambiencePlazaFountain;

  /// No description provided for @ambienceGeyser.
  ///
  /// In en, this message translates to:
  /// **'Geyser'**
  String get ambienceGeyser;

  /// No description provided for @ambienceBubblingGeyser.
  ///
  /// In en, this message translates to:
  /// **'Bubbling geyser'**
  String get ambienceBubblingGeyser;

  /// No description provided for @ambienceRainWindow.
  ///
  /// In en, this message translates to:
  /// **'Rain on the window'**
  String get ambienceRainWindow;

  /// No description provided for @ambienceRainThunder.
  ///
  /// In en, this message translates to:
  /// **'Rain and thunder'**
  String get ambienceRainThunder;

  /// No description provided for @ambienceThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get ambienceThunderstorm;

  /// No description provided for @ambienceThunderbolts.
  ///
  /// In en, this message translates to:
  /// **'Thunderbolts'**
  String get ambienceThunderbolts;

  /// No description provided for @ambienceStormWind.
  ///
  /// In en, this message translates to:
  /// **'Storm wind'**
  String get ambienceStormWind;

  /// No description provided for @ambienceForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get ambienceForest;

  /// No description provided for @ambienceForestBirds.
  ///
  /// In en, this message translates to:
  /// **'Forest with birds'**
  String get ambienceForestBirds;

  /// No description provided for @ambienceDawnChorus.
  ///
  /// In en, this message translates to:
  /// **'Dawn chorus'**
  String get ambienceDawnChorus;

  /// No description provided for @ambienceCountryDawn.
  ///
  /// In en, this message translates to:
  /// **'Country dawn'**
  String get ambienceCountryDawn;

  /// No description provided for @ambiencePondDusk.
  ///
  /// In en, this message translates to:
  /// **'Pond at dusk'**
  String get ambiencePondDusk;

  /// No description provided for @ambienceMorningBirds.
  ///
  /// In en, this message translates to:
  /// **'Morning birds'**
  String get ambienceMorningBirds;

  /// No description provided for @ambienceCampfire.
  ///
  /// In en, this message translates to:
  /// **'Campfire'**
  String get ambienceCampfire;

  /// No description provided for @ambienceFireplace.
  ///
  /// In en, this message translates to:
  /// **'Fireplace'**
  String get ambienceFireplace;

  /// No description provided for @ambienceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get ambienceLibrary;

  /// No description provided for @ambienceBusyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Busy library'**
  String get ambienceBusyLibrary;

  /// No description provided for @ambienceOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get ambienceOffice;

  /// No description provided for @ambienceClassroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get ambienceClassroom;

  /// No description provided for @ambienceCafeteria.
  ///
  /// In en, this message translates to:
  /// **'Cafeteria'**
  String get ambienceCafeteria;

  /// No description provided for @ambienceRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get ambienceRestaurant;

  /// No description provided for @ambienceSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get ambienceSupermarket;

  /// No description provided for @ambienceShoppingMall.
  ///
  /// In en, this message translates to:
  /// **'Shopping mall'**
  String get ambienceShoppingMall;

  /// No description provided for @ambienceRainyStreet.
  ///
  /// In en, this message translates to:
  /// **'Rainy street'**
  String get ambienceRainyStreet;

  /// No description provided for @ambienceSpringStreet.
  ///
  /// In en, this message translates to:
  /// **'Spring street'**
  String get ambienceSpringStreet;

  /// No description provided for @ambienceSubway.
  ///
  /// In en, this message translates to:
  /// **'Subway'**
  String get ambienceSubway;

  /// No description provided for @ambienceSubwayRide.
  ///
  /// In en, this message translates to:
  /// **'Subway ride'**
  String get ambienceSubwayRide;

  /// No description provided for @ambienceStationTunnel.
  ///
  /// In en, this message translates to:
  /// **'Station tunnel'**
  String get ambienceStationTunnel;

  /// No description provided for @ambienceTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get ambienceTrain;

  /// No description provided for @ambienceTaiwanTrain.
  ///
  /// In en, this message translates to:
  /// **'Taiwan train'**
  String get ambienceTaiwanTrain;

  /// No description provided for @ambienceEscalator.
  ///
  /// In en, this message translates to:
  /// **'Escalator'**
  String get ambienceEscalator;

  /// No description provided for @ambienceElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get ambienceElevator;

  /// No description provided for @ambiencePlayground.
  ///
  /// In en, this message translates to:
  /// **'Playground'**
  String get ambiencePlayground;

  /// No description provided for @ambienceStreetMarket.
  ///
  /// In en, this message translates to:
  /// **'Street market'**
  String get ambienceStreetMarket;

  /// No description provided for @ambienceKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get ambienceKeyboard;

  /// No description provided for @ambientNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get ambientNature;

  /// No description provided for @ambientPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get ambientPlaces;

  /// No description provided for @breaksRelaxSound.
  ///
  /// In en, this message translates to:
  /// **'Break sound'**
  String get breaksRelaxSound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'ja',
        'ko',
        'pt',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
