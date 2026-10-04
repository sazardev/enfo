import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Android home-screen widgets a user can place. The names are the ones
/// the native side uses (`WidgetKind` in Kotlin).
enum WidgetKind {
  clock,
  analog,
  pomodoro,
  timer,
  stopwatch,
  alarm,
  world,
  music,
  focus;

  /// Kinds drawn as a picture of one of the 63 clock styles.
  bool get isFace => this == pomodoro || this == timer;
}

/// Thin, failure-proof wrapper around the native widget channel. Everything
/// is a no-op off Android (and when the platform side is missing, as in
/// tests), so callers never have to check.
class WidgetBridge {
  static const _channel = MethodChannel('com.sazarcode.enfo/widgets');

  /// Tests flip this to exercise the channel on the host platform.
  @visibleForTesting
  static bool? debugSupported;

  static bool get supported =>
      debugSupported ?? (!kIsWeb && Platform.isAndroid);

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Where frames for face widgets are written (native app files dir).
  static Future<String?> framesDir() => _call<String>('framesDir');

  /// The system (Material You) accent as ARGB, or null before Android 12.
  static Future<int?> systemSeed() => _call<int>('systemSeed');

  /// Which kinds currently have at least one instance on a home screen.
  static Future<Set<WidgetKind>> activeKinds() async {
    final names = await _call<List<Object?>>('activeKinds');
    if (names == null) return const {};
    return WidgetKind.values.where((k) => names.contains(k.name)).toSet();
  }

  /// Hands the native side the latest state (a JSON document) and asks it to
  /// refresh every widget.
  static Future<void> sync(String json) => _call<void>('sync', json);

  /// Whether the launcher lets an app ask to pin a widget.
  static Future<bool> canPin() async => await _call<bool>('canPin') ?? false;

  /// Asks the launcher to add [kind] to the home screen.
  static Future<bool> pin(WidgetKind kind) async =>
      await _call<bool>('pin', kind.name) ?? false;

  /// The tap that launched (or is about to reach) the app, once.
  static Future<Map<String, String>?> takeLaunch() async {
    final raw = await _call<Map<Object?, Object?>>('takeLaunch');
    return _launch(raw);
  }

  static Map<String, String>? _launch(Map<Object?, Object?>? raw) {
    if (raw == null) return null;
    final mode = raw['mode'];
    if (mode is! String || mode.isEmpty) return null;
    final action = raw['action'];
    return {'mode': mode, if (action is String) 'action': action};
  }

  /// Native pushes to the app while it runs: a tap on a widget ([onLaunch])
  /// or a newly placed widget that wants its pictures ([onResync]).
  static void listen({
    required void Function(Map<String, String> launch) onLaunch,
    required VoidCallback onResync,
  }) {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'launch':
          final launch = _launch(call.arguments as Map<Object?, Object?>?);
          if (launch != null) onLaunch(launch);
        case 'resync':
          onResync();
      }
    });
  }
}
