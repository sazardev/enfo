/// Short human duration: `45s`, `12m`, `1h 5m`.
String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String two(int n) => n.toString().padLeft(2, '0');

/// Stopwatch style: `03:07.42` (or `1:03:07.42` past an hour).
String formatStopwatch(Duration d) {
  final total = d.inMilliseconds;
  final h = total ~/ 3600000;
  final m = (total % 3600000) ~/ 60000;
  final s = (total % 60000) ~/ 1000;
  final cs = (total % 1000) ~/ 10;
  final head = h > 0 ? '$h:${two(m)}' : two(m);
  return '$head:${two(s)}.${two(cs)}';
}

/// Timer style: `05:00`, or `1:05:00` past an hour.
String formatCountdown(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
