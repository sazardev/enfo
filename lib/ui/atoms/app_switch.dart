import 'package:flutter/material.dart';

import '../../haptics/haptics.dart';

/// The app's switch: a Material [Switch] that also gives the toggle its
/// haptic (a rising double-tap when turned on, a single soft one when off).
/// Use it instead of a bare `Switch` so every toggle feels the same.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              Haptics.toggle(v);
              onChanged!(v);
            },
    );
  }
}
