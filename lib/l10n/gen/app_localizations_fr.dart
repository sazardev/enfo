// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Enfo';

  @override
  String get tooltipSettings => 'Réglages';

  @override
  String get tooltipStats => 'Statistiques';

  @override
  String get tooltipPin => 'Garder toujours visible';

  @override
  String get tooltipUnpin => 'Ne plus garder visible';

  @override
  String get phasePaused => 'En pause';

  @override
  String get phaseFocus => 'Focus';

  @override
  String get phaseRelax => 'Repos';

  @override
  String get notifRestTitle => 'C\'est l\'heure de la pause';

  @override
  String get notifRestBody => 'Prends un moment pour souffler.';

  @override
  String get notifWorkTitle => 'C\'est l\'heure de travailler';

  @override
  String get notifWorkBody => 'On s\'y remet !';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get rhythmTitle => 'Rythme de focus';

  @override
  String get presetClassic => 'Classique';

  @override
  String get presetExtended => 'Étendu';

  @override
  String get presetDeep => 'Profond';

  @override
  String get presetManual => 'Manuel';

  @override
  String get workLabel => 'Focus';

  @override
  String get restLabel => 'Repos';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String presetSummary(int work, int rest) {
    return '$work/$rest min';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get timersTitle => 'Durées';

  @override
  String timersSubtitle(int work, int rest) {
    return '$work min de focus · $rest min de repos';
  }

  @override
  String timersCycle(int total) {
    return 'Un cycle complet : $total min';
  }

  @override
  String get timersApplyHint =>
      'Si l\'horloge tourne, le changement s\'applique dès le prochain cycle. Si elle est en pause, elle est réinitialisée.';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceLight => 'Thème clair';

  @override
  String get appearanceDark => 'Thème sombre';

  @override
  String get darkTheme => 'Thème sombre';

  @override
  String get themeModeSystem => 'Système';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get accentColor => 'Couleur d\'accent';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsOn => 'Activées';

  @override
  String get notificationsOff => 'Désactivées';

  @override
  String get notificationsToggle => 'Alertes de changement de phase';

  @override
  String get notificationsHint =>
      'Reçois une alerte quand il est temps de faire une pause ou de reprendre le travail.';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageSystem => 'Par défaut du système';

  @override
  String get languageHint => 'Choisis la langue de l\'app.';

  @override
  String get supportTitle => 'Soutenir Enfo';

  @override
  String get supportSubtitleNoAds => 'Dons et café';

  @override
  String get buyCoffee => 'Offre-moi un café';

  @override
  String get supportHint =>
      'Enfo est gratuit et développé par une seule personne. Merci de l\'utiliser.';

  @override
  String get rateApp => 'Noter Enfo';

  @override
  String get shareApp => 'Partager Enfo';

  @override
  String shareMessage(String url) {
    return 'Enfo, une boîte à outils d\'horloges et de minuteurs pour Android : $url';
  }

  @override
  String get donateTitle => 'Faire un don';

  @override
  String get donateSubtitle => 'Paiement unique, via Google Play';

  @override
  String get donateHint =>
      'Enfo est gratuit et sans pub. Pour le soutenir, vous pouvez laisser un don unique via Google Play. Merci !';

  @override
  String get donateUnavailable =>
      'Les dons ne sont pas disponibles pour le moment. Vous pouvez toujours m\'offrir un café.';

  @override
  String get donateThanks => 'Merci de soutenir Enfo !';

  @override
  String get donatePending => 'Achat en attente…';

  @override
  String get donateError =>
      'L\'achat n\'a pas pu être finalisé. Rien n\'a été débité.';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsEmpty =>
      'Aucune session pour l\'instant.\nLance un pomodoro et il apparaîtra ici.';

  @override
  String get statsTodayPomodoros => 'Pomodoros aujourd\'hui';

  @override
  String get statsTodayFocus => 'Focus aujourd\'hui';

  @override
  String get statsCompleted => 'Terminés';

  @override
  String statsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jours d\'affilée',
      one: 'Jour d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String get statsLast7Days => '7 derniers jours';

  @override
  String get statsTotalFocus => 'Temps de focus total';

  @override
  String get statsTotalRest => 'Temps de repos total';

  @override
  String get statsAbandoned => 'Abandonnés';

  @override
  String statsAbandonedValue(int count, int percent) {
    return '$count  ·  $percent % terminés';
  }

  @override
  String get statsAverageFocus => 'Focus moyen';

  @override
  String get statsLongestSession => 'Session la plus longue';

  @override
  String get statsPauses => 'Pauses';

  @override
  String get statsAverageGap => 'Attente moyenne entre les sessions';

  @override
  String get statsLongestGap => 'Plus longue période d\'inactivité';

  @override
  String get statsSinceLast => 'Depuis la dernière session';

  @override
  String get statsHistory => 'Historique';

  @override
  String get statsClearHistory => 'Effacer l\'historique';

  @override
  String get statsClearConfirm => 'Confirmer : effacer toutes les sessions';

  @override
  String get statsClearHint => 'Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get sessionFocus => 'Focus';

  @override
  String get sessionRest => 'Repos';

  @override
  String sessionProgress(String done, String planned) {
    return '$done sur $planned';
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
    return 'après $gap d\'inactivité';
  }

  @override
  String get sessionCompleted => 'Terminé';

  @override
  String get sessionAbandoned => 'Abandonné';

  @override
  String get clockStyleTitle => 'Style d\'horloge';

  @override
  String get tooltipClockStyle => 'Style d\'horloge';

  @override
  String get clockCategoryProgress => 'Progression et chiffres';

  @override
  String get clockCategoryNumbers => 'Chiffres seuls';

  @override
  String get clockCategoryIcons => 'Icône seule';

  @override
  String get clockCategoryMotion => 'Animation seule';

  @override
  String get clockUnitMinutes => 'min';

  @override
  String get clockUnitSeconds => 's';

  @override
  String get clockRing => 'Anneau';

  @override
  String get clockWavyRing => 'Onde';

  @override
  String get clockSegments => 'Segments';

  @override
  String get clockOrbit => 'Orbite';

  @override
  String get clockPie => 'Camembert';

  @override
  String get clockKitchen => 'Cuisine';

  @override
  String get clockDots => 'Points';

  @override
  String get clockBar => 'Barre';

  @override
  String get clockWavyBar => 'Vague';

  @override
  String get clockDigits => 'Chiffres';

  @override
  String get clockMinutes => 'Minutes';

  @override
  String get clockTiles => 'Tuiles';

  @override
  String get clockStack => 'Empilé';

  @override
  String get clockTomato => 'Tomate';

  @override
  String get clockHourglass => 'Sablier';

  @override
  String get clockBattery => 'Batterie';

  @override
  String get clockIcon => 'Icône';

  @override
  String get clockCookie => 'Biscuit';

  @override
  String get clockLiquid => 'Liquide';

  @override
  String get clockBreathe => 'Respiration';

  @override
  String get clockEqualizer => 'Égaliseur';

  @override
  String get clockRipple => 'Ondulations';

  @override
  String get accentApply => 'Appliquer';

  @override
  String get accentCustom => 'Couleur personnalisée';

  @override
  String get accentHue => 'Teinte';

  @override
  String get accentSaturation => 'Saturation';

  @override
  String get accentBrightness => 'Luminosité';

  @override
  String get accentHex => 'Code hex';

  @override
  String get displayTitle => 'Affichage';

  @override
  String get displayClockShown => 'Heure visible';

  @override
  String get displayClockHidden => 'Heure masquée';

  @override
  String get showClock => 'Afficher l\'heure';

  @override
  String get showClockHint => 'La petite horloge au-dessus du minuteur.';

  @override
  String get clockFormat => 'Format de l\'heure';

  @override
  String get clockFormatSystem => 'Par défaut du système';

  @override
  String get clockFormat12 => '12 heures';

  @override
  String get clockFormat24 => '24 heures';

  @override
  String get behaviorTitle => 'Comportement';

  @override
  String get autoStartNext => 'Lancer automatiquement la phase suivante';

  @override
  String get autoStartNextHint =>
      'À la fin du focus ou du repos, la suivante démarre sans toucher l\'écran.';

  @override
  String get hapticFeedback => 'Vibration';

  @override
  String get hapticFeedbackHint =>
      'Appuis, molettes, changements de phase et alarmes.';

  @override
  String get clockCombosTitle => 'Combos';

  @override
  String get clockCollapseAll => 'Tout réduire';

  @override
  String get clockExpandAll => 'Tout développer';

  @override
  String get comboDeepFocus => 'Focus profond';

  @override
  String get comboMint => 'Menthe fraîche';

  @override
  String get comboSunset => 'Coucher de soleil';

  @override
  String get comboZen => 'Zen';

  @override
  String get comboTomato => 'Tomate classique';

  @override
  String get comboNight => 'Chouette de nuit';

  @override
  String get comboPlayful => 'Ludique';

  @override
  String get comboMinimal => 'Minimaliste';

  @override
  String get uiSizeTitle => 'Taille de l\'interface';

  @override
  String get uiSizeSmall => 'Petite';

  @override
  String get uiSizeNormal => 'Normale';

  @override
  String get uiSizeLarge => 'Grande';

  @override
  String get uiSizeExtraLarge => 'Très grande';

  @override
  String get uiSizeHint =>
      'Agrandit ou réduit le texte et les commandes. Utile sur TV et écrans de voiture.';

  @override
  String get clockBlob => 'Blob';

  @override
  String get clockFlower => 'Fleur';

  @override
  String get clockSun => 'Soleil';

  @override
  String get clockGears => 'Engrenages';

  @override
  String get clockBubbles => 'Bulles';

  @override
  String get clockSunflower => 'Tournesol';

  @override
  String get clockFireflies => 'Lucioles';

  @override
  String get clockPendulum => 'Pendule';

  @override
  String get clockBounce => 'Rebond';

  @override
  String get clockMorph => 'Morphing';

  @override
  String get dataTitle => 'Données';

  @override
  String get dataSubtitle => 'Historique, réinitialisation et introduction';

  @override
  String dataSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées enregistrées',
      one: '1 entrée enregistrée',
      zero: 'Aucune activité enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get dataIntro => 'Revoir l\'introduction';

  @override
  String get dataIntroHint =>
      'Reviens sur l\'écran de bienvenue et choisis à nouveau ton rythme. Rien n\'est effacé.';

  @override
  String get dataClearHistoryHint =>
      'Supprime toute l\'activité enregistrée : pomodoros, minuteurs, chronomètres, alarmes et temps d\'horloge. Les réglages ne changent pas.';

  @override
  String get dataConfirmClearHistory => 'Confirmer : effacer l\'historique';

  @override
  String get dataResetSettings => 'Réinitialiser les réglages';

  @override
  String get dataResetSettingsHint =>
      'Durées, thème, couleur d\'accent, langue, modes et affichage reviennent aux valeurs d\'origine. L\'historique est conservé.';

  @override
  String get dataConfirmResetSettings =>
      'Confirmer : réinitialiser les réglages';

  @override
  String get dataEraseAll => 'Tout effacer';

  @override
  String get dataEraseAllHint =>
      'Supprime l\'historique et les réglages pour repartir de zéro, comme la première fois.';

  @override
  String get dataConfirmEraseAll => 'Confirmer : tout effacer';

  @override
  String get dataDoneHistory => 'Historique effacé.';

  @override
  String get dataDoneSettings => 'Réglages réinitialisés.';

  @override
  String get dataCacheNote =>
      'Enfo ne conserve aucun cache : il ne stocke que l\'historique et les réglages décrits ici.';

  @override
  String get clockEndsAt => 'Fin';

  @override
  String get clockFill => 'Remplissage';

  @override
  String get clockCapsule => 'Capsule';

  @override
  String get clockRollers => 'Rouleau';

  @override
  String get clockMatrix => 'Matrice';

  @override
  String get clockSevenSeg => 'Digital';

  @override
  String get clockFlip => 'Flip';

  @override
  String get clockFine => 'Fin';

  @override
  String get clockSuperscript => 'Exposant';

  @override
  String get clockPercent => 'Pourcentage';

  @override
  String get clockEndTime => 'Fin à';

  @override
  String get clockSeconds => 'Secondes';

  @override
  String get clockTall => 'Haut';

  @override
  String get clockWobble => 'Ondulé';

  @override
  String get clockLabeled => 'Étiqueté';

  @override
  String get clockGauge => 'Jauge';

  @override
  String get clockNeedle => 'Aiguille';

  @override
  String get clockAnalog => 'Analogique';

  @override
  String get clockRings => 'Anneaux';

  @override
  String get clockSquircle => 'Carré arrondi';

  @override
  String get clockColumns => 'Colonnes';

  @override
  String get clockVertical => 'Vertical';

  @override
  String get clockSteps => 'Étapes';

  @override
  String get clockBlocks => 'Blocs';

  @override
  String get clockSpiral => 'Spirale';

  @override
  String get clockSlices => 'Quartiers';

  @override
  String get clockPills => 'Pilules';

  @override
  String get clockHexagon => 'Hexagone';

  @override
  String get clockStairs => 'Escalier';

  @override
  String get clockCandle => 'Bougie';

  @override
  String get clockMoon => 'Lune';

  @override
  String get clockRuler => 'Règle';

  @override
  String get comboArcade => 'Arcade';

  @override
  String get comboCalculator => 'Calculatrice';

  @override
  String get comboDepartures => 'Tableau des départs';

  @override
  String get comboCandlelight => 'À la lueur d\'une bougie';

  @override
  String get comboMoonlight => 'Clair de lune';

  @override
  String get comboGarden => 'Jardin';

  @override
  String get comboSummer => 'Été';

  @override
  String get comboWorkshop => 'Atelier';

  @override
  String get comboFizzy => 'Pétillant';

  @override
  String get comboSunfield => 'Champ de tournesols';

  @override
  String get comboSummerNight => 'Nuit d\'été';

  @override
  String get comboHypnosis => 'Hypnose';

  @override
  String get comboBouncy => 'Rebondissant';

  @override
  String get comboShapeshifter => 'Métamorphe';

  @override
  String get comboLava => 'Lampe à lave';

  @override
  String get comboOcean => 'Océan';

  @override
  String get comboPulse => 'Pouls';

  @override
  String get comboPond => 'Étang';

  @override
  String get comboEspresso => 'Espresso';

  @override
  String get comboSpeedometer => 'Compteur de vitesse';

  @override
  String get comboCompass => 'Boussole';

  @override
  String get comboClassicClock => 'Horloge classique';

  @override
  String get comboConcentric => 'Concentrique';

  @override
  String get comboRounded => 'Arrondi';

  @override
  String get comboSignal => 'Signal';

  @override
  String get comboThermometer => 'Thermomètre';

  @override
  String get comboMilestones => 'Jalons';

  @override
  String get comboRetroBlocks => 'Blocs rétro';

  @override
  String get comboHypnoSpiral => 'Spirale hypnotique';

  @override
  String get comboCitrus => 'Agrumes';

  @override
  String get comboChocolate => 'Tablette de chocolat';

  @override
  String get comboCrystal => 'Cristal';

  @override
  String get comboStaircase => 'Escalier';

  @override
  String get comboTapeMeasure => 'Mètre ruban';

  @override
  String get comboBoldType => 'Typographie audacieuse';

  @override
  String get comboPill => 'Capsule';

  @override
  String get comboSlotMachine => 'Machine à sous';

  @override
  String get comboWhisper => 'Murmure';

  @override
  String get comboDeadline => 'Date limite';

  @override
  String get comboPercentage => 'Pourcentage';

  @override
  String get comboStopwatch => 'Secondes seules';

  @override
  String get comboSkyscraper => 'Gratte-ciel';

  @override
  String get comboWaveText => 'Texte ondulé';

  @override
  String get comboDashboard => 'Tableau de bord';

  @override
  String get comboExponent => 'Exposant';

  @override
  String get comboGrandmaKitchen => 'Cuisine de mamie';

  @override
  String get comboCyber => 'Cyber';

  @override
  String get comboCandy => 'Bonbon';

  @override
  String get comboConfetti => 'Confettis';

  @override
  String get comboCookieJar => 'Boîte à biscuits';

  @override
  String get comboSandbox => 'Bac à sable';

  @override
  String get comboPizzaNight => 'Soirée pizza';

  @override
  String get onbLanguageTitle => 'Ta langue';

  @override
  String get onbLanguageBody =>
      'Choisis ta langue. Tout ce que tu choisis ici pourra être modifié plus tard dans les Réglages.';

  @override
  String get onbRhythmTitle => 'Ton rythme';

  @override
  String get onbRhythmBody =>
      'Combien de temps tu te concentres et combien tu te reposes.';

  @override
  String get onbLookTitle => 'Personnalise-le';

  @override
  String get onbLookBody =>
      'Thème, style d\'horloge et couleur. Partez d\'un combo, puis ajustez la couleur.';

  @override
  String get onbClockTitle => 'Choisis une horloge';

  @override
  String get onbClockBody =>
      'Des combinaisons prêtes à l\'emploi : un style d\'horloge et une couleur en un geste.';

  @override
  String get onbAllStyles => 'Voir tous les styles';

  @override
  String get onbOptionsTitle => 'Derniers détails';

  @override
  String get onbOptionsBody =>
      'Affichage et comportement. Tout cela se trouve aussi dans les Réglages.';

  @override
  String get onbModesTitle => 'Vos outils';

  @override
  String get onbModesBody =>
      'Enfo est une boîte à outils d\'horloges et de minuteurs. Activez ce que vous utiliserez ; modifiable à tout moment depuis le menu des modes.';

  @override
  String get onbPreview => 'Aperçu';

  @override
  String get onbDisplayTitle => 'Affichage';

  @override
  String get onbDisplayBody =>
      'L\'apparence de l\'horloge et la taille de l\'interface.';

  @override
  String get onbClockModeDesign => 'Design du mode Horloge';

  @override
  String get onbPermTitle => 'Autorisations';

  @override
  String get onbPermBody =>
      'Pour que minuteurs et alarmes vous préviennent même quand Enfo est fermé.';

  @override
  String get onbPermNotifications => 'Notifications';

  @override
  String get onbPermNotificationsHint =>
      'Alertes quand un minuteur se termine ou qu\'une alarme sonne.';

  @override
  String get onbPermExact => 'Alarmes exactes';

  @override
  String get onbPermExactHint =>
      'Sonnent à la minute près, même en économie d\'énergie.';

  @override
  String get onbPermAllow => 'Autoriser';

  @override
  String get onbPermAllowed => 'Autorisé';

  @override
  String get onbPermLater =>
      'Modifiable à tout moment dans les réglages du système.';

  @override
  String get onbNext => 'Suivant';

  @override
  String get onbBack => 'Retour';

  @override
  String get onbSkip => 'Passer';

  @override
  String onbStepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get clockFormatAuto => 'Auto';

  @override
  String get modePomodoro => 'Pomodoro';

  @override
  String get modeClock => 'Horloge';

  @override
  String get modeTimer => 'Minuteur';

  @override
  String get modeStopwatch => 'Chronomètre';

  @override
  String get modeAlarm => 'Alarme';

  @override
  String get modeWorld => 'Heure mondiale';

  @override
  String get modeDescPomodoro => 'Cycles de focus et de repos';

  @override
  String get modeDescClock => 'Une belle horloge, toujours visible';

  @override
  String get modeDescTimer => 'Compte à rebours de n\'importe quelle durée';

  @override
  String get modeDescStopwatch => 'Mesure le temps, avec tours';

  @override
  String get modeDescAlarm => 'Réveils et rappels';

  @override
  String get modeDescWorld => 'L\'heure dans les villes du monde';

  @override
  String get tooltipModes => 'Modes';

  @override
  String get tooltipSwitchMode => 'Mode suivant';

  @override
  String get tooltipFullscreen => 'Plein écran';

  @override
  String get tooltipExitFullscreen => 'Quitter le plein écran';

  @override
  String get tooltipDim => 'Atténuer l\'écran';

  @override
  String get modesTitle => 'Modes';

  @override
  String get modesHint =>
      'Choisis les modes que tu utilises et leur ordre. Fais glisser pour réorganiser.';

  @override
  String get modesStart => 'Démarrer avec';

  @override
  String get modesStartLast => 'Dernier mode utilisé';

  @override
  String get modesCustomize => 'Personnaliser';

  @override
  String get modesActivity => 'Historique d\'activité';

  @override
  String get modesAtLeastOne => 'Au moins un mode doit rester actif.';

  @override
  String modesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modes actifs',
      one: '1 mode actif',
    );
    return '$_temp0';
  }

  @override
  String get tooltipActivity => 'Historique d\'activité';

  @override
  String get activityTitle => 'Activité';

  @override
  String get activityEmpty =>
      'Rien pour l\'instant.\nUtilise un minuteur, un chronomètre, une alarme ou l\'horloge et cela apparaîtra ici.';

  @override
  String get activityFilterAll => 'Tout';

  @override
  String get activityTimersToday => 'Minuteurs aujourd\'hui';

  @override
  String get activityStopwatchToday => 'Chronomètre aujourd\'hui';

  @override
  String get activityDisplayToday => 'À l\'écran aujourd\'hui';

  @override
  String activityLaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
    );
    return '$_temp0';
  }

  @override
  String activityLap(int n) {
    return 'Tour $n';
  }

  @override
  String get activityAlarmDismissed => 'Arrêtée';

  @override
  String get activityAlarmSnoozed => 'Reportée';

  @override
  String get activityAlarmMissed => 'Manquée';

  @override
  String activityDisplay(String mode) {
    return '$mode à l\'écran';
  }

  @override
  String activityRan(String done, String planned) {
    return '$done sur $planned';
  }

  @override
  String get faceRing => 'Anneau';

  @override
  String get faceDigital => 'Numérique';

  @override
  String get faceAnalog => 'Analogique';

  @override
  String get faceSplit => 'Grand';

  @override
  String get faceDay => 'Jour';

  @override
  String get tooltipCustomize => 'Personnaliser';

  @override
  String get clockSettingsTitle => 'Personnaliser l\'horloge';

  @override
  String get clockFaceTitle => 'Design';

  @override
  String get clockShowSeconds => 'Afficher les secondes';

  @override
  String get clockShowDate => 'Afficher la date';

  @override
  String get clockBlinkColon => 'Deux-points clignotants';

  @override
  String get clockKeepAwake => 'Garder l\'écran allumé';

  @override
  String get clockKeepAwakeHint => 'Tant que l\'horloge est visible.';

  @override
  String get clockFullscreenHint =>
      'Touche plein écran pour une horloge de bureau qui reste allumée. Balaie l\'horloge pour changer son design.';

  @override
  String clockDayPercent(int percent) {
    return '$percent % de la journée';
  }

  @override
  String get ringDismiss => 'Arrêter';

  @override
  String ringSnooze(int minutes) {
    return 'Reporter de $minutes min';
  }

  @override
  String get timerStart => 'Démarrer';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerResume => 'Reprendre';

  @override
  String get timerReset => 'Réinitialiser';

  @override
  String get timerAddMinute => '+1 min';

  @override
  String get timerHoursShort => 'h';

  @override
  String get timerMinutesShort => 'min';

  @override
  String get timerSecondsShort => 's';

  @override
  String get timerUpTitle => 'Temps écoulé';

  @override
  String timerUpBody(String duration) {
    return 'Le minuteur de $duration est terminé.';
  }

  @override
  String get timerSavePreset => 'Enregistrer cette durée';

  @override
  String get timerPresetHint =>
      'Touche + pour enregistrer cette durée. Maintiens appuyé sur un préréglage pour le retirer.';

  @override
  String get stopwatchStop => 'Arrêter';

  @override
  String get stopwatchLap => 'Tour';

  @override
  String get stopwatchLapBest => 'Meilleur';

  @override
  String get stopwatchLapWorst => 'Plus lent';

  @override
  String get worldLocal => 'Heure locale';

  @override
  String get worldToday => 'Aujourd\'hui';

  @override
  String get worldTomorrow => 'Demain';

  @override
  String get worldYesterday => 'Hier';

  @override
  String get worldAdd => 'Ajouter une ville';

  @override
  String get worldSearch => 'Rechercher des villes';

  @override
  String get worldNoResults => 'Aucune ville trouvée.';

  @override
  String get worldEdit => 'Modifier la liste';

  @override
  String get worldDone => 'OK';

  @override
  String get worldRemove => 'Retirer';

  @override
  String get worldEmpty =>
      'Aucune autre ville pour l\'instant. Touche + pour en ajouter une.';

  @override
  String get worldSameTime => 'Même heure que toi';

  @override
  String worldDiffAhead(String diff) {
    return '$diff d\'avance sur toi';
  }

  @override
  String worldDiffBehind(String diff) {
    return '$diff de retard sur toi';
  }

  @override
  String alarmNext(String duration) {
    return 'Prochaine alarme dans $duration';
  }

  @override
  String get alarmNone => 'Aucune alarme active';

  @override
  String get alarmNew => 'Nouvelle alarme';

  @override
  String get alarmEditTitle => 'Modifier l\'alarme';

  @override
  String get alarmLabel => 'Nom';

  @override
  String get alarmRepeat => 'Répéter';

  @override
  String get alarmSave => 'Enregistrer';

  @override
  String get alarmDelete => 'Supprimer l\'alarme';

  @override
  String get alarmConfirmDelete => 'Confirmer : supprimer l\'alarme';

  @override
  String get alarmDeleteHint => 'Cette alarme sera supprimée.';

  @override
  String get alarmEmpty =>
      'Aucune alarme pour l\'instant.\nTouche + pour en créer une.';

  @override
  String get alarmEveryDay => 'Tous les jours';

  @override
  String get alarmWeekdays => 'En semaine';

  @override
  String get alarmWeekends => 'Week-ends';

  @override
  String get alarmOnce => 'Une fois';

  @override
  String get alarmPermissionHint =>
      'Pour sonner quand l\'app est fermée, Enfo a besoin de l\'autorisation pour les notifications et les alarmes exactes.';

  @override
  String get alarmPermissionButton => 'Autoriser les alarmes';

  @override
  String get alarmDesktopHint =>
      'Sur cet appareil, Enfo doit rester ouvert pour que les alarmes sonnent.';

  @override
  String get hapticsTitle => 'Vibration';

  @override
  String get hapticsOff => 'Désactivée';

  @override
  String get hapticsStrength => 'Intensité';

  @override
  String get hapticsSoft => 'Douce';

  @override
  String get hapticsMedium => 'Moyenne';

  @override
  String get hapticsStrong => 'Forte';

  @override
  String get hapticsTouch => 'Toucher';

  @override
  String get hapticsTouchHint => 'Boutons, interrupteurs et sélections.';

  @override
  String get hapticsMotion => 'Mouvement';

  @override
  String get hapticsMotionHint =>
      'Molettes, curseurs, glissements et transitions.';

  @override
  String get hapticsAlerts => 'Alertes';

  @override
  String get hapticsAlertsHint =>
      'Minuteurs, changements de phase, compte à rebours final et alarmes.';

  @override
  String get hapticsAlarmPattern => 'Motif de l\'alarme';

  @override
  String get hapticsAlarmPatternHint =>
      'Touche un motif pour le ressentir. L\'écran de l\'alarme pulse au même rythme.';

  @override
  String get hapticsPatternHeartbeat => 'Battement';

  @override
  String get hapticsPatternPulse => 'Pouls';

  @override
  String get hapticsPatternCrescendo => 'Crescendo';

  @override
  String get hapticsPatternRipple => 'Ondulations';

  @override
  String get hapticsPatternBeacon => 'Phare';

  @override
  String get hapticsTry => 'Essayer';

  @override
  String get hapticsTryTap => 'Toucher';

  @override
  String get hapticsTrySuccess => 'Succès';

  @override
  String get hapticsTryToRest => 'Fin du focus';

  @override
  String get hapticsTryToWork => 'Fin du repos';

  @override
  String get hapticsTryTimer => 'Fin du minuteur';

  @override
  String get hapticsTryWarning => 'Avertissement';

  @override
  String get hapticsUnavailable =>
      'Cet appareil n\'a pas de moteur de vibration.';

  @override
  String get hapticsWhen => 'Quand vibrer';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSubtitle =>
      'Horloges et minuteurs sur ton écran d\'accueil';

  @override
  String get widgetsAddHeader => 'Ajouter à l\'écran d\'accueil';

  @override
  String get widgetsAdd => 'Ajouter';

  @override
  String get widgetsDynamicColor => 'Couleurs Material You';

  @override
  String get widgetsDynamicColorHint =>
      'Les widgets reprennent les couleurs de ton fond d\'écran. Désactive pour utiliser la couleur d\'accent d\'Enfo.';

  @override
  String get widgetsManualHint =>
      'Ton lanceur ne permet pas d\'ajouter des widgets d\'ici. Appuie longuement sur l\'écran d\'accueil, choisis Widgets et cherche Enfo.';

  @override
  String get widgetsStyleHint =>
      'Les widgets Pomodoro et minuteur sont dessinés avec le style d\'horloge que tu as choisi. Change le style dans l\'app et ils suivent.';

  @override
  String get widgetsTapHint =>
      'Les boutons d\'un widget ouvrent Enfo et exécutent l\'action, ainsi le temps est toujours géré par l\'app.';

  @override
  String get shortcutsTitle => 'Clavier et télécommande';

  @override
  String get shortcutsSubtitle =>
      'Raccourcis pour clavier, souris et télécommande de TV';

  @override
  String get shortcutsIntro =>
      'Les flèches ou le pavé directionnel de la télécommande déplacent, Entrée ou OK valide. Ces touches font le reste.';

  @override
  String get shortcutKeySpace => 'Espace';

  @override
  String get shortcutPlayPause => 'Démarrer ou mettre en pause';

  @override
  String get shortcutReset => 'Réinitialiser';

  @override
  String get shortcutLap => 'Tour (chronomètre)';

  @override
  String get shortcutJumpMode => 'Aller au mode 1–9';

  @override
  String get shortcutStepMode => 'Mode précédent / suivant';

  @override
  String get shortcutFullscreen => 'Plein écran';

  @override
  String get shortcutDim => 'Atténuer l\'écran (plein écran)';

  @override
  String get shortcutSettings => 'Réglages';

  @override
  String get shortcutModes => 'Menu des modes';

  @override
  String get shortcutBack => 'Retour / quitter le plein écran';

  @override
  String get shortcutHelp => 'Afficher cette liste';

  @override
  String get onbMoreTools => 'Plus d\'outils';

  @override
  String get modeEvent => 'Événements';

  @override
  String get modeDescEvent => 'Comptez les jours avant l\'important';

  @override
  String get modeIntervals => 'Intervalles';

  @override
  String get modeDescIntervals => 'Rounds effort/repos, type HIIT';

  @override
  String get modeBreathe => 'Respirer';

  @override
  String get modeDescBreathe => 'Respiration guidée pour se calmer';

  @override
  String get modeTracker => 'Suivi';

  @override
  String get modeDescTracker =>
      'Chronométrez vos activités et voyez les totaux';

  @override
  String get modeKitchen => 'Cuisine';

  @override
  String get modeDescKitchen => 'Plusieurs minuteurs nommés en même temps';

  @override
  String get modeSleep => 'Sommeil';

  @override
  String get modeDescSleep => 'Planifiez coucher et réveil par cycles';

  @override
  String get modeVersus => 'Tours';

  @override
  String get modeDescVersus => 'Pendule à deux pour échecs, jeux et débats';

  @override
  String get modeBreaks => 'Pauses';

  @override
  String get modeDescBreaks => 'Rappels pour reposer les yeux et s\'étirer';

  @override
  String get modeAmbient => 'Ambiance';

  @override
  String get modeDescAmbient => 'Sons d\'ambiance avec minuterie d\'arrêt';

  @override
  String get intervalsPresetTabata => 'Tabata';

  @override
  String get intervalsPresetHiit => 'HIIT';

  @override
  String get intervalsPresetEmom => 'EMOM';

  @override
  String get intervalsPresetCustom => 'Perso';

  @override
  String get intervalsWarmUp => 'Échauffement';

  @override
  String get intervalsWork => 'Effort';

  @override
  String get intervalsRest => 'Repos';

  @override
  String get intervalsRounds => 'Tours';

  @override
  String get intervalsCoolDown => 'Retour au calme';

  @override
  String get intervalsOff => 'Non';

  @override
  String intervalsRound(int current, int total) {
    return 'Tour $current/$total';
  }

  @override
  String intervalsTotal(String duration) {
    return 'Total $duration';
  }

  @override
  String get intervalsSkip => 'Passer à la phase suivante';

  @override
  String get intervalsHint =>
      'Touchez une ligne pour la modifier. Toute modification est enregistrée en Perso.';

  @override
  String get intervalsDoneTitle => 'Séance terminée';

  @override
  String intervalsDoneBody(String name, String duration) {
    return '$name · $duration. Bravo !';
  }

  @override
  String get kitchenPasta => 'Pâtes';

  @override
  String get kitchenEggs => 'Œufs';

  @override
  String get kitchenTea => 'Thé';

  @override
  String get kitchenRice => 'Riz';

  @override
  String get kitchenOven => 'Four';

  @override
  String get kitchenCustom => 'Autre';

  @override
  String get kitchenNameHint => 'Nom';

  @override
  String get kitchenAdd => 'Lancer le minuteur';

  @override
  String get kitchenDelete => 'Supprimer le minuteur';

  @override
  String get kitchenEmpty =>
      'Aucun minuteur. Touchez une puce pour en lancer un.';

  @override
  String get kitchenDefaultName => 'Minuteur';

  @override
  String kitchenDoneTitle(String name) {
    return '$name est prêt';
  }

  @override
  String kitchenDoneBody(String duration) {
    return 'Le minuteur de $duration est terminé.';
  }

  @override
  String get trackerToday => 'Aujourd\'hui';

  @override
  String get trackerWeek => '7 derniers jours';

  @override
  String get trackerTapToStart => 'Touchez une activité pour la chronométrer';

  @override
  String get trackerNoRunning => 'Rien en cours';

  @override
  String get trackerAddActivity => 'Nouvelle activité';

  @override
  String get trackerNameHint => 'Nom';

  @override
  String get trackerStudy => 'Étude';

  @override
  String get trackerReading => 'Lecture';

  @override
  String get trackerCode => 'Code';

  @override
  String get trackerExercise => 'Sport';

  @override
  String get trackerEdit => 'Modifier l\'activité';

  @override
  String get trackerDetails => 'Détails et graphique';

  @override
  String get trackerColor => 'Couleur';

  @override
  String get trackerIcon => 'Icône';

  @override
  String get trackerDelete => 'Supprimer l\'activité';

  @override
  String get trackerDeleteConfirm => 'Confirmer : supprimer l\'activité';

  @override
  String get trackerDeleteHint =>
      'Le temps déjà enregistré reste dans l\'historique.';

  @override
  String get trackerAddTime => 'Ajouter du temps';

  @override
  String trackerAddMinutes(int minutes) {
    return 'Ajouter $minutes min';
  }

  @override
  String get trackerMinutesFewer => 'Moins de minutes';

  @override
  String get trackerMinutesMore => 'Plus de minutes';

  @override
  String get trackerStop => 'Arrêter';

  @override
  String get versusDuel => 'Duel';

  @override
  String get versusSpeakers => 'Intervenants';

  @override
  String get versusCustom => 'Perso';

  @override
  String get versusIncrement => 'Incrément';

  @override
  String get versusTapToStart => 'Touchez votre côté pour lancer votre pendule';

  @override
  String get versusTimeIsUp => 'Temps écoulé';

  @override
  String versusMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coups',
      one: '1 coup',
    );
    return '$_temp0';
  }

  @override
  String get versusResetGame => 'Réinitialiser la partie';

  @override
  String get versusConfirmReset => 'Confirmer';

  @override
  String versusSpeakerN(int n) {
    return 'Intervenant $n';
  }

  @override
  String get versusAddSpeaker => 'Ajouter un intervenant';

  @override
  String get versusRemoveSpeaker => 'Retirer l\'intervenant';

  @override
  String get versusSpeakerName => 'Intervenant ou sujet';

  @override
  String get versusNext => 'Intervenant suivant';

  @override
  String get versusFinish => 'Terminer';

  @override
  String get versusOvertime => 'Dépassement';

  @override
  String versusElapsedOfPlanned(String elapsed, String planned) {
    return '$elapsed sur $planned';
  }

  @override
  String get versusAgendaDone => 'Ordre du jour terminé';

  @override
  String get versusStartAgenda => 'Démarrer l\'ordre du jour';

  @override
  String get versusMinutesFewer => 'Moins de minutes';

  @override
  String get versusMinutesMore => 'Plus de minutes';

  @override
  String get versusTotal => 'Total';

  @override
  String get breatheInhale => 'Inspirez';

  @override
  String get breatheHold => 'Retenez';

  @override
  String get breatheExhale => 'Expirez';

  @override
  String get breatheStart => 'Commencer';

  @override
  String get breathePause => 'Pause';

  @override
  String get breatheResume => 'Reprendre';

  @override
  String get breatheReset => 'Arrêter la séance';

  @override
  String get breatheDone => 'Bravo';

  @override
  String get breatheReady => 'Installez-vous confortablement';

  @override
  String get breathePatternBox => 'Carrée';

  @override
  String get breathePatternCoherent => 'Cohérente';

  @override
  String get breathePatternCalm => 'Calme';

  @override
  String get breathePatternCustom => 'Perso';

  @override
  String get breatheSession => 'Durée';

  @override
  String get breatheEndless => 'Sans fin';

  @override
  String breatheSeconds(int n) {
    return '$n s';
  }

  @override
  String get ambientWhite => 'Bruit blanc';

  @override
  String get ambientPink => 'Bruit rose';

  @override
  String get ambientBrown => 'Bruit brun';

  @override
  String get ambientRain => 'Pluie';

  @override
  String get ambientWind => 'Vent';

  @override
  String get ambientOcean => 'Océan';

  @override
  String get ambientVolume => 'Volume';

  @override
  String get ambientSleepTimer => 'Minuterie de sommeil';

  @override
  String get ambientTimerOff => 'Non';

  @override
  String get ambientPlay => 'Lancer le son';

  @override
  String get ambientStop => 'Arrêter le son';

  @override
  String get ambientUnavailable =>
      'Le son n\'est pas disponible sur cet appareil.';

  @override
  String get ambientPreparing => 'Préparation du son…';

  @override
  String ambientTimeLeft(String time) {
    return 'Reste $time';
  }

  @override
  String get breaksStart => 'Démarrer les pauses';

  @override
  String get breaksStop => 'Arrêter les pauses';

  @override
  String get breaksStatusOff => 'Les rappels sont désactivés';

  @override
  String get breaksNoneEnabled => 'Active au moins un rappel';

  @override
  String breaksNextName(String name) {
    return 'Prochain : $name';
  }

  @override
  String get breaksToday => 'Aujourd\'hui';

  @override
  String get breaksTaken => 'Pauses faites';

  @override
  String get breaksSkipped => 'Ignorées';

  @override
  String get breaksEyeName => 'Repos des yeux (20-20-20)';

  @override
  String get breaksEyeHint => 'Regarde quelque chose à 6 m pendant 20 secondes';

  @override
  String get breaksStretchName => 'Étirements';

  @override
  String get breaksStretchHint => 'Lève-toi et étire tout ton corps';

  @override
  String get breaksWaterName => 'Boire de l\'eau';

  @override
  String get breaksWaterHint => 'Bois un verre d\'eau';

  @override
  String get breaksPostureName => 'Vérifier la posture';

  @override
  String get breaksPostureHint => 'Redresse-toi et détends les épaules';

  @override
  String get breaksCustomDefault => 'Mon rappel';

  @override
  String breaksForDuration(String duration) {
    return 'Prends $duration';
  }

  @override
  String breaksEveryMinutes(int minutes) {
    return 'Toutes les $minutes min';
  }

  @override
  String get breaksShorter => 'Intervalle plus court';

  @override
  String get breaksLonger => 'Intervalle plus long';

  @override
  String get breaksDone => 'Fait';

  @override
  String get breaksSkip => 'Ignorer';

  @override
  String get breaksActiveHours => 'Heures actives';

  @override
  String get breaksActiveHoursHint =>
      'Les rappels n\'apparaissent que dans cette plage';

  @override
  String get breaksFrom => 'De';

  @override
  String get breaksTo => 'À';

  @override
  String get breaksLaterHour => 'Plus tard';

  @override
  String get breaksEarlierHour => 'Plus tôt';

  @override
  String get breaksBackground => 'Aussi quand Enfo est fermé';

  @override
  String get breaksBackgroundOn =>
      'Les notifications te rappellent même quand l\'app est fermée.';

  @override
  String get breaksBackgroundOff =>
      'Les rappels n\'apparaissent que lorsque Enfo est ouvert.';

  @override
  String get breaksDesktopNotice =>
      'Les rappels apparaissent tant qu\'Enfo est lancé (même réduit).';

  @override
  String get breaksAddCustom => 'Ajouter un rappel perso';

  @override
  String get breaksEdit => 'Modifier le rappel';

  @override
  String get breaksName => 'Nom';

  @override
  String get breaksDuration => 'Durée';

  @override
  String get breaksIcon => 'Icône';

  @override
  String get breaksShorterDuration => 'Pause plus courte';

  @override
  String get breaksLongerDuration => 'Pause plus longue';

  @override
  String get breaksRemove => 'Supprimer le rappel';

  @override
  String get breaksRemoveConfirm => 'Confirmer : supprimer le rappel';

  @override
  String get breaksRemoveHint => 'Il ne te préviendra plus.';

  @override
  String get worldPlan => 'Planifier une réunion';

  @override
  String get worldPlanIntro =>
      'Déplace le repère pour trouver une heure qui convient à tous.';

  @override
  String get worldPlanNow => 'Maintenant';

  @override
  String get worldPlanEarlier => '15 minutes plus tôt';

  @override
  String get worldPlanLater => '15 minutes plus tard';

  @override
  String worldPlanSelected(String city) {
    return 'Heure choisie à $city';
  }

  @override
  String get worldPlanTapCity =>
      'Touche une ville pour utiliser son heure comme référence.';

  @override
  String get worldPlanNextDay => '+1 jour';

  @override
  String get worldPlanPrevDay => '-1 jour';

  @override
  String get worldPlanOverlapTitle => 'Tout le monde travaille';

  @override
  String get worldPlanNoOverlap =>
      'Aucun créneau des 24 prochaines heures ne convient à tous.';

  @override
  String worldPlanLeastBad(String time) {
    return 'Le moins pire : $time';
  }

  @override
  String worldPlanAtWork(int count, int total) {
    return '$count sur $total au travail';
  }

  @override
  String get worldPlanWork => 'Heures de travail (09-18)';

  @override
  String get worldPlanNight => 'Nuit';

  @override
  String get worldPlanMarker => 'Heure choisie';

  @override
  String get eventAdd => 'Nouvel événement';

  @override
  String get eventEdit => 'Modifier l\'événement';

  @override
  String get eventName => 'Nom';

  @override
  String get eventNameHint => 'Anniversaire, voyage, lancement...';

  @override
  String get eventYearly => 'Répéter chaque année';

  @override
  String get eventYearlyHint =>
      'Pour les anniversaires : passe automatiquement au suivant.';

  @override
  String get eventNotify => 'Me prévenir';

  @override
  String get eventNotifyHint => 'Au moment où il arrive.';

  @override
  String get eventDayBefore => 'Aussi la veille';

  @override
  String get eventSave => 'Enregistrer';

  @override
  String get eventDelete => 'Supprimer l\'événement';

  @override
  String get eventConfirmDelete => 'Confirmer : supprimer l\'événement';

  @override
  String get eventDeleteHint => 'Cet événement sera supprimé.';

  @override
  String get eventEmpty =>
      'Aucun événement pour l\'instant.\nAppuyez sur + pour lancer un compte à rebours.';

  @override
  String get eventToday => 'Aujourd\'hui !';

  @override
  String eventDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get eventDaysShort => 'j';

  @override
  String get eventUnitDays => 'jours';

  @override
  String get eventUnitHours => 'heures';

  @override
  String get eventUnitMinutes => 'min';

  @override
  String get eventRepeatsYearly => 'Chaque année';

  @override
  String get eventNotifyNow => 'C\'est le moment !';

  @override
  String get eventNotifyTomorrow => 'Demain';

  @override
  String get sleepPlanWake => 'Réveil à';

  @override
  String get sleepPlanBed => 'Coucher à';

  @override
  String get sleepPlanNow => 'Dormir maintenant';

  @override
  String get sleepTitleWake => 'Je veux me réveiller à';

  @override
  String get sleepTitleBed => 'Je me couche à';

  @override
  String sleepTitleNow(String time) {
    return 'Si je m\'endors maintenant ($time)';
  }

  @override
  String get sleepBedtimeWord => 'Coucher';

  @override
  String get sleepWakeWord => 'Réveil';

  @override
  String sleepCyclesLine(int cycles, String duration) {
    return '$cycles cycles · $duration de sommeil';
  }

  @override
  String get sleepNote =>
      'Un cycle dure 90 minutes et l\'endormissement environ 15. Cinq ou six cycles sont recommandés.';

  @override
  String get sleepWindDown => 'Rappel pour se détendre';

  @override
  String get sleepWindDownHint => 'Une alarme 30 minutes avant le coucher.';

  @override
  String get sleepWindDownPassed => 'Cette heure est déjà passée.';

  @override
  String get sleepWindDownLabel => 'C\'est l\'heure de se détendre';

  @override
  String get sleepAlarmLabel => 'Réveil';

  @override
  String get sleepSetAlarm => 'Régler l\'alarme';

  @override
  String get sleepRemoveAlarm => 'Supprimer l\'alarme';

  @override
  String sleepAlarmSet(String time) {
    return 'Alarme réglée sur $time';
  }

  @override
  String get sleepPast => 'Cette heure est déjà passée';

  @override
  String get sleepRecommended => 'Recommandé';

  @override
  String get ambientMusicTabSounds => 'Sons';

  @override
  String get ambientMusicTab => 'Musique';

  @override
  String get ambientMusicPlay => 'Lire la musique';

  @override
  String get ambientMusicPause => 'Mettre la musique en pause';

  @override
  String get ambientMusicNext => 'Titre suivant';

  @override
  String get ambientMusicPrevious => 'Titre précédent';

  @override
  String get ambientMusicShuffle => 'Aléatoire';

  @override
  String get ambientMusicRepeat => 'Tout répéter';

  @override
  String get ambientMusicVolume => 'Volume de la musique';

  @override
  String get ambientMusicCredits => 'Crédits musiques et ambiances';

  @override
  String get ambientMusicCreditsNote =>
      'Titres de Wikimedia Commons et de la collection Open Lo-Fi, et ambiances de Wikimedia Commons, publiés sous licence CC0, domaine public ou Creative Commons Attribution.';

  @override
  String get modeMusic => 'Musique';

  @override
  String get modeDescMusic => 'Musique lo-fi pour se concentrer';

  @override
  String get musicCreditsSubtitle => 'Artistes et licences';

  @override
  String get displayMenuButtons => 'Boutons du menu';

  @override
  String get displayMenuButtonsHint =>
      'Choisissez les boutons du menu du bas. Les réglages restent toujours là.';

  @override
  String get onbWelcomeTitle => 'Bienvenue sur Enfo';

  @override
  String get onbWelcomeTagline => 'Se concentrer, un cadran serein.';

  @override
  String get timerRunningTitle => 'Minuteur en cours';

  @override
  String timerRunningBody(String time) {
    return 'Se termine à $time';
  }

  @override
  String get timerPausedTitle => 'Minuteur en pause';

  @override
  String timerPausedBody(String duration) {
    return '$duration restantes';
  }

  @override
  String get musicActionPlay => 'Lecture';

  @override
  String get musicActionPause => 'Pause';

  @override
  String get widgetsFocusSubtitle =>
      'Temps de focus et pomodoros du jour en un coup d\'œil.';

  @override
  String get ambienceStream => 'Ruisseau';

  @override
  String get ambienceSnowmelt => 'Fonte des neiges';

  @override
  String get ambienceRivulet => 'Ruisselet';

  @override
  String get ambienceFountain => 'Fontaine';

  @override
  String get ambiencePlazaFountain => 'Fontaine de place';

  @override
  String get ambienceGeyser => 'Geyser';

  @override
  String get ambienceBubblingGeyser => 'Geyser bouillonnant';

  @override
  String get ambienceRainWindow => 'Pluie sur la fenêtre';

  @override
  String get ambienceRainThunder => 'Pluie et tonnerre';

  @override
  String get ambienceThunderstorm => 'Orage';

  @override
  String get ambienceThunderbolts => 'Foudre';

  @override
  String get ambienceStormWind => 'Vent d\'orage';

  @override
  String get ambienceForest => 'Forêt';

  @override
  String get ambienceForestBirds => 'Forêt avec oiseaux';

  @override
  String get ambienceDawnChorus => 'Chœur de l\'aube';

  @override
  String get ambienceCountryDawn => 'Aube à la campagne';

  @override
  String get ambiencePondDusk => 'Étang au crépuscule';

  @override
  String get ambienceMorningBirds => 'Oiseaux du matin';

  @override
  String get ambienceCampfire => 'Feu de camp';

  @override
  String get ambienceFireplace => 'Cheminée';

  @override
  String get ambienceLibrary => 'Bibliothèque';

  @override
  String get ambienceBusyLibrary => 'Bibliothèque animée';

  @override
  String get ambienceOffice => 'Bureau';

  @override
  String get ambienceClassroom => 'Salle de classe';

  @override
  String get ambienceCafeteria => 'Cafétéria';

  @override
  String get ambienceRestaurant => 'Restaurant';

  @override
  String get ambienceSupermarket => 'Supermarché';

  @override
  String get ambienceShoppingMall => 'Centre commercial';

  @override
  String get ambienceRainyStreet => 'Rue pluvieuse';

  @override
  String get ambienceSpringStreet => 'Rue au printemps';

  @override
  String get ambienceSubway => 'Métro';

  @override
  String get ambienceSubwayRide => 'Trajet en métro';

  @override
  String get ambienceStationTunnel => 'Tunnel de gare';

  @override
  String get ambienceTrain => 'Train';

  @override
  String get ambienceTaiwanTrain => 'Train de Taïwan';

  @override
  String get ambienceEscalator => 'Escalator';

  @override
  String get ambienceElevator => 'Ascenseur';

  @override
  String get ambiencePlayground => 'Aire de jeux';

  @override
  String get ambienceStreetMarket => 'Marché de rue';

  @override
  String get ambienceKeyboard => 'Clavier';

  @override
  String get ambientNature => 'Nature';

  @override
  String get ambientPlaces => 'Lieux';

  @override
  String get breaksRelaxSound => 'Son de pause';

  @override
  String get quoteLead1 => 'Respire profondément.';

  @override
  String get quoteLead2 => 'Une chose à la fois.';

  @override
  String get quoteLead3 => 'Commence petit.';

  @override
  String get quoteLead4 => 'Reviens au présent.';

  @override
  String get quoteLead5 => 'Aujourd\'hui, sans hâte.';

  @override
  String get quoteLead6 => 'Fais simple.';

  @override
  String get quoteLead7 => 'Un pas de plus.';

  @override
  String get quoteLead8 => 'Baisse le bruit.';

  @override
  String get quoteLead9 => 'Concentre-toi maintenant.';

  @override
  String get quoteLead10 => 'Moins, mais mieux.';

  @override
  String get quoteLead11 => 'Cinq minutes suffisent.';

  @override
  String get quoteLead12 => 'Choisis l\'essentiel.';

  @override
  String get quoteLead13 => 'Ici et maintenant.';

  @override
  String get quoteLead14 => 'Avec calme.';

  @override
  String get quoteLead15 => 'Pas à pas.';

  @override
  String get quoteLead16 => 'Ferme ce qui distrait.';

  @override
  String get quoteLead17 => 'Ton attention t\'appartient.';

  @override
  String get quoteLead18 => 'Commence par le plus dur.';

  @override
  String get quoteLead19 => 'Respire, puis continue.';

  @override
  String get quoteLead20 => 'Aujourd\'hui compte.';

  @override
  String get quoteThought1 =>
      'Ton prochain pas vaut mieux que le plan parfait.';

  @override
  String get quoteThought2 => 'Le progrès n\'a pas besoin d\'être parfait.';

  @override
  String get quoteThought3 =>
      'Cinq minutes de concentration valent une heure de doute.';

  @override
  String get quoteThought4 => 'Concentre-toi sur ce que tu peux contrôler.';

  @override
  String get quoteThought5 => 'La régularité bat la précipitation.';

  @override
  String get quoteThought6 => 'Une tâche finie vaut mieux que dix commencées.';

  @override
  String get quoteThought7 => 'Ton esprit va là où va ton attention.';

  @override
  String get quoteThought8 => 'Le silence est productif lui aussi.';

  @override
  String get quoteThought9 => 'Fais-le pour la personne que tu deviens.';

  @override
  String get quoteThought10 =>
      'Tu n\'as pas besoin de motivation, tu as besoin de commencer.';

  @override
  String get quoteThought11 => 'Le repos fait partie du travail.';

  @override
  String get quoteThought12 =>
      'Le calme ne freine pas le progrès, il le soutient.';

  @override
  String get quoteThought13 =>
      'Termine une chose avant d\'en ouvrir une autre.';

  @override
  String get quoteThought14 => 'Ton énergie mérite un objectif clair.';

  @override
  String get quoteThought15 =>
      'Les petits jours construisent les grandes années.';

  @override
  String get quoteThought16 => 'Apprends du détour ; ne t\'y arrête pas.';

  @override
  String get quoteThought17 =>
      'La discipline se pratique, elle ne s\'attend pas.';

  @override
  String get quoteThought18 => 'Chaque essai te rapproche.';

  @override
  String get quoteThought19 =>
      'La concentration n\'est pas une force, c\'est une décision.';

  @override
  String get quoteThought20 => 'Protège ta matinée et la journée s\'ordonne.';

  @override
  String get quoteThought21 => 'Avance même si le pas est court.';

  @override
  String get quoteThought22 => 'Laisse l\'important occuper le centre.';

  @override
  String get quoteThought23 => 'Un jour à la fois suffit.';

  @override
  String get quoteThought24 =>
      'Ton meilleur travail commence quand tu commences.';

  @override
  String get quoteThought25 =>
      'L\'attention d\'aujourd\'hui est un cadeau pour demain.';

  @override
  String get focusQuoteTitle => 'Phrase de concentration du jour';

  @override
  String get focusQuoteToggle => 'Phrase de concentration quotidienne';

  @override
  String get focusQuoteHint =>
      'Une notification par jour, choisie parmi 500 phrases, pour vous inspirer.';

  @override
  String get focusQuoteTime => 'Heure d\'envoi';

  @override
  String get focusQuoteExample => 'Aujourd\'hui :';
}
