import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../ui/organisms/window_title_bar.dart';

/// The custom Windows title bar (the window has no native one), or null on
/// every other platform. Shared by every mode's screen.
PreferredSizeWidget? platformTitleBar() {
  if (!Platform.isWindows) return null;
  return WindowTitleBar(
    title: 'Enfo',
    onMinimize: () async => windowManager.minimize(),
    onMaximize: () async {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    },
    onClose: () async => windowManager.close(),
  );
}
