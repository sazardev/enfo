import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../history.dart';
import '../l10n/locale_controller.dart';
import '../ui/atoms/bouncy_tap.dart';
import '../ui/design/motion.dart';
import '../ui/design/radii.dart';
import '../ui/design/responsive.dart';
import '../ui/design/spacing.dart';
import '../ui/molecules/confirm_action_row.dart';
import '../ui/molecules/settings_row.dart';
import '../ui/templates/settings_shell.dart';
import 'app_mode.dart';
import 'format.dart';
import 'tool_history.dart';

enum _Filter { all, pomodoro, timer, stopwatch, alarm, display, more }

/// One row of the unified feed, whatever produced it.
class _Entry {
  const _Entry({
    required this.at,
    required this.filter,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.done,
    this.details = const [],
  });

  final DateTime at;
  final _Filter filter;
  final IconData icon;
  final String title;
  final String subtitle;

  /// Trailing check (true) / cross (false); null for no marker.
  final bool? done;

  /// Extra lines shown when the row is expanded (stopwatch laps).
  final List<String> details;
}

/// Everything Enfo has done, newest first: pomodoro sessions, timers,
/// stopwatch runs (with laps), alarms and time spent as a full-screen clock.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<PomodoroSession>? _sessions;
  List<ToolEvent>? _events;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await SessionHistory.load();
    final events = await ToolHistory.load();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _events = events;
    });
  }

  Future<void> _clearAll() async {
    await SessionHistory.clear();
    await ToolHistory.clear();
    await _load();
  }

  bool _today(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  List<_Entry> _entries() {
    final l10n = context.l10n;
    String clock(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
    final entries = <_Entry>[];

    for (final s in _sessions!) {
      entries.add(_Entry(
        at: s.startedAt,
        filter: _Filter.pomodoro,
        icon: AppMode.pomodoro.icon,
        title: '${s.isWork ? l10n.sessionFocus : l10n.sessionRest}'
            '  ·  ${clock(s.startedAt)}',
        subtitle: l10n.sessionProgress(
          formatDuration(s.focusedSeconds),
          formatDuration(s.plannedSeconds),
        ),
        done: s.completed,
      ));
    }

    for (final e in _events!) {
      final time = clock(e.at);
      switch (e.kind) {
        case ToolKind.timer:
          entries.add(_Entry(
            at: e.at,
            filter: _Filter.timer,
            icon: AppMode.timer.icon,
            title: '${e.label ?? l10n.modeTimer}  ·  $time',
            subtitle: e.planned == null
                ? formatDuration(e.seconds)
                : l10n.activityRan(
                    formatDuration(e.seconds),
                    formatDuration(e.planned!),
                  ),
            done: e.completed,
          ));
        case ToolKind.stopwatch:
          final best =
              e.laps.isEmpty ? null : e.laps.reduce((a, b) => a < b ? a : b);
          entries.add(_Entry(
            at: e.at,
            filter: _Filter.stopwatch,
            icon: AppMode.stopwatch.icon,
            title: '${e.label ?? l10n.modeStopwatch}  ·  $time',
            subtitle: [
              formatStopwatch(Duration(seconds: e.seconds)),
              if (e.laps.isNotEmpty) l10n.activityLaps(e.laps.length),
              if (best != null) formatStopwatch(Duration(milliseconds: best)),
            ].join('  ·  '),
            details: [
              for (var i = 0; i < e.laps.length; i++)
                '${l10n.activityLap(i + 1)}   '
                    '${formatStopwatch(Duration(milliseconds: e.laps[i]))}',
            ],
          ));
        case ToolKind.alarm:
          entries.add(_Entry(
            at: e.at,
            filter: _Filter.alarm,
            icon: AppMode.alarm.icon,
            title: '${e.label ?? l10n.modeAlarm}  ·  $time',
            subtitle: switch (e.outcome) {
              'snoozed' => l10n.activityAlarmSnoozed,
              'missed' => l10n.activityAlarmMissed,
              _ => l10n.activityAlarmDismissed,
            },
            done: e.outcome != 'missed',
          ));
        case ToolKind.intervals:
        case ToolKind.breathe:
        case ToolKind.tracker:
        case ToolKind.kitchen:
        case ToolKind.versus:
          final mode = AppMode.values.firstWhere((m) => m.name == e.kind.name);
          entries.add(_Entry(
            at: e.at,
            filter: _Filter.more,
            icon: mode.icon,
            title: '${e.label ?? mode.labelOf(l10n)}  ·  $time',
            subtitle: e.planned == null
                ? formatDuration(e.seconds)
                : l10n.activityRan(
                    formatDuration(e.seconds),
                    formatDuration(e.planned!),
                  ),
            done: e.completed,
          ));
        case ToolKind.display:
          final mode = AppMode.values.firstWhere(
            (m) => m.name == e.outcome,
            orElse: () => AppMode.clock,
          );
          entries.add(_Entry(
            at: e.at,
            filter: _Filter.display,
            icon: Icons.fullscreen_rounded,
            title: '${l10n.activityDisplay(mode.labelOf(l10n))}  ·  $time',
            subtitle: formatDuration(e.seconds),
          ));
      }
    }

    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final loaded = _sessions != null && _events != null;

    if (!loaded) {
      return SettingsShell(
        title: l10n.activityTitle,
        loaded: false,
        children: const [],
      );
    }

    final all = _entries();
    if (all.isEmpty) {
      return SettingsShell(
        title: l10n.activityTitle,
        loaded: true,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.huge),
            child: Text(
              l10n.activityEmpty,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    final shown = _filter == _Filter.all
        ? all
        : all.where((e) => e.filter == _filter).toList();

    // Today's headline numbers.
    int todaySeconds(ToolKind kind) => _events!
        .where((e) => e.kind == kind && _today(e.at))
        .fold(0, (sum, e) => sum + e.seconds);
    final pomodorosToday = _sessions!
        .where((s) => s.isWork && s.completed && _today(s.startedAt))
        .length;
    final timersToday =
        _events!.where((e) => e.kind == ToolKind.timer && _today(e.at)).length;

    final cards = [
      _Stat(value: '$pomodorosToday', label: l10n.statsTodayPomodoros),
      _Stat(value: '$timersToday', label: l10n.activityTimersToday),
      _Stat(
        value: formatDuration(todaySeconds(ToolKind.stopwatch)),
        label: l10n.activityStopwatchToday,
      ),
      _Stat(
        value: formatDuration(todaySeconds(ToolKind.display)),
        label: l10n.activityDisplayToday,
      ),
    ];

    final locale = Localizations.localeOf(context).toString();
    final rows = <Widget>[];
    DateTime? day;
    for (final e in shown) {
      final d = DateTime(e.at.year, e.at.month, e.at.day);
      if (d != day) {
        day = d;
        rows.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.xs,
            left: AppSpacing.lg,
          ),
          child: Text(
            DateFormat.yMMMEd(locale).format(d),
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ));
      }
      rows.add(_EntryTile(entry: e));
    }

    return SettingsShell(
      title: l10n.activityTitle,
      loaded: true,
      wide: true,
      children: [
        GridView.count(
          crossAxisCount: r.isWatch ? 1 : (r.isWide || r.isExpanded ? 4 : 2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: r.isWatch ? 2.6 : 1.9,
          children: cards,
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in _Filter.values)
              _FilterPill(
                label: switch (f) {
                  _Filter.all => l10n.activityFilterAll,
                  _Filter.pomodoro => l10n.modePomodoro,
                  _Filter.timer => l10n.modeTimer,
                  _Filter.stopwatch => l10n.modeStopwatch,
                  _Filter.alarm => l10n.modeAlarm,
                  _Filter.display => l10n.tooltipFullscreen,
                  _Filter.more => l10n.onbMoreTools,
                },
                selected: f == _filter,
                onTap: () => setState(() => _filter = f),
              ),
          ],
        ),
        ...rows,
        const SizedBox(height: AppSpacing.xl),
        ConfirmActionRow(
          icon: Icons.delete_outline_rounded,
          label: l10n.statsClearHistory,
          confirmLabel: l10n.dataConfirmClearHistory,
          hint: l10n.dataClearHistoryHint,
          onConfirmed: _clearAll,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A feed row; taps to expand when it has extra lines (stopwatch laps).
class _EntryTile extends StatefulWidget {
  const _EntryTile({required this.entry});

  final _Entry entry;

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          label: e.title,
          subtitle: e.subtitle,
          onTap:
              e.details.isEmpty ? null : () => setState(() => _open = !_open),
          trailing: e.done == null
              ? Icon(e.icon, color: colorScheme.onSurfaceVariant)
              : Icon(
                  e.done! ? Icons.check_circle_rounded : Icons.cancel_outlined,
                  size: 20,
                  color: e.done!
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in e.details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            line,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
