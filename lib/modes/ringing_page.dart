import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../haptics/haptic_events.dart';
import '../haptics/haptics.dart';
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

  /// One ringer cycle. The vibration pattern, the sound and the pulse of the
  /// disc all restart together each cycle, so they beat as one.
  late final int _period = Haptics.ringPeriod(timer: widget.request.timer);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _period),
  );
  late final HapticEvent _feel = widget.request.timer
      ? HapticEvents.timerDone
      : Haptics.alarmPattern.value.event;

  Timer? _cycle;
  Timer? _expire;
  bool _done = false;
  bool _started = false;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    // The first beat waits for dependencies (it reads MediaQuery).
    if (!_started) {
      _started = true;
      _beat();
    }
  }

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(Duration(milliseconds: _period), (_) => _beat());
    _expire = Timer(widget.request.giveUpAfter ?? _giveUpAfter,
        () => _finish(widget.request.onExpire));
  }

  void _beat() {
    if (widget.request.gentle) {
      Haptics.transition();
    } else {
      SystemSound.play(SystemSoundType.alert);
      Haptics.ringCycle(timer: widget.request.timer);
    }
    if (!_still) _pulse.forward(from: 0);
  }

  void _finish(VoidCallback? action) {
    if (_done) return;
    _done = true;
    _cycle?.cancel();
    _expire?.cancel();
    // Cut whatever is still buzzing, then acknowledge with a clean tap.
    Haptics.cancel().then((_) => Haptics.confirm());
    (action ?? widget.request.onDismiss).call();
    Alerts.finish();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _cycle?.cancel();
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
                      // The disc swells on each beat and relaxes between them:
                      // the same envelope as the vibration.
                      builder: (context, child) => Transform.scale(
                        scale: still
                            ? 1
                            : 0.94 +
                                0.14 *
                                    _feel.envelopeAt(
                                      (_pulse.value * _period).round(),
                                    ),
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
                      child: Text(req.dismissLabel ?? l10n.ringDismiss),
                    ),
                    if (req.onSnooze != null && req.snoozeMinutes != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _finish(req.onSnooze),
                        child: Text(l10n.ringSnooze(req.snoozeMinutes!)),
                      ),
                    ],
                    if (req.onExtra != null && req.extraLabel != null)
                      TextButton(
                        onPressed: () => _finish(req.onExtra),
                        child: Text(req.extraLabel!),
                      ),
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
