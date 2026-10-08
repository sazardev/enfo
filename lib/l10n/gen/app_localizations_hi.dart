// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => 'सेटिंग्स';

  @override
  String get tooltipStats => 'आँकड़े';

  @override
  String get tooltipPin => 'हमेशा ऊपर रखें';

  @override
  String get tooltipUnpin => 'हमेशा ऊपर रखना बंद करें';

  @override
  String get phasePaused => 'रुका हुआ';

  @override
  String get phaseFocus => 'फ़ोकस';

  @override
  String get phaseRelax => 'आराम';

  @override
  String get notifRestTitle => 'आराम का समय';

  @override
  String get notifRestBody => 'थोड़ा सुस्ता लें।';

  @override
  String get notifWorkTitle => 'काम का समय';

  @override
  String get notifWorkBody => 'चलिए, काम जारी रखें!';

  @override
  String get onboardingStart => 'शुरू करें';

  @override
  String get rhythmTitle => 'फ़ोकस की लय';

  @override
  String get presetClassic => 'क्लासिक';

  @override
  String get presetExtended => 'लंबा';

  @override
  String get presetDeep => 'गहरा';

  @override
  String get presetManual => 'मैनुअल';

  @override
  String get workLabel => 'फ़ोकस';

  @override
  String get restLabel => 'आराम';

  @override
  String minutes(int n) {
    return '$n मिनट';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest मिनट';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get timersTitle => 'समय';

  @override
  String timersSubtitle(int work, int rest) {
    return '$work मिनट फ़ोकस · $rest मिनट आराम';
  }

  @override
  String timersCycle(int total) {
    return 'एक पूरा चक्र: $total मिनट';
  }

  @override
  String get timersApplyHint =>
      'अगर घड़ी चल रही है, तो बदलाव अगले चक्र से लागू होगा। अगर रुकी है, तो घड़ी रीसेट हो जाएगी।';

  @override
  String get appearanceTitle => 'रूप-रंग';

  @override
  String get appearanceLight => 'लाइट थीम';

  @override
  String get appearanceDark => 'डार्क थीम';

  @override
  String get darkTheme => 'डार्क थीम';

  @override
  String get themeModeSystem => 'सिस्टम';

  @override
  String get themeModeLight => 'लाइट';

  @override
  String get themeModeDark => 'डार्क';

  @override
  String get accentColor => 'एक्सेंट रंग';

  @override
  String get notificationsTitle => 'सूचनाएँ';

  @override
  String get notificationsOn => 'चालू';

  @override
  String get notificationsOff => 'बंद';

  @override
  String get notificationsToggle => 'चरण बदलने पर सूचना';

  @override
  String get notificationsHint =>
      'आराम करने या काम पर लौटने का समय होने पर सूचना पाएँ।';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageHint => 'ऐप की भाषा चुनें।';

  @override
  String get supportTitle => 'Enfo को सहयोग दें';

  @override
  String get supportSubtitleNoAds => 'दान और कॉफ़ी';

  @override
  String get buyCoffee => 'मुझे एक कॉफ़ी पिलाएँ';

  @override
  String get supportHint =>
      'Enfo मुफ़्त है और इसे एक ही व्यक्ति बनाता है। इसे इस्तेमाल करने के लिए धन्यवाद।';

  @override
  String get rateApp => 'Enfo को रेट करें';

  @override
  String get shareApp => 'Enfo शेयर करें';

  @override
  String shareMessage(String url) {
    return 'Enfo, Android के लिए एक शांत घड़ी और टाइमर टूलबॉक्स: $url';
  }

  @override
  String get donateTitle => 'दान करें';

  @override
  String get donateSubtitle => 'Google Play से एक बार का भुगतान';

  @override
  String get donateHint =>
      'Enfo मुफ़्त और विज्ञापन-मुक्त है। अगर आप साथ देना चाहें, तो Google Play से एक बार का दान दे सकते हैं। धन्यवाद!';

  @override
  String get donateUnavailable =>
      'अभी दान उपलब्ध नहीं है। आप फिर भी मुझे एक कॉफ़ी पिला सकते हैं।';

  @override
  String get donateThanks => 'Enfo का साथ देने के लिए धन्यवाद!';

  @override
  String get donatePending => 'ख़रीद लंबित…';

  @override
  String get donateError =>
      'ख़रीद पूरी नहीं हो सकी। कुछ भी शुल्क नहीं लिया गया।';

  @override
  String get statsTitle => 'आँकड़े';

  @override
  String get statsEmpty =>
      'अभी कोई सेशन नहीं है।\nपोमोडोरो शुरू करें, वह यहाँ दिखेगा।';

  @override
  String get statsTodayPomodoros => 'आज के पोमोडोरो';

  @override
  String get statsTodayFocus => 'आज का फ़ोकस';

  @override
  String get statsCompleted => 'पूरे हुए';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'दिन लगातार',
      one: 'दिन लगातार',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => 'पिछले 7 दिन';

  @override
  String get statsTotalFocus => 'कुल फ़ोकस समय';

  @override
  String get statsTotalRest => 'कुल आराम समय';

  @override
  String get statsAbandoned => 'अधूरे छोड़े';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent% पूरे हुए';
  }

  @override
  String get statsAverageFocus => 'औसत फ़ोकस';

  @override
  String get statsLongestSession => 'सबसे लंबा सेशन';

  @override
  String get statsPauses => 'विराम';

  @override
  String get statsAverageGap => 'सेशनों के बीच औसत इंतज़ार';

  @override
  String get statsLongestGap => 'सबसे लंबा निष्क्रिय समय';

  @override
  String get statsSinceLast => 'पिछले सेशन के बाद से';

  @override
  String get statsHistory => 'इतिहास';

  @override
  String get statsClearHistory => 'इतिहास मिटाएँ';

  @override
  String get statsClearConfirm => 'पुष्टि करें: सभी सेशन मिटाएँ';

  @override
  String get statsClearHint => 'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get sessionFocus => 'फ़ोकस';

  @override
  String get sessionRest => 'आराम';

  @override
  String sessionProgress(String done, String planned) {
    return '$planned में से $done';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count विराम',
      one: '1 विराम',
    );
    return '$_temp0 ($time)';
  }

  @override
  String sessionIdleBefore(String gap) {
    return '$gap निष्क्रिय रहने के बाद';
  }

  @override
  String get sessionCompleted => 'पूरा हुआ';

  @override
  String get sessionAbandoned => 'अधूरा छोड़ा';

  @override
  String get clockStyleTitle => 'घड़ी की शैली';

  @override
  String get tooltipClockStyle => 'घड़ी की शैली';

  @override
  String get clockCategoryProgress => 'प्रगति और अंक';

  @override
  String get clockCategoryNumbers => 'सिर्फ़ अंक';

  @override
  String get clockCategoryIcons => 'सिर्फ़ आइकन';

  @override
  String get clockCategoryMotion => 'सिर्फ़ एनिमेशन';

  @override
  String get clockUnitMinutes => 'मिनट';

  @override
  String get clockUnitSeconds => 'सेक';

  @override
  String get clockRing => 'रिंग';

  @override
  String get clockWavyRing => 'लहर';

  @override
  String get clockSegments => 'खंड';

  @override
  String get clockOrbit => 'कक्षा';

  @override
  String get clockPie => 'पाई';

  @override
  String get clockKitchen => 'रसोई';

  @override
  String get clockDots => 'बिंदु';

  @override
  String get clockBar => 'पट्टी';

  @override
  String get clockWavyBar => 'लहरदार पट्टी';

  @override
  String get clockDigits => 'अंक';

  @override
  String get clockMinutes => 'मिनट';

  @override
  String get clockTiles => 'टाइल';

  @override
  String get clockStack => 'परतें';

  @override
  String get clockTomato => 'टमाटर';

  @override
  String get clockHourglass => 'रेतघड़ी';

  @override
  String get clockBattery => 'बैटरी';

  @override
  String get clockIcon => 'आइकन';

  @override
  String get clockCookie => 'कुकी';

  @override
  String get clockLiquid => 'तरल';

  @override
  String get clockBreathe => 'साँस';

  @override
  String get clockEqualizer => 'इक्वलाइज़र';

  @override
  String get clockRipple => 'तरंगें';

  @override
  String get accentApply => 'लागू करें';

  @override
  String get accentCustom => 'कस्टम रंग';

  @override
  String get accentHue => 'रंगत';

  @override
  String get accentSaturation => 'संतृप्ति';

  @override
  String get accentBrightness => 'चमक';

  @override
  String get accentHex => 'हेक्स कोड';

  @override
  String get displayTitle => 'डिस्प्ले';

  @override
  String get displayClockShown => 'समय दिख रहा है';

  @override
  String get displayClockHidden => 'समय छिपा है';

  @override
  String get showClock => 'समय दिखाएँ';

  @override
  String get showClockHint => 'टाइमर के ऊपर छोटी घड़ी।';

  @override
  String get clockFormat => 'समय का प्रारूप';

  @override
  String get clockFormatSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get clockFormat12 => '12 घंटे';

  @override
  String get clockFormat24 => '24 घंटे';

  @override
  String get behaviorTitle => 'व्यवहार';

  @override
  String get autoStartNext => 'अगला चरण अपने-आप शुरू करें';

  @override
  String get autoStartNextHint =>
      'फ़ोकस या आराम खत्म होने पर अगला बिना छुए शुरू हो जाता है।';

  @override
  String get hapticFeedback => 'कंपन';

  @override
  String get hapticFeedbackHint => 'टैप, व्हील, चरण बदलाव और अलार्म।';

  @override
  String get clockCombosTitle => 'कॉम्बो';

  @override
  String get clockCollapseAll => 'सब समेटें';

  @override
  String get clockExpandAll => 'सब फैलाएँ';

  @override
  String get comboDeepFocus => 'गहरा फ़ोकस';

  @override
  String get comboMint => 'ताज़ा पुदीना';

  @override
  String get comboSunset => 'सूर्यास्त';

  @override
  String get comboZen => 'ज़ेन';

  @override
  String get comboTomato => 'क्लासिक टमाटर';

  @override
  String get comboNight => 'रात का उल्लू';

  @override
  String get comboPlayful => 'चुलबुला';

  @override
  String get comboMinimal => 'मिनिमल';

  @override
  String get uiSizeTitle => 'इंटरफ़ेस का आकार';

  @override
  String get uiSizeSmall => 'छोटा';

  @override
  String get uiSizeNormal => 'सामान्य';

  @override
  String get uiSizeLarge => 'बड़ा';

  @override
  String get uiSizeExtraLarge => 'बहुत बड़ा';

  @override
  String get uiSizeHint =>
      'टेक्स्ट और कंट्रोल को बड़ा या छोटा करता है। टीवी और कार डिस्प्ले पर उपयोगी।';

  @override
  String get clockBlob => 'ब्लॉब';

  @override
  String get clockFlower => 'फूल';

  @override
  String get clockSun => 'सूरज';

  @override
  String get clockGears => 'गियर';

  @override
  String get clockBubbles => 'बुलबुले';

  @override
  String get clockSunflower => 'सूरजमुखी';

  @override
  String get clockFireflies => 'जुगनू';

  @override
  String get clockPendulum => 'पेंडुलम';

  @override
  String get clockBounce => 'उछाल';

  @override
  String get clockMorph => 'मॉर्फ़';

  @override
  String get dataTitle => 'डेटा';

  @override
  String get dataSubtitle => 'इतिहास, रीसेट और परिचय';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिकॉर्ड सहेजे गए',
      one: '1 रिकॉर्ड सहेजा गया',
      zero: 'कोई गतिविधि सहेजी नहीं गई',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'परिचय फिर से देखें';

  @override
  String get dataIntroHint =>
      'स्वागत स्क्रीन दोबारा देखें और अपनी लय फिर से चुनें। कुछ भी नहीं मिटता।';

  @override
  String get dataClearHistoryHint =>
      'दर्ज की गई सारी गतिविधि मिटा देता है: पोमोडोरो, टाइमर, स्टॉपवॉच, अलार्म और घड़ी का समय। सेटिंग्स नहीं बदलतीं।';

  @override
  String get dataConfirmClearHistory => 'पुष्टि करें: इतिहास मिटाएँ';

  @override
  String get dataResetSettings => 'सेटिंग्स रीसेट करें';

  @override
  String get dataResetSettingsHint =>
      'समय, थीम, एक्सेंट रंग, भाषा, मोड और डिस्प्ले मूल मानों पर लौट जाते हैं। इतिहास बना रहता है।';

  @override
  String get dataConfirmResetSettings => 'पुष्टि करें: सेटिंग्स रीसेट करें';

  @override
  String get dataEraseAll => 'सब कुछ मिटाएँ';

  @override
  String get dataEraseAllHint =>
      'इतिहास और सेटिंग्स मिटाकर पहली बार जैसी नई शुरुआत करता है।';

  @override
  String get dataConfirmEraseAll => 'पुष्टि करें: सब कुछ मिटाएँ';

  @override
  String get dataDoneHistory => 'इतिहास मिटा दिया गया।';

  @override
  String get dataDoneSettings => 'सेटिंग्स रीसेट हो गईं।';

  @override
  String get dataCacheNote =>
      'Enfo कैश नहीं रखता: यह सिर्फ़ यहाँ बताया गया इतिहास और सेटिंग्स सहेजता है।';

  @override
  String get clockEndsAt => 'समाप्ति';

  @override
  String get clockFill => 'भराव';

  @override
  String get clockCapsule => 'कैप्सूल';

  @override
  String get clockRollers => 'रोलर';

  @override
  String get clockMatrix => 'मैट्रिक्स';

  @override
  String get clockSevenSeg => 'डिजिटल';

  @override
  String get clockFlip => 'फ़्लिप';

  @override
  String get clockFine => 'बारीक';

  @override
  String get clockSuperscript => 'घात';

  @override
  String get clockPercent => 'प्रतिशत';

  @override
  String get clockEndTime => 'समाप्ति समय';

  @override
  String get clockSeconds => 'सेकंड';

  @override
  String get clockTall => 'ऊँचा';

  @override
  String get clockWobble => 'डगमग';

  @override
  String get clockLabeled => 'लेबल सहित';

  @override
  String get clockGauge => 'गेज';

  @override
  String get clockNeedle => 'सुई';

  @override
  String get clockAnalog => 'एनालॉग';

  @override
  String get clockRings => 'छल्ले';

  @override
  String get clockSquircle => 'स्क्वर्कल';

  @override
  String get clockColumns => 'स्तंभ';

  @override
  String get clockVertical => 'खड़ा';

  @override
  String get clockSteps => 'सीढ़ियाँ';

  @override
  String get clockBlocks => 'ब्लॉक';

  @override
  String get clockSpiral => 'सर्पिल';

  @override
  String get clockSlices => 'फाँकें';

  @override
  String get clockPills => 'गोलियाँ';

  @override
  String get clockHexagon => 'षट्भुज';

  @override
  String get clockStairs => 'सीढ़ी';

  @override
  String get clockCandle => 'मोमबत्ती';

  @override
  String get clockMoon => 'चाँद';

  @override
  String get clockRuler => 'स्केल';

  @override
  String get comboArcade => 'आर्केड';

  @override
  String get comboCalculator => 'कैलकुलेटर';

  @override
  String get comboDepartures => 'रेलवे स्टेशन';

  @override
  String get comboCandlelight => 'मोमबत्ती की रोशनी';

  @override
  String get comboMoonlight => 'चाँदनी';

  @override
  String get comboGarden => 'बगीचा';

  @override
  String get comboSummer => 'गर्मी';

  @override
  String get comboWorkshop => 'वर्कशॉप';

  @override
  String get comboFizzy => 'बुलबुलेदार';

  @override
  String get comboSunfield => 'सूरजमुखी का खेत';

  @override
  String get comboSummerNight => 'गर्मी की रात';

  @override
  String get comboHypnosis => 'सम्मोहन';

  @override
  String get comboBouncy => 'उछलता';

  @override
  String get comboShapeshifter => 'रूप बदलने वाला';

  @override
  String get comboLava => 'लावा लैंप';

  @override
  String get comboOcean => 'समुद्र';

  @override
  String get comboPulse => 'धड़कन';

  @override
  String get comboPond => 'तालाब';

  @override
  String get comboEspresso => 'एस्प्रेसो';

  @override
  String get comboSpeedometer => 'स्पीडोमीटर';

  @override
  String get comboCompass => 'कंपास';

  @override
  String get comboClassicClock => 'क्लासिक घड़ी';

  @override
  String get comboConcentric => 'संकेंद्रित';

  @override
  String get comboRounded => 'गोलाकार';

  @override
  String get comboSignal => 'सिग्नल';

  @override
  String get comboThermometer => 'थर्मामीटर';

  @override
  String get comboMilestones => 'मील के पत्थर';

  @override
  String get comboRetroBlocks => 'रेट्रो ब्लॉक';

  @override
  String get comboHypnoSpiral => 'सम्मोहक सर्पिल';

  @override
  String get comboCitrus => 'खट्टा-मीठा नींबू';

  @override
  String get comboChocolate => 'चॉकलेट बार';

  @override
  String get comboCrystal => 'क्रिस्टल';

  @override
  String get comboStaircase => 'सीढ़ीदार';

  @override
  String get comboTapeMeasure => 'इंच टेप';

  @override
  String get comboBoldType => 'मोटे अक्षर';

  @override
  String get comboPill => 'कैप्सूल';

  @override
  String get comboSlotMachine => 'स्लॉट मशीन';

  @override
  String get comboWhisper => 'फुसफुसाहट';

  @override
  String get comboDeadline => 'अंतिम तिथि';

  @override
  String get comboPercentage => 'प्रतिशत';

  @override
  String get comboStopwatch => 'सिर्फ़ सेकंड';

  @override
  String get comboSkyscraper => 'गगनचुंबी इमारत';

  @override
  String get comboWaveText => 'लहरदार टेक्स्ट';

  @override
  String get comboDashboard => 'डैशबोर्ड';

  @override
  String get comboExponent => 'घात';

  @override
  String get comboGrandmaKitchen => 'दादी की रसोई';

  @override
  String get comboCyber => 'साइबर';

  @override
  String get comboCandy => 'टॉफ़ी';

  @override
  String get comboConfetti => 'कॉन्फ़ेटी';

  @override
  String get comboCookieJar => 'कुकी जार';

  @override
  String get comboSandbox => 'सैंडबॉक्स';

  @override
  String get comboPizzaNight => 'पिज़्ज़ा नाइट';

  @override
  String get onbLanguageTitle => 'आपकी भाषा';

  @override
  String get onbLanguageBody =>
      'अपनी भाषा चुनें। यहाँ चुनी गई हर चीज़ बाद में सेटिंग्स में बदली जा सकती है।';

  @override
  String get onbRhythmTitle => 'आपकी लय';

  @override
  String get onbRhythmBody => 'कितनी देर फ़ोकस करें और कितनी देर आराम।';

  @override
  String get onbLookTitle => 'इसे अपना बनाएँ';

  @override
  String get onbLookBody =>
      'थीम, घड़ी की शैली और रंग। कॉम्बो से शुरू करें, फिर चाहें तो रंग बदलें।';

  @override
  String get onbClockTitle => 'घड़ी चुनें';

  @override
  String get onbClockBody =>
      'तैयार कॉम्बिनेशन: एक टैप में घड़ी की शैली और रंग।';

  @override
  String get onbAllStyles => 'सभी शैलियाँ देखें';

  @override
  String get onbOptionsTitle => 'आख़िरी बातें';

  @override
  String get onbOptionsBody => 'डिस्प्ले और व्यवहार। यह सब सेटिंग्स में भी है।';

  @override
  String get onbModesTitle => 'आपके टूल';

  @override
  String get onbModesBody =>
      'Enfo घड़ी और टाइमर का टूलबॉक्स है। जो उपयोग करेंगे उसे चालू करें; मोड मेनू से कभी भी बदल सकते हैं।';

  @override
  String get onbPreview => 'पूर्वावलोकन';

  @override
  String get onbDisplayTitle => 'डिस्प्ले';

  @override
  String get onbDisplayBody => 'घड़ी कैसी दिखे और सब कुछ कितना बड़ा हो।';

  @override
  String get onbClockModeDesign => 'घड़ी मोड का डिज़ाइन';

  @override
  String get onbPermTitle => 'अनुमतियाँ';

  @override
  String get onbPermBody =>
      'ताकि Enfo बंद होने पर भी टाइमर और अलार्म आप तक पहुँचें।';

  @override
  String get onbPermNotifications => 'सूचनाएँ';

  @override
  String get onbPermNotificationsHint =>
      'टाइमर खत्म होने या अलार्म बजने पर सूचना।';

  @override
  String get onbPermExact => 'सटीक अलार्म';

  @override
  String get onbPermExactHint => 'बैटरी सेवर में भी ठीक समय पर बजते हैं।';

  @override
  String get onbPermAllow => 'अनुमति दें';

  @override
  String get onbPermAllowed => 'अनुमत';

  @override
  String get onbPermLater => 'इन्हें सिस्टम सेटिंग्स में कभी भी बदल सकते हैं।';

  @override
  String get onbNext => 'आगे';

  @override
  String get onbBack => 'पीछे';

  @override
  String get onbSkip => 'छोड़ें';

  @override
  String onbStepOf(int step, int total) {
    return 'चरण $step/$total';
  }

  @override
  String get clockFormatAuto => 'ऑटो';

  @override
  String get modePomodoro => 'पोमोडोरो';

  @override
  String get modeClock => 'घड़ी';

  @override
  String get modeTimer => 'टाइमर';

  @override
  String get modeStopwatch => 'स्टॉपवॉच';

  @override
  String get modeAlarm => 'अलार्म';

  @override
  String get modeWorld => 'विश्व घड़ी';

  @override
  String get modeDescPomodoro => 'फ़ोकस और आराम के चक्र';

  @override
  String get modeDescClock => 'एक सुंदर, हमेशा दिखती घड़ी';

  @override
  String get modeDescTimer => 'किसी भी समय से उलटी गिनती';

  @override
  String get modeDescStopwatch => 'लैप के साथ समय मापें';

  @override
  String get modeDescAlarm => 'जागें या याद दिलाए जाएँ';

  @override
  String get modeDescWorld => 'दुनिया के शहरों का समय';

  @override
  String get tooltipModes => 'मोड';

  @override
  String get tooltipSwitchMode => 'अगला मोड';

  @override
  String get tooltipFullscreen => 'फ़ुल स्क्रीन';

  @override
  String get tooltipExitFullscreen => 'फ़ुल स्क्रीन से बाहर निकलें';

  @override
  String get tooltipDim => 'स्क्रीन धीमी करें';

  @override
  String get modesTitle => 'मोड';

  @override
  String get modesHint =>
      'जो मोड आप इस्तेमाल करते हैं और उनका क्रम चुनें। क्रम बदलने के लिए खींचें।';

  @override
  String get modesStart => 'इससे शुरू करें';

  @override
  String get modesStartLast => 'आख़िरी इस्तेमाल किया मोड';

  @override
  String get modesCustomize => 'कस्टमाइज़ करें';

  @override
  String get modesActivity => 'गतिविधि का इतिहास';

  @override
  String get modesAtLeastOne => 'कम से कम एक मोड चालू रहना चाहिए।';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मोड चालू',
      one: '1 मोड चालू',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'गतिविधि का इतिहास';

  @override
  String get activityTitle => 'गतिविधि';

  @override
  String get activityEmpty =>
      'अभी यहाँ कुछ नहीं है।\nटाइमर, स्टॉपवॉच, अलार्म या घड़ी इस्तेमाल करें, वह यहाँ दिखेगा।';

  @override
  String get activityFilterAll => 'सब';

  @override
  String get activityTimersToday => 'आज के टाइमर';

  @override
  String get activityStopwatchToday => 'आज की स्टॉपवॉच';

  @override
  String get activityDisplayToday => 'आज स्क्रीन पर';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लैप',
      one: '1 लैप',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'लैप $n';
  }

  @override
  String get activityAlarmDismissed => 'बंद की गई';

  @override
  String get activityAlarmSnoozed => 'स्नूज़ की गई';

  @override
  String get activityAlarmMissed => 'छूट गई';

  @override
  String activityDisplay(String mode) {
    return 'स्क्रीन पर $mode';
  }

  @override
  String activityRan(String done, String planned) {
    return '$planned में से $done';
  }

  @override
  String get faceRing => 'रिंग';

  @override
  String get faceDigital => 'डिजिटल';

  @override
  String get faceAnalog => 'एनालॉग';

  @override
  String get faceSplit => 'बड़ा';

  @override
  String get faceDay => 'दिन';

  @override
  String get tooltipCustomize => 'कस्टमाइज़ करें';

  @override
  String get clockSettingsTitle => 'घड़ी कस्टमाइज़ करें';

  @override
  String get clockFaceTitle => 'डिज़ाइन';

  @override
  String get clockShowSeconds => 'सेकंड दिखाएँ';

  @override
  String get clockShowDate => 'तारीख़ दिखाएँ';

  @override
  String get clockBlinkColon => 'टिमटिमाता कोलन';

  @override
  String get clockKeepAwake => 'स्क्रीन चालू रखें';

  @override
  String get clockKeepAwakeHint => 'जब तक घड़ी दिख रही हो।';

  @override
  String get clockFullscreenHint =>
      'हमेशा चालू रहने वाली डेस्क घड़ी के लिए फ़ुल स्क्रीन दबाएँ। डिज़ाइन बदलने के लिए घड़ी को स्वाइप करें।';

  @override
  String clockDayPercent(int percent) {
    return 'दिन का $percent%';
  }

  @override
  String get ringDismiss => 'बंद करें';

  @override
  String ringSnooze(int minutes) {
    return '$minutes मिनट स्नूज़';
  }

  @override
  String get timerStart => 'शुरू करें';

  @override
  String get timerPause => 'रोकें';

  @override
  String get timerResume => 'फिर शुरू करें';

  @override
  String get timerReset => 'रीसेट';

  @override
  String get timerAddMinute => '+1 मिनट';

  @override
  String get timerHoursShort => 'घं';

  @override
  String get timerMinutesShort => 'मि';

  @override
  String get timerSecondsShort => 'से';

  @override
  String get timerUpTitle => 'समय पूरा हुआ';

  @override
  String timerUpBody(String duration) {
    return '$duration का टाइमर खत्म हो गया।';
  }

  @override
  String get timerSavePreset => 'यह समय सहेजें';

  @override
  String get timerPresetHint =>
      'यह समय सहेजने के लिए + दबाएँ। किसी प्रीसेट को हटाने के लिए उसे देर तक दबाएँ।';

  @override
  String get stopwatchStop => 'रोकें';

  @override
  String get stopwatchLap => 'लैप';

  @override
  String get stopwatchLapBest => 'सर्वश्रेष्ठ';

  @override
  String get stopwatchLapWorst => 'सबसे धीमा';

  @override
  String get worldLocal => 'स्थानीय समय';

  @override
  String get worldToday => 'आज';

  @override
  String get worldTomorrow => 'कल';

  @override
  String get worldYesterday => 'बीता कल';

  @override
  String get worldAdd => 'शहर जोड़ें';

  @override
  String get worldSearch => 'शहर खोजें';

  @override
  String get worldNoResults => 'कोई शहर नहीं मिला।';

  @override
  String get worldEdit => 'सूची संपादित करें';

  @override
  String get worldDone => 'हो गया';

  @override
  String get worldRemove => 'हटाएँ';

  @override
  String get worldEmpty => 'अभी कोई और शहर नहीं है। जोड़ने के लिए + दबाएँ।';

  @override
  String get worldSameTime => 'आपके जितना ही समय';

  @override
  String worldDiffAhead(String diff) {
    return 'आपसे $diff आगे';
  }

  @override
  String worldDiffBehind(String diff) {
    return 'आपसे $diff पीछे';
  }

  @override
  String alarmNext(String duration) {
    return 'अगला अलार्म $duration में';
  }

  @override
  String get alarmNone => 'कोई अलार्म चालू नहीं';

  @override
  String get alarmNew => 'नया अलार्म';

  @override
  String get alarmEditTitle => 'अलार्म संपादित करें';

  @override
  String get alarmLabel => 'लेबल';

  @override
  String get alarmRepeat => 'दोहराएँ';

  @override
  String get alarmSave => 'सहेजें';

  @override
  String get alarmDelete => 'अलार्म हटाएँ';

  @override
  String get alarmConfirmDelete => 'पुष्टि करें: अलार्म हटाएँ';

  @override
  String get alarmDeleteHint => 'यह अलार्म हटा दिया जाएगा।';

  @override
  String get alarmEmpty => 'अभी कोई अलार्म नहीं है।\nबनाने के लिए + दबाएँ।';

  @override
  String get alarmEveryDay => 'हर दिन';

  @override
  String get alarmWeekdays => 'सप्ताह के दिन';

  @override
  String get alarmWeekends => 'सप्ताहांत';

  @override
  String get alarmOnce => 'एक बार';

  @override
  String get alarmPermissionHint =>
      'ऐप बंद होने पर भी बजने के लिए Enfo को सूचनाएँ भेजने और सटीक अलार्म लगाने की अनुमति चाहिए।';

  @override
  String get alarmPermissionButton => 'अलार्म की अनुमति दें';

  @override
  String get alarmDesktopHint =>
      'इस डिवाइस पर अलार्म बजने के लिए Enfo का खुला रहना ज़रूरी है।';

  @override
  String get hapticsTitle => 'कंपन';

  @override
  String get hapticsOff => 'बंद';

  @override
  String get hapticsStrength => 'तीव्रता';

  @override
  String get hapticsSoft => 'हल्का';

  @override
  String get hapticsMedium => 'मध्यम';

  @override
  String get hapticsStrong => 'तेज़';

  @override
  String get hapticsTouch => 'स्पर्श';

  @override
  String get hapticsTouchHint => 'बटन, स्विच और चयन।';

  @override
  String get hapticsMotion => 'गति';

  @override
  String get hapticsMotionHint => 'व्हील, स्लाइडर, खींचना और ट्रांज़िशन।';

  @override
  String get hapticsAlerts => 'अलर्ट';

  @override
  String get hapticsAlertsHint =>
      'टाइमर, चरण बदलाव, अंतिम उलटी गिनती और अलार्म।';

  @override
  String get hapticsAlarmPattern => 'अलार्म का पैटर्न';

  @override
  String get hapticsAlarmPatternHint =>
      'महसूस करने के लिए किसी पैटर्न को दबाएँ। अलार्म स्क्रीन उसी लय में धड़कती है।';

  @override
  String get hapticsPatternHeartbeat => 'दिल की धड़कन';

  @override
  String get hapticsPatternPulse => 'नब्ज़';

  @override
  String get hapticsPatternCrescendo => 'क्रेशेंडो';

  @override
  String get hapticsPatternRipple => 'तरंगें';

  @override
  String get hapticsPatternBeacon => 'प्रकाशस्तंभ';

  @override
  String get hapticsTry => 'आज़माएँ';

  @override
  String get hapticsTryTap => 'टैप';

  @override
  String get hapticsTrySuccess => 'सफलता';

  @override
  String get hapticsTryToRest => 'फ़ोकस पूरा';

  @override
  String get hapticsTryToWork => 'आराम पूरा';

  @override
  String get hapticsTryTimer => 'टाइमर पूरा';

  @override
  String get hapticsTryWarning => 'चेतावनी';

  @override
  String get hapticsUnavailable => 'इस डिवाइस में वाइब्रेशन मोटर नहीं है।';

  @override
  String get hapticsWhen => 'कंपन कब होता है';

  @override
  String get widgetsTitle => 'विजेट';

  @override
  String get widgetsSubtitle => 'आपकी होम स्क्रीन पर घड़ियाँ और टाइमर';

  @override
  String get widgetsAddHeader => 'होम स्क्रीन पर जोड़ें';

  @override
  String get widgetsAdd => 'जोड़ें';

  @override
  String get widgetsDynamicColor => 'Material You रंग';

  @override
  String get widgetsDynamicColorHint =>
      'विजेट अपने रंग आपके वॉलपेपर से लेते हैं। Enfo का एक्सेंट रंग इस्तेमाल करने के लिए इसे बंद करें।';

  @override
  String get widgetsManualHint =>
      'आपका लॉन्चर यहाँ से विजेट जोड़ने नहीं देता। होम स्क्रीन को देर तक दबाएँ, विजेट चुनें और Enfo खोजें।';

  @override
  String get widgetsStyleHint =>
      'पोमोडोरो और टाइमर विजेट आपकी चुनी घड़ी की शैली में बनते हैं। ऐप में शैली बदलें, वे भी बदल जाएँगे।';

  @override
  String get widgetsTapHint =>
      'विजेट के बटन Enfo खोलकर क्रिया करते हैं, ताकि समय हमेशा ऐप ही संभाले।';

  @override
  String get shortcutsTitle => 'कीबोर्ड और रिमोट';

  @override
  String get shortcutsSubtitle => 'कीबोर्ड, माउस और टीवी रिमोट के शॉर्टकट';

  @override
  String get shortcutsIntro =>
      'तीर कुंजियाँ या रिमोट का D-pad घुमाते हैं, Enter या OK दबाता है। बाकी काम ये कुंजियाँ करती हैं।';

  @override
  String get shortcutKeySpace => 'स्पेस';

  @override
  String get shortcutPlayPause => 'शुरू करें या रोकें';

  @override
  String get shortcutReset => 'रीसेट';

  @override
  String get shortcutLap => 'लैप (स्टॉपवॉच)';

  @override
  String get shortcutJumpMode => 'मोड 1–9 पर जाएँ';

  @override
  String get shortcutStepMode => 'पिछला / अगला मोड';

  @override
  String get shortcutFullscreen => 'फ़ुल स्क्रीन';

  @override
  String get shortcutDim => 'स्क्रीन धीमी करें (फ़ुल स्क्रीन)';

  @override
  String get shortcutSettings => 'सेटिंग्स';

  @override
  String get shortcutModes => 'मोड मेनू';

  @override
  String get shortcutBack => 'पीछे / फ़ुल स्क्रीन से बाहर';

  @override
  String get shortcutHelp => 'यह सूची दिखाएँ';

  @override
  String get onbMoreTools => 'और टूल';

  @override
  String get modeEvent => 'इवेंट';

  @override
  String get modeDescEvent => 'ज़रूरी दिन तक गिनती';

  @override
  String get modeIntervals => 'इंटरवल';

  @override
  String get modeDescIntervals => 'काम और आराम के राउंड, HIIT जैसे';

  @override
  String get modeBreathe => 'साँस';

  @override
  String get modeDescBreathe => 'शांत होने के लिए निर्देशित साँस';

  @override
  String get modeTracker => 'ट्रैकर';

  @override
  String get modeDescTracker => 'अपने काम का समय नापें, कुल देखें';

  @override
  String get modeKitchen => 'रसोई';

  @override
  String get modeDescKitchen => 'एक साथ कई नामित टाइमर';

  @override
  String get modeSleep => 'नींद';

  @override
  String get modeDescSleep => 'नींद के चक्रों में सोना-जागना तय करें';

  @override
  String get modeVersus => 'बारी';

  @override
  String get modeDescVersus => 'शतरंज, खेल और बहस के लिए दो-खिलाड़ी घड़ी';

  @override
  String get modeBreaks => 'ब्रेक';

  @override
  String get modeDescBreaks => 'आँखों को आराम और स्ट्रेच की याद';

  @override
  String get modeAmbient => 'परिवेश';

  @override
  String get modeDescAmbient => 'स्लीप टाइमर के साथ बैकग्राउंड ध्वनियाँ';

  @override
  String get intervalsPresetTabata => 'ताबाता';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'कस्टम';

  @override
  String get intervalsWarmUp => 'वार्म-अप';

  @override
  String get intervalsWork => 'कसरत';

  @override
  String get intervalsRest => 'आराम';

  @override
  String get intervalsRounds => 'राउंड';

  @override
  String get intervalsCoolDown => 'कूल-डाउन';

  @override
  String get intervalsOff => 'बंद';

  @override
  String intervalsRound(int current, int total) {
    return 'राउंड $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return 'कुल $duration';
  }

  @override
  String get intervalsSkip => 'अगले चरण पर जाएँ';

  @override
  String get intervalsHint =>
      'किसी पंक्ति को बदलने के लिए उसे छुएँ। हर बदलाव कस्टम के रूप में सहेजा जाता है।';

  @override
  String get intervalsDoneTitle => 'वर्कआउट पूरा हुआ';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration। बहुत बढ़िया!';
  }

  @override
  String get kitchenPasta => 'पास्ता';

  @override
  String get kitchenEggs => 'अंडे';

  @override
  String get kitchenTea => 'चाय';

  @override
  String get kitchenRice => 'चावल';

  @override
  String get kitchenOven => 'ओवन';

  @override
  String get kitchenCustom => 'अन्य';

  @override
  String get kitchenNameHint => 'नाम';

  @override
  String get kitchenAdd => 'टाइमर शुरू करें';

  @override
  String get kitchenDelete => 'टाइमर हटाएँ';

  @override
  String get kitchenEmpty =>
      'अभी कोई टाइमर नहीं। शुरू करने के लिए ऊपर से चुनें।';

  @override
  String get kitchenDefaultName => 'टाइमर';

  @override
  String kitchenDoneTitle(String name) {
    return '$name तैयार है';
  }

  @override
  String kitchenDoneBody(String duration) {
    return '$duration का टाइमर पूरा हुआ।';
  }

  @override
  String get trackerToday => 'आज';

  @override
  String get trackerWeek => 'पिछले 7 दिन';

  @override
  String get trackerTapToStart =>
      'समय मापना शुरू करने के लिए किसी गतिविधि को टैप करें';

  @override
  String get trackerNoRunning => 'कुछ नहीं चल रहा';

  @override
  String get trackerAddActivity => 'नई गतिविधि';

  @override
  String get trackerNameHint => 'नाम';

  @override
  String get trackerStudy => 'पढ़ाई';

  @override
  String get trackerReading => 'पठन';

  @override
  String get trackerCode => 'कोडिंग';

  @override
  String get trackerExercise => 'व्यायाम';

  @override
  String get trackerEdit => 'गतिविधि संपादित करें';

  @override
  String get trackerDetails => 'विवरण और चार्ट';

  @override
  String get trackerColor => 'रंग';

  @override
  String get trackerIcon => 'आइकन';

  @override
  String get trackerDelete => 'गतिविधि हटाएँ';

  @override
  String get trackerDeleteConfirm => 'पुष्टि करें: गतिविधि हटाएँ';

  @override
  String get trackerDeleteHint => 'पहले दर्ज समय इतिहास में बना रहेगा।';

  @override
  String get trackerAddTime => 'समय मैन्युअल जोड़ें';

  @override
  String trackerAddMinutes(int minutes) {
    return '$minutes मिनट जोड़ें';
  }

  @override
  String get trackerMinutesFewer => 'कम मिनट';

  @override
  String get trackerMinutesMore => 'अधिक मिनट';

  @override
  String get trackerStop => 'रोकें';

  @override
  String get versusDuel => 'द्वंद्व';

  @override
  String get versusSpeakers => 'वक्ता';

  @override
  String get versusCustom => 'कस्टम';

  @override
  String get versusIncrement => 'वृद्धि';

  @override
  String get versusTapToStart => 'अपनी घड़ी शुरू करने के लिए अपनी तरफ टैप करें';

  @override
  String get versusTimeIsUp => 'समय समाप्त';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालें',
      one: '1 चाल',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => 'खेल रीसेट करें';

  @override
  String get versusConfirmReset => 'रीसेट की पुष्टि करें';

  @override
  String versusSpeakerN(int n) {
    return 'वक्ता $n';
  }

  @override
  String get versusAddSpeaker => 'वक्ता जोड़ें';

  @override
  String get versusRemoveSpeaker => 'वक्ता हटाएँ';

  @override
  String get versusSpeakerName => 'वक्ता या विषय';

  @override
  String get versusNext => 'अगला वक्ता';

  @override
  String get versusFinish => 'समाप्त';

  @override
  String get versusOvertime => 'अतिरिक्त समय';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$planned में से $elapsed';
  }

  @override
  String get versusAgendaDone => 'एजेंडा पूरा';

  @override
  String get versusStartAgenda => 'एजेंडा शुरू करें';

  @override
  String get versusMinutesFewer => 'कम मिनट';

  @override
  String get versusMinutesMore => 'अधिक मिनट';

  @override
  String get versusTotal => 'कुल';

  @override
  String get breatheInhale => 'साँस लें';

  @override
  String get breatheHold => 'रोकें';

  @override
  String get breatheExhale => 'साँस छोड़ें';

  @override
  String get breatheStart => 'शुरू करें';

  @override
  String get breathePause => 'रोकें';

  @override
  String get breatheResume => 'जारी रखें';

  @override
  String get breatheReset => 'सत्र समाप्त करें';

  @override
  String get breatheDone => 'बहुत बढ़िया';

  @override
  String get breatheReady => 'आराम से बैठ जाएँ';

  @override
  String get breathePatternBox => 'बॉक्स';

  @override
  String get breathePatternCoherent => 'सुसंगत';

  @override
  String get breathePatternCalm => 'शांत';

  @override
  String get breathePatternCustom => 'कस्टम';

  @override
  String get breatheSession => 'अवधि';

  @override
  String get breatheEndless => 'अनंत';

  @override
  String breatheSeconds(int n) {
    return '$n से';
  }

  @override
  String get ambientWhite => 'व्हाइट नॉइज़';

  @override
  String get ambientPink => 'पिंक नॉइज़';

  @override
  String get ambientBrown => 'ब्राउन नॉइज़';

  @override
  String get ambientRain => 'बारिश';

  @override
  String get ambientWind => 'हवा';

  @override
  String get ambientOcean => 'समुद्र';

  @override
  String get ambientVolume => 'वॉल्यूम';

  @override
  String get ambientSleepTimer => 'स्लीप टाइमर';

  @override
  String get ambientTimerOff => 'बंद';

  @override
  String get ambientPlay => 'ध्वनि चलाएँ';

  @override
  String get ambientStop => 'ध्वनि रोकें';

  @override
  String get ambientUnavailable => 'इस डिवाइस पर ध्वनि उपलब्ध नहीं है।';

  @override
  String get ambientPreparing => 'ध्वनि तैयार हो रही है…';

  @override
  String ambientTimeLeft(String time) {
    return '$time शेष';
  }

  @override
  String get breaksStart => 'ब्रेक शुरू करें';

  @override
  String get breaksStop => 'ब्रेक बंद करें';

  @override
  String get breaksStatusOff => 'ब्रेक रिमाइंडर बंद हैं';

  @override
  String get breaksNoneEnabled => 'कम से कम एक रिमाइंडर चालू करें';

  @override
  String breaksNextName(String name) {
    return 'अगला: $name';
  }

  @override
  String get breaksToday => 'आज';

  @override
  String get breaksTaken => 'लिए गए ब्रेक';

  @override
  String get breaksSkipped => 'छोड़े गए';

  @override
  String get breaksEyeName => 'आँखों का आराम (20-20-20)';

  @override
  String get breaksEyeHint => '20 सेकंड तक 6 मीटर दूर किसी चीज़ को देखें';

  @override
  String get breaksStretchName => 'स्ट्रेच';

  @override
  String get breaksStretchHint => 'खड़े होकर पूरे शरीर को स्ट्रेच करें';

  @override
  String get breaksWaterName => 'पानी पिएँ';

  @override
  String get breaksWaterHint => 'एक गिलास पानी पिएँ';

  @override
  String get breaksPostureName => 'बैठने की मुद्रा जाँचें';

  @override
  String get breaksPostureHint => 'सीधे बैठें और कंधों को ढीला छोड़ें';

  @override
  String get breaksCustomDefault => 'मेरा रिमाइंडर';

  @override
  String breaksForDuration(String duration) {
    return '$duration का समय लें';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return 'हर $minutes मिनट';
  }

  @override
  String get breaksShorter => 'कम अंतराल';

  @override
  String get breaksLonger => 'लंबा अंतराल';

  @override
  String get breaksDone => 'हो गया';

  @override
  String get breaksSkip => 'छोड़ें';

  @override
  String get breaksActiveHours => 'सक्रिय समय';

  @override
  String get breaksActiveHoursHint => 'रिमाइंडर केवल इसी समय के बीच आएँगे';

  @override
  String get breaksFrom => 'से';

  @override
  String get breaksTo => 'तक';

  @override
  String get breaksLaterHour => 'बाद में';

  @override
  String get breaksEarlierHour => 'पहले';

  @override
  String get breaksBackground => 'Enfo बंद होने पर भी';

  @override
  String get breaksBackgroundOn =>
      'ऐप बंद होने पर भी नोटिफ़िकेशन याद दिलाएँगे।';

  @override
  String get breaksBackgroundOff => 'रिमाइंडर केवल Enfo खुला होने पर दिखेंगे।';

  @override
  String get breaksDesktopNotice =>
      'Enfo चलते रहने पर रिमाइंडर दिखेंगे (मिनिमाइज़ रह सकता है)।';

  @override
  String get breaksAddCustom => 'अपना रिमाइंडर जोड़ें';

  @override
  String get breaksEdit => 'रिमाइंडर संपादित करें';

  @override
  String get breaksName => 'नाम';

  @override
  String get breaksDuration => 'अवधि';

  @override
  String get breaksIcon => 'आइकन';

  @override
  String get breaksShorterDuration => 'छोटा ब्रेक';

  @override
  String get breaksLongerDuration => 'लंबा ब्रेक';

  @override
  String get breaksRemove => 'रिमाइंडर हटाएँ';

  @override
  String get breaksRemoveConfirm => 'पुष्टि करें: रिमाइंडर हटाएँ';

  @override
  String get breaksRemoveHint => 'यह याद दिलाना बंद कर देगा।';

  @override
  String get worldPlan => 'मीटिंग की योजना बनाएँ';

  @override
  String get worldPlanIntro => 'सबके लिए सही समय खोजने के लिए मार्कर खिसकाएँ।';

  @override
  String get worldPlanNow => 'अभी';

  @override
  String get worldPlanEarlier => '15 मिनट पहले';

  @override
  String get worldPlanLater => '15 मिनट बाद';

  @override
  String worldPlanSelected(String city) {
    return '$city में चुना गया समय';
  }

  @override
  String get worldPlanTapCity => 'किसी शहर पर टैप करके उसका समय संदर्भ बनाएँ।';

  @override
  String get worldPlanNextDay => '+1 दिन';

  @override
  String get worldPlanPrevDay => '-1 दिन';

  @override
  String get worldPlanOverlapTitle => 'सभी काम के घंटों में हैं';

  @override
  String get worldPlanNoOverlap =>
      'अगले 24 घंटों में कोई समय सबके लिए ठीक नहीं है।';

  @override
  String worldPlanLeastBad(String time) {
    return 'सबसे कम बुरा: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$total में से $count काम के घंटों में';
  }

  @override
  String get worldPlanWork => 'कार्य समय (09-18)';

  @override
  String get worldPlanNight => 'रात';

  @override
  String get worldPlanMarker => 'चुना गया समय';

  @override
  String get eventAdd => 'नया इवेंट';

  @override
  String get eventEdit => 'इवेंट संपादित करें';

  @override
  String get eventName => 'नाम';

  @override
  String get eventNameHint => 'जन्मदिन, यात्रा, लॉन्च...';

  @override
  String get eventYearly => 'हर साल दोहराएँ';

  @override
  String get eventYearlyHint =>
      'जन्मदिन और सालगिरह के लिए: अपने आप अगले पर चला जाता है।';

  @override
  String get eventNotify => 'मुझे सूचित करें';

  @override
  String get eventNotifyHint => 'जैसे ही वह समय आए।';

  @override
  String get eventDayBefore => 'एक दिन पहले भी';

  @override
  String get eventSave => 'सहेजें';

  @override
  String get eventDelete => 'इवेंट हटाएँ';

  @override
  String get eventConfirmDelete => 'पुष्टि करें: इवेंट हटाएँ';

  @override
  String get eventDeleteHint => 'यह इवेंट हटा दिया जाएगा।';

  @override
  String get eventEmpty =>
      'अभी कोई इवेंट नहीं है।\nकाउंटडाउन शुरू करने के लिए + दबाएँ।';

  @override
  String get eventToday => 'आज!';

  @override
  String eventDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String get eventDaysShort => 'दि';

  @override
  String get eventUnitDays => 'दिन';

  @override
  String get eventUnitHours => 'घंटे';

  @override
  String get eventUnitMinutes => 'मिनट';

  @override
  String get eventRepeatsYearly => 'हर साल';

  @override
  String get eventNotifyNow => 'समय हो गया!';

  @override
  String get eventNotifyTomorrow => 'कल';

  @override
  String get sleepPlanWake => 'जागना';

  @override
  String get sleepPlanBed => 'सोना';

  @override
  String get sleepPlanNow => 'अभी सोएँ';

  @override
  String get sleepTitleWake => 'मैं इस समय जागना चाहता हूँ';

  @override
  String get sleepTitleBed => 'मैं इस समय सोने जाता हूँ';

  @override
  String sleepTitleNow(String time) {
    return 'अगर मैं अभी सो जाऊँ ($time)';
  }

  @override
  String get sleepBedtimeWord => 'सोने का समय';

  @override
  String get sleepWakeWord => 'जागना';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles चक्र · $duration की नींद';
  }

  @override
  String get sleepNote =>
      'हर चक्र 90 मिनट का होता है और नींद आने में लगभग 15 मिनट लगते हैं। पाँच या छह चक्र सुझाए जाते हैं।';

  @override
  String get sleepWindDown => 'आराम करने की याद दिलाएँ';

  @override
  String get sleepWindDownHint => 'सोने से 30 मिनट पहले एक अलार्म।';

  @override
  String get sleepWindDownPassed => 'वह समय बीत चुका है।';

  @override
  String get sleepWindDownLabel => 'आराम करने का समय';

  @override
  String get sleepAlarmLabel => 'जागने का समय';

  @override
  String get sleepSetAlarm => 'अलार्म लगाएँ';

  @override
  String get sleepRemoveAlarm => 'अलार्म हटाएँ';

  @override
  String sleepAlarmSet(String time) {
    return 'अलार्म $time के लिए लगा है';
  }

  @override
  String get sleepPast => 'यह समय बीत चुका है';

  @override
  String get sleepRecommended => 'अनुशंसित';

  @override
  String get ambientMusicTabSounds => 'ध्वनियाँ';

  @override
  String get ambientMusicTab => 'संगीत';

  @override
  String get ambientMusicPlay => 'संगीत चलाएँ';

  @override
  String get ambientMusicPause => 'संगीत रोकें';

  @override
  String get ambientMusicNext => 'अगला गाना';

  @override
  String get ambientMusicPrevious => 'पिछला गाना';

  @override
  String get ambientMusicShuffle => 'शफ़ल';

  @override
  String get ambientMusicRepeat => 'सब दोहराएँ';

  @override
  String get ambientMusicVolume => 'संगीत की आवाज़';

  @override
  String get ambientMusicCredits => 'संगीत और परिवेश श्रेय';

  @override
  String get ambientMusicCreditsNote =>
      'Wikimedia Commons और Open Lo-Fi संग्रह के गाने, और Wikimedia Commons के परिवेश — CC0, सार्वजनिक डोमेन या Creative Commons Attribution लाइसेंस के अंतर्गत।';

  @override
  String get modeMusic => 'संगीत';

  @override
  String get modeDescMusic => 'ध्यान लगाने के लिए लो-फाई गाने';

  @override
  String get musicCreditsSubtitle => 'कलाकार और लाइसेंस';

  @override
  String get displayMenuButtons => 'मेनू बटन';

  @override
  String get displayMenuButtonsHint =>
      'चुनें कि निचले मेनू में कौन से बटन दिखें। सेटिंग्स हमेशा रहेगी।';

  @override
  String get onbWelcomeTitle => 'Enfo में आपका स्वागत है';

  @override
  String get onbWelcomeTagline => 'फ़ोकस, एक शांत डायल में।';

  @override
  String get timerRunningTitle => 'टाइमर चल रहा है';

  @override
  String timerRunningBody(String time) {
    return '$time पर समाप्त';
  }

  @override
  String get timerPausedTitle => 'टाइमर रुका हुआ';

  @override
  String timerPausedBody(String duration) {
    return '$duration शेष';
  }

  @override
  String get musicActionPlay => 'चलाएँ';

  @override
  String get musicActionPause => 'रोकें';

  @override
  String get widgetsFocusSubtitle =>
      'आज का फ़ोकस समय और पोमोडोरो, एक नज़र में।';

  @override
  String get ambienceStream => 'धारा';

  @override
  String get ambienceSnowmelt => 'हिम-पिघलाव';

  @override
  String get ambienceRivulet => 'छोटी धारा';

  @override
  String get ambienceFountain => 'फ़व्वारा';

  @override
  String get ambiencePlazaFountain => 'चौक का फ़व्वारा';

  @override
  String get ambienceGeyser => 'गीज़र';

  @override
  String get ambienceBubblingGeyser => 'बुदबुदाता गीज़र';

  @override
  String get ambienceRainWindow => 'खिड़की पर बारिश';

  @override
  String get ambienceRainThunder => 'बारिश और गड़गड़ाहट';

  @override
  String get ambienceThunderstorm => 'आंधी-तूफ़ान';

  @override
  String get ambienceThunderbolts => 'बिजली की कड़क';

  @override
  String get ambienceStormWind => 'तूफ़ानी हवा';

  @override
  String get ambienceForest => 'जंगल';

  @override
  String get ambienceForestBirds => 'पक्षियों वाला जंगल';

  @override
  String get ambienceDawnChorus => 'भोर का कलरव';

  @override
  String get ambienceCountryDawn => 'गाँव की भोर';

  @override
  String get ambiencePondDusk => 'साँझ का तालाब';

  @override
  String get ambienceMorningBirds => 'सुबह के पक्षी';

  @override
  String get ambienceCampfire => 'अलाव';

  @override
  String get ambienceFireplace => 'अंगीठी';

  @override
  String get ambienceLibrary => 'पुस्तकालय';

  @override
  String get ambienceBusyLibrary => 'भीड़भाड़ वाला पुस्तकालय';

  @override
  String get ambienceOffice => 'कार्यालय';

  @override
  String get ambienceClassroom => 'कक्षा';

  @override
  String get ambienceCafeteria => 'कैफ़ेटेरिया';

  @override
  String get ambienceRestaurant => 'रेस्तराँ';

  @override
  String get ambienceSupermarket => 'सुपरमार्केट';

  @override
  String get ambienceShoppingMall => 'शॉपिंग मॉल';

  @override
  String get ambienceRainyStreet => 'बरसाती सड़क';

  @override
  String get ambienceSpringStreet => 'वसंत की सड़क';

  @override
  String get ambienceSubway => 'मेट्रो';

  @override
  String get ambienceSubwayRide => 'मेट्रो की सवारी';

  @override
  String get ambienceStationTunnel => 'स्टेशन सुरंग';

  @override
  String get ambienceTrain => 'ट्रेन';

  @override
  String get ambienceTaiwanTrain => 'ताइवान ट्रेन';

  @override
  String get ambienceEscalator => 'एस्केलेटर';

  @override
  String get ambienceElevator => 'लिफ़्ट';

  @override
  String get ambiencePlayground => 'खेल का मैदान';

  @override
  String get ambienceStreetMarket => 'सड़क बाज़ार';

  @override
  String get ambienceKeyboard => 'कीबोर्ड';

  @override
  String get ambientNature => 'प्रकृति';

  @override
  String get ambientPlaces => 'स्थान';

  @override
  String get breaksRelaxSound => 'ब्रेक ध्वनि';
}
