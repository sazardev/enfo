import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app_preferences.dart';
import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/spacing.dart';
import '../../ui/templates/settings_shell.dart';
import '../clock/time_builder.dart';
import 'cities.dart';
import 'meeting_planner.dart';
import 'time_format.dart';
import 'world_prefs.dart';

/// Time-zone planner: every city as a 24 h strip (working hours tinted,
/// night dimmed), a selectable instant over the next 24 hours, and the
/// windows in which everyone is at work.
class MeetingPlannerPage extends StatefulWidget {
  const MeetingPlannerPage({super.key});

  @override
  State<MeetingPlannerPage> createState() => _MeetingPlannerPageState();
}

class _Row {
  const _Row(this.id, this.name, this.zone);
  final String id;
  final String name;
  final PlanZone zone;
}

const _localId = '_local';

class _MeetingPlannerPageState extends State<MeetingPlannerPage> {
  late DateTime _origin = floorToQuarter(nowProvider().toUtc());
  int _step = 0;
  String _ref = _localId;

  DateTime get _selected => _origin.add(planStep * _step);

  void _setStep(int v) {
    final next = v.clamp(0, planSteps);
    if (next == _step) return;
    Haptics.tick();
    setState(() => _step = next);
  }

  void _now() {
    Haptics.tap();
    setState(() {
      _origin = floorToQuarter(nowProvider().toUtc());
      _step = 0;
    });
  }

  List<_Row> _rows(BuildContext context) {
    final l10n = context.l10n;
    return [
      _Row(
        _localId,
        l10n.worldLocal,
        PlanZone(
            _localId,
            (utc) =>
                DateTime.fromMillisecondsSinceEpoch(utc.millisecondsSinceEpoch)
                    .timeZoneOffset),
      ),
      for (final id in WorldPrefs.cities.value)
        if (cityById(id) case final city?)
          _Row(
            id,
            cityName(city),
            PlanZone(id, (utc) {
              final loc = tz.getLocation(city.zone);
              return tz.TZDateTime.fromMillisecondsSinceEpoch(
                      loc, utc.millisecondsSinceEpoch)
                  .timeZoneOffset;
            }),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable:
          Listenable.merge([WorldPrefs.cities, AppPreferences.clockFormat]),
      builder: (context, _) {
        final rows = _rows(context);
        final ref =
            rows.firstWhere((r) => r.id == _ref, orElse: () => rows.first);
        final zones = [for (final r in rows) r.zone];
        final plan = planMeeting(zones, _origin);
        final selected = _selected;
        final refWall = ref.zone.wall(selected);

        // Quarter hours in which everybody is at work.
        final everyone = List<bool>.generate(planSteps, (i) {
          final t = _origin.add(planStep * i);
          return zones.every((z) => z.working(t));
        });

        String hm(DateTime wall) =>
            formatHourMinute(context, wall.hour, wall.minute);
        String range(OverlapWindow w) =>
            '${hm(ref.zone.wall(w.start))} - ${hm(ref.zone.wall(w.end))}';

        Widget card({required Widget child}) => Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: AppRadii.mdRadius,
              ),
              child: child,
            );

        return SettingsShell(
          title: l10n.worldPlan,
          loaded: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.sm, bottom: AppSpacing.md),
              child: Text(
                l10n.worldPlanIntro,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            // The selected instant, in the reference city's time.
            card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.worldPlanSelected(ref.name),
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    hm(refWall),
                    key: const ValueKey('plan-selected-time'),
                    style: textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      AppIconButton(
                        size: 40,
                        tooltip: l10n.worldPlanEarlier,
                        onPressed: _step > 0 ? () => _setStep(_step - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Slider(
                          value: _step.toDouble(),
                          min: 0,
                          max: planSteps.toDouble(),
                          divisions: planSteps,
                          semanticFormatterCallback: (_) => hm(refWall),
                          onChanged: (v) => _setStep(v.round()),
                        ),
                      ),
                      AppIconButton(
                        size: 40,
                        tooltip: l10n.worldPlanLater,
                        onPressed: _step < planSteps
                            ? () => _setStep(_step + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _now,
                      icon: const Icon(Icons.update_rounded),
                      label: Text(l10n.worldPlanNow),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Overlap.
            card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        plan.hasOverlap
                            ? Icons.event_available_rounded
                            : Icons.event_busy_rounded,
                        color: plan.hasOverlap
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          plan.hasOverlap
                              ? l10n.worldPlanOverlapTitle
                              : l10n.worldPlanNoOverlap,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (plan.hasOverlap)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final w in plan.windows.take(3))
                          _Chip(
                            label: range(w),
                            selected: !selected.isBefore(w.start) &&
                                selected.isBefore(w.end),
                            onTap: () => _setStep(
                                w.start.difference(_origin).inMinutes ~/ 15),
                          ),
                      ],
                    )
                  else if (plan.leastBad != null)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Chip(
                          label: l10n.worldPlanLeastBad(
                              hm(ref.zone.wall(plan.leastBad!))),
                          selected: selected == plan.leastBad,
                          onTap: () => _setStep(
                              plan.leastBad!.difference(_origin).inMinutes ~/
                                  15),
                        ),
                        Text(
                          l10n.worldPlanAtWork(
                              plan.leastBadAtWork ?? 0, zones.length),
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Legend(
              items: [
                (_StripPainter.workColor(scheme), l10n.worldPlanWork),
                (
                  scheme.tertiary.withValues(alpha: 0.75),
                  l10n.worldPlanOverlapTitle
                ),
                (_StripPainter.nightColor(scheme), l10n.worldPlanNight),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.sm),
              child: Text(
                l10n.worldPlanTapCity,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            for (final row in rows) ...[
              _CityRow(
                name: row.name,
                time: hm(row.zone.wall(selected)),
                dayLabel: switch (dayOffset(row.zone, ref.zone, selected)) {
                  > 0 => l10n.worldPlanNextDay,
                  < 0 => l10n.worldPlanPrevDay,
                  _ => '',
                },
                isRef: row.id == ref.id,
                onSelect: () {
                  Haptics.select();
                  setState(() => _ref = row.id);
                },
                strip: _Strip(
                  painter: _StripPainter(
                    scheme: scheme,
                    cells: [
                      for (var i = 0; i < planSteps; i++)
                        () {
                          final t = _origin.add(planStep * i);
                          return everyone[i]
                              ? _Cell.everyone
                              : row.zone.working(t)
                                  ? _Cell.work
                                  : row.zone.night(t)
                                      ? _Cell.night
                                      : _Cell.day;
                        }(),
                    ],
                    marker: _step / planSteps,
                  ),
                  onFraction: (f) => _setStep((f * planSteps).round()),
                  semantic: hm(row.zone.wall(selected)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: onTap,
      focusBorderRadius: const BorderRadius.all(Radius.circular(999)),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (color, label) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.name,
    required this.time,
    required this.dayLabel,
    required this.isRef,
    required this.onSelect,
    required this.strip,
  });

  final String name;
  final String time;
  final String dayLabel;
  final bool isRef;
  final VoidCallback onSelect;
  final Widget strip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fg = isRef ? scheme.onPrimaryContainer : scheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isRef ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          BouncyTap(
            onTap: onSelect,
            pressedScale: 0.98,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(color: fg),
                    ),
                  ),
                  if (dayLabel.isNotEmpty) ...[
                    Text(
                      dayLabel,
                      style: textTheme.labelMedium
                          ?.copyWith(color: scheme.tertiary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    time,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: fg),
                  ),
                ],
              ),
            ),
          ),
          strip,
        ],
      ),
    );
  }
}

enum _Cell { day, work, night, everyone }

class _Strip extends StatelessWidget {
  const _Strip({
    required this.painter,
    required this.onFraction,
    required this.semantic,
  });

  final _StripPainter painter;
  final ValueChanged<double> onFraction;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      void at(double dx) =>
          onFraction((dx / c.maxWidth).clamp(0.0, 1.0).toDouble());
      return Semantics(
        label: semantic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => at(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => at(d.localPosition.dx),
          child: SizedBox(
            height: 26,
            width: double.infinity,
            child: CustomPaint(painter: painter),
          ),
        ),
      );
    });
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter(
      {required this.scheme, required this.cells, required this.marker});

  final ColorScheme scheme;
  final List<_Cell> cells;
  final double marker;

  static Color workColor(ColorScheme s) => s.primary.withValues(alpha: 0.5);
  static Color nightColor(ColorScheme s) => s.onSurface.withValues(alpha: 0.16);

  Color _color(_Cell c) => switch (c) {
        _Cell.work => workColor(scheme),
        _Cell.night => nightColor(scheme),
        _Cell.everyone => scheme.tertiary.withValues(alpha: 0.75),
        _Cell.day => scheme.surface.withValues(alpha: 0.9),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / cells.length;
    final clip =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    canvas.save();
    canvas.clipRRect(clip);
    for (var i = 0; i < cells.length; i++) {
      // Overlap by a hair so no seams show between cells.
      canvas.drawRect(
        Rect.fromLTWH(i * w, 0, w + 0.6, size.height),
        Paint()..color = _color(cells[i]),
      );
    }
    canvas.restore();

    // The selected instant: a bar with a round handle.
    final x = (marker * size.width).clamp(2.0, size.width - 2.0).toDouble();
    final paint = Paint()..color = scheme.onSurface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(x, size.height / 2), width: 3, height: size.height),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawCircle(Offset(x, 3), 3.5, paint);
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.marker != marker || old.scheme != scheme || !_same(old.cells, cells);

  static bool _same(List<_Cell> a, List<_Cell> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
