import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/locale_controller.dart';
import '../ui/design/responsive.dart';
import '../ui/design/spacing.dart';
import 'alerts.dart';

/// Full-screen "it's going off" page for alarms and timers: a pulsing disc,
/// what rang, and Dismiss (+ Snooze when offered). Repeats the system alert
/// sound and a vibration until answered, and gives up after two minutes.
class RingingPage extends StatefulWidget {
  const RingingPage({super.key, required this.request});

  final RingRequest request;

  @override
  State<RingingPage> createState() => _RingingPageState();
}

class _RingingPageState extends State<RingingPage>
    with SingleTickerProviderStateMixin {
  static const _giveUpAfter = Duration(minutes: 2);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _beep;
  Timer? _expire;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pulse.repeat(reverse: true);
    _ring();
    _beep = Timer.periodic(const Duration(seconds: 2), (_) => _ring());
    _expire = Timer(_giveUpAfter, () => _finish(widget.request.onExpire));
  }

  void _ring() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
  }

  void _finish(VoidCallback? action) {
    if (_done) return;
    _done = true;
    _beep?.cancel();
    _expire?.cancel();
    (action ?? widget.request.onDismiss).call();
    Alerts.finish();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _beep?.cancel();
    _expire?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final r = Responsive.of(context);
    final req = widget.request;
    final still = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(null);
      },
      child: Scaffold(
        backgroundColor: scheme.primaryContainer,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(r.pagePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.contentWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: still
                            ? 1
                            : 0.92 +
                                0.16 * Curves.easeInOut.transform(_pulse.value),
                        child: child,
                      ),
                      child: Container(
                        width: r.isWatch ? 96 : 168,
                        height: r.isWatch ? 96 : 168,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          req.icon,
                          size: r.isWatch ? 44 : 84,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                        height: r.isWatch ? AppSpacing.md : AppSpacing.xxxl),
                    Text(
                      req.title,
                      textAlign: TextAlign.center,
                      style: (r.isWatch
                              ? textTheme.titleLarge
                              : textTheme.displaySmall)
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    if (req.subtitle != null && !r.isWatch) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        req.subtitle!,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color:
                              scheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    SizedBox(
                        height: r.isWatch ? AppSpacing.md : AppSpacing.huge),
                    FilledButton(
                      onPressed: () => _finish(null),
                      child: Text(l10n.ringDismiss),
                    ),
                    if (req.onSnooze != null && req.snoozeMinutes != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _finish(req.onSnooze),
                        child: Text(l10n.ringSnooze(req.snoozeMinutes!)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
