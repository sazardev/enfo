import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/locale_controller.dart';
import '../ui/atoms/app_icon_button.dart';
import '../ui/design/responsive.dart';
import '../ui/design/spacing.dart';
import 'fullscreen.dart';
import 'mode_prefs.dart';

/// The full-screen layout: just the mode's main content, edge to edge.
///
/// * Tap anywhere to reveal the controls (exit, next mode, dim); they hide
///   themselves after a few seconds.
/// * The content drifts a few pixels every minute so a screen left on all
///   night doesn't burn the same pixels in.
/// * Back / Escape leaves full screen.
class ImmersiveView extends StatefulWidget {
  const ImmersiveView({super.key, required this.child});

  final Widget child;

  @override
  State<ImmersiveView> createState() => _ImmersiveViewState();
}

class _ImmersiveViewState extends State<ImmersiveView> {
  static const _controlsFor = Duration(seconds: 4);
  static const _driftEvery = Duration(minutes: 1);

  bool _controls = true;
  Timer? _hideTimer;
  Timer? _driftTimer;
  Offset _drift = Offset.zero;
  int _driftTick = 0;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
    _driftTimer = Timer.periodic(_driftEvery, (_) => _nextDrift());
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _driftTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_controlsFor, () {
      if (mounted) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    if (_controls) _scheduleHide();
  }

  /// Walks the content around a small square, one corner per minute.
  void _nextDrift() {
    if (!mounted) return;
    final amount = Responsive.of(context).size.shortestSide * 0.025;
    const corners = [
      Offset(1, 1),
      Offset(-1, 1),
      Offset(-1, -1),
      Offset(1, -1),
    ];
    setState(() {
      _drift = corners[_driftTick++ % corners.length] * amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Fullscreen.exit();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): Fullscreen.exit,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<Offset>(
                    tween: Tween(end: _drift),
                    duration:
                        still ? Duration.zero : const Duration(seconds: 4),
                    curve: Curves.easeInOut,
                    builder: (context, offset, child) =>
                        Transform.translate(offset: offset, child: child),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: widget.child,
                    ),
                  ),
                  // Dimming sits under the controls so they stay usable.
                  ValueListenableBuilder<int>(
                    valueListenable: Fullscreen.dimStep,
                    builder: (context, _, __) => IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        color: Colors.black
                            .withValues(alpha: Fullscreen.dimOpacity),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _controls ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !_controls,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIconButton(
                                  tooltip: l10n.tooltipDim,
                                  onPressed: () {
                                    Fullscreen.cycleDim();
                                    _scheduleHide();
                                  },
                                  icon: const Icon(
                                    Icons.brightness_medium_rounded,
                                  ),
                                ),
                                if (ModePrefs.enabled.length > 1)
                                  AppIconButton(
                                    tooltip: l10n.tooltipSwitchMode,
                                    onPressed: () {
                                      ModePrefs.step();
                                      _scheduleHide();
                                    },
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                  ),
                                AppIconButton(
                                  tooltip: l10n.tooltipExitFullscreen,
                                  onPressed: Fullscreen.exit,
                                  icon: const Icon(
                                    Icons.fullscreen_exit_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
