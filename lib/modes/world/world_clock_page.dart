import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app_preferences.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/design/page_transition.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../clock/time_builder.dart';
import '../mode_scaffold.dart';
import 'cities.dart';
import 'city_picker_page.dart';
import 'world_prefs.dart';

/// "+9h", "-5h", "+5h 30m".
String formatOffset(Duration d) {
  final sign = d.isNegative ? '-' : '+';
  final total = d.inMinutes.abs();
  final h = total ~/ 60;
  final m = total % 60;
  return m == 0 ? '$sign${h}h' : '$sign${h}h ${m}m';
}

/// World clock: your time on top, then the cities you follow, each with
/// its own time, day and how far it is from you. Time zones come from the
/// real tz database, so daylight-saving changes are right.
class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);

    return ModeScaffold(
      actions: [
        AppIconButton(
          tooltip: l10n.worldAdd,
          onPressed: () => Navigator.of(context)
              .push(appPageRoute((_) => const CityPickerPage())),
          icon: const Icon(Icons.add_rounded),
        ),
        if (!r.isWatch)
          AppIconButton(
            tooltip: _editing ? l10n.worldDone : l10n.worldEdit,
            selected: _editing,
            onPressed: () => setState(() => _editing = !_editing),
            icon: Icon(
              _editing ? Icons.check_rounded : Icons.edit_outlined,
              color: _editing ? Theme.of(context).colorScheme.onPrimary : null,
            ),
          ),
      ],
      body: ListenableBuilder(
        listenable: Listenable.merge([
          WorldPrefs.cities,
          AppPreferences.clockFormat,
        ]),
        builder: (context, _) => TimeBuilder(
          builder: (context, now) => _content(context, now),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DateTime now) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final ids = WorldPrefs.cities.value;

    final use24h = switch (AppPreferences.clockFormat.value) {
      ClockFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
      ClockFormat.h12 => false,
      ClockFormat.h24 => true,
    };
    final material = MaterialLocalizations.of(context);
    String timeOf(DateTime t) => material.formatTimeOfDay(
          TimeOfDay(hour: t.hour, minute: t.minute),
          alwaysUse24HourFormat: use24h,
        );

    final localTile = _WorldTile(
      title: l10n.worldLocal,
      subtitle: now.timeZoneName,
      time: timeOf(now),
      hour: now.hour,
      compact: r.isWatch,
      highlight: true,
    );

    _WorldTile tileFor(String id, {Widget? trailing}) {
      final city = cityById(id)!;
      final zoned = tz.TZDateTime.from(now, tz.getLocation(city.zone));
      final diff = zoned.timeZoneOffset - now.timeZoneOffset;
      final days = DateTime.utc(zoned.year, zoned.month, zoned.day)
          .difference(DateTime.utc(now.year, now.month, now.day))
          .inDays;
      final day = switch (days) {
        0 => l10n.worldToday,
        1 => l10n.worldTomorrow,
        -1 => l10n.worldYesterday,
        _ => '',
      };
      final delta = diff == Duration.zero
          ? l10n.worldSameTime
          : (diff.isNegative
              ? l10n.worldDiffBehind(formatOffset(diff).substring(1))
              : l10n.worldDiffAhead(formatOffset(diff).substring(1)));
      return _WorldTile(
        title: cityName(city),
        subtitle: [day, delta].where((s) => s.isNotEmpty).join('  ·  '),
        time: timeOf(zoned),
        hour: zoned.hour,
        compact: r.isWatch,
        trailing: trailing,
      );
    }

    if (_editing) {
      return Column(
        children: [
          localTile,
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              proxyDecorator: (child, _, __) =>
                  Material(color: Colors.transparent, child: child),
              onReorderItem: WorldPrefs.reorder,
              children: [
                for (var i = 0; i < ids.length; i++)
                  Padding(
                    key: ValueKey(ids[i]),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: tileFor(
                      ids[i],
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconButton(
                            size: 40,
                            tooltip: l10n.worldRemove,
                            onPressed: () => WorldPrefs.remove(ids[i]),
                            icon:
                                const Icon(Icons.remove_circle_outline_rounded),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: Icon(Icons.drag_indicator_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(builder: (context, c) {
      // As many columns as fit a comfortable tile.
      final columns = r.isWatch ? 1 : (c.maxWidth / 340).floor().clamp(1, 4);
      const gap = AppSpacing.md;
      final width = (c.maxWidth - gap * (columns - 1)) / columns;
      final tiles = [localTile, for (final id in ids) tileFor(id)];

      return SingleChildScrollView(
        child: Column(
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final t in tiles) SizedBox(width: width, child: t),
              ],
            ),
            if (ids.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.worldEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.hour,
    this.compact = false,
    this.highlight = false,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String time;
  final int hour;
  final bool compact;
  final bool highlight;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final night = hour < 6 || hour >= 19;

    final foreground = highlight ? scheme.onPrimary : scheme.onSurface;
    final muted = highlight
        ? scheme.onPrimary.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: highlight ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: compact ? AppRadii.smRadius : AppRadii.mdRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!compact) ...[
                Icon(
                  night ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: highlight ? scheme.onPrimary : scheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(color: foreground),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Never squeezes the name: the time scales down if it must.
              Flexible(
                flex: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    time,
                    style:
                        (compact ? textTheme.titleMedium : textTheme.titleLarge)
                            ?.copyWith(
                                fontWeight: FontWeight.w700, color: foreground),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle.isNotEmpty && !compact)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
        ],
      ),
    );
  }
}
