import 'package:flutter/widgets.dart';

import 'app_mode.dart';

/// What a mode does when the user presses its keyboard / remote shortcut.
class ModeKeyActions {
  const ModeKeyActions({this.primary, this.reset, this.lap});

  /// Start / pause (Space, media play/pause).
  final VoidCallback? primary;

  /// Back to the start (R, media stop).
  final VoidCallback? reset;

  /// Stopwatch lap (L).
  final VoidCallback? lap;
}

/// Where each mode publishes its shortcut actions, so one global key handler
/// can drive whichever mode is showing. Pomodoro stays alive while hidden, so
/// the lookup is by mode rather than by "last one registered".
class ModeKeys {
  static final _actions = <AppMode, ModeKeyActions>{};

  static ModeKeyActions? of(AppMode mode) => _actions[mode];
}

/// Publishes [actions] for [mode] while it is in the tree. Draws nothing.
/// The callbacks are read when a key is pressed, so they may close over state.
class ModeKeyBindings extends StatefulWidget {
  const ModeKeyBindings({
    super.key,
    required this.mode,
    required this.actions,
    required this.child,
  });

  final AppMode mode;
  final ModeKeyActions actions;
  final Widget child;

  @override
  State<ModeKeyBindings> createState() => _ModeKeyBindingsState();
}

class _ModeKeyBindingsState extends State<ModeKeyBindings> {
  @override
  void initState() {
    super.initState();
    ModeKeys._actions[widget.mode] = widget.actions;
  }

  @override
  void didUpdateWidget(covariant ModeKeyBindings oldWidget) {
    super.didUpdateWidget(oldWidget);
    ModeKeys._actions[widget.mode] = widget.actions;
  }

  @override
  void dispose() {
    // A newer instance of the same mode (page transition) may have taken
    // over already: only remove our own entry.
    if (identical(ModeKeys._actions[widget.mode], widget.actions)) {
      ModeKeys._actions.remove(widget.mode);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
