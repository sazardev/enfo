// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => '설정';

  @override
  String get tooltipStats => '통계';

  @override
  String get tooltipPin => '항상 위에 표시';

  @override
  String get tooltipUnpin => '항상 위에 표시 해제';

  @override
  String get phasePaused => '일시정지';

  @override
  String get phaseFocus => '집중';

  @override
  String get phaseRelax => '휴식';

  @override
  String get notifRestTitle => '쉬어 갈 시간이에요';

  @override
  String get notifRestBody => '잠시 숨을 돌리세요.';

  @override
  String get notifWorkTitle => '일할 시간이에요';

  @override
  String get notifWorkBody => '다시 힘내 볼까요!';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get rhythmTitle => '집중 리듬';

  @override
  String get presetClassic => '클래식';

  @override
  String get presetExtended => '확장';

  @override
  String get presetDeep => '딥';

  @override
  String get presetManual => '직접 설정';

  @override
  String get workLabel => '집중';

  @override
  String get restLabel => '휴식';

  @override
  String minutes(int n) {
    return '$n분';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest분';
  }

  @override
  String get settingsTitle => '설정';

  @override
  String get timersTitle => '시간';

  @override
  String timersSubtitle(int work, int rest) {
    return '집중 $work분 · 휴식 $rest분';
  }

  @override
  String timersCycle(int total) {
    return '한 사이클: $total분';
  }

  @override
  String get timersApplyHint =>
      '타이머가 실행 중이면 다음 사이클부터 적용돼요. 일시정지 상태면 타이머가 초기화돼요.';

  @override
  String get appearanceTitle => '화면 스타일';

  @override
  String get appearanceLight => '라이트 테마';

  @override
  String get appearanceDark => '다크 테마';

  @override
  String get darkTheme => '다크 테마';

  @override
  String get themeModeSystem => '시스템';

  @override
  String get themeModeLight => '라이트';

  @override
  String get themeModeDark => '다크';

  @override
  String get accentColor => '강조 색상';

  @override
  String get notificationsTitle => '알림';

  @override
  String get notificationsOn => '켜짐';

  @override
  String get notificationsOff => '꺼짐';

  @override
  String get notificationsToggle => '단계가 바뀔 때 알림';

  @override
  String get notificationsHint => '휴식하거나 다시 일할 시간이 되면 알려 드려요.';

  @override
  String get languageTitle => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get languageHint => '앱 언어를 선택하세요.';

  @override
  String get supportTitle => 'Enfo 후원하기';

  @override
  String get supportSubtitleNoAds => '후원과 커피';

  @override
  String get buyCoffee => '커피 한 잔 사주기';

  @override
  String get supportHint => 'Enfo는 무료이며 한 사람이 만들고 있어요. 사용해 주셔서 감사합니다.';

  @override
  String get rateApp => 'Enfo 평가하기';

  @override
  String get shareApp => 'Enfo 공유하기';

  @override
  String shareMessage(String url) {
    return 'Enfo — Android용 차분한 시계·타이머 도구 상자: $url';
  }

  @override
  String get donateTitle => '후원하기';

  @override
  String get donateSubtitle => 'Google Play로 1회 결제';

  @override
  String get donateHint =>
      'Enfo는 무료이고 광고도 없습니다. 응원하고 싶다면 Google Play로 1회 후원할 수 있어요. 감사합니다!';

  @override
  String get donateUnavailable => '지금은 후원을 이용할 수 없습니다. 커피 한 잔 사주기는 가능해요.';

  @override
  String get donateThanks => 'Enfo를 후원해 주셔서 감사합니다!';

  @override
  String get donatePending => '결제 대기 중…';

  @override
  String get donateError => '결제를 완료하지 못했습니다. 청구되지 않았습니다.';

  @override
  String get statsTitle => '통계';

  @override
  String get statsEmpty => '아직 세션이 없어요.\n뽀모도로를 시작하면 여기에 표시돼요.';

  @override
  String get statsTodayPomodoros => '오늘의 뽀모도로';

  @override
  String get statsTodayFocus => '오늘의 집중';

  @override
  String get statsCompleted => '완료';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '일 연속',
      one: '일 연속',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => '최근 7일';

  @override
  String get statsTotalFocus => '총 집중 시간';

  @override
  String get statsTotalRest => '총 휴식 시간';

  @override
  String get statsAbandoned => '중단됨';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent% 완료';
  }

  @override
  String get statsAverageFocus => '평균 집중 시간';

  @override
  String get statsLongestSession => '가장 긴 세션';

  @override
  String get statsPauses => '일시정지';

  @override
  String get statsAverageGap => '세션 간 평균 대기 시간';

  @override
  String get statsLongestGap => '가장 오래 쉰 시간';

  @override
  String get statsSinceLast => '마지막 세션 이후';

  @override
  String get statsHistory => '기록';

  @override
  String get statsClearHistory => '기록 삭제';

  @override
  String get statsClearConfirm => '확인: 모든 세션 삭제';

  @override
  String get statsClearHint => '이 작업은 되돌릴 수 없어요.';

  @override
  String get cancel => '취소';

  @override
  String get sessionFocus => '집중';

  @override
  String get sessionRest => '휴식';

  @override
  String sessionProgress(String done, String planned) {
    return '$done/$planned';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '일시정지 $count회',
      one: '일시정지 1회',
    );
    return '$_temp0 ($time)';
  }

  @override
  String sessionIdleBefore(String gap) {
    return '$gap 쉰 후';
  }

  @override
  String get sessionCompleted => '완료';

  @override
  String get sessionAbandoned => '중단됨';

  @override
  String get clockStyleTitle => '시계 스타일';

  @override
  String get tooltipClockStyle => '시계 스타일';

  @override
  String get clockCategoryProgress => '진행률과 숫자';

  @override
  String get clockCategoryNumbers => '숫자만';

  @override
  String get clockCategoryIcons => '아이콘만';

  @override
  String get clockCategoryMotion => '애니메이션만';

  @override
  String get clockUnitMinutes => '분';

  @override
  String get clockUnitSeconds => '초';

  @override
  String get clockRing => '링';

  @override
  String get clockWavyRing => '물결 링';

  @override
  String get clockSegments => '세그먼트';

  @override
  String get clockOrbit => '궤도';

  @override
  String get clockPie => '파이';

  @override
  String get clockKitchen => '주방';

  @override
  String get clockDots => '점';

  @override
  String get clockBar => '바';

  @override
  String get clockWavyBar => '물결 바';

  @override
  String get clockDigits => '숫자';

  @override
  String get clockMinutes => '분';

  @override
  String get clockTiles => '타일';

  @override
  String get clockStack => '스택';

  @override
  String get clockTomato => '토마토';

  @override
  String get clockHourglass => '모래시계';

  @override
  String get clockBattery => '배터리';

  @override
  String get clockIcon => '아이콘';

  @override
  String get clockCookie => '쿠키';

  @override
  String get clockLiquid => '액체';

  @override
  String get clockBreathe => '호흡';

  @override
  String get clockEqualizer => '이퀄라이저';

  @override
  String get clockRipple => '파문';

  @override
  String get accentApply => '적용';

  @override
  String get accentCustom => '사용자 지정 색상';

  @override
  String get accentHue => '색조';

  @override
  String get accentSaturation => '채도';

  @override
  String get accentBrightness => '밝기';

  @override
  String get accentHex => '16진수 코드';

  @override
  String get displayTitle => '화면';

  @override
  String get displayClockShown => '시간 표시';

  @override
  String get displayClockHidden => '시간 숨김';

  @override
  String get showClock => '시간 표시';

  @override
  String get showClockHint => '타이머 위에 표시되는 작은 시계예요.';

  @override
  String get clockFormat => '시간 형식';

  @override
  String get clockFormatSystem => '시스템 기본값';

  @override
  String get clockFormat12 => '12시간';

  @override
  String get clockFormat24 => '24시간';

  @override
  String get behaviorTitle => '동작';

  @override
  String get autoStartNext => '다음 단계 자동 시작';

  @override
  String get autoStartNextHint => '집중이나 휴식이 끝나면 누르지 않아도 다음 단계가 시작돼요.';

  @override
  String get hapticFeedback => '진동';

  @override
  String get hapticFeedbackHint => '터치, 휠, 단계 전환, 알람에 반응해요.';

  @override
  String get clockCombosTitle => '콤보';

  @override
  String get clockCollapseAll => '모두 접기';

  @override
  String get clockExpandAll => '모두 펼치기';

  @override
  String get comboDeepFocus => '딥 포커스';

  @override
  String get comboMint => '상쾌한 민트';

  @override
  String get comboSunset => '노을';

  @override
  String get comboZen => '젠';

  @override
  String get comboTomato => '클래식 토마토';

  @override
  String get comboNight => '밤부엉이';

  @override
  String get comboPlayful => '장난꾸러기';

  @override
  String get comboMinimal => '미니멀';

  @override
  String get uiSizeTitle => '인터페이스 크기';

  @override
  String get uiSizeSmall => '작게';

  @override
  String get uiSizeNormal => '보통';

  @override
  String get uiSizeLarge => '크게';

  @override
  String get uiSizeExtraLarge => '매우 크게';

  @override
  String get uiSizeHint => '글자와 컨트롤을 더 크게 또는 작게 조정해요. TV나 차량 화면에서 유용해요.';

  @override
  String get clockBlob => '블롭';

  @override
  String get clockFlower => '꽃';

  @override
  String get clockSun => '태양';

  @override
  String get clockGears => '톱니바퀴';

  @override
  String get clockBubbles => '거품';

  @override
  String get clockSunflower => '해바라기';

  @override
  String get clockFireflies => '반딧불이';

  @override
  String get clockPendulum => '진자';

  @override
  String get clockBounce => '바운스';

  @override
  String get clockMorph => '모프';

  @override
  String get dataTitle => '데이터';

  @override
  String get dataSubtitle => '기록, 초기화, 소개 화면';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '저장된 기록 $count개',
      one: '저장된 기록 1개',
      zero: '저장된 활동 없음',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => '소개 화면 다시 보기';

  @override
  String get dataIntroHint => '환영 화면을 다시 보고 리듬을 새로 선택해요. 삭제되는 것은 없어요.';

  @override
  String get dataClearHistoryHint =>
      '뽀모도로, 타이머, 스톱워치, 알람, 시계 사용 시간 등 기록된 모든 활동을 삭제해요. 설정은 바뀌지 않아요.';

  @override
  String get dataConfirmClearHistory => '확인: 기록 삭제';

  @override
  String get dataResetSettings => '설정 초기화';

  @override
  String get dataResetSettingsHint =>
      '시간, 테마, 강조 색상, 언어, 모드, 화면 설정이 기본값으로 돌아가요. 기록은 유지돼요.';

  @override
  String get dataConfirmResetSettings => '확인: 설정 초기화';

  @override
  String get dataEraseAll => '모두 삭제';

  @override
  String get dataEraseAllHint => '기록과 설정을 모두 삭제하고 처음 실행했을 때처럼 새로 시작해요.';

  @override
  String get dataConfirmEraseAll => '확인: 모두 삭제';

  @override
  String get dataDoneHistory => '기록을 삭제했어요.';

  @override
  String get dataDoneSettings => '설정을 초기화했어요.';

  @override
  String get dataCacheNote => 'Enfo는 캐시를 저장하지 않아요. 저장되는 것은 여기에 설명된 기록과 설정뿐이에요.';

  @override
  String get clockEndsAt => '종료';

  @override
  String get clockFill => '채우기';

  @override
  String get clockCapsule => '캡슐';

  @override
  String get clockRollers => '롤러';

  @override
  String get clockMatrix => '매트릭스';

  @override
  String get clockSevenSeg => '디지털';

  @override
  String get clockFlip => '플립';

  @override
  String get clockFine => '가늘게';

  @override
  String get clockSuperscript => '위첨자';

  @override
  String get clockPercent => '퍼센트';

  @override
  String get clockEndTime => '종료 시각';

  @override
  String get clockSeconds => '초';

  @override
  String get clockTall => '길쭉하게';

  @override
  String get clockWobble => '물결 글자';

  @override
  String get clockLabeled => '라벨';

  @override
  String get clockGauge => '게이지';

  @override
  String get clockNeedle => '바늘';

  @override
  String get clockAnalog => '아날로그';

  @override
  String get clockRings => '링 여러 개';

  @override
  String get clockSquircle => '스퀴클';

  @override
  String get clockColumns => '기둥';

  @override
  String get clockVertical => '세로';

  @override
  String get clockSteps => '단계';

  @override
  String get clockBlocks => '블록';

  @override
  String get clockSpiral => '나선';

  @override
  String get clockSlices => '조각';

  @override
  String get clockPills => '알약';

  @override
  String get clockHexagon => '육각형';

  @override
  String get clockStairs => '계단';

  @override
  String get clockCandle => '양초';

  @override
  String get clockMoon => '달';

  @override
  String get clockRuler => '자';

  @override
  String get comboArcade => '아케이드';

  @override
  String get comboCalculator => '계산기';

  @override
  String get comboDepartures => '기차역';

  @override
  String get comboCandlelight => '촛불 아래';

  @override
  String get comboMoonlight => '달빛';

  @override
  String get comboGarden => '정원';

  @override
  String get comboSummer => '여름';

  @override
  String get comboWorkshop => '공방';

  @override
  String get comboFizzy => '톡톡 탄산';

  @override
  String get comboSunfield => '해바라기밭';

  @override
  String get comboSummerNight => '여름밤';

  @override
  String get comboHypnosis => '최면';

  @override
  String get comboBouncy => '통통';

  @override
  String get comboShapeshifter => '변신';

  @override
  String get comboLava => '라바 램프';

  @override
  String get comboOcean => '바다';

  @override
  String get comboPulse => '맥박';

  @override
  String get comboPond => '연못';

  @override
  String get comboEspresso => '에스프레소';

  @override
  String get comboSpeedometer => '속도계';

  @override
  String get comboCompass => '나침반';

  @override
  String get comboClassicClock => '클래식 시계';

  @override
  String get comboConcentric => '동심원';

  @override
  String get comboRounded => '둥글둥글';

  @override
  String get comboSignal => '신호';

  @override
  String get comboThermometer => '온도계';

  @override
  String get comboMilestones => '이정표';

  @override
  String get comboRetroBlocks => '레트로 블록';

  @override
  String get comboHypnoSpiral => '최면 나선';

  @override
  String get comboCitrus => '시트러스';

  @override
  String get comboChocolate => '초콜릿 바';

  @override
  String get comboCrystal => '크리스털';

  @override
  String get comboStaircase => '계단';

  @override
  String get comboTapeMeasure => '줄자';

  @override
  String get comboBoldType => '굵은 글씨';

  @override
  String get comboPill => '캡슐';

  @override
  String get comboSlotMachine => '슬롯머신';

  @override
  String get comboWhisper => '속삭임';

  @override
  String get comboDeadline => '마감';

  @override
  String get comboPercentage => '퍼센트';

  @override
  String get comboStopwatch => '초만 표시';

  @override
  String get comboSkyscraper => '마천루';

  @override
  String get comboWaveText => '물결 글자';

  @override
  String get comboDashboard => '대시보드';

  @override
  String get comboExponent => '지수';

  @override
  String get comboGrandmaKitchen => '할머니의 부엌';

  @override
  String get comboCyber => '사이버';

  @override
  String get comboCandy => '사탕';

  @override
  String get comboConfetti => '색종이';

  @override
  String get comboCookieJar => '쿠키 병';

  @override
  String get comboSandbox => '모래놀이터';

  @override
  String get comboPizzaNight => '피자 나이트';

  @override
  String get onbLanguageTitle => '언어';

  @override
  String get onbLanguageBody => '언어를 선택하세요. 여기서 고른 항목은 나중에 설정에서 바꿀 수 있어요.';

  @override
  String get onbRhythmTitle => '나만의 리듬';

  @override
  String get onbRhythmBody => '집중하고 쉬는 시간을 정해요.';

  @override
  String get onbLookTitle => '내 스타일로';

  @override
  String get onbLookBody => '테마, 시계 스타일, 색상. 조합을 고른 뒤 원하면 색을 조정하세요.';

  @override
  String get onbClockTitle => '시계 선택';

  @override
  String get onbClockBody => '시계 스타일과 포인트 색상이 어우러진 추천 조합이에요.';

  @override
  String get onbAllStyles => '모든 스타일 보기';

  @override
  String get onbOptionsTitle => '마지막 설정';

  @override
  String get onbOptionsBody => '화면과 동작 설정이에요. 설정에서도 바꿀 수 있어요.';

  @override
  String get onbModesTitle => '사용할 도구';

  @override
  String get onbModesBody =>
      'Enfo는 시계와 타이머 도구 모음입니다. 사용할 것을 켜세요. 모드 메뉴에서 언제든 바꿀 수 있습니다.';

  @override
  String get onbPreview => '미리보기';

  @override
  String get onbDisplayTitle => '화면';

  @override
  String get onbDisplayBody => '시계의 모양과 전체 크기.';

  @override
  String get onbClockModeDesign => '시계 모드 디자인';

  @override
  String get onbPermTitle => '권한';

  @override
  String get onbPermBody => 'Enfo가 꺼져 있어도 타이머와 알람이 알려 줄 수 있도록.';

  @override
  String get onbPermNotifications => '알림';

  @override
  String get onbPermNotificationsHint => '타이머가 끝나거나 알람이 울릴 때 알려 줍니다.';

  @override
  String get onbPermExact => '정확한 알람';

  @override
  String get onbPermExactHint => '절전 모드에서도 정확한 시각에 울립니다.';

  @override
  String get onbPermAllow => '허용';

  @override
  String get onbPermAllowed => '허용됨';

  @override
  String get onbPermLater => '시스템 설정에서 언제든 변경할 수 있습니다.';

  @override
  String get onbNext => '다음';

  @override
  String get onbBack => '이전';

  @override
  String get onbSkip => '건너뛰기';

  @override
  String onbStepOf(int step, int total) {
    return '$step/$total 단계';
  }

  @override
  String get clockFormatAuto => '자동';

  @override
  String get modePomodoro => '뽀모도로';

  @override
  String get modeClock => '시계';

  @override
  String get modeTimer => '타이머';

  @override
  String get modeStopwatch => '스톱워치';

  @override
  String get modeAlarm => '알람';

  @override
  String get modeWorld => '세계 시각';

  @override
  String get modeDescPomodoro => '집중과 휴식 사이클';

  @override
  String get modeDescClock => '언제나 보이는 아름다운 시계';

  @override
  String get modeDescTimer => '원하는 시간부터 카운트다운';

  @override
  String get modeDescStopwatch => '랩 기능이 있는 시간 측정';

  @override
  String get modeDescAlarm => '기상 알람과 리마인더';

  @override
  String get modeDescWorld => '세계 도시의 현재 시각';

  @override
  String get tooltipModes => '모드';

  @override
  String get tooltipSwitchMode => '다음 모드';

  @override
  String get tooltipFullscreen => '전체 화면';

  @override
  String get tooltipExitFullscreen => '전체 화면 종료';

  @override
  String get tooltipDim => '화면 어둡게';

  @override
  String get modesTitle => '모드';

  @override
  String get modesHint => '사용할 모드와 순서를 선택하세요. 끌어서 순서를 바꿀 수 있어요.';

  @override
  String get modesStart => '시작 모드';

  @override
  String get modesStartLast => '마지막으로 사용한 모드';

  @override
  String get modesCustomize => '사용자 지정';

  @override
  String get modesActivity => '활동 기록';

  @override
  String get modesAtLeastOne => '최소 하나의 모드는 켜져 있어야 해요.';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '모드 $count개 사용 중',
      one: '모드 1개 사용 중',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => '활동 기록';

  @override
  String get activityTitle => '활동';

  @override
  String get activityEmpty =>
      '아직 아무것도 없어요.\n타이머, 스톱워치, 알람 또는 시계를 사용하면 여기에 표시돼요.';

  @override
  String get activityFilterAll => '전체';

  @override
  String get activityTimersToday => '오늘의 타이머';

  @override
  String get activityStopwatchToday => '오늘의 스톱워치';

  @override
  String get activityDisplayToday => '오늘 화면 표시';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '랩 $count개',
      one: '랩 1개',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return '랩 $n';
  }

  @override
  String get activityAlarmDismissed => '해제됨';

  @override
  String get activityAlarmSnoozed => '다시 알림';

  @override
  String get activityAlarmMissed => '놓침';

  @override
  String activityDisplay(String mode) {
    return '$mode 화면 표시';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done/$planned';
  }

  @override
  String get faceRing => '링';

  @override
  String get faceDigital => '디지털';

  @override
  String get faceAnalog => '아날로그';

  @override
  String get faceSplit => '크게';

  @override
  String get faceDay => '하루';

  @override
  String get tooltipCustomize => '사용자 지정';

  @override
  String get clockSettingsTitle => '시계 사용자 지정';

  @override
  String get clockFaceTitle => '디자인';

  @override
  String get clockShowSeconds => '초 표시';

  @override
  String get clockShowDate => '날짜 표시';

  @override
  String get clockBlinkColon => '콜론 깜박임';

  @override
  String get clockKeepAwake => '화면 켜 두기';

  @override
  String get clockKeepAwakeHint => '시계가 표시되는 동안 유지돼요.';

  @override
  String get clockFullscreenHint =>
      '전체 화면을 누르면 계속 켜져 있는 탁상시계로 쓸 수 있어요. 시계를 살짝 밀어 디자인을 바꿔 보세요.';

  @override
  String clockDayPercent(int percent) {
    return '하루의 $percent%';
  }

  @override
  String get ringDismiss => '해제';

  @override
  String ringSnooze(int minutes) {
    return '$minutes분 후 다시 알림';
  }

  @override
  String get timerStart => '시작';

  @override
  String get timerPause => '일시정지';

  @override
  String get timerResume => '계속';

  @override
  String get timerReset => '초기화';

  @override
  String get timerAddMinute => '+1분';

  @override
  String get timerHoursShort => '시간';

  @override
  String get timerMinutesShort => '분';

  @override
  String get timerSecondsShort => '초';

  @override
  String get timerUpTitle => '시간이 다 됐어요';

  @override
  String timerUpBody(String duration) {
    return '$duration 타이머가 끝났어요.';
  }

  @override
  String get timerSavePreset => '이 시간 저장';

  @override
  String get timerPresetHint => '+를 눌러 이 시간을 저장하세요. 프리셋을 길게 누르면 삭제돼요.';

  @override
  String get stopwatchStop => '정지';

  @override
  String get stopwatchLap => '랩';

  @override
  String get stopwatchLapBest => '최고';

  @override
  String get stopwatchLapWorst => '최저';

  @override
  String get worldLocal => '현지 시각';

  @override
  String get worldToday => '오늘';

  @override
  String get worldTomorrow => '내일';

  @override
  String get worldYesterday => '어제';

  @override
  String get worldAdd => '도시 추가';

  @override
  String get worldSearch => '도시 검색';

  @override
  String get worldNoResults => '일치하는 도시가 없어요.';

  @override
  String get worldEdit => '목록 편집';

  @override
  String get worldDone => '완료';

  @override
  String get worldRemove => '삭제';

  @override
  String get worldEmpty => '아직 다른 도시가 없어요. +를 눌러 추가하세요.';

  @override
  String get worldSameTime => '나와 같은 시각';

  @override
  String worldDiffAhead(String diff) {
    return '나보다 $diff 빨라요';
  }

  @override
  String worldDiffBehind(String diff) {
    return '나보다 $diff 늦어요';
  }

  @override
  String alarmNext(String duration) {
    return '$duration 후 다음 알람';
  }

  @override
  String get alarmNone => '켜진 알람 없음';

  @override
  String get alarmNew => '새 알람';

  @override
  String get alarmEditTitle => '알람 편집';

  @override
  String get alarmLabel => '라벨';

  @override
  String get alarmRepeat => '반복';

  @override
  String get alarmSave => '저장';

  @override
  String get alarmDelete => '알람 삭제';

  @override
  String get alarmConfirmDelete => '확인: 알람 삭제';

  @override
  String get alarmDeleteHint => '이 알람이 삭제돼요.';

  @override
  String get alarmEmpty => '아직 알람이 없어요.\n+를 눌러 만들어 보세요.';

  @override
  String get alarmEveryDay => '매일';

  @override
  String get alarmWeekdays => '평일';

  @override
  String get alarmWeekends => '주말';

  @override
  String get alarmOnce => '한 번';

  @override
  String get alarmPermissionHint =>
      '앱이 닫혀 있어도 알람이 울리려면 Enfo에 알림 및 정확한 알람 권한이 필요해요.';

  @override
  String get alarmPermissionButton => '알람 허용';

  @override
  String get alarmDesktopHint => '이 기기에서는 Enfo가 열려 있어야 알람이 울려요.';

  @override
  String get hapticsTitle => '진동';

  @override
  String get hapticsOff => '꺼짐';

  @override
  String get hapticsStrength => '세기';

  @override
  String get hapticsSoft => '약하게';

  @override
  String get hapticsMedium => '보통';

  @override
  String get hapticsStrong => '강하게';

  @override
  String get hapticsTouch => '터치';

  @override
  String get hapticsTouchHint => '버튼, 스위치, 선택 동작이에요.';

  @override
  String get hapticsMotion => '움직임';

  @override
  String get hapticsMotionHint => '휠, 슬라이더, 드래그, 화면 전환이에요.';

  @override
  String get hapticsAlerts => '알림';

  @override
  String get hapticsAlertsHint => '타이머, 단계 전환, 마지막 카운트다운, 알람이에요.';

  @override
  String get hapticsAlarmPattern => '알람 패턴';

  @override
  String get hapticsAlarmPatternHint => '패턴을 눌러 느껴 보세요. 알람 화면도 같은 리듬으로 뛰어요.';

  @override
  String get hapticsPatternHeartbeat => '심장박동';

  @override
  String get hapticsPatternPulse => '맥박';

  @override
  String get hapticsPatternCrescendo => '크레센도';

  @override
  String get hapticsPatternRipple => '파문';

  @override
  String get hapticsPatternBeacon => '등대';

  @override
  String get hapticsTry => '체험해 보기';

  @override
  String get hapticsTryTap => '터치';

  @override
  String get hapticsTrySuccess => '성공';

  @override
  String get hapticsTryToRest => '집중 종료';

  @override
  String get hapticsTryToWork => '휴식 종료';

  @override
  String get hapticsTryTimer => '타이머 종료';

  @override
  String get hapticsTryWarning => '경고';

  @override
  String get hapticsUnavailable => '이 기기에는 진동 모터가 없어요.';

  @override
  String get hapticsWhen => '진동 시점';

  @override
  String get widgetsTitle => '위젯';

  @override
  String get widgetsSubtitle => '홈 화면의 시계와 타이머';

  @override
  String get widgetsAddHeader => '홈 화면에 추가';

  @override
  String get widgetsAdd => '추가';

  @override
  String get widgetsDynamicColor => 'Material You 색상';

  @override
  String get widgetsDynamicColorHint =>
      '위젯이 배경화면에서 색상을 가져와요. 끄면 Enfo의 강조 색상을 사용해요.';

  @override
  String get widgetsManualHint =>
      '현재 런처에서는 여기서 위젯을 추가할 수 없어요. 홈 화면을 길게 눌러 위젯을 선택하고 Enfo를 찾아보세요.';

  @override
  String get widgetsStyleHint =>
      '뽀모도로와 타이머 위젯은 선택한 시계 스타일로 그려져요. 앱에서 스타일을 바꾸면 위젯도 따라 바뀌어요.';

  @override
  String get widgetsTapHint =>
      '위젯의 버튼을 누르면 Enfo가 열리고 동작이 실행돼요. 그래서 시간은 항상 앱이 관리해요.';

  @override
  String get shortcutsTitle => '키보드 및 리모컨';

  @override
  String get shortcutsSubtitle => '키보드, 마우스, TV 리모컨 단축키';

  @override
  String get shortcutsIntro =>
      '방향키나 리모컨의 D-pad로 이동하고, Enter나 OK로 선택해요. 나머지는 아래 키를 사용하세요.';

  @override
  String get shortcutKeySpace => '스페이스';

  @override
  String get shortcutPlayPause => '시작 또는 일시정지';

  @override
  String get shortcutReset => '초기화';

  @override
  String get shortcutLap => '랩 (스톱워치)';

  @override
  String get shortcutJumpMode => '1–9번 모드로 이동';

  @override
  String get shortcutStepMode => '이전 / 다음 모드';

  @override
  String get shortcutFullscreen => '전체 화면';

  @override
  String get shortcutDim => '화면 어둡게 (전체 화면)';

  @override
  String get shortcutSettings => '설정';

  @override
  String get shortcutModes => '모드 메뉴';

  @override
  String get shortcutBack => '뒤로 / 전체 화면 종료';

  @override
  String get shortcutHelp => '이 목록 보기';

  @override
  String get onbMoreTools => '더 많은 도구';

  @override
  String get modeEvent => '이벤트';

  @override
  String get modeDescEvent => '중요한 날까지 남은 시간';

  @override
  String get modeIntervals => '인터벌';

  @override
  String get modeDescIntervals => 'HIIT 같은 운동·휴식 라운드';

  @override
  String get modeBreathe => '호흡';

  @override
  String get modeDescBreathe => '마음을 가라앉히는 호흡 가이드';

  @override
  String get modeTracker => '트래커';

  @override
  String get modeDescTracker => '활동 시간을 재고 합계 보기';

  @override
  String get modeKitchen => '주방';

  @override
  String get modeDescKitchen => '이름 붙인 타이머 여러 개';

  @override
  String get modeSleep => '수면';

  @override
  String get modeDescSleep => '수면 주기로 취침·기상 계획';

  @override
  String get modeVersus => '턴';

  @override
  String get modeDescVersus => '체스·게임·토론용 대국 시계';

  @override
  String get modeBreaks => '휴식';

  @override
  String get modeDescBreaks => '눈 휴식과 스트레칭 알림';

  @override
  String get modeAmbient => '배경음';

  @override
  String get modeDescAmbient => '수면 타이머가 있는 배경 소리';

  @override
  String get intervalsPresetTabata => '타바타';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => '사용자 설정';

  @override
  String get intervalsWarmUp => '워밍업';

  @override
  String get intervalsWork => '운동';

  @override
  String get intervalsRest => '휴식';

  @override
  String get intervalsRounds => '라운드';

  @override
  String get intervalsCoolDown => '쿨다운';

  @override
  String get intervalsOff => '없음';

  @override
  String intervalsRound(int current, int total) {
    return '라운드 $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return '총 $duration';
  }

  @override
  String get intervalsSkip => '다음 단계로 건너뛰기';

  @override
  String get intervalsHint => '행을 눌러 수정하세요. 변경 사항은 사용자 설정으로 저장됩니다.';

  @override
  String get intervalsDoneTitle => '운동 완료';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration. 수고하셨어요!';
  }

  @override
  String get kitchenPasta => '파스타';

  @override
  String get kitchenEggs => '달걀';

  @override
  String get kitchenTea => '차';

  @override
  String get kitchenRice => '밥';

  @override
  String get kitchenOven => '오븐';

  @override
  String get kitchenCustom => '직접 설정';

  @override
  String get kitchenNameHint => '이름';

  @override
  String get kitchenAdd => '타이머 시작';

  @override
  String get kitchenDelete => '타이머 삭제';

  @override
  String get kitchenEmpty => '타이머가 없습니다. 위 칩을 눌러 시작하세요.';

  @override
  String get kitchenDefaultName => '타이머';

  @override
  String kitchenDoneTitle(String name) {
    return '$name 준비 완료';
  }

  @override
  String kitchenDoneBody(String duration) {
    return '$duration 타이머가 끝났습니다.';
  }

  @override
  String get trackerToday => '오늘';

  @override
  String get trackerWeek => '최근 7일';

  @override
  String get trackerTapToStart => '활동을 탭하면 시간 측정이 시작돼요';

  @override
  String get trackerNoRunning => '실행 중인 활동 없음';

  @override
  String get trackerAddActivity => '새 활동';

  @override
  String get trackerNameHint => '이름';

  @override
  String get trackerStudy => '공부';

  @override
  String get trackerReading => '독서';

  @override
  String get trackerCode => '코딩';

  @override
  String get trackerExercise => '운동';

  @override
  String get trackerEdit => '활동 편집';

  @override
  String get trackerDetails => '상세 및 차트';

  @override
  String get trackerColor => '색상';

  @override
  String get trackerIcon => '아이콘';

  @override
  String get trackerDelete => '활동 삭제';

  @override
  String get trackerDeleteConfirm => '확인: 이 활동 삭제';

  @override
  String get trackerDeleteHint => '이미 기록된 시간은 기록에 남아요.';

  @override
  String get trackerAddTime => '시간 직접 추가';

  @override
  String trackerAddMinutes(int minutes) {
    return '$minutes분 추가';
  }

  @override
  String get trackerMinutesFewer => '분 줄이기';

  @override
  String get trackerMinutesMore => '분 늘리기';

  @override
  String get trackerStop => '중지';

  @override
  String get versusDuel => '대결';

  @override
  String get versusSpeakers => '발표자';

  @override
  String get versusCustom => '사용자 지정';

  @override
  String get versusIncrement => '증가';

  @override
  String get versusTapToStart => '자신의 쪽을 탭해 시계를 시작하세요';

  @override
  String get versusTimeIsUp => '시간 종료';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count수',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => '대국 초기화';

  @override
  String get versusConfirmReset => '초기화 확인';

  @override
  String versusSpeakerN(int n) {
    return '발표자 $n';
  }

  @override
  String get versusAddSpeaker => '발표자 추가';

  @override
  String get versusRemoveSpeaker => '발표자 삭제';

  @override
  String get versusSpeakerName => '발표자 또는 주제';

  @override
  String get versusNext => '다음 발표자';

  @override
  String get versusFinish => '끝내기';

  @override
  String get versusOvertime => '초과';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed / $planned';
  }

  @override
  String get versusAgendaDone => '안건 종료';

  @override
  String get versusStartAgenda => '안건 시작';

  @override
  String get versusMinutesFewer => '분 줄이기';

  @override
  String get versusMinutesMore => '분 늘리기';

  @override
  String get versusTotal => '합계';

  @override
  String get breatheInhale => '들이마시기';

  @override
  String get breatheHold => '멈추기';

  @override
  String get breatheExhale => '내쉬기';

  @override
  String get breatheStart => '호흡 시작';

  @override
  String get breathePause => '일시정지';

  @override
  String get breatheResume => '계속';

  @override
  String get breatheReset => '세션 종료';

  @override
  String get breatheDone => '잘하셨어요';

  @override
  String get breatheReady => '편안한 자세를 잡으세요';

  @override
  String get breathePatternBox => '박스';

  @override
  String get breathePatternCoherent => '코히런트';

  @override
  String get breathePatternCalm => '진정';

  @override
  String get breathePatternCustom => '사용자 지정';

  @override
  String get breatheSession => '세션 길이';

  @override
  String get breatheEndless => '무제한';

  @override
  String breatheSeconds(int n) {
    return '$n초';
  }

  @override
  String get ambientWhite => '화이트 노이즈';

  @override
  String get ambientPink => '핑크 노이즈';

  @override
  String get ambientBrown => '브라운 노이즈';

  @override
  String get ambientRain => '빗소리';

  @override
  String get ambientWind => '바람';

  @override
  String get ambientOcean => '바다';

  @override
  String get ambientVolume => '볼륨';

  @override
  String get ambientSleepTimer => '수면 타이머';

  @override
  String get ambientTimerOff => '끄기';

  @override
  String get ambientPlay => '소리 재생';

  @override
  String get ambientStop => '소리 정지';

  @override
  String get ambientUnavailable => '이 기기에서는 소리를 재생할 수 없습니다.';

  @override
  String get ambientPreparing => '소리 준비 중…';

  @override
  String ambientTimeLeft(String time) {
    return '$time 남음';
  }

  @override
  String get breaksStart => '휴식 시작';

  @override
  String get breaksStop => '휴식 중지';

  @override
  String get breaksStatusOff => '휴식 알림이 꺼져 있습니다';

  @override
  String get breaksNoneEnabled => '알림을 하나 이상 켜세요';

  @override
  String breaksNextName(String name) {
    return '다음: $name';
  }

  @override
  String get breaksToday => '오늘';

  @override
  String get breaksTaken => '쉰 횟수';

  @override
  String get breaksSkipped => '건너뜀';

  @override
  String get breaksEyeName => '눈 휴식 (20-20-20)';

  @override
  String get breaksEyeHint => '6m 떨어진 곳을 20초간 바라보세요';

  @override
  String get breaksStretchName => '스트레칭';

  @override
  String get breaksStretchHint => '일어나서 온몸을 쭉 펴 보세요';

  @override
  String get breaksWaterName => '물 마시기';

  @override
  String get breaksWaterHint => '물 한 잔을 마시세요';

  @override
  String get breaksPostureName => '자세 점검';

  @override
  String get breaksPostureHint => '허리를 펴고 어깨의 힘을 빼세요';

  @override
  String get breaksCustomDefault => '내 알림';

  @override
  String breaksForDuration(String duration) {
    return '$duration 동안 쉬세요';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return '$minutes분마다';
  }

  @override
  String get breaksShorter => '간격 줄이기';

  @override
  String get breaksLonger => '간격 늘리기';

  @override
  String get breaksDone => '완료';

  @override
  String get breaksSkip => '건너뛰기';

  @override
  String get breaksActiveHours => '활성 시간';

  @override
  String get breaksActiveHoursHint => '이 시간대에만 알림이 표시됩니다';

  @override
  String get breaksFrom => '시작';

  @override
  String get breaksTo => '종료';

  @override
  String get breaksLaterHour => '늦게';

  @override
  String get breaksEarlierHour => '일찍';

  @override
  String get breaksBackground => 'Enfo를 닫아도';

  @override
  String get breaksBackgroundOn => '앱을 닫아도 알림으로 알려 드립니다.';

  @override
  String get breaksBackgroundOff => 'Enfo가 열려 있는 동안에만 알림이 표시됩니다.';

  @override
  String get breaksDesktopNotice => 'Enfo가 실행 중인 동안 알림이 표시됩니다(최소화 가능).';

  @override
  String get breaksAddCustom => '사용자 알림 추가';

  @override
  String get breaksEdit => '알림 편집';

  @override
  String get breaksName => '이름';

  @override
  String get breaksDuration => '시간';

  @override
  String get breaksIcon => '아이콘';

  @override
  String get breaksShorterDuration => '휴식 줄이기';

  @override
  String get breaksLongerDuration => '휴식 늘리기';

  @override
  String get breaksRemove => '알림 삭제';

  @override
  String get breaksRemoveConfirm => '확인: 알림 삭제';

  @override
  String get breaksRemoveHint => '더 이상 알려 주지 않습니다.';

  @override
  String get worldPlan => '회의 계획';

  @override
  String get worldPlanIntro => '마커를 움직여 모두에게 맞는 시간을 찾아보세요.';

  @override
  String get worldPlanNow => '지금';

  @override
  String get worldPlanEarlier => '15분 앞으로';

  @override
  String get worldPlanLater => '15분 뒤로';

  @override
  String worldPlanSelected(String city) {
    return '$city 기준 선택 시간';
  }

  @override
  String get worldPlanTapCity => '도시를 누르면 그 도시의 시간이 기준이 됩니다.';

  @override
  String get worldPlanNextDay => '+1일';

  @override
  String get worldPlanPrevDay => '-1일';

  @override
  String get worldPlanOverlapTitle => '모두 근무 시간';

  @override
  String get worldPlanNoOverlap => '앞으로 24시간 안에 모두에게 맞는 시간이 없습니다.';

  @override
  String worldPlanLeastBad(String time) {
    return '차선책: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$total곳 중 $count곳 근무 시간';
  }

  @override
  String get worldPlanWork => '근무 시간 (09-18)';

  @override
  String get worldPlanNight => '밤';

  @override
  String get worldPlanMarker => '선택한 시간';

  @override
  String get eventAdd => '새 이벤트';

  @override
  String get eventEdit => '이벤트 편집';

  @override
  String get eventName => '이름';

  @override
  String get eventNameHint => '생일, 여행, 출시...';

  @override
  String get eventYearly => '매년 반복';

  @override
  String get eventYearlyHint => '생일·기념일용: 자동으로 다음 날짜로 넘어갑니다.';

  @override
  String get eventNotify => '알림 받기';

  @override
  String get eventNotifyHint => '해당 시각이 되면 알려 드립니다.';

  @override
  String get eventDayBefore => '하루 전에도';

  @override
  String get eventSave => '저장';

  @override
  String get eventDelete => '이벤트 삭제';

  @override
  String get eventConfirmDelete => '확인: 이벤트 삭제';

  @override
  String get eventDeleteHint => '이 이벤트가 삭제됩니다.';

  @override
  String get eventEmpty => '아직 이벤트가 없습니다.\n+를 눌러 카운트다운을 만드세요.';

  @override
  String get eventToday => '오늘!';

  @override
  String eventDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get eventDaysShort => '일';

  @override
  String get eventUnitDays => '일';

  @override
  String get eventUnitHours => '시간';

  @override
  String get eventUnitMinutes => '분';

  @override
  String get eventRepeatsYearly => '매년';

  @override
  String get eventNotifyNow => '때가 되었습니다!';

  @override
  String get eventNotifyTomorrow => '내일';

  @override
  String get sleepPlanWake => '기상 시각';

  @override
  String get sleepPlanBed => '취침 시각';

  @override
  String get sleepPlanNow => '지금 자기';

  @override
  String get sleepTitleWake => '일어나고 싶은 시각';

  @override
  String get sleepTitleBed => '잠자리에 드는 시각';

  @override
  String sleepTitleNow(String time) {
    return '지금 잠들면 ($time)';
  }

  @override
  String get sleepBedtimeWord => '취침';

  @override
  String get sleepWakeWord => '기상';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles주기 · 수면 $duration';
  }

  @override
  String get sleepNote => '한 주기는 90분이고 잠드는 데 약 15분이 걸립니다. 5~6주기를 권장합니다.';

  @override
  String get sleepWindDown => '휴식 알림';

  @override
  String get sleepWindDownHint => '취침 30분 전에 알람이 울립니다.';

  @override
  String get sleepWindDownPassed => '이미 지난 시각입니다.';

  @override
  String get sleepWindDownLabel => '휴식할 시간';

  @override
  String get sleepAlarmLabel => '기상';

  @override
  String get sleepSetAlarm => '알람 설정';

  @override
  String get sleepRemoveAlarm => '알람 삭제';

  @override
  String sleepAlarmSet(String time) {
    return '$time에 알람이 설정되었습니다';
  }

  @override
  String get sleepPast => '이미 지난 시각입니다';

  @override
  String get sleepRecommended => '권장';

  @override
  String get ambientMusicTabSounds => '사운드';

  @override
  String get ambientMusicTab => '음악';

  @override
  String get ambientMusicPlay => '음악 재생';

  @override
  String get ambientMusicPause => '음악 일시정지';

  @override
  String get ambientMusicNext => '다음 곡';

  @override
  String get ambientMusicPrevious => '이전 곡';

  @override
  String get ambientMusicShuffle => '셔플';

  @override
  String get ambientMusicRepeat => '전체 반복';

  @override
  String get ambientMusicVolume => '음악 볼륨';

  @override
  String get ambientMusicCredits => '음악 크레딧';

  @override
  String get ambientMusicCreditsNote =>
      'Wikimedia Commons의 곡으로, CC0 또는 크리에이티브 커먼즈 저작자표시 라이선스로 공개되었습니다.';

  @override
  String get modeMusic => '음악';

  @override
  String get modeDescMusic => '집중을 위한 로파이 음악';

  @override
  String get musicCreditsSubtitle => '아티스트와 라이선스';

  @override
  String get displayMenuButtons => '메뉴 버튼';

  @override
  String get displayMenuButtonsHint => '하단 메뉴에 표시할 버튼을 고르세요. 설정은 항상 표시됩니다.';

  @override
  String get onbWelcomeTitle => 'Enfo에 오신 것을 환영해요';

  @override
  String get onbWelcomeTagline => '집중을, 차분한 다이얼 하나로.';

  @override
  String get timerRunningTitle => '타이머 실행 중';

  @override
  String timerRunningBody(String time) {
    return '$time에 종료';
  }

  @override
  String get timerPausedTitle => '타이머 일시정지';

  @override
  String timerPausedBody(String duration) {
    return '$duration 남음';
  }

  @override
  String get musicActionPlay => '재생';

  @override
  String get musicActionPause => '일시정지';

  @override
  String get widgetsFocusSubtitle => '오늘의 집중 시간과 뽀모도로를 한눈에 확인하세요.';
}
