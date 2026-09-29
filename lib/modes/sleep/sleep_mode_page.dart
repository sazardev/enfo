import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_preferences.dart';
import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_switch.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/settings_row.dart';
import '../alarm/alarm.dart';
import '../alarm/alarm_service.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_scaffold.dart';
import '../timer/duration_wheels.dart';
import 'sleep_logic.dart';

/// Sleep-cycle planner: pick when you want to wake (or when you go to bed)
/// and get times that end on a 90-minute cycle. One tap turns a suggestion
/// into a real alarm, with an optional wind-down reminder before bedtime.
class SleepModePage extends StatefulWidget {
  const SleepModePage({super.key});

  @override
  State<SleepModePage> createState() => _SleepModePageState();
}

class _SleepModePageState extends State<SleepModePage> {
  static const _kPlan = 'sleep_plan';
  static const _kWake = 'sleep_wake';
  static const _kBed = 'sleep_bed';
  static const _kWind = 'sleep_wind';
  static const _kAlarmId = 'sleep_alarm_id';
  static const _kWindId = 'sleep_wind_id';

  bool _loaded = false;
  SleepPlan _plan = SleepPlan.wakeAt;
  int _wakeH = 7, _wakeM = 0;
  int _bedH = 23, _bedM = 0;
  bool _wind = false;
  int _cycles = 5;
  int? _alarmId;
  int? _windId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final wake = prefs.getInt(_kWake) ?? 7 * 60;
    final bed = prefs.getInt(_kBed) ?? 23 * 60;
    setState(() {
      _plan = SleepPlan.values.firstWhere(
        (p) => p.name == prefs.getString(_kPlan),
        orElse: () => SleepPlan.wakeAt,
      );
      _wakeH = (wake ~/ 60) % 24;
      _wakeM = wake % 60;
      _bedH = (bed ~/ 60) % 24;
      _bedM = bed % 60;
      _wind = prefs.getBool(_kWind) ?? false;
      _alarmId = prefs.getInt(_kAlarmId);
      _windId = prefs.getInt(_kWindId);
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlan, _plan.name);
    await prefs.setInt(_kWake, _wakeH * 60 + _wakeM);
    await prefs.setInt(_kBed, _bedH * 60 + _bedM);
    await prefs.setBool(_kWind, _wind);
    if (_alarmId != null) await prefs.setInt(_kAlarmId, _alarmId!);
    if (_windId != null) await prefs.setInt(_kWindId, _windId!);
  }

  void _update(VoidCallback change) {
    setState(change);
    _save();
  }

  Alarm? _alarmById(int? id) {
    if (id == null) return null;
    for (final a in AlarmService.alarms.value) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Creates the alarm, or moves the one this page made earlier.
  Future<int> _put(int? id, DateTime at, String label) async {
    final existing = _alarmById(id);
    final alarm = existing == null
        ? AlarmService.create(hour: at.hour, minute: at.minute, label: label)
        : existing.copyWith(
            hour: at.hour,
            minute: at.minute,
            label: label,
            days: const {},
            enabled: true,
          );
    await AlarmService.upsert(alarm.copyWith(enabled: true));
    return alarm.id;
  }

  Future<void> _setAlarm(SleepPlanResult result, SleepOption option) async {
    final l10n = context.l10n;
    final now = nowProvider();
    final wake = result.wakeOf(option);
    final alarmId = await _put(_alarmId, wake, l10n.sleepAlarmLabel);
    int? windId = _windId;
    final windAt = windDownFor(result.bedtimeOf(option));
    if (_wind && windAt.isAfter(now)) {
      windId = await _put(windId, windAt, l10n.sleepWindDownLabel);
    } else {
      final old = _alarmById(windId);
      if (old != null) await AlarmService.remove(old);
    }
    Haptics.success();
    if (!mounted) return;
    setState(() {
      _alarmId = alarmId;
      _windId = windId;
    });
    _save();
  }

  Future<void> _removeAlarm() async {
    for (final id in [_alarmId, _windId]) {
      final a = _alarmById(id);
      if (a != null) await AlarmService.remove(a);
    }
    Haptics.warning();
    if (mounted) setState(() {});
  }

  /// The alarm this page made for exactly [wake], if it is still armed.
  Alarm? _armedFor(DateTime wake) {
    final a = _alarmById(_alarmId);
    if (a == null || !a.enabled) return null;
    return a.hour == wake.hour && a.minute == wake.minute ? a : null;
  }

  @override
  Widget build(BuildContext context) {
    return ModeScaffold(
      body: !_loaded
          ? const SizedBox.shrink()
          : ListenableBuilder(
              listenable: Listenable.merge([
                AlarmService.alarms,
                AppPreferences.clockFormat,
              ]),
              builder: (context, _) => TimeBuilder(
                builder: (context, now) => _planner(context, now),
              ),
            ),
    );
  }

  Widget _planner(BuildContext context, DateTime now) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = r.isWatch;

    final result = planFor(
      plan: _plan,
      now: now,
      wakeHour: _wakeH,
      wakeMinute: _wakeM,
      bedHour: _bedH,
      bedMinute: _bedM,
    );
    final options = result.options;
    final chosen = options.firstWhere(
      (o) => o.cycles == _cycles,
      orElse: () => options.firstWhere((o) => o.recommended),
    );
    final wake = result.wakeOf(chosen);
    final armed = _armedFor(wake);
    final bed = result.bedtimeOf(chosen);
    final windAt = windDownFor(bed);
    final windPossible = windAt.isAfter(now);
    final asBedtimes = _plan == SleepPlan.wakeAt;

    Widget gap(double h) => SizedBox(height: h);

    final titles = switch (_plan) {
      SleepPlan.wakeAt => l10n.sleepTitleWake,
      SleepPlan.sleepAt => l10n.sleepTitleBed,
      SleepPlan.sleepNow => l10n.sleepTitleNow(_fmt(context, now)),
    };

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 200 : 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final p in SleepPlan.values)
                    _PlanChip(
                      label: switch (p) {
                        SleepPlan.wakeAt => l10n.sleepPlanWake,
                        SleepPlan.sleepAt => l10n.sleepPlanBed,
                        SleepPlan.sleepNow => l10n.sleepPlanNow,
                      },
                      selected: p == _plan,
                      compact: compact,
                      onTap: () {
                        Haptics.select();
                        _update(() => _plan = p);
                      },
                    ),
                ],
              ),
              gap(compact ? AppSpacing.sm : AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Text(
                  titles,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              if (_plan != SleepPlan.sleepNow) ...[
                gap(AppSpacing.sm),
                _TimeWheels(
                  key: ValueKey(_plan),
                  hour: asBedtimes ? _wakeH : _bedH,
                  minute: asBedtimes ? _wakeM : _bedM,
                  extent: compact ? 28 : 52,
                  onChanged: (h, m) => _update(() {
                    if (asBedtimes) {
                      _wakeH = h;
                      _wakeM = m;
                    } else {
                      _bedH = h;
                      _bedM = m;
                    }
                  }),
                ),
              ],
              gap(compact ? AppSpacing.sm : AppSpacing.lg),
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _OptionCard(
                    option: o,
                    time: _fmt(context, o.time),
                    caption:
                        asBedtimes ? l10n.sleepBedtimeWord : l10n.sleepWakeWord,
                    selected: identical(o, chosen),
                    past: asBedtimes && !o.time.isAfter(now),
                    compact: compact,
                    onTap: () {
                      Haptics.select();
                      setState(() => _cycles = o.cycles);
                    },
                  ),
                ),
              if (!compact)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.md,
                  ),
                  child: Text(
                    l10n.sleepNote,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              if (!compact)
                SettingsRow(
                  label: l10n.sleepWindDown,
                  subtitle: windPossible || !_wind
                      ? l10n.sleepWindDownHint
                      : l10n.sleepWindDownPassed,
                  trailing: AppSwitch(
                    value: _wind,
                    onChanged: (v) => _update(() => _wind = v),
                  ),
                  onTap: () {
                    Haptics.toggle(!_wind);
                    _update(() => _wind = !_wind);
                  },
                ),
              gap(AppSpacing.md),
              if (armed == null)
                FilledButton.icon(
                  autofocus: true,
                  onPressed: () => _setAlarm(result, chosen),
                  icon: const Icon(Icons.alarm_add_rounded),
                  label: Text(l10n.sleepSetAlarm),
                )
              else
                FilledButton.tonalIcon(
                  autofocus: true,
                  onPressed: _removeAlarm,
                  icon: const Icon(Icons.alarm_off_rounded),
                  label: Text(l10n.sleepRemoveAlarm),
                ),
              if (armed != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.sleepAlarmSet(_fmt(context, wake)),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ),
              gap(AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(BuildContext context, DateTime t) {
    final use24h = switch (AppPreferences.clockFormat.value) {
      ClockFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
      ClockFormat.h12 => false,
      ClockFormat.h24 => true,
    };
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: t.hour, minute: t.minute),
      alwaysUse24HourFormat: use24h,
    );
  }
}

class _TimeWheels extends StatefulWidget {
  const _TimeWheels({
    super.key,
    required this.hour,
    required this.minute,
    required this.extent,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final double extent;
  final void Function(int hour, int minute) onChanged;

  @override
  State<_TimeWheels> createState() => _TimeWheelsState();
}

class _TimeWheelsState extends State<_TimeWheels> {
  late final FixedExtentScrollController _h =
      FixedExtentScrollController(initialItem: widget.hour);
  late final FixedExtentScrollController _m =
      FixedExtentScrollController(initialItem: widget.minute);

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_h.selectedItem % 24, _m.selectedItem % 60);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final e = widget.extent;
    return SizedBox(
      height: e * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: e,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: LoopWheel(
                  controller: _h,
                  count: 24,
                  unit: l10n.timerHoursShort,
                  extent: e,
                  onChanged: _emit,
                ),
              ),
              Expanded(
                child: LoopWheel(
                  controller: _m,
                  count: 60,
                  unit: l10n.timerMinutesShort,
                  extent: e,
                  onChanged: _emit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(24),
      child: Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : null,
              fontWeight: FontWeight.w600,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.time,
    required this.caption,
    required this.selected,
    required this.past,
    required this.compact,
    required this.onTap,
  });

  final SleepOption option;
  final String time;
  final String caption;
  final bool selected;
  final bool past;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final fg = selected
        ? colorScheme.onPrimaryContainer
        : (past ? colorScheme.onSurfaceVariant : colorScheme.onSurface);
    final total = formatDuration(option.sleep.inMinutes * 60);

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.98,
      focusBorderRadius: BorderRadius.circular(selected ? 28 : 20),
      child: Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            // Selection morphs the card's corners.
            borderRadius: BorderRadius.circular(selected ? 28 : 20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        time,
                        style: (compact
                                ? textTheme.titleLarge
                                : textTheme.headlineMedium)
                            ?.copyWith(fontWeight: FontWeight.w700, color: fg),
                      ),
                    ),
                    Text(
                      compact
                          ? '${option.cycles} · $total'
                          : '$caption  ·  ${l10n.sleepCyclesLine(option.cycles, total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (past && !compact)
                      Text(
                        l10n.sleepPast,
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.error),
                      ),
                  ],
                ),
              ),
              if (option.recommended && !compact)
                Icon(
                  Icons.thumb_up_alt_rounded,
                  size: 20,
                  semanticLabel: l10n.sleepRecommended,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
