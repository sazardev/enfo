import 'package:flutter/material.dart';

import 'ui/brand/enfo_mark.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/responsive.dart';

/// Cold-start splash for returning users: the logo builds itself, the
/// wordmark settles in beneath it, then the app fades in. Tap to skip.
/// (First-run users get the longer version inside the onboarding welcome.)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  /// The screen to show afterwards.
  final Widget next;

  static const duration = Duration(milliseconds: 1900);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
  );
  late final Animation<double> _mark = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.68),
  );
  late final Animation<double> _word = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
  );
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _leave();
    });
    // Reduced motion: no build, just the finished logo for a moment.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(appPageRoute((_) => widget.next));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final size = (r.size.shortestSide * 0.34).clamp(72.0, 220.0);
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _leave,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EnfoMark(progress: _mark, size: size),
              SizedBox(height: size * 0.22),
              AnimatedBuilder(
                animation: _word,
                builder: (context, child) => Opacity(
                  opacity: _word.value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - _word.value)),
                    child: child,
                  ),
                ),
                child: Text(
                  'enfo',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    fontSize: (size * 0.2).clamp(18.0, 40.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
