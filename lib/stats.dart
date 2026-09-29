import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'history.dart';
import 'modes/activity_page.dart';
import 'ui/design/page_transition.dart';
import 'l10n/locale_controller.dart';
import 'ui/design/radii.dart';
import 'ui/design/responsive.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/confirm_action_row.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String _formatGap(Duration d) {
  if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
  return _formatDuration(d.inSeconds);
}

String _two(int n) => n.toString().padLeft(2, '0');

class Stats extends StatefulWidget {
  const Stats({super.key});

  @override
  State<Stats> createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  SessionStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await SessionHistory.load();
    if (!mounted) return;
    setState(() => _stats = SessionStats(sessions));
  }

  Future<void> _clear() async {
    await SessionHistory.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: context.l10n.statsTitle,
      loaded: stats != null,
      wide: true,
      children: stats == null
          ? const []
          : stats.sessions.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.huge),
                    child: Text(
                      context.l10n.statsEmpty,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ]
              : _content(stats, textTheme, colorScheme),
    );
  }

  List<Widget> _content(
    SessionStats stats,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final rate = stats.completionRate;
    final averageGap = stats.averageGap;
    final longestGap = stats.longestGap;
    final sinceLast = stats.sinceLastSession;

    // Newest first, grouped by day.
    final indexes = List.generate(stats.sessions.length, (i) => i).reversed;
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final i in indexes) {
      final s = stats.sessions[i];
      final day =
          DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      if (day != currentDay) {
        currentDay = day;
        rows.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.xs,
            left: AppSpacing.lg,
          ),
          child: Text(
            DateFormat.yMMMEd(locale).format(day),
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ));
      }
      rows.add(_SessionTile(session: s, gap: stats.gapBefore(i)));
    }

    final r = Responsive.of(context);

    final cards = <Widget>[
      Row(
        children: [
          Expanded(
            child: _StatCard(
              value: '${stats.todayPomodoros}',
              label: l10n.statsTodayPomodoros,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              value: _formatDuration(stats.todayFocusSeconds),
              label: l10n.statsTodayFocus,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              value: '${stats.completedPomodoros}',
              label: l10n.statsCompleted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              value: '${stats.currentStreakDays}',
              label: l10n.statsStreak(stats.currentStreakDays),
            ),
          ),
        ],
      ),
    ];

    final chart = _WeekChart(days: stats.lastDays(7));

    final metrics = <Widget>[
      _MetricRow(
        label: l10n.statsTotalFocus,
        value: _formatDuration(stats.totalFocusSeconds),
      ),
      _MetricRow(
        label: l10n.statsTotalRest,
        value: _formatDuration(stats.totalRestSeconds),
      ),
      _MetricRow(
        label: l10n.statsAbandoned,
        value: rate == null
            ? '${stats.abandonedPomodoros}'
            : l10n.statsAbandonedValue(
                stats.abandonedPomodoros,
                (rate * 100).round(),
              ),
      ),
      _MetricRow(
        label: l10n.statsAverageFocus,
        value: _formatDuration(stats.averageFocusSeconds),
      ),
      _MetricRow(
        label: l10n.statsLongestSession,
        value: _formatDuration(stats.longestFocusSeconds),
      ),
      _MetricRow(
        label: l10n.statsPauses,
        value:
            '${stats.totalPauses}  ·  ${_formatDuration(stats.totalPausedSeconds)}',
      ),
      if (averageGap != null)
        _MetricRow(
          label: l10n.statsAverageGap,
          value: _formatGap(averageGap),
        ),
      if (longestGap != null)
        _MetricRow(
          label: l10n.statsLongestGap,
          value: _formatGap(longestGap),
        ),
      if (sinceLast != null)
        _MetricRow(
          label: l10n.statsSinceLast,
          value: _formatGap(sinceLast),
        ),
    ];

    final history = <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Text(l10n.statsHistory, style: textTheme.titleMedium),
      ),
      ...rows,
      const SizedBox(height: AppSpacing.xl),
      SettingsRow(
        label: l10n.modesActivity,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context)
            .push(appPageRoute((_) => const ActivityPage())),
      ),
      const SizedBox(height: AppSpacing.md),
      ConfirmActionRow(
        icon: Icons.delete_outline_rounded,
        label: l10n.statsClearHistory,
        confirmLabel: l10n.statsClearConfirm,
        hint: l10n.statsClearHint,
        onConfirmed: _clear,
      ),
    ];

    // Watch: just today's headline numbers, stacked.
    if (r.isWatch) {
      return [
        _StatCard(
          value: '${stats.todayPomodoros}',
          label: l10n.statsTodayPomodoros,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatCard(
          value: _formatDuration(stats.todayFocusSeconds),
          label: l10n.statsTodayFocus,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatCard(
          value: '${stats.currentStreakDays}',
          label: l10n.statsStreak(stats.currentStreakDays),
        ),
      ];
    }

    // Large screens: summary + metrics on the left, history on the right.
    if (r.isExpanded) {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...cards,
                  const SizedBox(height: AppSpacing.xl),
                  chart,
                  const SizedBox(height: AppSpacing.md),
                  ...metrics,
                ],
              ),
            ),
            SizedBox(width: r.pagePadding * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: history,
              ),
            ),
          ],
        ),
      ];
    }

    return [
      ...cards,
      const SizedBox(height: AppSpacing.xl),
      chart,
      const SizedBox(height: AppSpacing.md),
      ...metrics,
      const SizedBox(height: AppSpacing.md),
      ...history,
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style:
                textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: label,
      trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<({DateTime day, int count})> days;

  static const double _maxBarHeight = 80;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = days.fold(1, (m, d) => d.count > m ? d.count : m);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.statsLast7Days, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${d.count}', style: textTheme.labelSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        height: d.count == 0
                            ? 4
                            : 8 + (_maxBarHeight - 8) * d.count / maxCount,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: d.count == 0
                              ? colorScheme.primary.withValues(alpha: 0.14)
                              : colorScheme.primary,
                          borderRadius: AppRadii.smRadius,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        DateFormat.E(Localizations.localeOf(context).toString())
                            .format(d.day),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.gap});

  final PomodoroSession session;
  final Duration? gap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final s = session;

    final details = <String>[
      l10n.sessionProgress(
        _formatDuration(s.focusedSeconds),
        _formatDuration(s.plannedSeconds),
      ),
      if (s.pauseCount > 0)
        l10n.sessionPauses(s.pauseCount, _formatDuration(s.pausedSeconds)),
      if (gap != null) l10n.sessionIdleBefore(_formatGap(gap!)),
    ];

    return SettingsRow(
      label: '${s.isWork ? l10n.sessionFocus : l10n.sessionRest}'
          '  ·  ${_two(s.startedAt.hour)}:${_two(s.startedAt.minute)}',
      subtitle: details.join('  ·  '),
      trailing: Icon(
        s.completed ? Icons.check_circle_rounded : Icons.cancel_outlined,
        size: 20,
        color: s.completed ? colorScheme.primary : colorScheme.onSurfaceVariant,
        semanticLabel:
            s.completed ? l10n.sessionCompleted : l10n.sessionAbandoned,
      ),
    );
  }
}
