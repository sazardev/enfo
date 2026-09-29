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
    with SingleTickerProviderStateMixin {
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
    } else if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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

  Widget _header({
    required Object key,
    required IconData icon,
    required String title,
  }) {
    final collapsed = _collapsed.contains(key);
    final cs = Theme.of(context).colorScheme;
    return BouncyTap(
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
      // Lazy slivers: only the tiles near the viewport are built, so the
      // ~120 live previews never all animate (or lay out) at once.
      body: LayoutBuilder(builder: (context, constraints) {
        final side =
            ((constraints.maxWidth - AppLayout.contentWidth(context)) / 2)
                .clamp(AppSpacing.xl, double.infinity);
        final styles = [
          for (final category in ClockCategory.values)
            (
              category,
              [
                for (final style in ClockStyle.values)
                  if (style.category == category) style,
              ],
            ),
        ];
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.xxxl),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _header(
                      key: _combosKey,
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.clockCombosTitle,
                    ),
                  ),
                  if (!_collapsed.contains(_combosKey))
                    SliverToBoxAdapter(
                      child: SizedBox(
                        // Two rows of cards scrolling sideways: 60 combos
                        // stay browsable without a very long list.
                        height: (responsive.isWatch ? 1 : 2) *
                                176 *
                                responsive.scale +
                            (responsive.isWatch ? 0 : AppSpacing.md),
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: ClockCombo.values.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: responsive.isWatch ? 1 : 2,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisExtent: 148 * responsive.scale,
                          ),
                          itemBuilder: (context, i) {
                            final combo = ClockCombo.values[i];
                            return _Pop(
                              child: ClockComboCard(
                                combo: combo,
                                width: 148 * responsive.scale,
                                selected: combo.style == _selected &&
                                    combo.color.toARGB32() ==
                                        Themes.accent.toARGB32(),
                                clock: _seconds,
                                onTap: () =>
                                    _apply(combo.style, accent: combo.color),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  for (final (category, items) in styles) ...[
                    SliverToBoxAdapter(
                      child: _header(
                        key: category,
                        icon: category.icon,
                        title: category.labelOf(l10n),
                      ),
                    ),
                    if (!_collapsed.contains(category))
                      SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _Pop(
                          child: ClockStyleTile(
                            style: items[i],
                            selected: items[i] == _selected,
                            clock: _seconds,
                            onTap: () => _apply(items[i]),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Short pop-in played when a tile is first built (tiles are lazy, so it
/// runs as they scroll into view instead of for all of them up front).
class _Pop extends StatelessWidget {
  const _Pop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.85 + 0.15 * Curves.easeOutBack.transform(t),
          child: child,
        ),
      ),
    );
  }
}
