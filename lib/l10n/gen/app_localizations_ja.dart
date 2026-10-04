// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => '設定';

  @override
  String get tooltipStats => '統計';

  @override
  String get tooltipPin => '常に表示';

  @override
  String get tooltipUnpin => '常に表示を解除';

  @override
  String get phasePaused => '一時停止中';

  @override
  String get phaseFocus => '集中';

  @override
  String get phaseRelax => '休憩';

  @override
  String get notifRestTitle => '休憩の時間です';

  @override
  String get notifRestBody => 'ひと息つきましょう。';

  @override
  String get notifWorkTitle => '作業の時間です';

  @override
  String get notifWorkBody => '作業を再開しましょう!';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get rhythmTitle => '集中のリズム';

  @override
  String get presetClassic => 'クラシック';

  @override
  String get presetExtended => 'ロング';

  @override
  String get presetDeep => 'ディープ';

  @override
  String get presetManual => 'カスタム';

  @override
  String get workLabel => '集中';

  @override
  String get restLabel => '休憩';

  @override
  String minutes(int n) {
    return '$n分';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest分';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get timersTitle => '時間';

  @override
  String timersSubtitle(int work, int rest) {
    return '集中$work分 · 休憩$rest分';
  }

  @override
  String timersCycle(int total) {
    return '1サイクル: $total分';
  }

  @override
  String get timersApplyHint =>
      'タイマー動作中の変更は、次のサイクルから反映されます。一時停止中はタイマーがリセットされます。';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearanceLight => 'ライトテーマ';

  @override
  String get appearanceDark => 'ダークテーマ';

  @override
  String get darkTheme => 'ダークテーマ';

  @override
  String get themeModeSystem => 'システム';

  @override
  String get themeModeLight => 'ライト';

  @override
  String get themeModeDark => 'ダーク';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsOn => 'オン';

  @override
  String get notificationsOff => 'オフ';

  @override
  String get notificationsToggle => 'フェーズ切り替え時に通知';

  @override
  String get notificationsHint => '休憩や作業再開のタイミングでお知らせします。';

  @override
  String get languageTitle => '言語';

  @override
  String get languageSystem => 'システムのデフォルト';

  @override
  String get languageHint => 'アプリの言語を選択します。';

  @override
  String get supportTitle => 'Enfoを応援';

  @override
  String get supportSubtitle => 'コーヒーと広告';

  @override
  String get supportSubtitleNoAds => 'コーヒーをおごる';

  @override
  String get buyCoffee => 'コーヒーをおごる';

  @override
  String get watchAd => '広告を見て応援';

  @override
  String get supportHint => 'Enfoは無料で、開発者ひとりで作っています。ご利用ありがとうございます。';

  @override
  String get statsTitle => '統計';

  @override
  String get statsEmpty => 'セッションはまだありません。\nポモドーロを開始するとここに表示されます。';

  @override
  String get statsTodayPomodoros => '今日のポモドーロ';

  @override
  String get statsTodayFocus => '今日の集中';

  @override
  String get statsCompleted => '完了';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '日連続',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => '過去7日間';

  @override
  String get statsTotalFocus => '集中時間の合計';

  @override
  String get statsTotalRest => '休憩時間の合計';

  @override
  String get statsAbandoned => '中断';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  完了率$percent%';
  }

  @override
  String get statsAverageFocus => '平均集中時間';

  @override
  String get statsLongestSession => '最長セッション';

  @override
  String get statsPauses => '一時停止';

  @override
  String get statsAverageGap => 'セッション間の平均間隔';

  @override
  String get statsLongestGap => '最長の未使用期間';

  @override
  String get statsSinceLast => '前回のセッションから';

  @override
  String get statsHistory => '履歴';

  @override
  String get statsClearHistory => '履歴を削除';

  @override
  String get statsClearConfirm => '確認: すべてのセッションを削除';

  @override
  String get statsClearHint => 'この操作は元に戻せません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get sessionFocus => '集中';

  @override
  String get sessionRest => '休憩';

  @override
  String sessionProgress(String done, String planned) {
    return '$done/$planned';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '一時停止$count回',
      one: '一時停止1回',
    );
    return '$_temp0 ($time)';
  }

  @override
  String sessionIdleBefore(String gap) {
    return '$gapの空き後';
  }

  @override
  String get sessionCompleted => '完了';

  @override
  String get sessionAbandoned => '中断';

  @override
  String get clockStyleTitle => '時計スタイル';

  @override
  String get tooltipClockStyle => '時計スタイル';

  @override
  String get clockCategoryProgress => '進捗と数字';

  @override
  String get clockCategoryNumbers => '数字のみ';

  @override
  String get clockCategoryIcons => 'アイコンのみ';

  @override
  String get clockCategoryMotion => 'アニメーションのみ';

  @override
  String get clockUnitMinutes => '分';

  @override
  String get clockUnitSeconds => '秒';

  @override
  String get clockRing => 'リング';

  @override
  String get clockWavyRing => 'ウェーブ';

  @override
  String get clockSegments => 'セグメント';

  @override
  String get clockOrbit => 'オービット';

  @override
  String get clockPie => 'パイ';

  @override
  String get clockKitchen => 'キッチン';

  @override
  String get clockDots => 'ドット';

  @override
  String get clockBar => 'バー';

  @override
  String get clockWavyBar => '波バー';

  @override
  String get clockDigits => 'デジタル数字';

  @override
  String get clockMinutes => '分';

  @override
  String get clockTiles => 'タイル';

  @override
  String get clockStack => 'スタック';

  @override
  String get clockTomato => 'トマト';

  @override
  String get clockHourglass => '砂時計';

  @override
  String get clockBattery => 'バッテリー';

  @override
  String get clockIcon => 'アイコン';

  @override
  String get clockCookie => 'クッキー';

  @override
  String get clockLiquid => 'リキッド';

  @override
  String get clockBreathe => '呼吸';

  @override
  String get clockEqualizer => 'イコライザー';

  @override
  String get clockRipple => '波紋';

  @override
  String get accentApply => '適用';

  @override
  String get accentCustom => 'カスタムカラー';

  @override
  String get accentHue => '色相';

  @override
  String get accentSaturation => '彩度';

  @override
  String get accentBrightness => '明度';

  @override
  String get accentHex => '16進コード';

  @override
  String get displayTitle => '画面';

  @override
  String get displayClockShown => '時刻を表示中';

  @override
  String get displayClockHidden => '時刻を非表示';

  @override
  String get showClock => '時刻を表示';

  @override
  String get showClockHint => 'タイマーの上に表示される小さな時計です。';

  @override
  String get clockFormat => '時刻の形式';

  @override
  String get clockFormatSystem => 'システムのデフォルト';

  @override
  String get clockFormat12 => '12時間';

  @override
  String get clockFormat24 => '24時間';

  @override
  String get behaviorTitle => '動作';

  @override
  String get autoStartNext => '次のフェーズを自動で開始';

  @override
  String get autoStartNextHint => '集中や休憩が終わると、操作なしで次が始まります。';

  @override
  String get hapticFeedback => '振動';

  @override
  String get hapticFeedbackHint => 'タップ、ホイール、フェーズ切り替え、アラーム。';

  @override
  String get clockCombosTitle => 'コンボ';

  @override
  String get clockCollapseAll => 'すべて折りたたむ';

  @override
  String get clockExpandAll => 'すべて展開';

  @override
  String get comboDeepFocus => '深い集中';

  @override
  String get comboMint => 'フレッシュミント';

  @override
  String get comboSunset => '夕焼け';

  @override
  String get comboZen => '禅';

  @override
  String get comboTomato => 'クラシックトマト';

  @override
  String get comboNight => '夜ふかしフクロウ';

  @override
  String get comboPlayful => 'ポップ';

  @override
  String get comboMinimal => 'ミニマル';

  @override
  String get uiSizeTitle => 'インターフェースのサイズ';

  @override
  String get uiSizeSmall => '小';

  @override
  String get uiSizeNormal => '標準';

  @override
  String get uiSizeLarge => '大';

  @override
  String get uiSizeExtraLarge => '特大';

  @override
  String get uiSizeHint => '文字とコントロールの大きさを変更します。テレビやカーナビ画面で便利です。';

  @override
  String get clockBlob => 'ブロブ';

  @override
  String get clockFlower => '花';

  @override
  String get clockSun => '太陽';

  @override
  String get clockGears => '歯車';

  @override
  String get clockBubbles => 'バブル';

  @override
  String get clockSunflower => 'ひまわり';

  @override
  String get clockFireflies => 'ホタル';

  @override
  String get clockPendulum => '振り子';

  @override
  String get clockBounce => 'バウンス';

  @override
  String get clockMorph => 'モーフ';

  @override
  String get dataTitle => 'データ';

  @override
  String get dataSubtitle => '履歴、リセット、イントロ';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の記録を保存済み',
      one: '1件の記録を保存済み',
      zero: '保存されたアクティビティなし',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'イントロをもう一度見る';

  @override
  String get dataIntroHint => 'ウェルカム画面を見直して、リズムを選び直せます。データは削除されません。';

  @override
  String get dataClearHistoryHint =>
      '記録されたすべてのアクティビティ(ポモドーロ、タイマー、ストップウォッチ、アラーム、時計の表示時間)を削除します。設定は変わりません。';

  @override
  String get dataConfirmClearHistory => '確認: 履歴を削除';

  @override
  String get dataResetSettings => '設定をリセット';

  @override
  String get dataResetSettingsHint =>
      '時間、テーマ、アクセントカラー、言語、モード、画面が初期値に戻ります。履歴は残ります。';

  @override
  String get dataConfirmResetSettings => '確認: 設定をリセット';

  @override
  String get dataEraseAll => 'すべて削除';

  @override
  String get dataEraseAllHint => '履歴と設定を削除して、初回起動時の状態に戻します。';

  @override
  String get dataConfirmEraseAll => '確認: すべて削除';

  @override
  String get dataDoneHistory => '履歴を削除しました。';

  @override
  String get dataDoneSettings => '設定をリセットしました。';

  @override
  String get dataCacheNote => 'Enfoはキャッシュを保存しません。保存するのは、ここで説明した履歴と設定だけです。';

  @override
  String get clockEndsAt => '終了時刻';

  @override
  String get clockFill => 'フィル';

  @override
  String get clockCapsule => 'カプセル';

  @override
  String get clockRollers => 'ローラー';

  @override
  String get clockMatrix => 'マトリクス';

  @override
  String get clockSevenSeg => '7セグ';

  @override
  String get clockFlip => 'フリップ';

  @override
  String get clockFine => '細字';

  @override
  String get clockSuperscript => '上付き';

  @override
  String get clockPercent => 'パーセント';

  @override
  String get clockEndTime => '終了時刻';

  @override
  String get clockSeconds => '秒';

  @override
  String get clockTall => '縦長';

  @override
  String get clockWobble => 'ゆらゆら';

  @override
  String get clockLabeled => 'ラベル付き';

  @override
  String get clockGauge => 'ゲージ';

  @override
  String get clockNeedle => '針';

  @override
  String get clockAnalog => 'アナログ';

  @override
  String get clockRings => 'リング群';

  @override
  String get clockSquircle => 'スクワークル';

  @override
  String get clockColumns => 'カラム';

  @override
  String get clockVertical => '縦';

  @override
  String get clockSteps => 'ステップ';

  @override
  String get clockBlocks => 'ブロック';

  @override
  String get clockSpiral => 'スパイラル';

  @override
  String get clockSlices => 'スライス';

  @override
  String get clockPills => 'ピル';

  @override
  String get clockHexagon => '六角形';

  @override
  String get clockStairs => '階段';

  @override
  String get clockCandle => 'キャンドル';

  @override
  String get clockMoon => '月';

  @override
  String get clockRuler => '定規';

  @override
  String get comboArcade => 'アーケード';

  @override
  String get comboCalculator => '電卓';

  @override
  String get comboDepartures => '駅の発車案内';

  @override
  String get comboCandlelight => 'キャンドルの灯り';

  @override
  String get comboMoonlight => '月明かり';

  @override
  String get comboGarden => '庭園';

  @override
  String get comboSummer => '夏';

  @override
  String get comboWorkshop => '工房';

  @override
  String get comboFizzy => 'シュワシュワ';

  @override
  String get comboSunfield => 'ひまわり畑';

  @override
  String get comboSummerNight => '夏の夜';

  @override
  String get comboHypnosis => '催眠';

  @override
  String get comboBouncy => 'はずむ';

  @override
  String get comboShapeshifter => '変身';

  @override
  String get comboLava => 'ラバランプ';

  @override
  String get comboOcean => '海';

  @override
  String get comboPulse => 'パルス';

  @override
  String get comboPond => '池';

  @override
  String get comboEspresso => 'エスプレッソ';

  @override
  String get comboSpeedometer => 'スピードメーター';

  @override
  String get comboCompass => 'コンパス';

  @override
  String get comboClassicClock => 'クラシック時計';

  @override
  String get comboConcentric => '同心円';

  @override
  String get comboRounded => 'まる';

  @override
  String get comboSignal => 'シグナル';

  @override
  String get comboThermometer => '温度計';

  @override
  String get comboMilestones => 'マイルストーン';

  @override
  String get comboRetroBlocks => 'レトロブロック';

  @override
  String get comboHypnoSpiral => '催眠スパイラル';

  @override
  String get comboCitrus => 'シトラス';

  @override
  String get comboChocolate => '板チョコ';

  @override
  String get comboCrystal => 'クリスタル';

  @override
  String get comboStaircase => '階段';

  @override
  String get comboTapeMeasure => '巻き尺';

  @override
  String get comboBoldType => 'ボールドタイプ';

  @override
  String get comboPill => 'カプセル';

  @override
  String get comboSlotMachine => 'スロットマシン';

  @override
  String get comboWhisper => 'ささやき';

  @override
  String get comboDeadline => '締め切り';

  @override
  String get comboPercentage => 'パーセンテージ';

  @override
  String get comboStopwatch => '秒のみ';

  @override
  String get comboSkyscraper => '摩天楼';

  @override
  String get comboWaveText => 'ウェーブ文字';

  @override
  String get comboDashboard => 'ダッシュボード';

  @override
  String get comboExponent => '指数';

  @override
  String get comboGrandmaKitchen => 'おばあちゃんのキッチン';

  @override
  String get comboCyber => 'サイバー';

  @override
  String get comboCandy => 'キャンディ';

  @override
  String get comboConfetti => '紙吹雪';

  @override
  String get comboCookieJar => 'クッキー缶';

  @override
  String get comboSandbox => '砂場';

  @override
  String get comboPizzaNight => 'ピザナイト';

  @override
  String get onbLanguageTitle => '言語';

  @override
  String get onbLanguageBody => '言語を選んでください。ここでの選択は、あとで設定から変更できます。';

  @override
  String get onbRhythmTitle => 'あなたのリズム';

  @override
  String get onbRhythmBody => '集中する時間と休憩する時間を決めます。';

  @override
  String get onbLookTitle => '自分好みに';

  @override
  String get onbLookBody => 'テーマ、時計スタイル、色。組み合わせを選び、必要なら色を調整できます。';

  @override
  String get onbClockTitle => '時計を選ぶ';

  @override
  String get onbClockBody => 'おすすめの組み合わせ: 時計スタイルと色をワンタップで。';

  @override
  String get onbAllStyles => 'すべてのスタイルを見る';

  @override
  String get onbOptionsTitle => '最後の仕上げ';

  @override
  String get onbOptionsBody => '画面と動作の設定です。これらは設定からも変更できます。';

  @override
  String get onbModesTitle => '使うツール';

  @override
  String get onbModesBody =>
      'Enfoは時計とタイマーのツールボックスです。使うものをオンにしてください。モードメニューからいつでも変更できます。';

  @override
  String get onbPreview => 'プレビュー';

  @override
  String get onbDisplayTitle => '表示';

  @override
  String get onbDisplayBody => '時計の見た目と、全体の大きさ。';

  @override
  String get onbClockModeDesign => '時計モードのデザイン';

  @override
  String get onbPermTitle => '権限';

  @override
  String get onbPermBody => 'Enfoを閉じていても、タイマーやアラームでお知らせするために。';

  @override
  String get onbPermNotifications => '通知';

  @override
  String get onbPermNotificationsHint => 'タイマー終了やアラーム時にお知らせします。';

  @override
  String get onbPermExact => '正確なアラーム';

  @override
  String get onbPermExactHint => 'バッテリーセーバー中でも時刻ぴったりに鳴ります。';

  @override
  String get onbPermAllow => '許可';

  @override
  String get onbPermAllowed => '許可済み';

  @override
  String get onbPermLater => 'システム設定からいつでも変更できます。';

  @override
  String get onbNext => '次へ';

  @override
  String get onbBack => '戻る';

  @override
  String get onbSkip => 'スキップ';

  @override
  String onbStepOf(int step, int total) {
    return 'ステップ $step/$total';
  }

  @override
  String get clockFormatAuto => '自動';

  @override
  String get modePomodoro => 'ポモドーロ';

  @override
  String get modeClock => '時計';

  @override
  String get modeTimer => 'タイマー';

  @override
  String get modeStopwatch => 'ストップウォッチ';

  @override
  String get modeAlarm => 'アラーム';

  @override
  String get modeWorld => '世界時計';

  @override
  String get modeDescPomodoro => '集中と休憩のサイクル';

  @override
  String get modeDescClock => '美しい時計を常時表示';

  @override
  String get modeDescTimer => '好きな時間からカウントダウン';

  @override
  String get modeDescStopwatch => 'ラップ付きで時間を計測';

  @override
  String get modeDescAlarm => '目覚ましやリマインダー';

  @override
  String get modeDescWorld => '世界の都市の時刻';

  @override
  String get tooltipModes => 'モード';

  @override
  String get tooltipSwitchMode => '次のモード';

  @override
  String get tooltipFullscreen => '全画面';

  @override
  String get tooltipExitFullscreen => '全画面を終了';

  @override
  String get tooltipDim => '画面を暗くする';

  @override
  String get modesTitle => 'モード';

  @override
  String get modesHint => '使うモードと順番を選びます。ドラッグして並べ替えできます。';

  @override
  String get modesStart => '起動時のモード';

  @override
  String get modesStartLast => '前回使ったモード';

  @override
  String get modesCustomize => 'カスタマイズ';

  @override
  String get modesActivity => 'アクティビティ履歴';

  @override
  String get modesAtLeastOne => '少なくとも1つのモードを有効にしてください。';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のモードが有効',
      one: '1個のモードが有効',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'アクティビティ履歴';

  @override
  String get activityTitle => 'アクティビティ';

  @override
  String get activityEmpty => 'まだ何もありません。\nタイマー、ストップウォッチ、アラーム、時計を使うとここに表示されます。';

  @override
  String get activityFilterAll => 'すべて';

  @override
  String get activityTimersToday => '今日のタイマー';

  @override
  String get activityStopwatchToday => '今日のストップウォッチ';

  @override
  String get activityDisplayToday => '今日の画面表示';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countラップ',
      one: '1ラップ',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'ラップ $n';
  }

  @override
  String get activityAlarmDismissed => '停止';

  @override
  String get activityAlarmSnoozed => 'スヌーズ';

  @override
  String get activityAlarmMissed => '不在';

  @override
  String activityDisplay(String mode) {
    return '$modeを表示';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done/$planned';
  }

  @override
  String get faceRing => 'リング';

  @override
  String get faceDigital => 'デジタル';

  @override
  String get faceAnalog => 'アナログ';

  @override
  String get faceSplit => 'ラージ';

  @override
  String get faceDay => '日';

  @override
  String get tooltipCustomize => 'カスタマイズ';

  @override
  String get clockSettingsTitle => '時計のカスタマイズ';

  @override
  String get clockFaceTitle => 'デザイン';

  @override
  String get clockShowSeconds => '秒を表示';

  @override
  String get clockShowDate => '日付を表示';

  @override
  String get clockBlinkColon => 'コロンを点滅';

  @override
  String get clockKeepAwake => '画面をつけたままにする';

  @override
  String get clockKeepAwakeHint => '時計が表示されている間。';

  @override
  String get clockFullscreenHint =>
      '全画面をタップすると、つけっぱなしの卓上時計になります。時計をスワイプするとデザインを切り替えられます。';

  @override
  String clockDayPercent(int percent) {
    return '一日の$percent%';
  }

  @override
  String get ringDismiss => '停止';

  @override
  String ringSnooze(int minutes) {
    return '$minutes分スヌーズ';
  }

  @override
  String get timerStart => '開始';

  @override
  String get timerPause => '一時停止';

  @override
  String get timerResume => '再開';

  @override
  String get timerReset => 'リセット';

  @override
  String get timerAddMinute => '+1分';

  @override
  String get timerHoursShort => '時間';

  @override
  String get timerMinutesShort => '分';

  @override
  String get timerSecondsShort => '秒';

  @override
  String get timerUpTitle => '時間になりました';

  @override
  String timerUpBody(String duration) {
    return '$durationのタイマーが終了しました。';
  }

  @override
  String get timerSavePreset => 'この時間を保存';

  @override
  String get timerPresetHint => '+をタップするとこの時間を保存できます。プリセットを長押しすると削除できます。';

  @override
  String get stopwatchStop => '停止';

  @override
  String get stopwatchLap => 'ラップ';

  @override
  String get stopwatchLapBest => 'ベスト';

  @override
  String get stopwatchLapWorst => 'ワースト';

  @override
  String get worldLocal => '現地時刻';

  @override
  String get worldToday => '今日';

  @override
  String get worldTomorrow => '明日';

  @override
  String get worldYesterday => '昨日';

  @override
  String get worldAdd => '都市を追加';

  @override
  String get worldSearch => '都市を検索';

  @override
  String get worldNoResults => '一致する都市がありません。';

  @override
  String get worldEdit => 'リストを編集';

  @override
  String get worldDone => '完了';

  @override
  String get worldRemove => '削除';

  @override
  String get worldEmpty => 'ほかの都市はまだありません。+をタップして追加します。';

  @override
  String get worldSameTime => 'あなたと同じ時刻';

  @override
  String worldDiffAhead(String diff) {
    return 'あなたより$diff進んでいます';
  }

  @override
  String worldDiffBehind(String diff) {
    return 'あなたより$diff遅れています';
  }

  @override
  String alarmNext(String duration) {
    return '次のアラームまで$duration';
  }

  @override
  String get alarmNone => '有効なアラームなし';

  @override
  String get alarmNew => '新しいアラーム';

  @override
  String get alarmEditTitle => 'アラームを編集';

  @override
  String get alarmLabel => 'ラベル';

  @override
  String get alarmRepeat => '繰り返し';

  @override
  String get alarmSave => '保存';

  @override
  String get alarmDelete => 'アラームを削除';

  @override
  String get alarmConfirmDelete => '確認: アラームを削除';

  @override
  String get alarmDeleteHint => 'このアラームは削除されます。';

  @override
  String get alarmEmpty => 'アラームはまだありません。\n+をタップして作成します。';

  @override
  String get alarmEveryDay => '毎日';

  @override
  String get alarmWeekdays => '平日';

  @override
  String get alarmWeekends => '週末';

  @override
  String get alarmOnce => '1回のみ';

  @override
  String get alarmPermissionHint => 'アプリを閉じていても鳴らすには、Enfoに通知と正確なアラームの権限が必要です。';

  @override
  String get alarmPermissionButton => 'アラームを許可';

  @override
  String get alarmDesktopHint => 'このデバイスでは、アラームを鳴らすためにEnfoを開いたままにする必要があります。';

  @override
  String get hapticsTitle => '振動';

  @override
  String get hapticsOff => 'オフ';

  @override
  String get hapticsStrength => '強さ';

  @override
  String get hapticsSoft => '弱';

  @override
  String get hapticsMedium => '中';

  @override
  String get hapticsStrong => '強';

  @override
  String get hapticsTouch => 'タッチ';

  @override
  String get hapticsTouchHint => 'ボタン、スイッチ、選択操作。';

  @override
  String get hapticsMotion => 'モーション';

  @override
  String get hapticsMotionHint => 'ホイール、スライダー、ドラッグ、画面遷移。';

  @override
  String get hapticsAlerts => 'アラート';

  @override
  String get hapticsAlertsHint => 'タイマー、フェーズ切り替え、最後のカウントダウン、アラーム。';

  @override
  String get hapticsAlarmPattern => 'アラームのパターン';

  @override
  String get hapticsAlarmPatternHint =>
      'パターンをタップすると振動を確かめられます。アラーム画面も同じリズムで脈打ちます。';

  @override
  String get hapticsPatternHeartbeat => '鼓動';

  @override
  String get hapticsPatternPulse => 'パルス';

  @override
  String get hapticsPatternCrescendo => 'クレッシェンド';

  @override
  String get hapticsPatternRipple => '波紋';

  @override
  String get hapticsPatternBeacon => 'ビーコン';

  @override
  String get hapticsTry => '試す';

  @override
  String get hapticsTryTap => 'タップ';

  @override
  String get hapticsTrySuccess => '成功';

  @override
  String get hapticsTryToRest => '集中の終了';

  @override
  String get hapticsTryToWork => '休憩の終了';

  @override
  String get hapticsTryTimer => 'タイマーの終了';

  @override
  String get hapticsTryWarning => '警告';

  @override
  String get hapticsUnavailable => 'このデバイスには振動モーターがありません。';

  @override
  String get hapticsWhen => '振動するタイミング';

  @override
  String get widgetsTitle => 'ウィジェット';

  @override
  String get widgetsSubtitle => 'ホーム画面に時計とタイマーを表示';

  @override
  String get widgetsAddHeader => 'ホーム画面に追加';

  @override
  String get widgetsAdd => '追加';

  @override
  String get widgetsDynamicColor => 'Material Youカラー';

  @override
  String get widgetsDynamicColorHint =>
      'ウィジェットは壁紙から色を取得します。オフにするとEnfoのアクセントカラーを使います。';

  @override
  String get widgetsManualHint =>
      'お使いのランチャーではここから追加できません。ホーム画面を長押しして「ウィジェット」を選び、Enfoを探してください。';

  @override
  String get widgetsStyleHint =>
      'ポモドーロとタイマーのウィジェットは、選択した時計スタイルで描画されます。アプリでスタイルを変えると、ウィジェットも変わります。';

  @override
  String get widgetsTapHint => 'ウィジェットのボタンはEnfoを開いて操作を実行します。時間の管理は常にアプリが行います。';

  @override
  String get shortcutsTitle => 'キーボードとリモコン';

  @override
  String get shortcutsSubtitle => 'キーボード、マウス、テレビのリモコン用ショートカット';

  @override
  String get shortcutsIntro =>
      '矢印キーまたはリモコンの十字キーで移動し、EnterまたはOKで決定します。そのほかの操作は以下のキーです。';

  @override
  String get shortcutKeySpace => 'スペース';

  @override
  String get shortcutPlayPause => '開始または一時停止';

  @override
  String get shortcutReset => 'リセット';

  @override
  String get shortcutLap => 'ラップ(ストップウォッチ)';

  @override
  String get shortcutJumpMode => 'モード1〜9へ移動';

  @override
  String get shortcutStepMode => '前 / 次のモード';

  @override
  String get shortcutFullscreen => '全画面';

  @override
  String get shortcutDim => '画面を暗くする(全画面時)';

  @override
  String get shortcutSettings => '設定';

  @override
  String get shortcutModes => 'モードメニュー';

  @override
  String get shortcutBack => '戻る / 全画面を終了';

  @override
  String get shortcutHelp => 'この一覧を表示';

  @override
  String get onbMoreTools => 'その他のツール';

  @override
  String get modeEvent => 'イベント';

  @override
  String get modeDescEvent => '大切な日までをカウント';

  @override
  String get modeIntervals => 'インターバル';

  @override
  String get modeDescIntervals => 'HIITのような運動と休憩のラウンド';

  @override
  String get modeBreathe => '呼吸';

  @override
  String get modeDescBreathe => '落ち着くためのガイド付き呼吸';

  @override
  String get modeTracker => 'トラッカー';

  @override
  String get modeDescTracker => '活動の時間を計って合計を確認';

  @override
  String get modeKitchen => 'キッチン';

  @override
  String get modeDescKitchen => '名前付きタイマーを同時に';

  @override
  String get modeSleep => '睡眠';

  @override
  String get modeDescSleep => '睡眠サイクルで就寝と起床を計画';

  @override
  String get modeVersus => 'ターン';

  @override
  String get modeDescVersus => 'チェスやゲーム、討論用の対局時計';

  @override
  String get modeBreaks => '休憩';

  @override
  String get modeDescBreaks => '目の休憩とストレッチのリマインダー';

  @override
  String get modeAmbient => '環境音';

  @override
  String get modeDescAmbient => 'スリープタイマー付きの環境音';

  @override
  String get intervalsPresetTabata => 'タバタ';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'カスタム';

  @override
  String get intervalsWarmUp => 'ウォームアップ';

  @override
  String get intervalsWork => 'ワーク';

  @override
  String get intervalsRest => '休憩';

  @override
  String get intervalsRounds => 'ラウンド';

  @override
  String get intervalsCoolDown => 'クールダウン';

  @override
  String get intervalsOff => 'なし';

  @override
  String intervalsRound(int current, int total) {
    return 'ラウンド $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return '合計 $duration';
  }

  @override
  String get intervalsSkip => '次のフェーズへ';

  @override
  String get intervalsHint => '行をタップして編集します。変更はカスタムとして保存されます。';

  @override
  String get intervalsDoneTitle => 'ワークアウト完了';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration。お疲れさまでした!';
  }

  @override
  String get kitchenPasta => 'パスタ';

  @override
  String get kitchenEggs => '卵';

  @override
  String get kitchenTea => 'お茶';

  @override
  String get kitchenRice => 'ごはん';

  @override
  String get kitchenOven => 'オーブン';

  @override
  String get kitchenCustom => 'カスタム';

  @override
  String get kitchenNameHint => '名前';

  @override
  String get kitchenAdd => 'タイマー開始';

  @override
  String get kitchenDelete => 'タイマーを削除';

  @override
  String get kitchenEmpty => 'タイマーはありません。上のチップをタップして開始します。';

  @override
  String get kitchenDefaultName => 'タイマー';

  @override
  String kitchenDoneTitle(String name) {
    return '$nameができました';
  }

  @override
  String kitchenDoneBody(String duration) {
    return '$durationのタイマーが終了しました。';
  }

  @override
  String get trackerToday => '今日';

  @override
  String get trackerWeek => '過去7日間';

  @override
  String get trackerTapToStart => 'アクティビティをタップして計測を開始';

  @override
  String get trackerNoRunning => '計測中なし';

  @override
  String get trackerAddActivity => '新しいアクティビティ';

  @override
  String get trackerNameHint => '名前';

  @override
  String get trackerStudy => '勉強';

  @override
  String get trackerReading => '読書';

  @override
  String get trackerCode => 'コーディング';

  @override
  String get trackerExercise => '運動';

  @override
  String get trackerEdit => 'アクティビティを編集';

  @override
  String get trackerDetails => '詳細とグラフ';

  @override
  String get trackerColor => '色';

  @override
  String get trackerIcon => 'アイコン';

  @override
  String get trackerDelete => 'アクティビティを削除';

  @override
  String get trackerDeleteConfirm => '確認：このアクティビティを削除';

  @override
  String get trackerDeleteHint => '記録済みの時間は履歴に残ります。';

  @override
  String get trackerAddTime => '時間を手動で追加';

  @override
  String trackerAddMinutes(int minutes) {
    return '$minutes分を追加';
  }

  @override
  String get trackerMinutesFewer => '分を減らす';

  @override
  String get trackerMinutesMore => '分を増やす';

  @override
  String get trackerStop => '停止';

  @override
  String get versusDuel => '対戦';

  @override
  String get versusSpeakers => 'スピーカー';

  @override
  String get versusCustom => 'カスタム';

  @override
  String get versusIncrement => '加算';

  @override
  String get versusTapToStart => '自分の側をタップして時計を開始';

  @override
  String get versusTimeIsUp => '時間切れ';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count手',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => '対局をリセット';

  @override
  String get versusConfirmReset => 'リセットを確認';

  @override
  String versusSpeakerN(int n) {
    return 'スピーカー $n';
  }

  @override
  String get versusAddSpeaker => 'スピーカーを追加';

  @override
  String get versusRemoveSpeaker => 'スピーカーを削除';

  @override
  String get versusSpeakerName => 'スピーカーまたはトピック';

  @override
  String get versusNext => '次のスピーカー';

  @override
  String get versusFinish => '終了';

  @override
  String get versusOvertime => '超過';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed / $planned';
  }

  @override
  String get versusAgendaDone => '議題が終了';

  @override
  String get versusStartAgenda => '議題を開始';

  @override
  String get versusMinutesFewer => '分を減らす';

  @override
  String get versusMinutesMore => '分を増やす';

  @override
  String get versusTotal => '合計';

  @override
  String get breatheInhale => '吸う';

  @override
  String get breatheHold => '止める';

  @override
  String get breatheExhale => '吐く';

  @override
  String get breatheStart => '呼吸を始める';

  @override
  String get breathePause => '一時停止';

  @override
  String get breatheResume => '再開';

  @override
  String get breatheReset => 'セッションを終了';

  @override
  String get breatheDone => 'お疲れさまでした';

  @override
  String get breatheReady => '楽な姿勢になりましょう';

  @override
  String get breathePatternBox => 'ボックス';

  @override
  String get breathePatternCoherent => 'コヒーレント';

  @override
  String get breathePatternCalm => 'リラックス';

  @override
  String get breathePatternCustom => 'カスタム';

  @override
  String get breatheSession => '時間';

  @override
  String get breatheEndless => '無制限';

  @override
  String breatheSeconds(int n) {
    return '$n秒';
  }

  @override
  String get ambientWhite => 'ホワイトノイズ';

  @override
  String get ambientPink => 'ピンクノイズ';

  @override
  String get ambientBrown => 'ブラウンノイズ';

  @override
  String get ambientRain => '雨';

  @override
  String get ambientWind => '風';

  @override
  String get ambientOcean => '海';

  @override
  String get ambientVolume => '音量';

  @override
  String get ambientSleepTimer => 'スリープタイマー';

  @override
  String get ambientTimerOff => 'オフ';

  @override
  String get ambientPlay => 'サウンドを再生';

  @override
  String get ambientStop => 'サウンドを停止';

  @override
  String get ambientUnavailable => 'このデバイスではサウンドを再生できません。';

  @override
  String get ambientPreparing => 'サウンドを準備中…';

  @override
  String ambientTimeLeft(String time) {
    return '残り $time';
  }

  @override
  String get breaksStart => '休憩を開始';

  @override
  String get breaksStop => '休憩を停止';

  @override
  String get breaksStatusOff => '休憩リマインダーはオフです';

  @override
  String get breaksNoneEnabled => 'リマインダーを1つ以上オンにしてください';

  @override
  String breaksNextName(String name) {
    return '次: $name';
  }

  @override
  String get breaksToday => '今日';

  @override
  String get breaksTaken => '取った休憩';

  @override
  String get breaksSkipped => 'スキップ';

  @override
  String get breaksEyeName => '目の休憩 (20-20-20)';

  @override
  String get breaksEyeHint => '6m先を20秒間見つめましょう';

  @override
  String get breaksStretchName => 'ストレッチ';

  @override
  String get breaksStretchHint => '立ち上がって全身を伸ばしましょう';

  @override
  String get breaksWaterName => '水を飲む';

  @override
  String get breaksWaterHint => 'コップ1杯の水を飲みましょう';

  @override
  String get breaksPostureName => '姿勢チェック';

  @override
  String get breaksPostureHint => '背筋を伸ばして肩の力を抜きましょう';

  @override
  String get breaksCustomDefault => 'マイリマインダー';

  @override
  String breaksForDuration(String duration) {
    return '$duration休みましょう';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return '$minutes分ごと';
  }

  @override
  String get breaksShorter => '間隔を短く';

  @override
  String get breaksLonger => '間隔を長く';

  @override
  String get breaksDone => '完了';

  @override
  String get breaksSkip => 'スキップ';

  @override
  String get breaksActiveHours => '有効な時間帯';

  @override
  String get breaksActiveHoursHint => 'この時間帯のみリマインダーを表示します';

  @override
  String get breaksFrom => '開始';

  @override
  String get breaksTo => '終了';

  @override
  String get breaksLaterHour => '遅く';

  @override
  String get breaksEarlierHour => '早く';

  @override
  String get breaksBackground => 'Enfoを閉じていても';

  @override
  String get breaksBackgroundOn => 'アプリを閉じていても通知でお知らせします。';

  @override
  String get breaksBackgroundOff => 'Enfoを開いている間だけリマインダーを表示します。';

  @override
  String get breaksDesktopNotice => 'Enfoが起動している間はリマインダーが表示されます（最小化でも可）。';

  @override
  String get breaksAddCustom => 'カスタムリマインダーを追加';

  @override
  String get breaksEdit => 'リマインダーを編集';

  @override
  String get breaksName => '名前';

  @override
  String get breaksDuration => '長さ';

  @override
  String get breaksIcon => 'アイコン';

  @override
  String get breaksShorterDuration => '休憩を短く';

  @override
  String get breaksLongerDuration => '休憩を長く';

  @override
  String get breaksRemove => 'リマインダーを削除';

  @override
  String get breaksRemoveConfirm => '確認: リマインダーを削除';

  @override
  String get breaksRemoveHint => '通知されなくなります。';

  @override
  String get worldPlan => '会議を計画';

  @override
  String get worldPlanIntro => 'マーカーを動かして、全員に都合のよい時間を探しましょう。';

  @override
  String get worldPlanNow => '現在';

  @override
  String get worldPlanEarlier => '15分前へ';

  @override
  String get worldPlanLater => '15分後へ';

  @override
  String worldPlanSelected(String city) {
    return '$cityでの選択時刻';
  }

  @override
  String get worldPlanTapCity => '都市をタップすると、その時刻が基準になります。';

  @override
  String get worldPlanNextDay => '+1日';

  @override
  String get worldPlanPrevDay => '-1日';

  @override
  String get worldPlanOverlapTitle => '全員が勤務時間内';

  @override
  String get worldPlanNoOverlap => '今後24時間に全員が都合のつく時間はありません。';

  @override
  String worldPlanLeastBad(String time) {
    return '次善: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$total人中$count人が勤務時間内';
  }

  @override
  String get worldPlanWork => '勤務時間 (09-18)';

  @override
  String get worldPlanNight => '夜';

  @override
  String get worldPlanMarker => '選択した時刻';

  @override
  String get eventAdd => '新しいイベント';

  @override
  String get eventEdit => 'イベントを編集';

  @override
  String get eventName => '名前';

  @override
  String get eventNameHint => '誕生日、旅行、発売日など';

  @override
  String get eventYearly => '毎年繰り返す';

  @override
  String get eventYearlyHint => '誕生日や記念日向け。自動的に次の日付へ進みます。';

  @override
  String get eventNotify => '通知する';

  @override
  String get eventNotifyHint => 'その時刻になったとき。';

  @override
  String get eventDayBefore => '前日にも通知';

  @override
  String get eventSave => '保存';

  @override
  String get eventDelete => 'イベントを削除';

  @override
  String get eventConfirmDelete => '確認：イベントを削除';

  @override
  String get eventDeleteHint => 'このイベントは削除されます。';

  @override
  String get eventEmpty => 'イベントはまだありません。\n＋をタップしてカウントダウンを作成しましょう。';

  @override
  String get eventToday => '今日！';

  @override
  String eventDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get eventDaysShort => '日';

  @override
  String get eventUnitDays => '日';

  @override
  String get eventUnitHours => '時間';

  @override
  String get eventUnitMinutes => '分';

  @override
  String get eventRepeatsYearly => '毎年';

  @override
  String get eventNotifyNow => 'その時が来ました！';

  @override
  String get eventNotifyTomorrow => '明日';

  @override
  String get sleepPlanWake => '起きる時刻';

  @override
  String get sleepPlanBed => '寝る時刻';

  @override
  String get sleepPlanNow => '今すぐ寝る';

  @override
  String get sleepTitleWake => '起きたい時刻';

  @override
  String get sleepTitleBed => '寝る時刻';

  @override
  String sleepTitleNow(String time) {
    return '今から寝るなら（$time）';
  }

  @override
  String get sleepBedtimeWord => '就寝';

  @override
  String get sleepWakeWord => '起床';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cyclesサイクル・睡眠 $duration';
  }

  @override
  String get sleepNote => '1サイクルは90分、寝つくまでに約15分かかります。5〜6サイクルがおすすめです。';

  @override
  String get sleepWindDown => 'リラックスのお知らせ';

  @override
  String get sleepWindDownHint => '就寝の30分前にアラームが鳴ります。';

  @override
  String get sleepWindDownPassed => 'その時刻はすでに過ぎています。';

  @override
  String get sleepWindDownLabel => 'そろそろリラックスの時間';

  @override
  String get sleepAlarmLabel => '起床';

  @override
  String get sleepSetAlarm => 'アラームを設定';

  @override
  String get sleepRemoveAlarm => 'アラームを削除';

  @override
  String sleepAlarmSet(String time) {
    return '$time にアラームを設定しました';
  }

  @override
  String get sleepPast => 'この時刻はすでに過ぎています';

  @override
  String get sleepRecommended => 'おすすめ';

  @override
  String get ambientMusicTabSounds => 'サウンド';

  @override
  String get ambientMusicTab => '音楽';

  @override
  String get ambientMusicPlay => '音楽を再生';

  @override
  String get ambientMusicPause => '音楽を一時停止';

  @override
  String get ambientMusicNext => '次の曲';

  @override
  String get ambientMusicPrevious => '前の曲';

  @override
  String get ambientMusicShuffle => 'シャッフル';

  @override
  String get ambientMusicRepeat => '全曲リピート';

  @override
  String get ambientMusicVolume => '音楽の音量';

  @override
  String get ambientMusicCredits => '音楽クレジット';

  @override
  String get ambientMusicCreditsNote =>
      'Wikimedia Commons の楽曲。CC0 または クリエイティブ・コモンズ 表示ライセンスで公開されています。';

  @override
  String get modeMusic => '音楽';

  @override
  String get modeDescMusic => '集中のためのローファイ音楽';

  @override
  String get musicCreditsSubtitle => 'アーティストとライセンス';

  @override
  String get displayMenuButtons => 'メニューボタン';

  @override
  String get displayMenuButtonsHint => '下のメニューに表示するボタンを選びます。設定は常に表示されます。';

  @override
  String get onbWelcomeTitle => 'Enfoへようこそ';

  @override
  String get onbWelcomeTagline => '集中を、ひとつの静かなダイヤルに。';

  @override
  String get timerRunningTitle => 'タイマー実行中';

  @override
  String timerRunningBody(String time) {
    return '$time に終了';
  }

  @override
  String get timerPausedTitle => 'タイマー一時停止';

  @override
  String timerPausedBody(String duration) {
    return '残り $duration';
  }

  @override
  String get musicActionPlay => '再生';

  @override
  String get musicActionPause => '一時停止';

  @override
  String get widgetsFocusSubtitle =>
      'Today\\\'s focus time and pomodoros at a glance.';
}
