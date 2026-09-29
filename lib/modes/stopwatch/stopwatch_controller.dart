import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clock/time_builder.dart';
import '../tool_history.dart';
import '../../haptics/haptics.dart';

/// The stopwatch. One app-wide instance built on timestamps: it keeps
/// counting while you use other modes or close the app, and only
/// [reset] — which also files the run, laps included, in the history —
/// clears it.
class StopwatchController extends ChangeNotifier {
  StopwatchController._();
  static final StopwatchController instance = StopwatchController._();

  static const _key = 'stopwatch_state';

  bool running = false;
  DateTime? _runStart;
  Duration _accumulated = Duration.zero;
  Duration _lapMark = Duration.zero;
  DateTime? _sessionStart;

  /// Lap durations in milliseconds, oldest first.
  final List<int> laps = [];

  Duration get elapsed => running
      ? _accumulated + nowProvider().difference(_runStart!)
      : _accumulated;

  /// Time since the last lap (or since the start).
  Duration get currentLap => elapsed - _lapMark;

  bool get hasData => elapsed > Duration.zero;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      running = json['r'] as bool;
      _accumulated = Duration(milliseconds: json['a'] as int);
      _lapMark = Duration(milliseconds: json['m'] as int);
      final run = json['t'] as int?;
      _runStart = run == null ? null : DateTime.fromMillisecondsSinceEpoch(run);
      final session = json['s'] as int?;
      _sessionStart =
          session == null ? null : DateTime.fromMillisecondsSinceEpoch(session);
      laps
        ..clear()
        ..addAll((json['l'] as List<dynamic>).cast<int>());
      if (running && _runStart == null) running = false;
    } catch (_) {
      _clear();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'r': running,
        'a': _accumulated.inMilliseconds,
        'm': _lapMark.inMilliseconds,
        if (_runStart != null) 't': _runStart!.millisecondsSinceEpoch,
        if (_sessionStart != null) 's': _sessionStart!.millisecondsSinceEpoch,
        'l': laps,
      }),
    );
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void start() {
    if (running) return;
    Haptics.confirm();
    _runStart = nowProvider();
    _sessionStart ??= _runStart;
    running = true;
    _changed();
  }

  void stop() {
    if (!running) return;
    Haptics.tap();
    _accumulated += nowProvider().difference(_runStart!);
    _runStart = null;
    running = false;
    _changed();
  }

  void lap() {
    if (!running) return;
    Haptics.lap();
    final now = elapsed;
    laps.add((now - _lapMark).inMilliseconds);
    _lapMark = now;
    _changed();
  }

  /// Clears the stopwatch, filing a run of at least a second in the history.
  void reset() {
    Haptics.warning();
    final total = elapsed;
    if (total >= const Duration(seconds: 1) && _sessionStart != null) {
      final finished = [...laps];
      // The stretch after the last lap counts as the final lap.
      if (finished.isNotEmpty && total > _lapMark) {
        finished.add((total - _lapMark).inMilliseconds);
      }
      ToolHistory.add(ToolEvent(
        kind: ToolKind.stopwatch,
        at: _sessionStart!,
        seconds: total.inSeconds,
        laps: finished,
      ));
    }
    _clear();
    _changed();
  }

  /// Back to factory state, in memory (after preferences were erased).
  void wipe() {
    _clear();
    notifyListeners();
  }

  void _clear() {
    running = false;
    _runStart = null;
    _sessionStart = null;
    _accumulated = Duration.zero;
    _lapMark = Duration.zero;
    laps.clear();
  }
}
