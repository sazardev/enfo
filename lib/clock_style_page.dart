import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'l10n/locale_controller.dart';
import 'theme.dart';
import 'ui/atoms/bouncy_tap.dart';
import 'ui/clock/clock_combo.dart';
import 'ui/clock/clock_style.dart';
import 'ui/clock/clock_style_l10n.dart';
import 'ui/design/layout.dart';
import 'ui/design/motion.dart';
import 'ui/design/responsive.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/app_top_bar.dart';
import 'ui/molecules/clock_combo_card.dart';
import 'ui/molecules/clock_style_tile.dart';

/// Full-page clock picker (pushed route, no modal). Every tile is a live
/// preview; picking one applies it and returns straight to the home screen
/// so the clock can be seen running right away. Sections collapse.
class ClockStylePage extends StatefulWidget {
  const ClockStylePage({super.key, required this.selected});

  final ClockStyle selected;

  @override
  State<ClockStylePage> createState() => _ClockStylePageState();
}

/// Key of the combos section in [_ClockStylePageState._collapsed].
const Object _combosKey = 'combos';

class _ClockStylePageState extends State<ClockStylePage>
    with TickerProviderStateMixin {
  late ClockStyle _selected = widget.selected;
  final Set<Object> _collapsed = {};
  bool _applying = false;

  /// One shared clock for all previews; `value * 3600` = elapsed seconds.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(hours: 1),
  );
  late final Animation<double> _seconds =
      _controller.drive(Tween<double>(begin: 0, end: 3600));

  /// Staggered entrance of the tiles.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _entranceStarted = false;

  static final List<Object> _allSections = [
    _combosKey,
    ...ClockCategory.values,
  ];

  bool get _allCollapsed => _collapsed.length == _allSections.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _entrance.value = 1;
    } else {
      if (!_controller.isAnimating) _controller.forward();
      if (!_entranceStarted) {
        _entranceStarted = true;
        _entrance.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _toggle(Object key) => setState(() {
        if (!_collapsed.remove(key)) _collapsed.add(key);
      });

  void _toggleAll() => setState(() {
        if (_allCollapsed) {
          _collapsed.clear();
        } else {
          _collapsed.addAll(_allSections);
        }
      });

  /// Saves the choice, lets the selection animation play for a beat, then
  /// pops back to home so the clock is visible immediately.
  Future<void> _apply(ClockStyle style, {Color? accent}) async {
    if (_applying) return;
    _applying = true;
    setState(() => _selected = style);
    await ClockStyle.save(style);
    if (accent != null) {
      await Themes.saveAccent(accent);
      if (!mounted) return;
      AdaptiveTheme.maybeOf(context)?.setTheme(
        light: Themes.light(accent),
        dark: Themes.dark(accent),
      );
    }
    if (!mounted) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  int _tileIndex = 0;

  Widget _pop(Widget child) => _Pop(
        animation: _entrance,
        index: _tileIndex++,
        child: child,
      );

  Widget _section({
    required Object key,
    required IconData icon,
    required String title,
    required Widget body,
  }) {
    final collapsed = _collapsed.contains(key);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BouncyTap(
          onTap: () => _toggle(key),
          pressedScale: 0.97,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: Motion.medium,
                  curve: Motion.snappy,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        _Collapsible(expanded: !collapsed, child: body),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final responsive = Responsive.of(context);
    final columns = switch (responsive.factor) {
      FormFactor.watch => 1,
      FormFactor.compact => 2,
      FormFactor.medium => 3,
      FormFactor.expanded => 4,
    };
    _tileIndex = 0;

    return Scaffold(
      appBar: appTopBar(
        context,
        title: Text(l10n.clockStyleTitle),
        actions: [
          IconButton(
            visualDensity: responsive.isWatch ? VisualDensity.compact : null,
            tooltip:
                _allCollapsed ? l10n.clockExpandAll : l10n.clockCollapseAll,
            onPressed: _toggleAll,
            icon: AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                _allCollapsed
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                key: ValueKey(_allCollapsed),
              ),
            ),
          ),
          SizedBox(width: responsive.isWatch ? 0 : AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppLayout.contentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(
                  key: _combosKey,
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.clockCombosTitle,
                  body: SizedBox(
                    // Two rows of cards scrolling sideways: 60 combos stay
                    // browsable without a very long list.
                    height:
                        (responsive.isWatch ? 1 : 2) * 176 * responsive.scale +
                            (responsive.isWatch ? 0 : AppSpacing.md),
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: ClockCombo.values.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: responsive.isWatch ? 1 : 2,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 148 * responsive.scale,
                      ),
                      itemBuilder: (context, i) {
                        final combo = ClockCombo.values[i];
                        return _pop(ClockComboCard(
                          combo: combo,
                          width: 148 * responsive.scale,
                          selected: combo.style == _selected &&
                              combo.color.toARGB32() ==
                                  Themes.accent.toARGB32(),
                          clock: _seconds,
                          onTap: () => _apply(combo.style, accent: combo.color),
                        ));
                      },
                    ),
                  ),
                ),
                for (final category in ClockCategory.values)
                  _section(
                    key: category,
                    icon: category.icon,
                    title: category.labelOf(l10n),
                    body: GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.9,
                      children: [
                        for (final style in ClockStyle.values)
                          if (style.category == category)
                            _pop(ClockStyleTile(
                              style: style,
                              selected: style == _selected,
                              clock: _seconds,
                              onTap: () => _apply(style),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggered pop-in: each item scales up with a spring-ish overshoot and
/// fades in slightly after the previous one.
class _Pop extends StatelessWidget {
  const _Pop({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.035).clamp(0.0, 0.55);
    final end = (start + 0.45).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = ((animation.value - start) / (end - start)).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.scale(
            scale: 0.8 + 0.2 * Curves.easeOutBack.transform(t),
            child: child,
          ),
        );
      },
    );
  }
}

/// Animated expand/collapse. While fully collapsed the child is not built at
/// all, so hidden live previews cost nothing.
class _Collapsible extends StatefulWidget {
  const _Collapsible({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  State<_Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<_Collapsible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: widget.expanded ? 1 : 0,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(covariant _Collapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed) {
          return const SizedBox(width: double.infinity);
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _curve.value,
            child: FadeTransition(opacity: _curve, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
