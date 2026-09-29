/// One alarm: a time of day, the weekdays it repeats on (none = once) and
/// an optional label.
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.days = const {},
    this.label = '',
    this.enabled = true,
    this.lastHandledMs = 0,
    this.snoozedUntilMs,
  });

  final int id;
  final int hour;
  final int minute;

  /// `DateTime.weekday` values, 1 = Monday .. 7 = Sunday. Empty = once.
  final Set<int> days;
  final String label;
  final bool enabled;

  /// The last occurrence that rang (or was missed), so it never rings twice.
  final int lastHandledMs;

  /// If snoozed: when it rings again.
  final int? snoozedUntilMs;

  bool get repeats => days.isNotEmpty;

  Alarm copyWith({
    int? hour,
    int? minute,
    Set<int>? days,
    String? label,
    bool? enabled,
    int? lastHandledMs,
    Object? snoozedUntilMs = _keep,
  }) {
    return Alarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      lastHandledMs: lastHandledMs ?? this.lastHandledMs,
      snoozedUntilMs: identical(snoozedUntilMs, _keep)
          ? this.snoozedUntilMs
          : snoozedUntilMs as int?,
    );
  }

  static const Object _keep = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'h': hour,
        'm': minute,
        'd': days.toList()..sort(),
        'l': label,
        'e': enabled,
        'lh': lastHandledMs,
        if (snoozedUntilMs != null) 'sn': snoozedUntilMs,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as int,
        hour: json['h'] as int,
        minute: json['m'] as int,
        days: (json['d'] as List<dynamic>).cast<int>().toSet(),
        label: json['l'] as String? ?? '',
        enabled: json['e'] as bool? ?? true,
        lastHandledMs: json['lh'] as int? ?? 0,
        snoozedUntilMs: json['sn'] as int?,
      );
}
