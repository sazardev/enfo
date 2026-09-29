// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => '设置';

  @override
  String get tooltipStats => '统计';

  @override
  String get tooltipPin => '保持置顶';

  @override
  String get tooltipUnpin => '取消置顶';

  @override
  String get phasePaused => '已暂停';

  @override
  String get phaseFocus => '专注';

  @override
  String get phaseRelax => '休息';

  @override
  String get notifRestTitle => '该休息了';

  @override
  String get notifRestBody => '喘口气吧。';

  @override
  String get notifWorkTitle => '该工作了';

  @override
  String get notifWorkBody => '继续加油！';

  @override
  String get onboardingStart => '开始';

  @override
  String get rhythmTitle => '专注节奏';

  @override
  String get presetClassic => '经典';

  @override
  String get presetExtended => '延长';

  @override
  String get presetDeep => '深度';

  @override
  String get presetManual => '自定义';

  @override
  String get workLabel => '专注';

  @override
  String get restLabel => '休息';

  @override
  String minutes(int n) {
    return '$n 分钟';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest 分钟';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get timersTitle => '时长';

  @override
  String timersSubtitle(int work, int rest) {
    return '专注 $work 分钟 · 休息 $rest 分钟';
  }

  @override
  String timersCycle(int total) {
    return '完整一轮：$total 分钟';
  }

  @override
  String get timersApplyHint => '如果计时正在运行，更改将从下一轮开始生效；如果已暂停，计时将重置。';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceLight => '浅色主题';

  @override
  String get appearanceDark => '深色主题';

  @override
  String get darkTheme => '深色主题';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get accentColor => '强调色';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsOn => '已开启';

  @override
  String get notificationsOff => '已关闭';

  @override
  String get notificationsToggle => '阶段切换提醒';

  @override
  String get notificationsHint => '到了休息或回到工作的时间时收到提醒。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageHint => '选择应用语言。';

  @override
  String get supportTitle => '支持 Enfo';

  @override
  String get supportSubtitle => '咖啡与广告';

  @override
  String get supportSubtitleNoAds => '请我喝杯咖啡';

  @override
  String get buyCoffee => '请我喝杯咖啡';

  @override
  String get watchAd => '观看广告以支持我';

  @override
  String get supportHint => 'Enfo 免费，由一个人独立开发。感谢你的使用。';

  @override
  String get statsTitle => '统计';

  @override
  String get statsEmpty => '还没有记录。\n开始一个番茄钟，记录就会出现在这里。';

  @override
  String get statsTodayPomodoros => '今日番茄钟';

  @override
  String get statsTodayFocus => '今日专注';

  @override
  String get statsCompleted => '已完成';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连续天数',
      one: '连续天数',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => '最近 7 天';

  @override
  String get statsTotalFocus => '总专注时间';

  @override
  String get statsTotalRest => '总休息时间';

  @override
  String get statsAbandoned => '已放弃';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  完成率 $percent%';
  }

  @override
  String get statsAverageFocus => '平均专注时长';

  @override
  String get statsLongestSession => '最长一次';

  @override
  String get statsPauses => '暂停';

  @override
  String get statsAverageGap => '两次之间的平均间隔';

  @override
  String get statsLongestGap => '最长未启动时间';

  @override
  String get statsSinceLast => '距上次已过';

  @override
  String get statsHistory => '历史记录';

  @override
  String get statsClearHistory => '清除历史记录';

  @override
  String get statsClearConfirm => '确认：删除所有记录';

  @override
  String get statsClearHint => '此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get sessionFocus => '专注';

  @override
  String get sessionRest => '休息';

  @override
  String sessionProgress(String done, String planned) {
    return '$done/$planned';
  }

  @override
  String sessionPauses(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '暂停 $count 次',
      one: '暂停 1 次',
    );
    return '$_temp0（$time）';
  }

  @override
  String sessionIdleBefore(String gap) {
    return '闲置 $gap 后';
  }

  @override
  String get sessionCompleted => '已完成';

  @override
  String get sessionAbandoned => '已放弃';

  @override
  String get clockStyleTitle => '时钟样式';

  @override
  String get tooltipClockStyle => '时钟样式';

  @override
  String get clockCategoryProgress => '进度与数字';

  @override
  String get clockCategoryNumbers => '仅数字';

  @override
  String get clockCategoryIcons => '仅图标';

  @override
  String get clockCategoryMotion => '仅动画';

  @override
  String get clockUnitMinutes => '分';

  @override
  String get clockUnitSeconds => '秒';

  @override
  String get clockRing => '圆环';

  @override
  String get clockWavyRing => '波浪环';

  @override
  String get clockSegments => '分段';

  @override
  String get clockOrbit => '轨道';

  @override
  String get clockPie => '饼图';

  @override
  String get clockKitchen => '厨房';

  @override
  String get clockDots => '圆点';

  @override
  String get clockBar => '进度条';

  @override
  String get clockWavyBar => '波浪条';

  @override
  String get clockDigits => '数字';

  @override
  String get clockMinutes => '分钟';

  @override
  String get clockTiles => '方块';

  @override
  String get clockStack => '堆叠';

  @override
  String get clockTomato => '番茄';

  @override
  String get clockHourglass => '沙漏';

  @override
  String get clockBattery => '电池';

  @override
  String get clockIcon => '图标';

  @override
  String get clockCookie => '饼干';

  @override
  String get clockLiquid => '液体';

  @override
  String get clockBreathe => '呼吸';

  @override
  String get clockEqualizer => '均衡器';

  @override
  String get clockRipple => '涟漪';

  @override
  String get accentApply => '应用';

  @override
  String get accentCustom => '自定义颜色';

  @override
  String get accentHue => '色相';

  @override
  String get accentSaturation => '饱和度';

  @override
  String get accentBrightness => '亮度';

  @override
  String get accentHex => '十六进制码';

  @override
  String get displayTitle => '显示';

  @override
  String get displayClockShown => '显示时间';

  @override
  String get displayClockHidden => '隐藏时间';

  @override
  String get showClock => '显示时间';

  @override
  String get showClockHint => '计时器上方的小时钟。';

  @override
  String get clockFormat => '时间格式';

  @override
  String get clockFormatSystem => '跟随系统';

  @override
  String get clockFormat12 => '12 小时制';

  @override
  String get clockFormat24 => '24 小时制';

  @override
  String get behaviorTitle => '行为';

  @override
  String get autoStartNext => '自动开始下一阶段';

  @override
  String get autoStartNextHint => '专注或休息结束后，无需点击即可开始下一阶段。';

  @override
  String get hapticFeedback => '振动';

  @override
  String get hapticFeedbackHint => '点按、滚轮、阶段切换和闹钟。';

  @override
  String get clockCombosTitle => '组合';

  @override
  String get clockCollapseAll => '全部收起';

  @override
  String get clockExpandAll => '全部展开';

  @override
  String get comboDeepFocus => '深度专注';

  @override
  String get comboMint => '清新薄荷';

  @override
  String get comboSunset => '日落';

  @override
  String get comboZen => '禅';

  @override
  String get comboTomato => '经典番茄';

  @override
  String get comboNight => '夜猫子';

  @override
  String get comboPlayful => '俏皮';

  @override
  String get comboMinimal => '极简';

  @override
  String get uiSizeTitle => '界面大小';

  @override
  String get uiSizeSmall => '小';

  @override
  String get uiSizeNormal => '标准';

  @override
  String get uiSizeLarge => '大';

  @override
  String get uiSizeExtraLarge => '特大';

  @override
  String get uiSizeHint => '放大或缩小文字和控件，适合电视和车载屏幕。';

  @override
  String get clockBlob => '软泥';

  @override
  String get clockFlower => '花朵';

  @override
  String get clockSun => '太阳';

  @override
  String get clockGears => '齿轮';

  @override
  String get clockBubbles => '气泡';

  @override
  String get clockSunflower => '向日葵';

  @override
  String get clockFireflies => '萤火虫';

  @override
  String get clockPendulum => '摆锤';

  @override
  String get clockBounce => '弹跳';

  @override
  String get clockMorph => '变形';

  @override
  String get dataTitle => '数据';

  @override
  String get dataSubtitle => '历史记录、重置和引导页';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已保存 $count 条记录',
      one: '已保存 1 条记录',
      zero: '没有已保存的活动',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => '重新查看引导页';

  @override
  String get dataIntroHint => '重温欢迎页面并再次选择你的节奏。不会删除任何内容。';

  @override
  String get dataClearHistoryHint => '删除所有已记录的活动：番茄钟、计时器、秒表、闹钟和时钟时长。设置不会改变。';

  @override
  String get dataConfirmClearHistory => '确认：清除历史记录';

  @override
  String get dataResetSettings => '重置设置';

  @override
  String get dataResetSettingsHint => '时长、主题、强调色、语言、模式和显示将恢复为默认值。历史记录会保留。';

  @override
  String get dataConfirmResetSettings => '确认：重置设置';

  @override
  String get dataEraseAll => '全部清除';

  @override
  String get dataEraseAllHint => '删除历史记录和设置，像第一次使用一样重新开始。';

  @override
  String get dataConfirmEraseAll => '确认：全部清除';

  @override
  String get dataDoneHistory => '历史记录已清除。';

  @override
  String get dataDoneSettings => '设置已重置。';

  @override
  String get dataCacheNote => 'Enfo 不保存缓存：它存储的只有这里介绍的历史记录和设置。';

  @override
  String get clockEndsAt => '结束于';

  @override
  String get clockFill => '填充';

  @override
  String get clockCapsule => '胶囊';

  @override
  String get clockRollers => '滚筒';

  @override
  String get clockMatrix => '点阵';

  @override
  String get clockSevenSeg => '数码管';

  @override
  String get clockFlip => '翻页';

  @override
  String get clockFine => '纤细';

  @override
  String get clockSuperscript => '上标';

  @override
  String get clockPercent => '百分比';

  @override
  String get clockEndTime => '结束时刻';

  @override
  String get clockSeconds => '秒数';

  @override
  String get clockTall => '高瘦';

  @override
  String get clockWobble => '波动';

  @override
  String get clockLabeled => '带标签';

  @override
  String get clockGauge => '仪表';

  @override
  String get clockNeedle => '指针';

  @override
  String get clockAnalog => '指针式';

  @override
  String get clockRings => '多环';

  @override
  String get clockSquircle => '圆角方';

  @override
  String get clockColumns => '柱状';

  @override
  String get clockVertical => '竖向';

  @override
  String get clockSteps => '步进';

  @override
  String get clockBlocks => '积木';

  @override
  String get clockSpiral => '螺旋';

  @override
  String get clockSlices => '果瓣';

  @override
  String get clockPills => '药丸';

  @override
  String get clockHexagon => '六边形';

  @override
  String get clockStairs => '楼梯';

  @override
  String get clockCandle => '蜡烛';

  @override
  String get clockMoon => '月亮';

  @override
  String get clockRuler => '尺子';

  @override
  String get comboArcade => '街机';

  @override
  String get comboCalculator => '计算器';

  @override
  String get comboDepartures => '火车站';

  @override
  String get comboCandlelight => '烛光';

  @override
  String get comboMoonlight => '月光';

  @override
  String get comboGarden => '花园';

  @override
  String get comboSummer => '夏日';

  @override
  String get comboWorkshop => '工坊';

  @override
  String get comboFizzy => '气泡水';

  @override
  String get comboSunfield => '向日葵田';

  @override
  String get comboSummerNight => '夏夜';

  @override
  String get comboHypnosis => '催眠';

  @override
  String get comboBouncy => '蹦蹦跳';

  @override
  String get comboShapeshifter => '变形者';

  @override
  String get comboLava => '熔岩灯';

  @override
  String get comboOcean => '海洋';

  @override
  String get comboPulse => '脉冲';

  @override
  String get comboPond => '池塘';

  @override
  String get comboEspresso => '浓缩咖啡';

  @override
  String get comboSpeedometer => '速度表';

  @override
  String get comboCompass => '指南针';

  @override
  String get comboClassicClock => '经典时钟';

  @override
  String get comboConcentric => '同心圆';

  @override
  String get comboRounded => '圆润';

  @override
  String get comboSignal => '信号';

  @override
  String get comboThermometer => '温度计';

  @override
  String get comboMilestones => '里程碑';

  @override
  String get comboRetroBlocks => '复古方块';

  @override
  String get comboHypnoSpiral => '催眠螺旋';

  @override
  String get comboCitrus => '柑橘';

  @override
  String get comboChocolate => '巧克力板';

  @override
  String get comboCrystal => '水晶';

  @override
  String get comboStaircase => '阶梯';

  @override
  String get comboTapeMeasure => '卷尺';

  @override
  String get comboBoldType => '粗体字';

  @override
  String get comboPill => '胶囊';

  @override
  String get comboSlotMachine => '老虎机';

  @override
  String get comboWhisper => '低语';

  @override
  String get comboDeadline => '截止时间';

  @override
  String get comboPercentage => '百分比';

  @override
  String get comboStopwatch => '仅秒数';

  @override
  String get comboSkyscraper => '摩天大楼';

  @override
  String get comboWaveText => '波浪文字';

  @override
  String get comboDashboard => '仪表盘';

  @override
  String get comboExponent => '指数';

  @override
  String get comboGrandmaKitchen => '外婆的厨房';

  @override
  String get comboCyber => '赛博';

  @override
  String get comboCandy => '糖果';

  @override
  String get comboConfetti => '彩纸';

  @override
  String get comboCookieJar => '饼干罐';

  @override
  String get comboSandbox => '沙盒';

  @override
  String get comboPizzaNight => '披萨之夜';

  @override
  String get onbLanguageTitle => '你的语言';

  @override
  String get onbLanguageBody => '选择你的语言。这里的所有选择之后都可以在设置中更改。';

  @override
  String get onbRhythmTitle => '你的节奏';

  @override
  String get onbRhythmBody => '专注多久，休息多久。';

  @override
  String get onbLookTitle => '打造专属风格';

  @override
  String get onbLookBody => '主题、时钟样式和颜色。先选一个组合,再按需微调颜色。';

  @override
  String get onbClockTitle => '选择时钟';

  @override
  String get onbClockBody => '现成的搭配：一种时钟样式加一种颜色，一键应用。';

  @override
  String get onbAllStyles => '查看所有样式';

  @override
  String get onbOptionsTitle => '最后的细节';

  @override
  String get onbOptionsBody => '显示与行为。这些在设置中同样可以找到。';

  @override
  String get onbModesTitle => '你的工具';

  @override
  String get onbModesBody => 'Enfo 是一个时钟与计时工具箱。打开你要用的功能,之后可随时在模式菜单中更改。';

  @override
  String get onbPreview => '预览';

  @override
  String get onbDisplayTitle => '显示';

  @override
  String get onbDisplayBody => '时钟的外观与界面大小。';

  @override
  String get onbClockModeDesign => '时钟模式样式';

  @override
  String get onbPermTitle => '权限';

  @override
  String get onbPermBody => '这样即使 Enfo 已关闭,计时器和闹钟也能提醒你。';

  @override
  String get onbPermNotifications => '通知';

  @override
  String get onbPermNotificationsHint => '计时结束或闹钟响起时提醒你。';

  @override
  String get onbPermExact => '精确闹钟';

  @override
  String get onbPermExactHint => '即使在省电模式下也准点响起。';

  @override
  String get onbPermAllow => '允许';

  @override
  String get onbPermAllowed => '已允许';

  @override
  String get onbPermLater => '你可以随时在系统设置中更改。';

  @override
  String get onbNext => '下一步';

  @override
  String get onbBack => '返回';

  @override
  String get onbSkip => '跳过';

  @override
  String onbStepOf(int step, int total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get clockFormatAuto => '自动';

  @override
  String get modePomodoro => '番茄钟';

  @override
  String get modeClock => '时钟';

  @override
  String get modeTimer => '计时器';

  @override
  String get modeStopwatch => '秒表';

  @override
  String get modeAlarm => '闹钟';

  @override
  String get modeWorld => '世界时间';

  @override
  String get modeDescPomodoro => '专注与休息循环';

  @override
  String get modeDescClock => '一个漂亮的时钟，始终可见';

  @override
  String get modeDescTimer => '从任意时长开始倒计时';

  @override
  String get modeDescStopwatch => '计时并记录分段';

  @override
  String get modeDescAlarm => '叫醒或提醒你';

  @override
  String get modeDescWorld => '世界各城市的时间';

  @override
  String get tooltipModes => '模式';

  @override
  String get tooltipSwitchMode => '下一个模式';

  @override
  String get tooltipFullscreen => '全屏';

  @override
  String get tooltipExitFullscreen => '退出全屏';

  @override
  String get tooltipDim => '调暗屏幕';

  @override
  String get modesTitle => '模式';

  @override
  String get modesHint => '选择要使用的模式及其顺序。拖动可重新排序。';

  @override
  String get modesStart => '启动时进入';

  @override
  String get modesStartLast => '上次使用的模式';

  @override
  String get modesCustomize => '自定义';

  @override
  String get modesActivity => '活动记录';

  @override
  String get modesAtLeastOne => '至少要保留一个启用的模式。';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已启用 $count 个模式',
      one: '已启用 1 个模式',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => '活动记录';

  @override
  String get activityTitle => '活动';

  @override
  String get activityEmpty => '暂无内容。\n使用计时器、秒表、闹钟或时钟后，记录会显示在这里。';

  @override
  String get activityFilterAll => '全部';

  @override
  String get activityTimersToday => '今日计时器';

  @override
  String get activityStopwatchToday => '今日秒表';

  @override
  String get activityDisplayToday => '今日显示';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 圈',
      one: '1 圈',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return '第 $n 圈';
  }

  @override
  String get activityAlarmDismissed => '已关闭';

  @override
  String get activityAlarmSnoozed => '已延后';

  @override
  String get activityAlarmMissed => '已错过';

  @override
  String activityDisplay(String mode) {
    return '$mode显示';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done/$planned';
  }

  @override
  String get faceRing => '圆环';

  @override
  String get faceDigital => '数字';

  @override
  String get faceAnalog => '指针';

  @override
  String get faceSplit => '大字';

  @override
  String get faceDay => '日';

  @override
  String get tooltipCustomize => '自定义';

  @override
  String get clockSettingsTitle => '自定义时钟';

  @override
  String get clockFaceTitle => '布局';

  @override
  String get clockShowSeconds => '显示秒';

  @override
  String get clockShowDate => '显示日期';

  @override
  String get clockBlinkColon => '冒号闪烁';

  @override
  String get clockKeepAwake => '保持屏幕常亮';

  @override
  String get clockKeepAwakeHint => '时钟显示期间有效。';

  @override
  String get clockFullscreenHint => '点按全屏，即可得到常亮的桌面时钟。滑动时钟可切换布局。';

  @override
  String clockDayPercent(int percent) {
    return '今天已过 $percent%';
  }

  @override
  String get ringDismiss => '关闭';

  @override
  String ringSnooze(int minutes) {
    return '延后 $minutes 分钟';
  }

  @override
  String get timerStart => '开始';

  @override
  String get timerPause => '暂停';

  @override
  String get timerResume => '继续';

  @override
  String get timerReset => '重置';

  @override
  String get timerAddMinute => '+1 分钟';

  @override
  String get timerHoursShort => '时';

  @override
  String get timerMinutesShort => '分';

  @override
  String get timerSecondsShort => '秒';

  @override
  String get timerUpTitle => '时间到';

  @override
  String timerUpBody(String duration) {
    return '$duration的计时器已结束。';
  }

  @override
  String get timerSavePreset => '保存此时长';

  @override
  String get timerPresetHint => '点按 + 保存此时长。长按预设可将其移除。';

  @override
  String get stopwatchStop => '停止';

  @override
  String get stopwatchLap => '分圈';

  @override
  String get stopwatchLapBest => '最快';

  @override
  String get stopwatchLapWorst => '最慢';

  @override
  String get worldLocal => '本地时间';

  @override
  String get worldToday => '今天';

  @override
  String get worldTomorrow => '明天';

  @override
  String get worldYesterday => '昨天';

  @override
  String get worldAdd => '添加城市';

  @override
  String get worldSearch => '搜索城市';

  @override
  String get worldNoResults => '没有匹配的城市。';

  @override
  String get worldEdit => '编辑列表';

  @override
  String get worldDone => '完成';

  @override
  String get worldRemove => '移除';

  @override
  String get worldEmpty => '还没有其他城市。点按 + 添加。';

  @override
  String get worldSameTime => '与你的时间相同';

  @override
  String worldDiffAhead(String diff) {
    return '比你早 $diff';
  }

  @override
  String worldDiffBehind(String diff) {
    return '比你晚 $diff';
  }

  @override
  String alarmNext(String duration) {
    return '下一个闹钟在 $duration后';
  }

  @override
  String get alarmNone => '没有启用的闹钟';

  @override
  String get alarmNew => '新建闹钟';

  @override
  String get alarmEditTitle => '编辑闹钟';

  @override
  String get alarmLabel => '标签';

  @override
  String get alarmRepeat => '重复';

  @override
  String get alarmSave => '保存';

  @override
  String get alarmDelete => '删除闹钟';

  @override
  String get alarmConfirmDelete => '确认：删除闹钟';

  @override
  String get alarmDeleteHint => '此闹钟将被删除。';

  @override
  String get alarmEmpty => '还没有闹钟。\n点按 + 创建。';

  @override
  String get alarmEveryDay => '每天';

  @override
  String get alarmWeekdays => '工作日';

  @override
  String get alarmWeekends => '周末';

  @override
  String get alarmOnce => '仅一次';

  @override
  String get alarmPermissionHint => '要在应用关闭时响铃，Enfo 需要通知和精确闹钟的权限。';

  @override
  String get alarmPermissionButton => '允许闹钟';

  @override
  String get alarmDesktopHint => '在此设备上，Enfo 必须保持打开，闹钟才会响。';

  @override
  String get hapticsTitle => '振动';

  @override
  String get hapticsOff => '已关闭';

  @override
  String get hapticsStrength => '强度';

  @override
  String get hapticsSoft => '轻';

  @override
  String get hapticsMedium => '中';

  @override
  String get hapticsStrong => '强';

  @override
  String get hapticsTouch => '触碰';

  @override
  String get hapticsTouchHint => '按钮、开关和选择。';

  @override
  String get hapticsMotion => '动作';

  @override
  String get hapticsMotionHint => '滚轮、滑块、拖动和转场。';

  @override
  String get hapticsAlerts => '提醒';

  @override
  String get hapticsAlertsHint => '计时器、阶段切换、最后倒数和闹钟。';

  @override
  String get hapticsAlarmPattern => '闹钟振动模式';

  @override
  String get hapticsAlarmPatternHint => '点按一种模式即可感受。闹钟界面会以相同的节奏跳动。';

  @override
  String get hapticsPatternHeartbeat => '心跳';

  @override
  String get hapticsPatternPulse => '脉冲';

  @override
  String get hapticsPatternCrescendo => '渐强';

  @override
  String get hapticsPatternRipple => '涟漪';

  @override
  String get hapticsPatternBeacon => '灯塔';

  @override
  String get hapticsTry => '试一试';

  @override
  String get hapticsTryTap => '点按';

  @override
  String get hapticsTrySuccess => '成功';

  @override
  String get hapticsTryToRest => '专注结束';

  @override
  String get hapticsTryToWork => '休息结束';

  @override
  String get hapticsTryTimer => '计时结束';

  @override
  String get hapticsTryWarning => '警告';

  @override
  String get hapticsUnavailable => '此设备没有振动马达。';

  @override
  String get hapticsWhen => '振动时机';

  @override
  String get widgetsTitle => '小组件';

  @override
  String get widgetsSubtitle => '主屏幕上的时钟和计时器';

  @override
  String get widgetsAddHeader => '添加到主屏幕';

  @override
  String get widgetsAdd => '添加';

  @override
  String get widgetsDynamicColor => 'Material You 配色';

  @override
  String get widgetsDynamicColorHint => '小组件从你的壁纸中取色。关闭后将使用 Enfo 的强调色。';

  @override
  String get widgetsManualHint =>
      '你的桌面启动器不支持从这里添加小组件。请长按主屏幕，选择“小组件”，然后找到 Enfo。';

  @override
  String get widgetsStyleHint => '番茄钟和计时器小组件使用你所选的时钟样式绘制。在应用中更改样式，它们会随之更新。';

  @override
  String get widgetsTapHint => '小组件上的按钮会打开 Enfo 并执行操作，因此计时始终由应用负责。';

  @override
  String get shortcutsTitle => '键盘与遥控器';

  @override
  String get shortcutsSubtitle => '键盘、鼠标和电视遥控器的快捷键';

  @override
  String get shortcutsIntro => '用方向键或遥控器十字键移动，Enter 或 OK 键确认。其余操作使用以下按键。';

  @override
  String get shortcutKeySpace => '空格';

  @override
  String get shortcutPlayPause => '开始或暂停';

  @override
  String get shortcutReset => '重置';

  @override
  String get shortcutLap => '分圈（秒表）';

  @override
  String get shortcutJumpMode => '跳转到模式 1–9';

  @override
  String get shortcutStepMode => '上一个 / 下一个模式';

  @override
  String get shortcutFullscreen => '全屏';

  @override
  String get shortcutDim => '调暗屏幕（全屏时）';

  @override
  String get shortcutSettings => '设置';

  @override
  String get shortcutModes => '模式菜单';

  @override
  String get shortcutBack => '返回 / 退出全屏';

  @override
  String get shortcutHelp => '显示此列表';

  @override
  String get onbMoreTools => '更多工具';

  @override
  String get modeEvent => '日程倒数';

  @override
  String get modeDescEvent => '倒数重要的日子';

  @override
  String get modeIntervals => '间歇训练';

  @override
  String get modeDescIntervals => '类似 HIIT 的训练与休息轮次';

  @override
  String get modeBreathe => '呼吸';

  @override
  String get modeDescBreathe => '引导式呼吸,帮你放松';

  @override
  String get modeTracker => '时间记录';

  @override
  String get modeDescTracker => '记录做事用时并查看总计';

  @override
  String get modeKitchen => '厨房';

  @override
  String get modeDescKitchen => '同时运行多个命名计时器';

  @override
  String get modeSleep => '睡眠';

  @override
  String get modeDescSleep => '按睡眠周期规划入睡与起床';

  @override
  String get modeVersus => '轮流计时';

  @override
  String get modeDescVersus => '用于国际象棋、游戏和辩论的双人计时';

  @override
  String get modeBreaks => '休息提醒';

  @override
  String get modeDescBreaks => '提醒你护眼和伸展';

  @override
  String get modeAmbient => '环境音';

  @override
  String get modeDescAmbient => '带定时关闭的背景音';

  @override
  String get intervalsPresetTabata => '塔巴塔';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => '自定义';

  @override
  String get intervalsWarmUp => '热身';

  @override
  String get intervalsWork => '运动';

  @override
  String get intervalsRest => '休息';

  @override
  String get intervalsRounds => '轮数';

  @override
  String get intervalsCoolDown => '放松';

  @override
  String get intervalsOff => '无';

  @override
  String intervalsRound(int current, int total) {
    return '第 $current/$total 轮';
  }

  @override
  String intervalsTotal(String duration) {
    return '共 $duration';
  }

  @override
  String get intervalsSkip => '跳到下一阶段';

  @override
  String get intervalsHint => '点按一行即可编辑。任何更改都会保存为自定义。';

  @override
  String get intervalsDoneTitle => '训练完成';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration。干得漂亮!';
  }

  @override
  String get kitchenPasta => '意面';

  @override
  String get kitchenEggs => '鸡蛋';

  @override
  String get kitchenTea => '茶';

  @override
  String get kitchenRice => '米饭';

  @override
  String get kitchenOven => '烤箱';

  @override
  String get kitchenCustom => '自定义';

  @override
  String get kitchenNameHint => '名称';

  @override
  String get kitchenAdd => '开始计时';

  @override
  String get kitchenDelete => '删除计时器';

  @override
  String get kitchenEmpty => '还没有计时器。点按上方的选项开始。';

  @override
  String get kitchenDefaultName => '计时器';

  @override
  String kitchenDoneTitle(String name) {
    return '$name好了';
  }

  @override
  String kitchenDoneBody(String duration) {
    return '$duration计时已结束。';
  }

  @override
  String get trackerToday => '今天';

  @override
  String get trackerWeek => '最近7天';

  @override
  String get trackerTapToStart => '点按活动开始计时';

  @override
  String get trackerNoRunning => '没有进行中的活动';

  @override
  String get trackerAddActivity => '新建活动';

  @override
  String get trackerNameHint => '名称';

  @override
  String get trackerStudy => '学习';

  @override
  String get trackerReading => '阅读';

  @override
  String get trackerCode => '编程';

  @override
  String get trackerExercise => '运动';

  @override
  String get trackerEdit => '编辑活动';

  @override
  String get trackerDetails => '详情与图表';

  @override
  String get trackerColor => '颜色';

  @override
  String get trackerIcon => '图标';

  @override
  String get trackerDelete => '删除活动';

  @override
  String get trackerDeleteConfirm => '确认：删除此活动';

  @override
  String get trackerDeleteHint => '已记录的时间会保留在历史中。';

  @override
  String get trackerAddTime => '手动添加时间';

  @override
  String trackerAddMinutes(int minutes) {
    return '添加 $minutes 分钟';
  }

  @override
  String get trackerMinutesFewer => '减少分钟';

  @override
  String get trackerMinutesMore => '增加分钟';

  @override
  String get trackerStop => '停止';

  @override
  String get versusDuel => '对弈';

  @override
  String get versusSpeakers => '发言人';

  @override
  String get versusCustom => '自定义';

  @override
  String get versusIncrement => '加时';

  @override
  String get versusTapToStart => '点按你这一侧开始计时';

  @override
  String get versusTimeIsUp => '时间到';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => '重置对局';

  @override
  String get versusConfirmReset => '确认重置';

  @override
  String versusSpeakerN(int n) {
    return '发言人 $n';
  }

  @override
  String get versusAddSpeaker => '添加发言人';

  @override
  String get versusRemoveSpeaker => '移除发言人';

  @override
  String get versusSpeakerName => '发言人或主题';

  @override
  String get versusNext => '下一位发言人';

  @override
  String get versusFinish => '结束';

  @override
  String get versusOvertime => '超时';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed / $planned';
  }

  @override
  String get versusAgendaDone => '议程结束';

  @override
  String get versusStartAgenda => '开始议程';

  @override
  String get versusMinutesFewer => '减少分钟';

  @override
  String get versusMinutesMore => '增加分钟';

  @override
  String get versusTotal => '总计';

  @override
  String get breatheInhale => '吸气';

  @override
  String get breatheHold => '屏息';

  @override
  String get breatheExhale => '呼气';

  @override
  String get breatheStart => '开始呼吸';

  @override
  String get breathePause => '暂停';

  @override
  String get breatheResume => '继续';

  @override
  String get breatheReset => '结束练习';

  @override
  String get breatheDone => '做得好';

  @override
  String get breatheReady => '找一个舒适的姿势';

  @override
  String get breathePatternBox => '方形';

  @override
  String get breathePatternCoherent => '共振';

  @override
  String get breathePatternCalm => '平静';

  @override
  String get breathePatternCustom => '自定义';

  @override
  String get breatheSession => '时长';

  @override
  String get breatheEndless => '不限';

  @override
  String breatheSeconds(int n) {
    return '$n秒';
  }

  @override
  String get ambientWhite => '白噪音';

  @override
  String get ambientPink => '粉红噪音';

  @override
  String get ambientBrown => '棕色噪音';

  @override
  String get ambientRain => '雨声';

  @override
  String get ambientWind => '风声';

  @override
  String get ambientOcean => '海浪';

  @override
  String get ambientVolume => '音量';

  @override
  String get ambientSleepTimer => '睡眠定时';

  @override
  String get ambientTimerOff => '关闭';

  @override
  String get ambientPlay => '播放声音';

  @override
  String get ambientStop => '停止声音';

  @override
  String get ambientUnavailable => '此设备无法播放声音。';

  @override
  String get ambientPreparing => '正在准备声音…';

  @override
  String ambientTimeLeft(String time) {
    return '剩余 $time';
  }

  @override
  String get breaksStart => '开始休息提醒';

  @override
  String get breaksStop => '停止休息提醒';

  @override
  String get breaksStatusOff => '休息提醒已关闭';

  @override
  String get breaksNoneEnabled => '请至少开启一个提醒';

  @override
  String breaksNextName(String name) {
    return '下一个：$name';
  }

  @override
  String get breaksToday => '今天';

  @override
  String get breaksTaken => '已休息';

  @override
  String get breaksSkipped => '已跳过';

  @override
  String get breaksEyeName => '护眼休息 (20-20-20)';

  @override
  String get breaksEyeHint => '远眺 6 米外的物体 20 秒';

  @override
  String get breaksStretchName => '拉伸';

  @override
  String get breaksStretchHint => '站起来伸展全身';

  @override
  String get breaksWaterName => '喝水';

  @override
  String get breaksWaterHint => '喝一杯水';

  @override
  String get breaksPostureName => '检查坐姿';

  @override
  String get breaksPostureHint => '坐直并放松肩膀';

  @override
  String get breaksCustomDefault => '我的提醒';

  @override
  String breaksForDuration(String duration) {
    return '休息 $duration';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return '每 $minutes 分钟';
  }

  @override
  String get breaksShorter => '缩短间隔';

  @override
  String get breaksLonger => '延长间隔';

  @override
  String get breaksDone => '完成';

  @override
  String get breaksSkip => '跳过';

  @override
  String get breaksActiveHours => '活动时段';

  @override
  String get breaksActiveHoursHint => '仅在此时段内提醒';

  @override
  String get breaksFrom => '开始';

  @override
  String get breaksTo => '结束';

  @override
  String get breaksLaterHour => '更晚';

  @override
  String get breaksEarlierHour => '更早';

  @override
  String get breaksBackground => 'Enfo 关闭时也提醒';

  @override
  String get breaksBackgroundOn => '即使应用已关闭，也会通过通知提醒你。';

  @override
  String get breaksBackgroundOff => '仅在 Enfo 打开时显示提醒。';

  @override
  String get breaksDesktopNotice => 'Enfo 运行期间会显示提醒（可最小化）。';

  @override
  String get breaksAddCustom => '添加自定义提醒';

  @override
  String get breaksEdit => '编辑提醒';

  @override
  String get breaksName => '名称';

  @override
  String get breaksDuration => '时长';

  @override
  String get breaksIcon => '图标';

  @override
  String get breaksShorterDuration => '缩短时长';

  @override
  String get breaksLongerDuration => '延长时长';

  @override
  String get breaksRemove => '删除提醒';

  @override
  String get breaksRemoveConfirm => '确认：删除提醒';

  @override
  String get breaksRemoveHint => '它将不再提醒你。';

  @override
  String get worldPlan => '规划会议';

  @override
  String get worldPlanIntro => '拖动标记，找到大家都方便的时间。';

  @override
  String get worldPlanNow => '现在';

  @override
  String get worldPlanEarlier => '提前 15 分钟';

  @override
  String get worldPlanLater => '推迟 15 分钟';

  @override
  String worldPlanSelected(String city) {
    return '$city 的所选时间';
  }

  @override
  String get worldPlanTapCity => '点按城市，以其时间为基准。';

  @override
  String get worldPlanNextDay => '+1 天';

  @override
  String get worldPlanPrevDay => '-1 天';

  @override
  String get worldPlanOverlapTitle => '大家都在工作时间';

  @override
  String get worldPlanNoOverlap => '未来 24 小时内没有适合所有人的时间。';

  @override
  String worldPlanLeastBad(String time) {
    return '相对最佳：$time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$total 处中 $count 处在工作时间';
  }

  @override
  String get worldPlanWork => '工作时间 (09-18)';

  @override
  String get worldPlanNight => '夜间';

  @override
  String get worldPlanMarker => '所选时间';

  @override
  String get eventAdd => '新建事件';

  @override
  String get eventEdit => '编辑事件';

  @override
  String get eventName => '名称';

  @override
  String get eventNameHint => '生日、旅行、发布……';

  @override
  String get eventYearly => '每年重复';

  @override
  String get eventYearlyHint => '适用于生日和纪念日：自动顺延到下一次。';

  @override
  String get eventNotify => '提醒我';

  @override
  String get eventNotifyHint => '在事件到来的那一刻。';

  @override
  String get eventDayBefore => '前一天也提醒';

  @override
  String get eventSave => '保存';

  @override
  String get eventDelete => '删除事件';

  @override
  String get eventConfirmDelete => '确认：删除事件';

  @override
  String get eventDeleteHint => '此事件将被删除。';

  @override
  String get eventEmpty => '还没有事件。\n点按 + 开始倒计时。';

  @override
  String get eventToday => '就是今天！';

  @override
  String eventDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String get eventDaysShort => '天';

  @override
  String get eventUnitDays => '天';

  @override
  String get eventUnitHours => '小时';

  @override
  String get eventUnitMinutes => '分钟';

  @override
  String get eventRepeatsYearly => '每年';

  @override
  String get eventNotifyNow => '时间到了！';

  @override
  String get eventNotifyTomorrow => '明天';

  @override
  String get sleepPlanWake => '起床时间';

  @override
  String get sleepPlanBed => '入睡时间';

  @override
  String get sleepPlanNow => '现在入睡';

  @override
  String get sleepTitleWake => '我想在这个时间起床';

  @override
  String get sleepTitleBed => '我上床的时间';

  @override
  String sleepTitleNow(String time) {
    return '如果现在入睡（$time）';
  }

  @override
  String get sleepBedtimeWord => '就寝';

  @override
  String get sleepWakeWord => '起床';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles 个周期 · 睡眠 $duration';
  }

  @override
  String get sleepNote => '每个周期约 90 分钟，入睡大约需要 15 分钟。建议睡 5 到 6 个周期。';

  @override
  String get sleepWindDown => '睡前放松提醒';

  @override
  String get sleepWindDownHint => '在就寝前 30 分钟响铃。';

  @override
  String get sleepWindDownPassed => '该时间已经过去。';

  @override
  String get sleepWindDownLabel => '该放松了';

  @override
  String get sleepAlarmLabel => '起床';

  @override
  String get sleepSetAlarm => '设置闹钟';

  @override
  String get sleepRemoveAlarm => '移除闹钟';

  @override
  String sleepAlarmSet(String time) {
    return '已设置 $time 的闹钟';
  }

  @override
  String get sleepPast => '该时间已经过去';

  @override
  String get sleepRecommended => '推荐';

  @override
  String get ambientMusicTabSounds => '声音';

  @override
  String get ambientMusicTab => '音乐';

  @override
  String get ambientMusicPlay => '播放音乐';

  @override
  String get ambientMusicPause => '暂停音乐';

  @override
  String get ambientMusicNext => '下一首';

  @override
  String get ambientMusicPrevious => '上一首';

  @override
  String get ambientMusicShuffle => '随机播放';

  @override
  String get ambientMusicRepeat => '全部循环';

  @override
  String get ambientMusicVolume => '音乐音量';

  @override
  String get ambientMusicCredits => '音乐版权信息';

  @override
  String get ambientMusicCreditsNote =>
      '歌曲来自 Wikimedia Commons，采用 CC0 或知识共享署名许可协议发布。';

  @override
  String get modeMusic => '音乐';

  @override
  String get modeDescMusic => '助你专注的 Lo-fi 音乐';

  @override
  String get musicCreditsSubtitle => '艺术家与许可协议';

  @override
  String get displayMenuButtons => '菜单按钮';

  @override
  String get displayMenuButtonsHint => '选择底部菜单显示哪些按钮。设置始终可用。';

  @override
  String get onbWelcomeTitle => '欢迎使用 Enfo';

  @override
  String get onbWelcomeTagline => '专注，一个宁静的表盘。';
}
