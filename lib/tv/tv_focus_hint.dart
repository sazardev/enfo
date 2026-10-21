import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../modes/fullscreen.dart';

/// The label of whatever currently has D-pad focus, shown in [TvHintBar].
///
/// On a television there is no hover, so a tooltip never appears. A small
/// bar at the bottom (the pattern Android TV apps use) keeps the focused
/// icon's meaning visible from the sofa. It only appears for icon-only
/// controls, and fades out after a few seconds so it does not sit on top of
/// the clock forever.
abstract final class TvFocusHint {
  const TvFocusHint._();

  static final ValueNotifier<String?> current = ValueNotifier<String?>(null);
  static final ValueNotifier<bool> visible = ValueNotifier<bool>(false);

  static Timer? _timer;

  static void show(String label) {
    if (current.value != label) current.value = label;
    visible.value = true;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      visible.value = false;
    });
  }

  /// Only clears the hint if it still belongs to [label], so a newer focus
  /// target is never wiped by the previous one being disposed.
  static void clear(String label) {
    if (current.value != label) return;
    current.value = null;
    visible.value = false;
    _timer?.cancel();
  }

  @visibleForTesting
  static void reset() {
    _timer?.cancel();
    current.value = null;
    visible.value = false;
  }
}

/// The bottom "OK Select · Back" strip. TV only; hidden in full screen.
class TvHintBar extends StatelessWidget {
  const TvHintBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: Fullscreen.active,
      builder: (context, fullscreen, _) {
        if (fullscreen) return const SizedBox.shrink();
        return ValueListenableBuilder<String?>(
          valueListenable: TvFocusHint.current,
          builder: (context, label, _) {
            // No focused control yet (splash, an empty screen): stay out of
            // the way. The first D-pad move brings the hint up.
            if (label == null || label.isEmpty) {
              return const SizedBox.shrink();
            }
            return ValueListenableBuilder<bool>(
              valueListenable: TvFocusHint.visible,
              builder: (context, visible, _) {
                if (!visible) return const SizedBox.shrink();
                return IgnorePointer(
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh
                                .withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              _KeyCap('OK'),
                              const SizedBox(width: 6),
                              Text(
                                l10n.tvHintSelect,
                                style: textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // The remote's Back key is labelled on the
                              // remote itself; repeating the word adds noise.
                              _KeyCap('Back'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
