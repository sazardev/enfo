import 'package:flutter/material.dart';

import '../design/layout.dart';
import '../design/responsive.dart';
import '../design/spacing.dart';
import '../molecules/app_top_bar.dart';

/// Tells settings pages they are shown inside the settings hub's detail
/// pane (wide screens), so they render without their own Scaffold/AppBar,
/// and gives them a way to tell the hub that a value changed.
class SettingsPaneScope extends InheritedWidget {
  const SettingsPaneScope({
    super.key,
    required this.onChanged,
    required super.child,
  });

  final VoidCallback onChanged;

  static SettingsPaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsPaneScope>();

  @override
  bool updateShouldNotify(SettingsPaneScope oldWidget) => false;
}

/// Scaffold layout for a scrollable, sectioned settings-style screen. Caps
/// content to a readable column that grows with the screen (phone → tablet
/// → TV), tightens on watches, and drops the Scaffold when embedded in the
/// settings hub's detail pane.
class SettingsShell extends StatelessWidget {
  const SettingsShell({
    super.key,
    required this.title,
    required this.loaded,
    required this.children,
    this.wide = false,
  });

  final String title;
  final bool loaded;
  final List<Widget> children;

  /// Allow the wider column used for dense screens (statistics) on large
  /// displays.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final embedded = SettingsPaneScope.maybeOf(context) != null;

    final maxWidth =
        wide ? AppLayout.wideContentWidth(context) : r.contentWidth;

    final body = !loaded
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              r.pagePadding,
              AppSpacing.sm,
              r.pagePadding,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (embedded)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          bottom: AppSpacing.lg,
                        ),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ...children,
                  ],
                ),
              ),
            ),
          );

    if (embedded) return body;

    return Scaffold(
      appBar: appTopBar(context, title: Text(title)),
      body: SafeArea(top: false, child: body),
    );
  }
}
