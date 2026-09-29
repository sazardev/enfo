import 'package:shared_preferences/shared_preferences.dart';

import 'breathe_model.dart';

/// What the breathing mode remembers between sessions.
class BreatheSettings {
  BreatheSettings({
    this.pattern = BreathePattern.box,
    this.custom = BreathePattern.custom,
    this.minutes = 5,
  });

  /// The selected pattern (for `custom`, [custom] holds the timings).
  BreathePattern pattern;
  BreathePattern custom;

  /// Session length in minutes; 0 means endless.
  int minutes;

  static const lengths = [1, 2, 5, 10, 0];

  static const _patternKey = 'breathe_pattern';
  static const _customKey = 'breathe_custom';
  static const _minutesKey = 'breathe_minutes';

  /// The pattern to actually breathe.
  BreathePattern get active => pattern.id == 'custom' ? custom : pattern;

  int? get plannedSeconds => minutes <= 0 ? null : minutes * 60;

  static Future<BreatheSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getStringList(_customKey)?.map(int.tryParse).toList();
    var custom = BreathePattern.custom;
    if (c != null && c.length == 4 && !c.contains(null)) {
      custom = BreathePattern('custom', c[0]!.clamp(1, 12), c[1]!.clamp(0, 12),
          c[2]!.clamp(1, 12), c[3]!.clamp(0, 12));
    }
    final minutes = prefs.getInt(_minutesKey) ?? 5;
    return BreatheSettings(
      pattern: BreathePattern.byId(prefs.getString(_patternKey)),
      custom: custom,
      minutes: lengths.contains(minutes) ? minutes : 5,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patternKey, pattern.id);
    await prefs.setInt(_minutesKey, minutes);
    await prefs.setStringList(_customKey, [
      '${custom.inhale}',
      '${custom.holdFull}',
      '${custom.exhale}',
      '${custom.holdEmpty}',
    ]);
  }
}
