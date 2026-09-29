import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../haptics/haptics.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/clock/clock_frame.dart';
import '../../ui/clock/clock_style.dart';
import '../../ui/clock/clock_view.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../clock/time_builder.dart';
import '../mode_scaffold.dart';
import 'event_editor.dart';
import 'event_logic.dart';
import 'event_service.dart';

/// Countdown to events: the nearest one large, drawn with the user's clock
/// style (swipe to change it), the others as flat cards below.
class EventModePage extends StatefulWidget {
  const EventModePage({super.key});

  @override
  State<EventModePage> createState() => _EventModePageState();
}

class _EventModePageState extends State<EventModePage> {
  ClockStyle _style = ClockStyle.ring;

  /// The event the user tapped to bring forward; null = the nearest.
  int? _focusId;
  bool _editing = false;
  CountdownEvent? _editTarget;

  @override
  void initState() {
    super.initState();
    ClockStyle.load().then((style) {
      if (mounted) setState(() => _style = style);
    });
  }

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final style = _style.step(velocity < 0 ? 1 : -1);
    setState(() => _style = style);
    ClockStyle.save(style);
  }

  void _openEditor([CountdownEvent? event]) => setState(() {
        _editing = true;
        _editTarget = event;
      });

  void _closeEditor(CountdownEvent? saved) => setState(() {
        _editing = false;
        _editTarget = null;
        if (saved != null) _focusId = saved.id;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);

    return ModeScaffold(
      primaryAction: _editing
          ? null
          : AppIconButton(
              tooltip: l10n.eventAdd,
              autofocus: true,
              onPressed: _openEditor,
              icon: const Icon(Icons.add_rounded),
            ),
      body: _editing
          ? EventEditor(
              key: ValueKey(_editTarget?.id ?? 'new'),
              event: _editTarget,
              onDone: _closeEditor,
            )
          : ValueListenableBuilder<List<CountdownEvent>>(
              valueListenable: EventService.instance.events,
              builder: (context, events, _) => TimeBuilder(
                builder: (context, now) => _content(context, events, now, r),
              ),
            ),
    );
  }

  Widget _content(
    BuildContext context,
    List<CountdownEvent> events,
    DateTime now,
    Responsive r,
  ) {
    final l10n = context.l10n;
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.eventEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final views = orderedViews(events, now);
    final hero = views.firstWhere(
      (v) => v.event.id == _focusId,
      orElse: () => views.first,
    );
    final others = [
      for (final v in views)
        if (v != hero) v
    ];

    final heroBlock = _Hero(
      view: hero,
      style: _style,
      compact: r.isWatch,
      onSwipe: _swipe,
      onEdit: () => _openEditor(hero.event),
    );

    // Watch: just the nearest event.
    if (r.isWatch) return heroBlock;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final v in others)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _EventCard(
              view: v,
              onTap: () {
                Haptics.select();
                setState(() => _focusId = v.event.id);
              },
              onEdit: () => _openEditor(v.event),
            ),
          ),
      ],
    );

    if (r.isWide) {
      // The side list takes a third of the width, between 260 and 340.
      return LayoutBuilder(
        builder: (context, c) => Row(
          children: [
            Expanded(child: heroBlock),
            const SizedBox(width: AppSpacing.xl),
            SizedBox(
              width: (c.maxWidth * 0.36).clamp(260.0, 340.0),
              child: SingleChildScrollView(child: list),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final heroHeight = others.isEmpty
          ? c.maxHeight
          : (c.maxHeight * 0.72).clamp(260.0, 460.0);
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: heroHeight, child: heroBlock),
            if (others.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              list,
            ],
          ],
        ),
      );
    });
  }
}

/// Words and units for the current state of an event.
String _shortText(AppLocalizations l10n, EventView v) => switch (v.phase) {
      EventPhase.today => l10n.eventToday,
      EventPhase.past => l10n.eventDaysAgo(v.daysAgo),
      EventPhase.upcoming => shortRemaining(
          v.remaining,
          dayUnit: l10n.eventDaysShort,
          hourUnit: l10n.timerHoursShort,
          minuteUnit: l10n.timerMinutesShort,
        ),
    };

class _Hero extends StatelessWidget {
  const _Hero({
    required this.view,
    required this.style,
    required this.compact,
    required this.onSwipe,
    required this.onEdit,
  });

  final EventView view;
  final ClockStyle style;
  final bool compact;
  final GestureDragEndCallback onSwipe;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final e = view.event;

    final headline = switch (view.phase) {
      EventPhase.today => l10n.eventToday,
      EventPhase.past => l10n.eventDaysAgo(view.daysAgo),
      EventPhase.upcoming => null,
    };

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: onSwipe,
            child: _EventFace(view: view, style: style),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
        if (headline != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              headline,
              style: (compact ? textTheme.titleLarge : textTheme.headlineLarge)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          )
        else if (!compact)
          // Scales down instead of overflowing next to the side list.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Stat(value: view.days, unit: l10n.eventUnitDays),
                const SizedBox(width: AppSpacing.sm),
                _Stat(value: view.hours, unit: l10n.eventUnitHours),
                const SizedBox(width: AppSpacing.sm),
                _Stat(value: view.minutes, unit: l10n.eventUnitMinutes),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact ? textTheme.titleSmall : textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!compact)
                    Text(
                      [
                        DateFormat.yMMMEd(locale).format(view.target),
                        DateFormat.Hm(locale).format(view.target),
                        if (e.yearly) l10n.eventRepeatsYearly,
                      ].join('  ·  '),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                size: 40,
                tooltip: l10n.eventEdit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            unit,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The clock visual for one event. Faces read "mm:ss", so days and hours
/// (or hours and minutes) ride in those two fields; see [FaceReading].
class _EventFace extends StatefulWidget {
  const _EventFace({required this.view, required this.style});

  final EventView view;
  final ClockStyle style;

  @override
  State<_EventFace> createState() => _EventFaceState();
}

class _EventFaceState extends State<_EventFace>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker = createTicker(
    (elapsed) =>
        _time.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond,
  );

  void _sync() {
    final run = widget.style.animated &&
        widget.view.isUpcoming &&
        !MediaQuery.disableAnimationsOf(context);
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _EventFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reading = widget.view.face;
    final name = widget.view.event.name;
    final labels = ClockLabels(
      focus: name,
      relax: name,
      paused: name,
      minutes: reading.daysMode ? l10n.eventDaysShort : l10n.timerHoursShort,
      seconds: reading.daysMode ? l10n.timerHoursShort : l10n.timerMinutesShort,
      ends: name,
    );
    final palette = ClockPalette.of(
      Theme.of(context).colorScheme,
      rest: false,
      paused: false,
    );

    return ValueListenableBuilder<double>(
      valueListenable: _time,
      builder: (context, time, _) => ClockView(
        style: widget.style,
        palette: palette,
        frame: ClockFrame(
          progress: reading.progress,
          totalSeconds: reading.totalUnits,
          phase: ClockPhase.running,
          time: time,
          labels: labels,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.view,
    required this.onTap,
    required this.onEdit,
  });

  final EventView view;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final e = view.event;
    final past = view.phase == EventPhase.past;
    final today = view.phase == EventPhase.today;

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: today
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: AppRadii.mdRadius,
        ),
        child: Row(
          children: [
            Icon(
              eventIconOf(e.icon),
              color: past
                  ? colorScheme.onSurfaceVariant
                  : (today
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: today
                          ? colorScheme.onPrimaryContainer
                          : (past ? colorScheme.onSurfaceVariant : null),
                    ),
                  ),
                  Text(
                    [
                      DateFormat.yMMMd(locale).format(view.target),
                      if (e.yearly) l10n.eventRepeatsYearly,
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _shortText(l10n, view),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: today
                    ? colorScheme.onPrimaryContainer
                    : (past ? colorScheme.onSurfaceVariant : null),
              ),
            ),
            AppIconButton(
              size: 36,
              tooltip: l10n.eventEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
