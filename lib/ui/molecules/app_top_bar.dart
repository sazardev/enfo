import 'package:flutter/material.dart';

import '../../tv/tv_mode.dart';
import '../design/responsive.dart';

/// Toolbar height for the current screen class: slim on watches so the
/// content keeps its space, roomier on large displays.
double appBarHeightFor(Responsive r) => switch (r.factor) {
      FormFactor.watch => 40,
      FormFactor.compact => kToolbarHeight,
      FormFactor.medium => 60,
      FormFactor.expanded => 64,
    };

/// Screen-aware [AppBar]: use instead of a bare `AppBar(...)` so the bar
/// never dominates a small screen. On watches it also shrinks the title,
/// back arrow and action icons.
AppBar appTopBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
}) {
  final r = Responsive.of(context);
  final watch = r.isWatch;
  final base = Theme.of(context).appBarTheme.titleTextStyle ??
      Theme.of(context).textTheme.titleMedium;
  const watchIcons = IconThemeData(size: 18);

  return AppBar(
    title: title,
    // On TV the remote's Back key is the way out; keeping the visible arrow
    // out of the focus order puts the first focus on the actual content.
    leading: ModalRoute.of(context)?.canPop == true
        ? ExcludeFocus(excluding: TvMode.isTv, child: const BackButton())
        : null,
    actions: actions,
    toolbarHeight: appBarHeightFor(r),
    leadingWidth: watch ? 36 : null,
    titleSpacing: watch ? 0 : null,
    titleTextStyle: watch ? base?.copyWith(fontSize: 13) : null,
    iconTheme: watch ? watchIcons : null,
    actionsIconTheme: watch ? watchIcons : null,
  );
}
