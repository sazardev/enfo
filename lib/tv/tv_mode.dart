import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether Enfo is running on Android TV / Google TV, plus the layout
/// adjustments that a television needs.
///
/// Flutter cannot tell a TV from a desktop by window size alone (a 1080p TV
/// is 960 x 540 logical pixels), so the Android side answers through a small
/// method channel. Everything TV-specific reads [isTv] instead of guessing
/// from the screen size.
abstract final class TvMode {
  const TvMode._();

  static const MethodChannel _channel = MethodChannel('com.sazarcode.enfo/tv');

  /// Tests force this. `null` means "use what the platform reported".
  @visibleForTesting
  static bool? debugIsTv;

  static bool _isTv = false;

  static bool get isTv => debugIsTv ?? _isTv;

  /// Called once at boot, before preferences are loaded, so the TV defaults
  /// (large UI) are already in place.
  static Future<void> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _isTv = false;
      return;
    }
    try {
      _isTv = await _channel.invokeMethod<bool>('isTv') ?? false;
    } on MissingPluginException {
      _isTv = false;
    } on PlatformException {
      _isTv = false;
    }
    if (_isTv) {
      // A TV must show where the remote is pointing before the first key
      // press, not only after it. This also makes autofocus visible.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    }
  }

  /// Android TV normally reports zero system padding, while many televisions
  /// crop the outer edge of the picture (overscan). Keep every [SafeArea] at
  /// least 5% away from the sides and 3.5% from the top/bottom.
  static EdgeInsets mergeSafePadding(MediaQueryData media) {
    if (!isTv) return media.padding;
    final horizontal = media.size.width * 0.05;
    final vertical = media.size.height * 0.035;
    return EdgeInsets.fromLTRB(
      math.max(media.padding.left, horizontal),
      math.max(media.padding.top, vertical),
      math.max(media.padding.right, horizontal),
      math.max(media.padding.bottom, vertical),
    );
  }
}
