import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The whole interface of the sound and music modes: big titles side by
/// side, the current one bright and the neighbours small and dim. Swipe,
/// mouse-drag, wheel or arrow keys (D-pad) move between them.
///
/// [onChanged] fires as soon as another title is centred; the owner
/// decides what to do with it (typically after a short debounce).
/// [index] moving from outside (a song ended) glides the pager there.
class TitlePager extends StatefulWidget {
  const TitlePager({
    super.key,
    required this.titles,
    required this.index,
    required this.onChanged,
    this.fontSize = 34,
    this.onVertical,
  });

  /// Up (-1) / down (+1) arrow presses, for the page's other control.
  final ValueChanged<int>? onVertical;

  final List<String> titles;
  final int index;
  final ValueChanged<int> onChanged;
  final double fontSize;

  @override
  State<TitlePager> createState() => _TitlePagerState();
}

class _TitlePagerState extends State<TitlePager> {
  late final PageController _controller = PageController(
    initialPage: widget.index,
    viewportFraction: 0.7,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'TitlePager');
  int _shown = 0;
  DateTime _lastWheel = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _shown = widget.index;
  }

  @override
  void didUpdateWidget(TitlePager old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index && widget.index != _shown) {
      _shown = widget.index;
      _goTo(widget.index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (!_controller.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(i);
    } else {
      _controller.animateToPage(i,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    }
  }

  void _step(int delta) {
    final n = widget.titles.length;
    final target = (_shown + delta).clamp(0, n - 1);
    if (target == _shown) return;
    _goTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _step(1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _step(-1);
          return KeyEventResult.handled;
        }
        if (widget.onVertical != null) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onVertical!(-1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onVertical!(1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerSignal: (e) {
          if (e is! PointerScrollEvent) return;
          final now = DateTime.now();
          if (now.difference(_lastWheel) < const Duration(milliseconds: 220)) {
            return;
          }
          final d = e.scrollDelta.dx.abs() > e.scrollDelta.dy.abs()
              ? e.scrollDelta.dx
              : e.scrollDelta.dy;
          if (d == 0) return;
          _lastWheel = now;
          _step(d > 0 ? 1 : -1);
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.titles.length,
            onPageChanged: (i) {
              _shown = i;
              widget.onChanged(i);
            },
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                var page = _shown.toDouble();
                if (_controller.hasClients &&
                    _controller.position.haveDimensions) {
                  page = _controller.page ?? page;
                }
                final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
                return Semantics(
                  selected: i == _shown,
                  label: widget.titles[i],
                  child: ExcludeSemantics(
                    child: Center(
                      child: Opacity(
                        opacity: 0.25 + 0.75 * t,
                        child: Transform.scale(
                          scale: 0.55 + 0.45 * t,
                          child: Text(
                            widget.titles[i],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
