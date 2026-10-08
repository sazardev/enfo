// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => 'Ajustes';

  @override
  String get tooltipStats => 'Estatísticas';

  @override
  String get tooltipPin => 'Manter sempre visível';

  @override
  String get tooltipUnpin => 'Remover de sempre visível';

  @override
  String get phasePaused => 'Em pausa';

  @override
  String get phaseFocus => 'Foco';

  @override
  String get phaseRelax => 'Descanso';

  @override
  String get notifRestTitle => 'Hora de descansar';

  @override
  String get notifRestBody => 'Respire um pouco.';

  @override
  String get notifWorkTitle => 'Hora de trabalhar';

  @override
  String get notifWorkBody => 'Vamos voltar ao trabalho!';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get rhythmTitle => 'Ritmo de foco';

  @override
  String get presetClassic => 'Clássico';

  @override
  String get presetExtended => 'Estendido';

  @override
  String get presetDeep => 'Profundo';

  @override
  String get presetManual => 'Manual';

  @override
  String get workLabel => 'Foco';

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
  String get timersTitle => 'Tempos';

  @override
  String timersSubtitle(int work, int rest) {
    return '$work min de foco · $rest min de descanso';
  }

  @override
  String timersCycle(int total) {
    return 'Um ciclo completo: $total min';
  }

  @override
  String get timersApplyHint =>
      'Se o relógio estiver em andamento, a mudança vale a partir do próximo ciclo. Se estiver em pausa, o relógio é reiniciado.';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceLight => 'Tema claro';

  @override
  String get appearanceDark => 'Tema escuro';

  @override
  String get darkTheme => 'Tema escuro';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsOn => 'Ativadas';

  @override
  String get notificationsOff => 'Desativadas';

  @override
  String get notificationsToggle => 'Avisos ao mudar de fase';

  @override
  String get notificationsHint =>
      'Receba um aviso quando for hora de descansar ou voltar ao trabalho.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageHint => 'Escolha o idioma do app.';

  @override
  String get supportTitle => 'Apoie o Enfo';

  @override
  String get supportSubtitleNoAds => 'Doações e café';

  @override
  String get buyCoffee => 'Me pague um café';

  @override
  String get supportHint =>
      'O Enfo é gratuito e feito por uma única pessoa. Obrigado por usar.';

  @override
  String get rateApp => 'Avaliar o Enfo';

  @override
  String get shareApp => 'Compartilhar o Enfo';

  @override
  String shareMessage(String url) {
    return 'Enfo, uma caixa de ferramentas de relógios e timers para Android: $url';
  }

  @override
  String get donateTitle => 'Doar';

  @override
  String get donateSubtitle => 'Pagamento único, pelo Google Play';

  @override
  String get donateHint =>
      'O Enfo é grátis e sem anúncios. Se quiser apoiar, você pode deixar uma doação única pelo Google Play. Obrigado!';

  @override
  String get donateUnavailable =>
      'As doações não estão disponíveis agora. Você ainda pode me pagar um café.';

  @override
  String get donateThanks => 'Obrigado por apoiar o Enfo!';

  @override
  String get donatePending => 'Compra pendente…';

  @override
  String get donateError =>
      'Não foi possível concluir a compra. Nada foi cobrado.';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsEmpty =>
      'Ainda não há sessões.\nInicie um pomodoro e ele aparecerá aqui.';

  @override
  String get statsTodayPomodoros => 'Pomodoros hoje';

  @override
  String get statsTodayFocus => 'Foco hoje';

  @override
  String get statsCompleted => 'Concluídos';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dias seguidos',
      one: 'Dia seguido',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => 'Últimos 7 dias';

  @override
  String get statsTotalFocus => 'Tempo total de foco';

  @override
  String get statsTotalRest => 'Tempo total de descanso';

  @override
  String get statsAbandoned => 'Abandonados';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent% concluídos';
  }

  @override
  String get statsAverageFocus => 'Foco médio';

  @override
  String get statsLongestSession => 'Sessão mais longa';

  @override
  String get statsPauses => 'Pausas';

  @override
  String get statsAverageGap => 'Espera média entre sessões';

  @override
  String get statsLongestGap => 'Maior tempo sem iniciar';

  @override
  String get statsSinceLast => 'Desde a última sessão';

  @override
  String get statsHistory => 'Histórico';

  @override
  String get statsClearHistory => 'Apagar histórico';

  @override
  String get statsClearConfirm => 'Confirmar: apagar todas as sessões';

  @override
  String get statsClearHint => 'Esta ação não pode ser desfeita.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get sessionFocus => 'Foco';

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
    return 'após $gap de inatividade';
  }

  @override
  String get sessionCompleted => 'Concluído';

  @override
  String get sessionAbandoned => 'Abandonado';

  @override
  String get clockStyleTitle => 'Estilo do relógio';

  @override
  String get tooltipClockStyle => 'Estilo do relógio';

  @override
  String get clockCategoryProgress => 'Progresso e números';

  @override
  String get clockCategoryNumbers => 'Só números';

  @override
  String get clockCategoryIcons => 'Só ícone';

  @override
  String get clockCategoryMotion => 'Só animação';

  @override
  String get clockUnitMinutes => 'min';

  @override
  String get clockUnitSeconds => 's';

  @override
  String get clockRing => 'Anel';

  @override
  String get clockWavyRing => 'Onda';

  @override
  String get clockSegments => 'Segmentos';

  @override
  String get clockOrbit => 'Órbita';

  @override
  String get clockPie => 'Pizza';

  @override
  String get clockKitchen => 'Cozinha';

  @override
  String get clockDots => 'Pontos';

  @override
  String get clockBar => 'Barra';

  @override
  String get clockWavyBar => 'Ondulada';

  @override
  String get clockDigits => 'Dígitos';

  @override
  String get clockMinutes => 'Minutos';

  @override
  String get clockTiles => 'Peças';

  @override
  String get clockStack => 'Empilhado';

  @override
  String get clockTomato => 'Tomate';

  @override
  String get clockHourglass => 'Ampulheta';

  @override
  String get clockBattery => 'Bateria';

  @override
  String get clockIcon => 'Ícone';

  @override
  String get clockCookie => 'Biscoito';

  @override
  String get clockLiquid => 'Líquido';

  @override
  String get clockBreathe => 'Respiração';

  @override
  String get clockEqualizer => 'Equalizador';

  @override
  String get clockRipple => 'Ondas';

  @override
  String get accentApply => 'Aplicar';

  @override
  String get accentCustom => 'Cor personalizada';

  @override
  String get accentHue => 'Matiz';

  @override
  String get accentSaturation => 'Saturação';

  @override
  String get accentBrightness => 'Brilho';

  @override
  String get accentHex => 'Código hex';

  @override
  String get displayTitle => 'Tela';

  @override
  String get displayClockShown => 'Hora visível';

  @override
  String get displayClockHidden => 'Hora oculta';

  @override
  String get showClock => 'Mostrar a hora';

  @override
  String get showClockHint => 'O relógio pequeno acima do temporizador.';

  @override
  String get clockFormat => 'Formato da hora';

  @override
  String get clockFormatSystem => 'Padrão do sistema';

  @override
  String get clockFormat12 => '12 horas';

  @override
  String get clockFormat24 => '24 horas';

  @override
  String get behaviorTitle => 'Comportamento';

  @override
  String get autoStartNext => 'Iniciar a próxima fase automaticamente';

  @override
  String get autoStartNextHint =>
      'Ao terminar o foco ou o descanso, a próxima fase começa sem precisar tocar.';

  @override
  String get hapticFeedback => 'Vibração';

  @override
  String get hapticFeedbackHint => 'Toques, rodas, mudanças de fase e alarmes.';

  @override
  String get clockCombosTitle => 'Combos';

  @override
  String get clockCollapseAll => 'Recolher tudo';

  @override
  String get clockExpandAll => 'Expandir tudo';

  @override
  String get comboDeepFocus => 'Foco profundo';

  @override
  String get comboMint => 'Menta fresca';

  @override
  String get comboSunset => 'Pôr do sol';

  @override
  String get comboZen => 'Zen';

  @override
  String get comboTomato => 'Tomate clássico';

  @override
  String get comboNight => 'Coruja noturna';

  @override
  String get comboPlayful => 'Divertido';

  @override
  String get comboMinimal => 'Minimalista';

  @override
  String get uiSizeTitle => 'Tamanho da interface';

  @override
  String get uiSizeSmall => 'Pequeno';

  @override
  String get uiSizeNormal => 'Normal';

  @override
  String get uiSizeLarge => 'Grande';

  @override
  String get uiSizeExtraLarge => 'Extra grande';

  @override
  String get uiSizeHint =>
      'Deixa o texto e os controles maiores ou menores. Útil em TVs e telas de carro.';

  @override
  String get clockBlob => 'Blob';

  @override
  String get clockFlower => 'Flor';

  @override
  String get clockSun => 'Sol';

  @override
  String get clockGears => 'Engrenagens';

  @override
  String get clockBubbles => 'Bolhas';

  @override
  String get clockSunflower => 'Girassol';

  @override
  String get clockFireflies => 'Vaga-lumes';

  @override
  String get clockPendulum => 'Pêndulo';

  @override
  String get clockBounce => 'Salto';

  @override
  String get clockMorph => 'Morfo';

  @override
  String get dataTitle => 'Dados';

  @override
  String get dataSubtitle => 'Histórico, redefinir e introdução';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros salvos',
      one: '1 registro salvo',
      zero: 'Nenhuma atividade salva',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'Ver a introdução novamente';

  @override
  String get dataIntroHint =>
      'Reveja a tela de boas-vindas e escolha seu ritmo de novo. Nada é apagado.';

  @override
  String get dataClearHistoryHint =>
      'Apaga toda a atividade registrada: pomodoros, temporizadores, cronômetros, alarmes e tempo de relógio. Os ajustes não mudam.';

  @override
  String get dataConfirmClearHistory => 'Confirmar: apagar histórico';

  @override
  String get dataResetSettings => 'Redefinir ajustes';

  @override
  String get dataResetSettingsHint =>
      'Tempos, tema, cor de destaque, idioma, modos e tela voltam aos valores originais. O histórico é mantido.';

  @override
  String get dataConfirmResetSettings => 'Confirmar: redefinir ajustes';

  @override
  String get dataEraseAll => 'Apagar tudo';

  @override
  String get dataEraseAllHint =>
      'Apaga histórico e ajustes e recomeça do zero, como na primeira vez.';

  @override
  String get dataConfirmEraseAll => 'Confirmar: apagar tudo';

  @override
  String get dataDoneHistory => 'Histórico apagado.';

  @override
  String get dataDoneSettings => 'Ajustes redefinidos.';

  @override
  String get dataCacheNote =>
      'O Enfo não guarda cache: tudo o que ele armazena é o histórico e os ajustes descritos aqui.';

  @override
  String get clockEndsAt => 'Termina';

  @override
  String get clockFill => 'Preenchimento';

  @override
  String get clockCapsule => 'Cápsula';

  @override
  String get clockRollers => 'Rolos';

  @override
  String get clockMatrix => 'Matriz';

  @override
  String get clockSevenSeg => 'Digital';

  @override
  String get clockFlip => 'Flip';

  @override
  String get clockFine => 'Fino';

  @override
  String get clockSuperscript => 'Expoente';

  @override
  String get clockPercent => 'Porcentagem';

  @override
  String get clockEndTime => 'Termina às';

  @override
  String get clockSeconds => 'Segundos';

  @override
  String get clockTall => 'Alto';

  @override
  String get clockWobble => 'Ondulado';

  @override
  String get clockLabeled => 'Com rótulo';

  @override
  String get clockGauge => 'Medidor';

  @override
  String get clockNeedle => 'Ponteiro';

  @override
  String get clockAnalog => 'Analógico';

  @override
  String get clockRings => 'Anéis';

  @override
  String get clockSquircle => 'Quadrado';

  @override
  String get clockColumns => 'Colunas';

  @override
  String get clockVertical => 'Vertical';

  @override
  String get clockSteps => 'Passos';

  @override
  String get clockBlocks => 'Blocos';

  @override
  String get clockSpiral => 'Espiral';

  @override
  String get clockSlices => 'Gomos';

  @override
  String get clockPills => 'Pílulas';

  @override
  String get clockHexagon => 'Hexágono';

  @override
  String get clockStairs => 'Escada';

  @override
  String get clockCandle => 'Vela';

  @override
  String get clockMoon => 'Lua';

  @override
  String get clockRuler => 'Régua';

  @override
  String get comboArcade => 'Arcade';

  @override
  String get comboCalculator => 'Calculadora';

  @override
  String get comboDepartures => 'Estação de trem';

  @override
  String get comboCandlelight => 'À luz de velas';

  @override
  String get comboMoonlight => 'Luar';

  @override
  String get comboGarden => 'Jardim';

  @override
  String get comboSummer => 'Verão';

  @override
  String get comboWorkshop => 'Oficina';

  @override
  String get comboFizzy => 'Efervescente';

  @override
  String get comboSunfield => 'Campo de girassóis';

  @override
  String get comboSummerNight => 'Noite de verão';

  @override
  String get comboHypnosis => 'Hipnose';

  @override
  String get comboBouncy => 'Saltitante';

  @override
  String get comboShapeshifter => 'Metamorfo';

  @override
  String get comboLava => 'Lâmpada de lava';

  @override
  String get comboOcean => 'Oceano';

  @override
  String get comboPulse => 'Pulso';

  @override
  String get comboPond => 'Lagoa';

  @override
  String get comboEspresso => 'Espresso';

  @override
  String get comboSpeedometer => 'Velocímetro';

  @override
  String get comboCompass => 'Bússola';

  @override
  String get comboClassicClock => 'Relógio clássico';

  @override
  String get comboConcentric => 'Concêntrico';

  @override
  String get comboRounded => 'Arredondado';

  @override
  String get comboSignal => 'Sinal';

  @override
  String get comboThermometer => 'Termômetro';

  @override
  String get comboMilestones => 'Marcos';

  @override
  String get comboRetroBlocks => 'Blocos retrô';

  @override
  String get comboHypnoSpiral => 'Espiral hipnótica';

  @override
  String get comboCitrus => 'Cítrico';

  @override
  String get comboChocolate => 'Barra de chocolate';

  @override
  String get comboCrystal => 'Cristal';

  @override
  String get comboStaircase => 'Escadaria';

  @override
  String get comboTapeMeasure => 'Fita métrica';

  @override
  String get comboBoldType => 'Tipografia ousada';

  @override
  String get comboPill => 'Cápsula';

  @override
  String get comboSlotMachine => 'Caça-níquel';

  @override
  String get comboWhisper => 'Sussurro';

  @override
  String get comboDeadline => 'Prazo final';

  @override
  String get comboPercentage => 'Porcentagem';

  @override
  String get comboStopwatch => 'Só segundos';

  @override
  String get comboSkyscraper => 'Arranha-céu';

  @override
  String get comboWaveText => 'Texto ondulado';

  @override
  String get comboDashboard => 'Painel';

  @override
  String get comboExponent => 'Expoente';

  @override
  String get comboGrandmaKitchen => 'Cozinha da vovó';

  @override
  String get comboCyber => 'Cyber';

  @override
  String get comboCandy => 'Doce';

  @override
  String get comboConfetti => 'Confete';

  @override
  String get comboCookieJar => 'Pote de biscoitos';

  @override
  String get comboSandbox => 'Caixa de areia';

  @override
  String get comboPizzaNight => 'Noite de pizza';

  @override
  String get onbLanguageTitle => 'Seu idioma';

  @override
  String get onbLanguageBody =>
      'Escolha seu idioma. Tudo o que você escolher aqui pode ser alterado depois em Ajustes.';

  @override
  String get onbRhythmTitle => 'Seu ritmo';

  @override
  String get onbRhythmBody => 'Quanto tempo você foca e quanto descansa.';

  @override
  String get onbLookTitle => 'Deixe com a sua cara';

  @override
  String get onbLookBody =>
      'Tema, estilo de relógio e cor. Comece por um combo e ajuste a cor se quiser.';

  @override
  String get onbClockTitle => 'Escolha um relógio';

  @override
  String get onbClockBody =>
      'Combinações prontas: um estilo de relógio e uma cor com um toque especial.';

  @override
  String get onbAllStyles => 'Ver todos os estilos';

  @override
  String get onbOptionsTitle => 'Últimos detalhes';

  @override
  String get onbOptionsBody =>
      'Tela e comportamento. Tudo isso também está em Ajustes.';

  @override
  String get onbModesTitle => 'Suas ferramentas';

  @override
  String get onbModesBody =>
      'O Enfo é uma caixa de ferramentas de relógios e temporizadores. Ative o que vai usar; mude quando quiser no menu de modos.';

  @override
  String get onbPreview => 'Prévia';

  @override
  String get onbDisplayTitle => 'Tela';

  @override
  String get onbDisplayBody => 'Como o relógio aparece e o tamanho de tudo.';

  @override
  String get onbClockModeDesign => 'Design do modo Relógio';

  @override
  String get onbPermTitle => 'Permissões';

  @override
  String get onbPermBody =>
      'Para que temporizadores e alarmes avisem você mesmo com o Enfo fechado.';

  @override
  String get onbPermNotifications => 'Notificações';

  @override
  String get onbPermNotificationsHint =>
      'Avisos quando um temporizador termina ou um alarme toca.';

  @override
  String get onbPermExact => 'Alarmes exatos';

  @override
  String get onbPermExactHint =>
      'Tocam no minuto exato, mesmo na economia de bateria.';

  @override
  String get onbPermAllow => 'Permitir';

  @override
  String get onbPermAllowed => 'Permitido';

  @override
  String get onbPermLater =>
      'Você pode mudar isso quando quiser nas configurações do sistema.';

  @override
  String get onbNext => 'Avançar';

  @override
  String get onbBack => 'Voltar';

  @override
  String get onbSkip => 'Pular';

  @override
  String onbStepOf(int step, int total) {
    return 'Passo $step de $total';
  }

  @override
  String get clockFormatAuto => 'Auto';

  @override
  String get modePomodoro => 'Pomodoro';

  @override
  String get modeClock => 'Relógio';

  @override
  String get modeTimer => 'Temporizador';

  @override
  String get modeStopwatch => 'Cronômetro';

  @override
  String get modeAlarm => 'Alarme';

  @override
  String get modeWorld => 'Hora mundial';

  @override
  String get modeDescPomodoro => 'Ciclos de foco e descanso';

  @override
  String get modeDescClock => 'Um relógio lindo, sempre visível';

  @override
  String get modeDescTimer => 'Contagem regressiva de qualquer tempo';

  @override
  String get modeDescStopwatch => 'Meça o tempo, com voltas';

  @override
  String get modeDescAlarm => 'Acorde ou receba lembretes';

  @override
  String get modeDescWorld => 'A hora em cidades do mundo';

  @override
  String get tooltipModes => 'Modos';

  @override
  String get tooltipSwitchMode => 'Próximo modo';

  @override
  String get tooltipFullscreen => 'Tela cheia';

  @override
  String get tooltipExitFullscreen => 'Sair da tela cheia';

  @override
  String get tooltipDim => 'Escurecer a tela';

  @override
  String get modesTitle => 'Modos';

  @override
  String get modesHint =>
      'Escolha os modos que você usa e a ordem deles. Arraste para reordenar.';

  @override
  String get modesStart => 'Iniciar com';

  @override
  String get modesStartLast => 'Último modo usado';

  @override
  String get modesCustomize => 'Personalizar';

  @override
  String get modesActivity => 'Histórico de atividade';

  @override
  String get modesAtLeastOne => 'Pelo menos um modo deve ficar ativo.';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modos ativos',
      one: '1 modo ativo',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'Histórico de atividade';

  @override
  String get activityTitle => 'Atividade';

  @override
  String get activityEmpty =>
      'Ainda não há nada.\nUse um temporizador, um cronômetro, um alarme ou o relógio e ele aparecerá aqui.';

  @override
  String get activityFilterAll => 'Tudo';

  @override
  String get activityTimersToday => 'Temporizadores hoje';

  @override
  String get activityStopwatchToday => 'Cronômetro hoje';

  @override
  String get activityDisplayToday => 'Na tela hoje';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voltas',
      one: '1 volta',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'Volta $n';
  }

  @override
  String get activityAlarmDismissed => 'Desligado';

  @override
  String get activityAlarmSnoozed => 'Adiado';

  @override
  String get activityAlarmMissed => 'Perdido';

  @override
  String activityDisplay(String mode) {
    return '$mode na tela';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done de $planned';
  }

  @override
  String get faceRing => 'Anel';

  @override
  String get faceDigital => 'Digital';

  @override
  String get faceAnalog => 'Analógico';

  @override
  String get faceSplit => 'Grande';

  @override
  String get faceDay => 'Dia';

  @override
  String get tooltipCustomize => 'Personalizar';

  @override
  String get clockSettingsTitle => 'Personalizar o relógio';

  @override
  String get clockFaceTitle => 'Layout';

  @override
  String get clockShowSeconds => 'Mostrar segundos';

  @override
  String get clockShowDate => 'Mostrar a data';

  @override
  String get clockBlinkColon => 'Dois pontos piscando';

  @override
  String get clockKeepAwake => 'Manter a tela ligada';

  @override
  String get clockKeepAwakeHint => 'Enquanto o relógio estiver visível.';

  @override
  String get clockFullscreenHint =>
      'Toque em tela cheia para um relógio de mesa que fica ligado. Deslize o relógio para mudar o layout.';

  @override
  String clockDayPercent(int percent) {
    return '$percent% do dia';
  }

  @override
  String get ringDismiss => 'Desligar';

  @override
  String ringSnooze(int minutes) {
    return 'Adiar $minutes min';
  }

  @override
  String get timerStart => 'Iniciar';

  @override
  String get timerPause => 'Pausar';

  @override
  String get timerResume => 'Retomar';

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
  String get timerUpTitle => 'O tempo acabou';

  @override
  String timerUpBody(String duration) {
    return 'O temporizador de $duration terminou.';
  }

  @override
  String get timerSavePreset => 'Salvar este tempo';

  @override
  String get timerPresetHint =>
      'Toque em + para salvar este tempo. Mantenha pressionado um preset para removê-lo.';

  @override
  String get stopwatchStop => 'Parar';

  @override
  String get stopwatchLap => 'Volta';

  @override
  String get stopwatchLapBest => 'Melhor';

  @override
  String get stopwatchLapWorst => 'Mais lenta';

  @override
  String get worldLocal => 'Hora local';

  @override
  String get worldToday => 'Hoje';

  @override
  String get worldTomorrow => 'Amanhã';

  @override
  String get worldYesterday => 'Ontem';

  @override
  String get worldAdd => 'Adicionar uma cidade';

  @override
  String get worldSearch => 'Buscar cidades';

  @override
  String get worldNoResults => 'Nenhuma cidade encontrada.';

  @override
  String get worldEdit => 'Editar lista';

  @override
  String get worldDone => 'Concluir';

  @override
  String get worldRemove => 'Remover';

  @override
  String get worldEmpty =>
      'Ainda não há outras cidades. Toque em + para adicionar uma.';

  @override
  String get worldSameTime => 'Mesma hora que você';

  @override
  String worldDiffAhead(String diff) {
    return '$diff à frente de você';
  }

  @override
  String worldDiffBehind(String diff) {
    return '$diff atrás de você';
  }

  @override
  String alarmNext(String duration) {
    return 'Próximo alarme em $duration';
  }

  @override
  String get alarmNone => 'Nenhum alarme ativo';

  @override
  String get alarmNew => 'Novo alarme';

  @override
  String get alarmEditTitle => 'Editar alarme';

  @override
  String get alarmLabel => 'Rótulo';

  @override
  String get alarmRepeat => 'Repetir';

  @override
  String get alarmSave => 'Salvar';

  @override
  String get alarmDelete => 'Excluir alarme';

  @override
  String get alarmConfirmDelete => 'Confirmar: excluir alarme';

  @override
  String get alarmDeleteHint => 'Este alarme será excluído.';

  @override
  String get alarmEmpty => 'Ainda não há alarmes.\nToque em + para criar um.';

  @override
  String get alarmEveryDay => 'Todos os dias';

  @override
  String get alarmWeekdays => 'Dias úteis';

  @override
  String get alarmWeekends => 'Fins de semana';

  @override
  String get alarmOnce => 'Uma vez';

  @override
  String get alarmPermissionHint =>
      'Para tocar com o app fechado, o Enfo precisa de permissão para notificações e alarmes exatos.';

  @override
  String get alarmPermissionButton => 'Permitir alarmes';

  @override
  String get alarmDesktopHint =>
      'Neste dispositivo, o Enfo precisa estar aberto para os alarmes tocarem.';

  @override
  String get hapticsTitle => 'Vibração';

  @override
  String get hapticsOff => 'Desativada';

  @override
  String get hapticsStrength => 'Intensidade';

  @override
  String get hapticsSoft => 'Suave';

  @override
  String get hapticsMedium => 'Média';

  @override
  String get hapticsStrong => 'Forte';

  @override
  String get hapticsTouch => 'Toque';

  @override
  String get hapticsTouchHint => 'Botões, interruptores e seleções.';

  @override
  String get hapticsMotion => 'Movimento';

  @override
  String get hapticsMotionHint =>
      'Rodas, controles deslizantes, arrastes e transições.';

  @override
  String get hapticsAlerts => 'Alertas';

  @override
  String get hapticsAlertsHint =>
      'Temporizadores, mudanças de fase, a contagem final e alarmes.';

  @override
  String get hapticsAlarmPattern => 'Padrão do alarme';

  @override
  String get hapticsAlarmPatternHint =>
      'Toque em um padrão para senti-lo. A tela do alarme pulsa no mesmo ritmo.';

  @override
  String get hapticsPatternHeartbeat => 'Batimento';

  @override
  String get hapticsPatternPulse => 'Pulso';

  @override
  String get hapticsPatternCrescendo => 'Crescendo';

  @override
  String get hapticsPatternRipple => 'Ondas';

  @override
  String get hapticsPatternBeacon => 'Farol';

  @override
  String get hapticsTry => 'Experimente';

  @override
  String get hapticsTryTap => 'Toque';

  @override
  String get hapticsTrySuccess => 'Sucesso';

  @override
  String get hapticsTryToRest => 'Fim do foco';

  @override
  String get hapticsTryToWork => 'Fim do descanso';

  @override
  String get hapticsTryTimer => 'Fim do temporizador';

  @override
  String get hapticsTryWarning => 'Aviso';

  @override
  String get hapticsUnavailable =>
      'Este dispositivo não tem motor de vibração.';

  @override
  String get hapticsWhen => 'Quando vibrar';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSubtitle => 'Relógios e temporizadores na tela inicial';

  @override
  String get widgetsAddHeader => 'Adicionar à tela inicial';

  @override
  String get widgetsAdd => 'Adicionar';

  @override
  String get widgetsDynamicColor => 'Cores Material You';

  @override
  String get widgetsDynamicColorHint =>
      'Os widgets usam as cores do seu papel de parede. Desative para usar a cor de destaque do Enfo.';

  @override
  String get widgetsManualHint =>
      'Seu launcher não permite adicionar widgets por aqui. Mantenha a tela inicial pressionada, escolha Widgets e procure Enfo.';

  @override
  String get widgetsStyleHint =>
      'Os widgets de Pomodoro e temporizador são desenhados com o estilo de relógio que você escolheu. Mude o estilo no app e eles acompanham.';

  @override
  String get widgetsTapHint =>
      'Os botões de um widget abrem o Enfo e executam a ação, assim o tempo é sempre controlado pelo app.';

  @override
  String get shortcutsTitle => 'Teclado e controle remoto';

  @override
  String get shortcutsSubtitle =>
      'Atalhos para teclado, mouse e controle da TV';

  @override
  String get shortcutsIntro =>
      'As setas ou o D-pad do controle movem, Enter ou OK seleciona. Estas teclas fazem o resto.';

  @override
  String get shortcutKeySpace => 'Espaço';

  @override
  String get shortcutPlayPause => 'Iniciar ou pausar';

  @override
  String get shortcutReset => 'Reiniciar';

  @override
  String get shortcutLap => 'Volta (cronômetro)';

  @override
  String get shortcutJumpMode => 'Ir para o modo 1–9';

  @override
  String get shortcutStepMode => 'Modo anterior / seguinte';

  @override
  String get shortcutFullscreen => 'Tela cheia';

  @override
  String get shortcutDim => 'Escurecer a tela (tela cheia)';

  @override
  String get shortcutSettings => 'Ajustes';

  @override
  String get shortcutModes => 'Menu de modos';

  @override
  String get shortcutBack => 'Voltar / sair da tela cheia';

  @override
  String get shortcutHelp => 'Mostrar esta lista';

  @override
  String get onbMoreTools => 'Mais ferramentas';

  @override
  String get modeEvent => 'Eventos';

  @override
  String get modeDescEvent => 'Conte os dias até o que importa';

  @override
  String get modeIntervals => 'Intervalos';

  @override
  String get modeDescIntervals => 'Rodadas de esforço e descanso, como HIIT';

  @override
  String get modeBreathe => 'Respirar';

  @override
  String get modeDescBreathe => 'Respiração guiada para relaxar';

  @override
  String get modeTracker => 'Registro';

  @override
  String get modeDescTracker => 'Cronometre o que faz e veja os totais';

  @override
  String get modeKitchen => 'Cozinha';

  @override
  String get modeDescKitchen => 'Vários temporizadores nomeados ao mesmo tempo';

  @override
  String get modeSleep => 'Sono';

  @override
  String get modeDescSleep => 'Planeje dormir e acordar por ciclos de sono';

  @override
  String get modeVersus => 'Turnos';

  @override
  String get modeDescVersus => 'Relógio de dois para xadrez, jogos e debates';

  @override
  String get modeBreaks => 'Pausas';

  @override
  String get modeDescBreaks => 'Lembretes para descansar a vista e se alongar';

  @override
  String get modeAmbient => 'Ambiente';

  @override
  String get modeDescAmbient => 'Sons de fundo com temporizador';

  @override
  String get intervalsPresetTabata => 'Tabata';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'Personalizado';

  @override
  String get intervalsWarmUp => 'Aquecimento';

  @override
  String get intervalsWork => 'Esforço';

  @override
  String get intervalsRest => 'Descanso';

  @override
  String get intervalsRounds => 'Rondas';

  @override
  String get intervalsCoolDown => 'Desaquecimento';

  @override
  String get intervalsOff => 'Não';

  @override
  String intervalsRound(int current, int total) {
    return 'Ronda $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return 'Total $duration';
  }

  @override
  String get intervalsSkip => 'Saltar para a próxima fase';

  @override
  String get intervalsHint =>
      'Toque numa linha para a editar. Qualquer alteração fica guardada como Personalizado.';

  @override
  String get intervalsDoneTitle => 'Treino concluído';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration. Bom trabalho!';
  }

  @override
  String get kitchenPasta => 'Massa';

  @override
  String get kitchenEggs => 'Ovos';

  @override
  String get kitchenTea => 'Chá';

  @override
  String get kitchenRice => 'Arroz';

  @override
  String get kitchenOven => 'Forno';

  @override
  String get kitchenCustom => 'Outro';

  @override
  String get kitchenNameHint => 'Nome';

  @override
  String get kitchenAdd => 'Iniciar temporizador';

  @override
  String get kitchenDelete => 'Eliminar temporizador';

  @override
  String get kitchenEmpty =>
      'Ainda sem temporizadores. Toque num acima para começar.';

  @override
  String get kitchenDefaultName => 'Temporizador';

  @override
  String kitchenDoneTitle(String name) {
    return '$name está pronto';
  }

  @override
  String kitchenDoneBody(String duration) {
    return 'O temporizador de $duration terminou.';
  }

  @override
  String get trackerToday => 'Hoje';

  @override
  String get trackerWeek => 'Últimos 7 dias';

  @override
  String get trackerTapToStart =>
      'Toque numa atividade para começar a cronometrá-la';

  @override
  String get trackerNoRunning => 'Nada em andamento';

  @override
  String get trackerAddActivity => 'Nova atividade';

  @override
  String get trackerNameHint => 'Nome';

  @override
  String get trackerStudy => 'Estudo';

  @override
  String get trackerReading => 'Leitura';

  @override
  String get trackerCode => 'Código';

  @override
  String get trackerExercise => 'Exercício';

  @override
  String get trackerEdit => 'Editar atividade';

  @override
  String get trackerDetails => 'Detalhes e gráfico';

  @override
  String get trackerColor => 'Cor';

  @override
  String get trackerIcon => 'Ícone';

  @override
  String get trackerDelete => 'Excluir atividade';

  @override
  String get trackerDeleteConfirm => 'Confirmar: excluir esta atividade';

  @override
  String get trackerDeleteHint =>
      'O tempo já registrado permanece no histórico.';

  @override
  String get trackerAddTime => 'Adicionar tempo manualmente';

  @override
  String trackerAddMinutes(int minutes) {
    return 'Adicionar $minutes min';
  }

  @override
  String get trackerMinutesFewer => 'Menos minutos';

  @override
  String get trackerMinutesMore => 'Mais minutos';

  @override
  String get trackerStop => 'Parar';

  @override
  String get versusDuel => 'Duelo';

  @override
  String get versusSpeakers => 'Oradores';

  @override
  String get versusCustom => 'Personalizado';

  @override
  String get versusIncrement => 'Incremento';

  @override
  String get versusTapToStart => 'Toque no seu lado para iniciar o seu relógio';

  @override
  String get versusTimeIsUp => 'O tempo acabou';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadas',
      one: '1 jogada',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => 'Reiniciar partida';

  @override
  String get versusConfirmReset => 'Confirmar reinício';

  @override
  String versusSpeakerN(int n) {
    return 'Orador $n';
  }

  @override
  String get versusAddSpeaker => 'Adicionar orador';

  @override
  String get versusRemoveSpeaker => 'Remover orador';

  @override
  String get versusSpeakerName => 'Orador ou tema';

  @override
  String get versusNext => 'Próximo orador';

  @override
  String get versusFinish => 'Terminar';

  @override
  String get versusOvertime => 'Tempo excedido';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed de $planned';
  }

  @override
  String get versusAgendaDone => 'Pauta concluída';

  @override
  String get versusStartAgenda => 'Iniciar pauta';

  @override
  String get versusMinutesFewer => 'Menos minutos';

  @override
  String get versusMinutesMore => 'Mais minutos';

  @override
  String get versusTotal => 'Total';

  @override
  String get breatheInhale => 'Inspire';

  @override
  String get breatheHold => 'Segure';

  @override
  String get breatheExhale => 'Expire';

  @override
  String get breatheStart => 'Começar a respirar';

  @override
  String get breathePause => 'Pausar';

  @override
  String get breatheResume => 'Retomar';

  @override
  String get breatheReset => 'Encerrar sessão';

  @override
  String get breatheDone => 'Muito bem';

  @override
  String get breatheReady => 'Fique confortável';

  @override
  String get breathePatternBox => 'Caixa';

  @override
  String get breathePatternCoherent => 'Coerente';

  @override
  String get breathePatternCalm => 'Calma';

  @override
  String get breathePatternCustom => 'Personalizado';

  @override
  String get breatheSession => 'Duração';

  @override
  String get breatheEndless => 'Sem fim';

  @override
  String breatheSeconds(int n) {
    return '$n s';
  }

  @override
  String get ambientWhite => 'Ruído branco';

  @override
  String get ambientPink => 'Ruído rosa';

  @override
  String get ambientBrown => 'Ruído marrom';

  @override
  String get ambientRain => 'Chuva';

  @override
  String get ambientWind => 'Vento';

  @override
  String get ambientOcean => 'Oceano';

  @override
  String get ambientVolume => 'Volume';

  @override
  String get ambientSleepTimer => 'Timer de sono';

  @override
  String get ambientTimerOff => 'Desligado';

  @override
  String get ambientPlay => 'Reproduzir som';

  @override
  String get ambientStop => 'Parar som';

  @override
  String get ambientUnavailable =>
      'O som não está disponível neste dispositivo.';

  @override
  String get ambientPreparing => 'Preparando o som…';

  @override
  String ambientTimeLeft(String time) {
    return 'Faltam $time';
  }

  @override
  String get breaksStart => 'Iniciar pausas';

  @override
  String get breaksStop => 'Parar pausas';

  @override
  String get breaksStatusOff => 'Os lembretes estão desligados';

  @override
  String get breaksNoneEnabled => 'Ative pelo menos um lembrete';

  @override
  String breaksNextName(String name) {
    return 'Próximo: $name';
  }

  @override
  String get breaksToday => 'Hoje';

  @override
  String get breaksTaken => 'Pausas feitas';

  @override
  String get breaksSkipped => 'Ignoradas';

  @override
  String get breaksEyeName => 'Descanso visual (20-20-20)';

  @override
  String get breaksEyeHint =>
      'Olhe para algo a 6 m de distância por 20 segundos';

  @override
  String get breaksStretchName => 'Alongar';

  @override
  String get breaksStretchHint => 'Levante-se e alongue o corpo todo';

  @override
  String get breaksWaterName => 'Beber água';

  @override
  String get breaksWaterHint => 'Tome um copo de água';

  @override
  String get breaksPostureName => 'Checar a postura';

  @override
  String get breaksPostureHint => 'Sente-se reto e relaxe os ombros';

  @override
  String get breaksCustomDefault => 'Meu lembrete';

  @override
  String breaksForDuration(String duration) {
    return 'Reserve $duration';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return 'A cada $minutes min';
  }

  @override
  String get breaksShorter => 'Intervalo menor';

  @override
  String get breaksLonger => 'Intervalo maior';

  @override
  String get breaksDone => 'Feito';

  @override
  String get breaksSkip => 'Pular';

  @override
  String get breaksActiveHours => 'Horário ativo';

  @override
  String get breaksActiveHoursHint =>
      'Os lembretes só aparecem neste intervalo';

  @override
  String get breaksFrom => 'Das';

  @override
  String get breaksTo => 'Às';

  @override
  String get breaksLaterHour => 'Mais tarde';

  @override
  String get breaksEarlierHour => 'Mais cedo';

  @override
  String get breaksBackground => 'Também com o Enfo fechado';

  @override
  String get breaksBackgroundOn =>
      'As notificações avisam mesmo com o app fechado.';

  @override
  String get breaksBackgroundOff =>
      'Os lembretes só aparecem com o Enfo aberto.';

  @override
  String get breaksDesktopNotice =>
      'Os lembretes aparecem enquanto o Enfo estiver em execução (pode ficar minimizado).';

  @override
  String get breaksAddCustom => 'Adicionar lembrete próprio';

  @override
  String get breaksEdit => 'Editar lembrete';

  @override
  String get breaksName => 'Nome';

  @override
  String get breaksDuration => 'Duração';

  @override
  String get breaksIcon => 'Ícone';

  @override
  String get breaksShorterDuration => 'Pausa mais curta';

  @override
  String get breaksLongerDuration => 'Pausa mais longa';

  @override
  String get breaksRemove => 'Remover lembrete';

  @override
  String get breaksRemoveConfirm => 'Confirmar: remover lembrete';

  @override
  String get breaksRemoveHint => 'Ele deixará de avisar você.';

  @override
  String get worldPlan => 'Planejar uma reunião';

  @override
  String get worldPlanIntro =>
      'Mova o marcador para achar um horário bom para todos.';

  @override
  String get worldPlanNow => 'Agora';

  @override
  String get worldPlanEarlier => '15 minutos antes';

  @override
  String get worldPlanLater => '15 minutos depois';

  @override
  String worldPlanSelected(String city) {
    return 'Horário escolhido em $city';
  }

  @override
  String get worldPlanTapCity =>
      'Toque em uma cidade para usar o horário dela como referência.';

  @override
  String get worldPlanNextDay => '+1 dia';

  @override
  String get worldPlanPrevDay => '-1 dia';

  @override
  String get worldPlanOverlapTitle => 'Todos estão no expediente';

  @override
  String get worldPlanNoOverlap =>
      'Nenhum horário nas próximas 24 horas serve para todos.';

  @override
  String worldPlanLeastBad(String time) {
    return 'Menos ruim: $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$count de $total no expediente';
  }

  @override
  String get worldPlanWork => 'Horário de trabalho (09-18)';

  @override
  String get worldPlanNight => 'Noite';

  @override
  String get worldPlanMarker => 'Horário escolhido';

  @override
  String get eventAdd => 'Novo evento';

  @override
  String get eventEdit => 'Editar evento';

  @override
  String get eventName => 'Nome';

  @override
  String get eventNameHint => 'Aniversário, viagem, lançamento...';

  @override
  String get eventYearly => 'Repetir todo ano';

  @override
  String get eventYearlyHint =>
      'Para aniversários e datas comemorativas: passa para o próximo.';

  @override
  String get eventNotify => 'Avisar-me';

  @override
  String get eventNotifyHint => 'No momento em que chegar.';

  @override
  String get eventDayBefore => 'Também na véspera';

  @override
  String get eventSave => 'Salvar';

  @override
  String get eventDelete => 'Excluir evento';

  @override
  String get eventConfirmDelete => 'Confirmar: excluir evento';

  @override
  String get eventDeleteHint => 'Este evento será removido.';

  @override
  String get eventEmpty =>
      'Ainda não há eventos.\nToque em + para criar uma contagem regressiva.';

  @override
  String get eventToday => 'Hoje!';

  @override
  String eventDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get eventDaysShort => 'd';

  @override
  String get eventUnitDays => 'dias';

  @override
  String get eventUnitHours => 'horas';

  @override
  String get eventUnitMinutes => 'min';

  @override
  String get eventRepeatsYearly => 'Todo ano';

  @override
  String get eventNotifyNow => 'É a hora!';

  @override
  String get eventNotifyTomorrow => 'Amanhã';

  @override
  String get sleepPlanWake => 'Acordar às';

  @override
  String get sleepPlanBed => 'Dormir às';

  @override
  String get sleepPlanNow => 'Dormir agora';

  @override
  String get sleepTitleWake => 'Quero acordar às';

  @override
  String get sleepTitleBed => 'Vou dormir às';

  @override
  String sleepTitleNow(String time) {
    return 'Se eu dormir agora ($time)';
  }

  @override
  String get sleepBedtimeWord => 'Deitar';

  @override
  String get sleepWakeWord => 'Acordar';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles ciclos · $duration de sono';
  }

  @override
  String get sleepNote =>
      'Cada ciclo dura 90 minutos e adormecer leva cerca de 15. Recomendam-se cinco ou seis ciclos.';

  @override
  String get sleepWindDown => 'Lembrete para relaxar';

  @override
  String get sleepWindDownHint => 'Um alarme 30 minutos antes de deitar.';

  @override
  String get sleepWindDownPassed => 'Esse horário já passou.';

  @override
  String get sleepWindDownLabel => 'Hora de relaxar';

  @override
  String get sleepAlarmLabel => 'Acordar';

  @override
  String get sleepSetAlarm => 'Definir alarme';

  @override
  String get sleepRemoveAlarm => 'Remover alarme';

  @override
  String sleepAlarmSet(String time) {
    return 'Alarme definido para $time';
  }

  @override
  String get sleepPast => 'Este horário já passou';

  @override
  String get sleepRecommended => 'Recomendado';

  @override
  String get ambientMusicTabSounds => 'Sons';

  @override
  String get ambientMusicTab => 'Música';

  @override
  String get ambientMusicPlay => 'Reproduzir música';

  @override
  String get ambientMusicPause => 'Pausar música';

  @override
  String get ambientMusicNext => 'Próxima música';

  @override
  String get ambientMusicPrevious => 'Música anterior';

  @override
  String get ambientMusicShuffle => 'Aleatório';

  @override
  String get ambientMusicRepeat => 'Repetir tudo';

  @override
  String get ambientMusicVolume => 'Volume da música';

  @override
  String get ambientMusicCredits => 'Créditos de música e ambiências';

  @override
  String get ambientMusicCreditsNote =>
      'Músicas do Wikimedia Commons e da coleção Open Lo-Fi, e ambiências do Wikimedia Commons, publicadas sob licenças CC0, domínio público ou Creative Commons Atribuição.';

  @override
  String get modeMusic => 'Música';

  @override
  String get modeDescMusic => 'Músicas lo-fi para focar';

  @override
  String get musicCreditsSubtitle => 'Artistas e licenças';

  @override
  String get displayMenuButtons => 'Botões do menu';

  @override
  String get displayMenuButtonsHint =>
      'Escolha quais botões aparecem no menu inferior. Configurações sempre fica visível.';

  @override
  String get onbWelcomeTitle => 'Bem-vindo ao Enfo';

  @override
  String get onbWelcomeTagline => 'Foco, em um só mostrador calmo.';

  @override
  String get timerRunningTitle => 'Temporizador em execução';

  @override
  String timerRunningBody(String time) {
    return 'Termina às $time';
  }

  @override
  String get timerPausedTitle => 'Temporizador em pausa';

  @override
  String timerPausedBody(String duration) {
    return 'Faltam $duration';
  }

  @override
  String get musicActionPlay => 'Reproduzir';

  @override
  String get musicActionPause => 'Pausar';

  @override
  String get widgetsFocusSubtitle =>
      'Tempo de foco e pomodoros de hoje em um relance.';

  @override
  String get ambienceStream => 'Riacho';

  @override
  String get ambienceSnowmelt => 'Degelo';

  @override
  String get ambienceRivulet => 'Riacho';

  @override
  String get ambienceFountain => 'Fonte';

  @override
  String get ambiencePlazaFountain => 'Fonte da praça';

  @override
  String get ambienceGeyser => 'Gêiser';

  @override
  String get ambienceBubblingGeyser => 'Gêiser borbulhante';

  @override
  String get ambienceRainWindow => 'Chuva na janela';

  @override
  String get ambienceRainThunder => 'Chuva e trovões';

  @override
  String get ambienceThunderstorm => 'Tempestade';

  @override
  String get ambienceThunderbolts => 'Raios';

  @override
  String get ambienceStormWind => 'Vento de tempestade';

  @override
  String get ambienceForest => 'Floresta';

  @override
  String get ambienceForestBirds => 'Floresta com pássaros';

  @override
  String get ambienceDawnChorus => 'Coro do amanhecer';

  @override
  String get ambienceCountryDawn => 'Amanhecer no campo';

  @override
  String get ambiencePondDusk => 'Lagoa ao anoitecer';

  @override
  String get ambienceMorningBirds => 'Pássaros da manhã';

  @override
  String get ambienceCampfire => 'Fogueira';

  @override
  String get ambienceFireplace => 'Lareira';

  @override
  String get ambienceLibrary => 'Biblioteca';

  @override
  String get ambienceBusyLibrary => 'Biblioteca movimentada';

  @override
  String get ambienceOffice => 'Escritório';

  @override
  String get ambienceClassroom => 'Sala de aula';

  @override
  String get ambienceCafeteria => 'Cantina';

  @override
  String get ambienceRestaurant => 'Restaurante';

  @override
  String get ambienceSupermarket => 'Supermercado';

  @override
  String get ambienceShoppingMall => 'Shopping';

  @override
  String get ambienceRainyStreet => 'Rua chuvosa';

  @override
  String get ambienceSpringStreet => 'Rua na primavera';

  @override
  String get ambienceSubway => 'Metrô';

  @override
  String get ambienceSubwayRide => 'Viagem de metrô';

  @override
  String get ambienceStationTunnel => 'Túnel de estação';

  @override
  String get ambienceTrain => 'Trem';

  @override
  String get ambienceTaiwanTrain => 'Trem de Taiwan';

  @override
  String get ambienceEscalator => 'Escada rolante';

  @override
  String get ambienceElevator => 'Elevador';

  @override
  String get ambiencePlayground => 'Parque infantil';

  @override
  String get ambienceStreetMarket => 'Feira de rua';

  @override
  String get ambienceKeyboard => 'Teclado';

  @override
  String get ambientNature => 'Natureza';

  @override
  String get ambientPlaces => 'Lugares';

  @override
  String get breaksRelaxSound => 'Som de pausa';

  @override
  String get quoteLead1 => 'Respire fundo.';

  @override
  String get quoteLead2 => 'Uma coisa de cada vez.';

  @override
  String get quoteLead3 => 'Comece pequeno.';

  @override
  String get quoteLead4 => 'Volte ao presente.';

  @override
  String get quoteLead5 => 'Hoje, sem pressa.';

  @override
  String get quoteLead6 => 'Faça simples.';

  @override
  String get quoteLead7 => 'Mais um passo.';

  @override
  String get quoteLead8 => 'Abaixe o ruído.';

  @override
  String get quoteLead9 => 'Foque agora.';

  @override
  String get quoteLead10 => 'Menos, mas melhor.';

  @override
  String get quoteLead11 => 'Cinco minutos bastam.';

  @override
  String get quoteLead12 => 'Escolha o que importa.';

  @override
  String get quoteLead13 => 'Aqui e agora.';

  @override
  String get quoteLead14 => 'Com calma.';

  @override
  String get quoteLead15 => 'Passo a passo.';

  @override
  String get quoteLead16 => 'Feche o que distrai.';

  @override
  String get quoteLead17 => 'Sua atenção é sua.';

  @override
  String get quoteLead18 => 'Comece pelo difícil.';

  @override
  String get quoteLead19 => 'Respire e siga.';

  @override
  String get quoteLead20 => 'Hoje conta.';

  @override
  String get quoteThought1 =>
      'Seu próximo passo vale mais que o plano perfeito.';

  @override
  String get quoteThought2 => 'O progresso não precisa ser perfeito.';

  @override
  String get quoteThought3 =>
      'Cinco minutos de foco vencem uma hora de dúvida.';

  @override
  String get quoteThought4 => 'Foque no que você pode controlar.';

  @override
  String get quoteThought5 => 'A constância vence a pressa.';

  @override
  String get quoteThought6 =>
      'Uma tarefa terminada vale mais que dez começadas.';

  @override
  String get quoteThought7 => 'Sua mente está onde está sua atenção.';

  @override
  String get quoteThought8 => 'O silêncio também é produtivo.';

  @override
  String get quoteThought9 => 'Faça pela pessoa em que você está se tornando.';

  @override
  String get quoteThought10 =>
      'Você não precisa de motivação; precisa começar.';

  @override
  String get quoteThought11 => 'O descanso também faz parte do trabalho.';

  @override
  String get quoteThought12 => 'A calma não freia o progresso; sustenta.';

  @override
  String get quoteThought13 => 'Termine uma coisa antes de abrir a próxima.';

  @override
  String get quoteThought14 => 'Sua energia merece um objetivo claro.';

  @override
  String get quoteThought15 => 'Dias pequenos constroem anos grandes.';

  @override
  String get quoteThought16 => 'Aprenda com o desvio; não fique nele.';

  @override
  String get quoteThought17 => 'A disciplina se pratica, não se espera.';

  @override
  String get quoteThought18 => 'Cada tentativa te aproxima.';

  @override
  String get quoteThought19 => 'Foco não é força, é decisão.';

  @override
  String get quoteThought20 => 'Proteja sua manhã e o dia se organiza.';

  @override
  String get quoteThought21 => 'Avance mesmo que o passo seja curto.';

  @override
  String get quoteThought22 => 'Deixe o importante ocupar o centro.';

  @override
  String get quoteThought23 => 'Um dia de cada vez já é suficiente.';

  @override
  String get quoteThought24 => 'Seu melhor trabalho começa quando você começa.';

  @override
  String get quoteThought25 => 'A atenção de hoje é um presente amanhã.';

  @override
  String get focusQuoteTitle => 'Frase de foco do dia';

  @override
  String get focusQuoteToggle => 'Frase de foco diária';

  @override
  String get focusQuoteHint =>
      'Uma notificação por dia, escolhida entre 500 frases, para inspirar você.';

  @override
  String get focusQuoteTime => 'Horário';

  @override
  String get focusQuoteExample => 'Hoje:';
}
