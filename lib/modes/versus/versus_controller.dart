import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../haptics/haptics.dart';
import '../clock/time_builder.dart';
import '../tool_history.dart';

enum VersusKind { duel, speakers }

/// setup: choosing the game. ready: (duel) clocks set, nobody has started.
enum VersusPhase { setup, ready, running, paused, over }

class DuelPreset {
  const DuelPreset(this.base, this.increment);
  final int base;
  final int increment;

  String get label => duelLabel(base, increment);

  @override
  bool operator ==(Object other) =>
      other is DuelPreset && other.base == base && other.increment == increment;

  @override
  int get hashCode => Object.hash(base, increment);
}

/// Bullet 1+0, Blitz 3+2, Blitz 5+0, Rapid 10+0, Rapid 15+10.
const List<DuelPreset> duelPresets = [
  DuelPreset(60, 0),
  DuelPreset(180, 2),
  DuelPreset(300, 0),
  DuelPreset(600, 0),
  DuelPreset(900, 10),
];

/// `3+2` (minutes + seconds of increment); `1:30+0` for a fraction.
String duelLabel(int base, int increment) {
  final m = base ~/ 60;
  final s = base % 60;
  return '${s == 0 ? '$m' : '$m:${s.toString().padLeft(2, '0')}'}+$increment';
}

/// Chess time-control class from the usual estimate: base + 40 x increment.
String duelName(int base, int increment) {
  final estimate = base + 40 * increment;
  final category = estimate < 180
      ? 'Bullet'
      : estimate < 480
          ? 'Blitz'
          : 'Rapid';
  return '$category ${duelLabel(base, increment)}';
}

class Speaker {
  Speaker({required this.id, this.name = '', this.minutes = 5});
  final int id;

  /// Empty = "Speaker N" in the current language.
  String name;
  int minutes;
}

/// The two-player "Turns" clock: a chess-style duel or a speakers agenda.
/// Timestamp-driven: every remaining time is computed from when the current
/// turn began, so it stays exact whatever the UI does. Only the setup is
/// persisted; a running game belongs to the running app.
class VersusController extends ChangeNotifier {
  VersusController._();
  static final VersusController instance = VersusController._();

  static const _key = 'versus_config';
  static const minLoggedSeconds = 10;
  static const maxSpeakers = 20;

  // ------------------------------------------------------------- setup
  VersusKind kind = VersusKind.duel;
  int baseSeconds = 180;
  int incrementSeconds = 2;
  bool custom = false;
  List<Speaker> speakers = _defaultSpeakers();
  int _nextId = 100;

  static List<Speaker> _defaultSpeakers() => [
        Speaker(id: 1),
        Speaker(id: 2),
        Speaker(id: 3),
      ];

  // -------------------------------------------------------------- game
  VersusPhase phase = VersusPhase.setup;

  // Duel: side 0 sits at the bottom (portrait) / left, side 1 at the top.
  final List<int> _leftMs = [0, 0];
  int? active;
  int moves = 0;
  final List<int> movesBy = [0, 0];
  int? flagged;
  DateTime? _turnStart;
  DateTime? _gameStart;

  // Speakers.
  int index = 0;
  List<int> _elapsedMs = [];
  bool _overtimeNotified = false;

  bool _logged = false;

  bool get running => phase == VersusPhase.running;
  bool get inGame => phase != VersusPhase.setup;

  bool _loaded = false;

  /// Restores the saved setup once (the page calls it; nothing boots it).
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    if (!inGame) await load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        kind = VersusKind.values
            .firstWhere((k) => k.name == j['k'], orElse: () => VersusKind.duel);
        baseSeconds = (j['b'] as int).clamp(10, 3 * 3600);
        incrementSeconds = (j['i'] as int).clamp(0, 300);
        custom = j['cu'] as bool? ?? false;
        final list = <Speaker>[
          for (final s in j['sp'] as List<dynamic>)
            Speaker(
              id: _nextId++,
              name: (s as Map<String, dynamic>)['n'] as String? ?? '',
              minutes: ((s['m'] as int?) ?? 5).clamp(1, 180),
            ),
        ];
        if (list.isNotEmpty) speakers = list;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'k': kind.name,
        'b': baseSeconds,
        'i': incrementSeconds,
        'cu': custom,
        'sp': [
          for (final s in speakers) {'n': s.name, 'm': s.minutes},
        ],
      }),
    );
  }

  void _configChanged() {
    notifyListeners();
    _save();
  }

  void setKind(VersusKind k) {
    if (inGame || k == kind) return;
    kind = k;
    _configChanged();
  }

  void setPreset(DuelPreset p) {
    if (inGame) return;
    baseSeconds = p.base;
    incrementSeconds = p.increment;
    custom = false;
    _configChanged();
  }

  void setCustom({int? minutes, int? increment}) {
    if (inGame) return;
    custom = true;
    if (minutes != null) baseSeconds = math.max(1, minutes) * 60;
    if (increment != null) incrementSeconds = increment.clamp(0, 300);
    _configChanged();
  }

  Speaker addSpeaker() {
    final s = Speaker(id: _nextId++);
    if (speakers.length < maxSpeakers) speakers = [...speakers, s];
    _configChanged();
    return s;
  }

  void removeSpeaker(int id) {
    if (speakers.length <= 1) return;
    speakers = [
      for (final s in speakers)
        if (s.id != id) s
    ];
    _configChanged();
  }

  void renameSpeaker(int id, String name) {
    for (final s in speakers) {
      if (s.id == id) s.name = name;
    }
    _save();
  }

  void setSpeakerMinutes(int id, int minutes) {
    for (final s in speakers) {
      if (s.id == id) s.minutes = minutes.clamp(1, 180);
    }
    _configChanged();
  }

  int get plannedSpeakerSeconds =>
      speakers.fold(0, (sum, s) => sum + s.minutes * 60);

  /// Log name of the current duel setup.
  String get duelLogLabel => duelName(baseSeconds, incrementSeconds);

  // -------------------------------------------------------------- duel

  /// Remaining milliseconds for [side].
  int remainingMs(int side) {
    if (phase == VersusPhase.setup) return baseSeconds * 1000;
    if (phase == VersusPhase.running && active == side && _turnStart != null) {
      return math.max(0,
          _leftMs[side] - nowProvider().difference(_turnStart!).inMilliseconds);
    }
    return _leftMs[side];
  }

  /// Milliseconds spent by both sides so far (increments excluded).
  int get duelUsedMs {
    final total = 2 * baseSeconds * 1000 + moves * incrementSeconds * 1000;
    return math.max(0, total - remainingMs(0) - remainingMs(1));
  }

  /// Sets the clocks and waits for the first tap.
  void begin() {
    if (phase != VersusPhase.setup) return;
    _logged = false;
    moves = 0;
    movesBy[0] = movesBy[1] = 0;
    flagged = null;
    active = null;
    _turnStart = null;
    if (kind == VersusKind.duel) {
      _leftMs[0] = _leftMs[1] = baseSeconds * 1000;
      phase = VersusPhase.ready;
      Haptics.confirm();
    } else {
      index = 0;
      _elapsedMs = List.filled(speakers.length, 0);
      _overtimeNotified = false;
      _turnStart = nowProvider();
      _gameStart = _turnStart;
      phase = VersusPhase.running;
      Haptics.confirm();
    }
    notifyListeners();
  }

  /// [side] tapped their half. Ready: starts their clock. Running: ends
  /// their turn (only if it is theirs).
  void tapSide(int side) {
    if (kind != VersusKind.duel) return;
    if (phase == VersusPhase.ready) {
      active = side;
      _turnStart = nowProvider();
      _gameStart = _turnStart;
      phase = VersusPhase.running;
      Haptics.confirm();
      notifyListeners();
    } else if (phase == VersusPhase.running && active == side) {
      endTurn();
    }
  }

  void endTurn() {
    if (kind != VersusKind.duel || phase != VersusPhase.running) return;
    check();
    if (phase != VersusPhase.running) return;
    final side = active!;
    _leftMs[side] = remainingMs(side) + incrementSeconds * 1000;
    moves++;
    movesBy[side]++;
    active = 1 - side;
    _turnStart = nowProvider();
    Haptics.confirm();
    notifyListeners();
  }

  // ---------------------------------------------------------- speakers

  Speaker get currentSpeaker => speakers[index.clamp(0, speakers.length - 1)];

  int get currentPlannedMs => currentSpeaker.minutes * 60000;

  int speakerElapsedMs(int i) {
    if (i >= _elapsedMs.length) return 0;
    final base = _elapsedMs[i];
    if (phase == VersusPhase.running && i == index && _turnStart != null) {
      return base + nowProvider().difference(_turnStart!).inMilliseconds;
    }
    return base;
  }

  int get totalElapsedMs {
    var sum = 0;
    for (var i = 0; i < _elapsedMs.length; i++) {
      sum += speakerElapsedMs(i);
    }
    return sum;
  }

  /// Positive while there is time left, negative in overtime.
  int get currentRemainingMs => currentPlannedMs - speakerElapsedMs(index);

  bool get overtime =>
      phase != VersusPhase.setup &&
      kind == VersusKind.speakers &&
      currentRemainingMs < 0;

  bool get isLastSpeaker => index >= speakers.length - 1;

  void next() {
    if (kind != VersusKind.speakers) return;
    if (phase != VersusPhase.running && phase != VersusPhase.paused) return;
    _elapsedMs[index] = speakerElapsedMs(index);
    _turnStart = nowProvider();
    _overtimeNotified = false;
    if (isLastSpeaker) {
      phase = VersusPhase.over;
      _turnStart = null;
      Haptics.success();
      _log(completed: true);
    } else {
      index++;
      // Moving on while paused keeps it paused.
      Haptics.confirm();
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ shared

  void pause() {
    if (phase != VersusPhase.running) return;
    check();
    if (phase != VersusPhase.running) return;
    if (kind == VersusKind.duel) {
      _leftMs[active!] = remainingMs(active!);
    } else {
      _elapsedMs[index] = speakerElapsedMs(index);
    }
    _turnStart = null;
    phase = VersusPhase.paused;
    Haptics.tap();
    notifyListeners();
  }

  void resume() {
    if (phase != VersusPhase.paused) return;
    _turnStart = nowProvider();
    phase = VersusPhase.running;
    Haptics.tap();
    notifyListeners();
  }

  void togglePause() => running ? pause() : resume();

  /// Called by the page's heartbeat: flag fall / overtime detection.
  void check() {
    if (phase != VersusPhase.running) return;
    if (kind == VersusKind.duel) {
      final side = active;
      if (side != null && remainingMs(side) <= 0) {
        _leftMs[side] = 0;
        flagged = side;
        phase = VersusPhase.over;
        _turnStart = null;
        Haptics.timerDone();
        SystemSound.play(SystemSoundType.alert);
        _log(completed: true);
        notifyListeners();
      }
    } else if (!_overtimeNotified && currentRemainingMs < 0) {
      _overtimeNotified = true;
      Haptics.warning();
      SystemSound.play(SystemSoundType.alert);
      notifyListeners();
    }
  }

  /// Back to the setup. A game that got somewhere is logged as unfinished.
  void reset() {
    if (phase == VersusPhase.setup) return;
    if (!_logged) {
      final started = kind == VersusKind.duel
          ? moves > 0 || duelUsedMs >= minLoggedSeconds * 1000
          : totalElapsedMs >= minLoggedSeconds * 1000;
      if (started) _log(completed: false);
    }
    phase = VersusPhase.setup;
    active = null;
    flagged = null;
    _turnStart = null;
    Haptics.warning();
    notifyListeners();
  }

  void _log({required bool completed}) {
    if (_logged) return;
    _logged = true;
    final duel = kind == VersusKind.duel;
    final seconds = ((duel ? duelUsedMs : totalElapsedMs) / 1000).round();
    ToolHistory.add(ToolEvent(
      kind: ToolKind.versus,
      at: _gameStart ?? nowProvider(),
      seconds: seconds,
      planned: duel ? baseSeconds * 2 : plannedSpeakerSeconds,
      completed: completed,
      label: duel ? duelLogLabel : 'Speakers',
    ));
  }

  /// Test hook: fresh install.
  void wipe() {
    kind = VersusKind.duel;
    baseSeconds = 180;
    incrementSeconds = 2;
    custom = false;
    speakers = _defaultSpeakers();
    _loaded = false;
    phase = VersusPhase.setup;
    active = null;
    flagged = null;
    moves = 0;
    _turnStart = null;
    _logged = false;
    notifyListeners();
  }
}
