import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../clock/faces.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../fullscreen.dart';
import '../app_mode.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import 'stopwatch_controller.dart';

/// Stopwatch with laps. The ring fills once a minute; the digits run to
/// hundredths.
class StopwatchModePage extends StatelessWidget {
  const StopwatchModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = StopwatchController.instance;
    final r = Responsive.of(context);

    final l10n = context.l10n;

    return ModeKeyBindings(
      mode: AppMode.stopwatch,
      actions: ModeKeyActions(
        primary: () => sw.running ? sw.stop() : sw.start(),
        reset: () {
          if (!sw.running && sw.hasData) sw.reset();
        },
        lap: sw.lap,
      ),
      child: ModeScaffold(
        primaryAction: ListenableBuilder(
          listenable: sw,
          builder: (context, _) => PrimaryActionButton(
            running: sw.running,
            label: sw.running
                ? l10n.timerPause
                : (sw.hasData ? l10n.timerResume : l10n.timerStart),
            onPressed: sw.running ? sw.stop : sw.start,
          ),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([sw, Fullscreen.active]),
          builder: (context, _) {
            final full = Fullscreen.active.value;
            final face = _Face(sw: sw);
            final controls = _Controls(sw: sw);
            final laps = _Laps(sw: sw);

            if (full) return face;

            return LayoutBuilder(builder: (context, c) {
              final sideBySide = c.maxWidth > c.maxHeight * 1.25 && !r.isWatch;
              if (sideBySide) {
                return Row(
                  children: [
                    Expanded(child: face),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        children: [
                          controls,
                          const SizedBox(height: AppSpacing.lg),
                          Expanded(child: laps),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(flex: 3, child: face),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: controls,
                  ),
                  if (!r.isWatch && sw.laps.isNotEmpty) Expanded(child: laps),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.sw});

  final StopwatchController sw;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TimeBuilder(
      // Frame-rate updates only while it is actually counting.
      smooth: sw.running,
      builder: (context, _) {
        final elapsed = sw.elapsed;
        final lap = sw.currentLap;
        return LayoutBuilder(builder: (context, c) {
          final side = c.biggest.shortestSide;
          return Center(
            child: SizedBox.square(
              dimension: side,
              child: CustomPaint(
                painter: TickRingPainter(
                  fraction: (elapsed.inMilliseconds % 60000) / 60000,
                  lit: scheme.primary,
                  dim: scheme.onSurface.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: SizedBox(
                    width: side * 0.7,
                    height: side * 0.4,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatStopwatch(elapsed),
                            maxLines: 1,
                            textScaler: TextScaler.noScaling,
                            style: (textTheme.displayLarge ?? const TextStyle())
                                .copyWith(
                              fontSize: 120,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              letterSpacing: -3,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (sw.laps.isNotEmpty)
                            Text(
                              formatStopwatch(lap),
                              maxLines: 1,
                              textScaler: TextScaler.noScaling,
                              style: (textTheme.titleLarge ?? const TextStyle())
                                  .copyWith(
                                fontSize: 44,
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.sw});

  final StopwatchController sw;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Nothing to offer before the first start: play lives in the menu.
    if (!sw.hasData && !sw.running) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset only makes sense once stopped with something to clear.
        if (sw.hasData && !sw.running)
          AppIconButton(
            tooltip: l10n.timerReset,
            onPressed: sw.reset,
            icon: const Icon(Icons.stop_rounded),
          ),
        if (sw.running)
          AppIconButton(
            tooltip: l10n.stopwatchLap,
            onPressed: sw.lap,
            icon: const Icon(Icons.flag_rounded),
          ),
      ],
    );
  }
}

class _Laps extends StatelessWidget {
  const _Laps({required this.sw});

  final StopwatchController sw;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final laps = sw.laps;
    if (laps.isEmpty) return const SizedBox.shrink();

    // Best / slowest only mean something with a few laps to compare.
    final best = laps.length >= 3 ? laps.reduce((a, b) => a < b ? a : b) : null;
    final worst =
        laps.length >= 3 ? laps.reduce((a, b) => a > b ? a : b) : null;

    var running = Duration.zero;
    final totals = [
      for (final l in laps) running += Duration(milliseconds: l),
    ];

    return ListView.builder(
      itemCount: laps.length,
      itemBuilder: (context, i) {
        // Newest first.
        final index = laps.length - 1 - i;
        final ms = laps[index];
        final tag = ms == best
            ? l10n.stopwatchLapBest
            : (ms == worst ? l10n.stopwatchLapWorst : null);
        final color =
            ms == best ? scheme.primary : (ms == worst ? scheme.error : null);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.smRadius,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  '#${index + 1}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Text(
                  formatStopwatch(Duration(milliseconds: ms)),
                  style: textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (tag != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Text(
                    tag,
                    style: textTheme.labelSmall?.copyWith(color: color),
                  ),
                ),
              Text(
                formatStopwatch(totals[index]),
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
