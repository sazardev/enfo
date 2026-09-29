import 'package:enfo/modes/app_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Values a scene's seeding code needs.
class ShotCtx {
  ShotCtx(this.lang, this.dark, this.frozen);
  final String lang;
  final bool dark;

  /// The frozen "now" (nowProvider).
  final DateTime frozen;

  bool get es => lang == 'es';

  /// Picks the text for the current language (falls back to English).
  String t(String en, {String? es, Map<String, String> more = const {}}) =>
      more[lang] ?? (lang == 'es' && es != null ? es : en);
}

class Scene {
  const Scene({
    required this.n,
    required this.id,
    required this.theme,
    required this.accent,
    this.mode,
    this.prefs,
    this.seed,
    this.home,
    this.drive,
    this.both = false,
    this.featuredHeadline,
    this.settleMore = 0,
    this.smallOn = const {},
    this.note = '',
  });

  /// Two-digit order in the file names.
  final int n;
  final String id;

  /// 'dark' | 'light': the theme that suits this scene best.
  final String theme;
  final Color accent;

  /// Mode to show through ModeHost (default: Pomodoro). Ignored if [home].
  final AppMode? mode;

  /// Extra shared_preferences values (in addition to the accent, modes...).
  final Map<String, Object> Function(ShotCtx c)? prefs;

  /// Seeding through the real services, run after prefs are loaded.
  final Future<void> Function(ShotCtx c)? seed;

  /// Replaces ModeHost with another root widget.
  final Widget Function(ShotCtx c)? home;

  /// Interactions after the first frame (taps, scrolling).
  final Future<void> Function(WidgetTester tester, ShotCtx c)? drive;

  /// Also render the opposite theme (hero scene).
  final bool both;

  /// Non-null when the scene is in the featured set: the headline l10n key
  /// suggestion for the composition step.
  final String? featuredHeadline;

  final int settleMore;

  /// Device dirs (e.g. phone/landscape) rendered with the user's "small"
  /// UI size because the default overflows there (see the report).
  final Set<String> smallOn;
  final String note;
}
