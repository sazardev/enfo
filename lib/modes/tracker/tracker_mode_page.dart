import 'dart:async';

import 'package:flutter/material.dart';

import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../../theme.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/motion.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/confirm_action_row.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import 'tracker_service.dart';
import 'tracker_stats.dart';

/// Time tracker: tap an activity to time it (one at a time), see today's
/// total on every card and a 7-day chart for the selected one.
class TrackerModePage extends StatefulWidget {
  const TrackerModePage({super.key});

  @override
  State<TrackerModePage> createState() => _TrackerModePageState();
}

class _TrackerModePageState extends State<TrackerModePage> {
  final TrackerService _tracker = TrackerService.instance;
  final TextEditingController _name = TextEditingController();
  Timer? _beat;
  String? _selectedId;
  bool _editing = false;
  int _addMinutes = 15;

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_onChanged);
    _tracker.reloadEvents();
    _selectedId = _tracker.runningId ??
        _tracker.byId(_tracker.lastId)?.id ??
        (_tracker.activities.isEmpty ? null : _tracker.activities.first.id);
    _syncBeat();
  }

  void _onChanged() {
    if (_tracker.byId(_selectedId) == null) {
      _selectedId =
          _tracker.activities.isEmpty ? null : _tracker.activities.first.id;
      _editing = false;
    }
    _syncBeat();
    if (mounted) setState(() {});
  }

  void _syncBeat() {
    if (_tracker.running) {
      _beat ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _beat?.cancel();
      _beat = null;
    }
  }

  @override
  void dispose() {
    _tracker.removeListener(_onChanged);
    _beat?.cancel();
    _name.dispose();
    super.dispose();
  }

  TrackerActivity? get _selected => _tracker.byId(_selectedId);

  void _select(String id, {bool edit = false}) {
    setState(() {
      _selectedId = id;
      _editing = edit;
      _name.text = _tracker.byId(id)?.displayName ?? '';
    });
  }

  void _toggle(TrackerActivity a) {
    if (_tracker.runningId == a.id) {
      Haptics.tap();
      _tracker.stop();
    } else {
      Haptics.confirm();
      _tracker.start(a.id);
    }
    setState(() => _selectedId = a.id);
  }

  Future<void> _create() async {
    Haptics.select();
    final a = await _tracker.create(Themes
        .colors[_tracker.activities.length % Themes.colors.length]
        .toARGB32());
    if (mounted) _select(a.id, edit: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);

    return ModeKeyBindings(
      mode: AppMode.tracker,
      actions: ModeKeyActions(
        primary: _tracker.toggleLast,
        reset: _tracker.stop,
      ),
      child: ModeScaffold(
        primaryAction: PrimaryActionButton(
          running: _tracker.running,
          label: _tracker.running ? l10n.trackerStop : l10n.timerStart,
          onPressed: _tracker.toggleLast,
        ),
        body: LayoutBuilder(builder: (context, c) {
          final left = _Left(
            tracker: _tracker,
            selectedId: _selectedId,
            onToggle: _toggle,
            onInfo: (a) => _select(a.id),
            onCreate: _create,
            compact: r.isWatch,
          );
          if (r.isWatch) {
            return SingleChildScrollView(child: left);
          }
          final detail = _selected == null
              ? const SizedBox.shrink()
              : _Detail(
                  tracker: _tracker,
                  activity: _selected!,
                  editing: _editing,
                  name: _name,
                  addMinutes: _addMinutes,
                  onAddMinutes: (m) => setState(() => _addMinutes = m),
                  onToggleEdit: () => _select(_selected!.id, edit: !_editing),
                );
          if (r.isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: left)),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(child: SingleChildScrollView(child: detail)),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(children: [
              left,
              const SizedBox(height: AppSpacing.xl),
              detail,
              const SizedBox(height: AppSpacing.lg),
            ]),
          );
        }),
      ),
    );
  }
}

// ------------------------------------------------------------------ left

class _Left extends StatelessWidget {
  const _Left({
    required this.tracker,
    required this.selectedId,
    required this.onToggle,
    required this.onInfo,
    required this.onCreate,
    required this.compact,
  });

  final TrackerService tracker;
  final String? selectedId;
  final ValueChanged<TrackerActivity> onToggle;
  final ValueChanged<TrackerActivity> onInfo;
  final VoidCallback onCreate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final today = nowProvider();
    final gap = compact ? AppSpacing.xs : AppSpacing.sm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Readout(tracker: tracker, compact: compact),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.xl),
        for (final a in tracker.activities)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: _ActivityCard(
              activity: a,
              running: tracker.runningId == a.id,
              selected: selectedId == a.id,
              todaySeconds:
                  totalOnDay(tracker.events, today, label: a.displayName) +
                      (tracker.runningId == a.id ? tracker.elapsedSeconds : 0),
              compact: compact,
              onTap: () => onToggle(a),
              onInfo: () => onInfo(a),
            ),
          ),
        BouncyTap(
          onTap: onCreate,
          focusBorderRadius: AppRadii.mdRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: scheme.primary),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(l10n.trackerAddActivity,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.tracker, required this.compact});

  final TrackerService tracker;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final a = tracker.runningActivity;
    final color = a == null ? scheme.onSurfaceVariant : Color(a.color);
    final seconds = a == null ? 0 : tracker.elapsedSeconds;
    final big = (textTheme.displayLarge?.fontSize ?? 57) * (compact ? 0.7 : 1);

    return Column(
      children: [
        Text(
          a?.displayName ?? l10n.trackerNoRunning,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatClock(seconds),
            style: textTheme.displayLarge?.copyWith(
              fontSize: big,
              fontWeight: FontWeight.w600,
              color:
                  a == null ? scheme.onSurface.withValues(alpha: 0.4) : color,
              height: 1.1,
            ),
          ),
        ),
        if (a == null && !compact) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.trackerTapToStart,
            textAlign: TextAlign.center,
            style:
                textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// `1:05:09` or `05:09`: like [formatCountdown] but always with hours once
/// an activity has run for one.
String formatClock(int seconds) => formatCountdown(seconds);

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.running,
    required this.selected,
    required this.todaySeconds,
    required this.compact,
    required this.onTap,
    required this.onInfo,
  });

  final TrackerActivity activity;
  final bool running;
  final bool selected;
  final int todaySeconds;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(activity.color);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    final fg = running ? onColor : scheme.onSurface;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(running ? AppRadii.lg : AppRadii.sm);

    return AnimatedContainer(
      duration: reduce ? Duration.zero : Motion.medium,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: running
            ? color
            : (selected
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainerHigh),
        borderRadius: radius,
      ),
      child: Row(
        children: [
          Expanded(
            child: BouncyTap(
              onTap: onTap,
              pressedScale: 0.97,
              focusBorderRadius: radius,
              child: Padding(
                padding:
                    EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
                child: Row(
                  children: [
                    Icon(activity.iconData, color: running ? onColor : color),
                    SizedBox(width: compact ? AppSpacing.xs : AppSpacing.md),
                    Expanded(
                      child: Text(
                        activity.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: fg, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      formatDuration(todaySeconds),
                      style: TextStyle(
                          color: fg.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!compact)
            AppIconButton(
              size: 40,
              tooltip: context.l10n.trackerDetails,
              onPressed: onInfo,
              icon: Icon(Icons.bar_chart_rounded,
                  color: fg.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- detail

class _Detail extends StatelessWidget {
  const _Detail({
    required this.tracker,
    required this.activity,
    required this.editing,
    required this.name,
    required this.addMinutes,
    required this.onAddMinutes,
    required this.onToggleEdit,
  });

  final TrackerService tracker;
  final TrackerActivity activity;
  final bool editing;
  final TextEditingController name;
  final int addMinutes;
  final ValueChanged<int> onAddMinutes;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = nowProvider();
    final live = tracker.runningId == activity.id ? tracker.elapsedSeconds : 0;
    final days =
        dailyTotals(tracker.events, label: activity.displayName, today: now);
    days[days.length - 1] += live;
    final week = days.fold<int>(0, (a, b) => a + b);
    final color = Color(activity.color);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadii.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(activity.iconData, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(activity.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium),
              ),
              AppIconButton(
                size: 40,
                selected: editing,
                tooltip: l10n.trackerEdit,
                onPressed: onToggleEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(
                child: _Total(label: l10n.trackerToday, seconds: days.last)),
            Expanded(child: _Total(label: l10n.trackerWeek, seconds: week)),
          ]),
          const SizedBox(height: AppSpacing.lg),
          WeekBars(days: days, color: color, today: now),
          const SizedBox(height: AppSpacing.lg),
          _AddTime(
            minutes: addMinutes,
            onChanged: onAddMinutes,
            onAdd: () {
              Haptics.confirm();
              tracker.addManual(activity.id, addMinutes);
            },
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Motion.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: editing
                ? _Editor(tracker: tracker, activity: activity, name: name)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.seconds});
  final String label;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
        Text(formatDuration(seconds),
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Flat 7-day bar chart; the last bar is today.
class WeekBars extends StatelessWidget {
  const WeekBars({
    super.key,
    required this.days,
    required this.color,
    required this.today,
  });

  final List<int> days;
  final Color color;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = MaterialLocalizations.of(context).narrowWeekdays;
    final peak = days.fold<int>(1, (a, b) => b > a ? b : a);

    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: days[i] == 0 ? 0.04 : days[i] / peak,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: days[i] == 0
                                  ? scheme.surfaceContainerHighest
                                  : color.withValues(
                                      alpha: i == days.length - 1 ? 1 : 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[today
                                  .subtract(Duration(days: days.length - 1 - i))
                                  .weekday %
                              7]
                          .toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: i == days.length - 1
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTime extends StatelessWidget {
  const _AddTime({
    required this.minutes,
    required this.onChanged,
    required this.onAdd,
  });

  final int minutes;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Row(
        children: [
          AppIconButton(
            size: 40,
            tooltip: l10n.trackerMinutesFewer,
            onPressed: minutes > 5
                ? () {
                    Haptics.tick();
                    onChanged(minutes - 5);
                  }
                : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Text(
              '$minutes ${l10n.timerMinutesShort}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          AppIconButton(
            size: 40,
            tooltip: l10n.trackerMinutesMore,
            onPressed: minutes < 600
                ? () {
                    Haptics.tick();
                    onChanged(minutes + 5);
                  }
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
          AppIconButton(
            size: 40,
            tooltip: l10n.trackerAddMinutes(minutes),
            onPressed: onAdd,
            icon: Icon(Icons.playlist_add_rounded, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.tracker,
    required this.activity,
    required this.name,
  });

  final TrackerService tracker;
  final TrackerActivity activity;
  final TextEditingController name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: name,
          maxLength: 30,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) {
            final t = v.trim();
            if (t.isNotEmpty) tracker.update(activity.copyWith(name: t));
          },
          decoration: InputDecoration(
            labelText: l10n.trackerNameHint,
            counterText: '',
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: const OutlineInputBorder(
              borderRadius: AppRadii.mdRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.trackerColor,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in Themes.colors.take(24))
              BouncyTap(
                onTap: () {
                  Haptics.select();
                  tracker.update(activity.copyWith(color: c.toARGB32()));
                },
                focusBorderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : Motion.fast,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    // Selection morphs the circle into a squircle.
                    borderRadius: BorderRadius.circular(
                        activity.color == c.toARGB32() ? 10 : 16),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.trackerIcon,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < trackerIcons.length; i++)
              AppIconButton(
                size: 40,
                selected: activity.icon == i,
                onPressed: () => tracker.update(activity.copyWith(icon: i)),
                icon: Icon(trackerIcons[i]),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ConfirmActionRow(
          icon: Icons.delete_outline_rounded,
          label: l10n.trackerDelete,
          confirmLabel: l10n.trackerDeleteConfirm,
          hint: l10n.trackerDeleteHint,
          onConfirmed: () => tracker.delete(activity.id),
        ),
      ],
    );
  }
}
