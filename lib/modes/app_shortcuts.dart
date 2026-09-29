import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings.dart';
import '../shortcuts_page.dart';
import '../ui/design/page_transition.dart';
import 'fullscreen.dart';
import 'mode_keys.dart';
import 'mode_prefs.dart';
import 'modes_page.dart';

/// The app's navigator, so shortcuts can push and pop from outside the tree.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// App-wide keyboard / remote shortcuts (desktop keyboards, Android TV and
/// car remotes, media keys, Bluetooth keyboards on a phone).
///
/// Arrow keys, Tab and Enter/Select are Flutter's own focus navigation and
/// are left alone; this adds the "do things" layer on top:
///
/// * Space or media play/pause: start / pause the current mode
/// * R or media stop: reset · L: lap
/// * 1-9: jump to a mode · `[` `]`, Ctrl+Tab, channel up/down, media
///   next/previous: previous / next mode
/// * F or F11: full screen · D: dim (in full screen)
/// * S: settings · M: modes · ? or F1: shortcut list
/// * Esc, Back, Alt+Left: go back / leave full screen
///
/// Mode-level keys only work on the main screen (not over a settings page or
/// dialog) and never while typing in a text field.
class AppShortcuts extends StatefulWidget {
  const AppShortcuts({super.key, required this.child});

  final Widget child;

  @override
  State<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends State<AppShortcuts> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool get _typing {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// True when nothing in particular has focus, so Space is ours rather than
  /// a focused button's "press".
  bool get _nothingFocused {
    final focus = FocusManager.instance.primaryFocus;
    return focus == null || focus is FocusScopeNode;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final nav = appNavigatorKey.currentState;
    if (nav == null || _typing) return false;

    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final ctrl = keyboard.isControlPressed || keyboard.isMetaPressed;
    final alt = keyboard.isAltPressed;
    final shift = keyboard.isShiftPressed;

    // Back / leave full screen: works everywhere.
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack ||
        (alt && key == LogicalKeyboardKey.arrowLeft)) {
      if (Fullscreen.active.value) {
        Fullscreen.exit();
        return true;
      }
      if (nav.canPop()) {
        nav.maybePop();
        return true;
      }
      return false;
    }

    // Everything else belongs to the main screen only.
    if (nav.canPop()) return false;

    if (ctrl && key == LogicalKeyboardKey.tab) {
      ModePrefs.step(shift ? -1 : 1);
      return true;
    }
    if (ctrl && key == LogicalKeyboardKey.comma) {
      nav.push(appPageRoute((_) => const Settings()));
      return true;
    }
    if (ctrl || alt) return false;

    switch (key) {
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.mediaPlay:
      case LogicalKeyboardKey.mediaPause:
        return _run(_actions?.primary);
      case LogicalKeyboardKey.mediaStop:
        return _run(_actions?.reset);
      case LogicalKeyboardKey.space:
        return _nothingFocused && _run(_actions?.primary);
      case LogicalKeyboardKey.channelUp:
      case LogicalKeyboardKey.mediaTrackNext:
        ModePrefs.step(1);
        return true;
      case LogicalKeyboardKey.channelDown:
      case LogicalKeyboardKey.mediaTrackPrevious:
        ModePrefs.step(-1);
        return true;
      case LogicalKeyboardKey.f11:
        Fullscreen.toggle();
        return true;
      case LogicalKeyboardKey.f1:
        return _openHelp(nav);
    }

    switch (event.character?.toLowerCase()) {
      case 'r':
        return _run(_actions?.reset);
      case 'l':
        return _run(_actions?.lap);
      case 'f':
        Fullscreen.toggle();
        return true;
      case 'd':
        if (!Fullscreen.active.value) return false;
        Fullscreen.cycleDim();
        return true;
      case 's':
        nav.push(appPageRoute((_) => const Settings()));
        return true;
      case 'm':
        nav.push(appPageRoute((_) => const ModesPage()));
        return true;
      case '?':
        return _openHelp(nav);
      case ']':
        ModePrefs.step(1);
        return true;
      case '[':
        ModePrefs.step(-1);
        return true;
      case final digit? when digit.length == 1:
        final n = int.tryParse(digit);
        final modes = ModePrefs.enabled;
        if (n == null || n < 1 || n > modes.length) return false;
        ModePrefs.setCurrent(modes[n - 1]);
        return true;
    }
    return false;
  }

  ModeKeyActions? get _actions => ModeKeys.of(ModePrefs.current.value);

  bool _run(VoidCallback? action) {
    if (action == null) return false;
    action();
    return true;
  }

  bool _openHelp(NavigatorState nav) {
    nav.push(appPageRoute((_) => const ShortcutsPage()));
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
