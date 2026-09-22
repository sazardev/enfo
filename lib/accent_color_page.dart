import 'package:flutter/material.dart';

import 'ui/atoms/accent_swatch.dart';
import 'ui/design/layout.dart';
import 'ui/design/spacing.dart';

/// Full-page accent-color picker — a real screen (pushed via [Navigator]),
/// not a modal. The app allows zero modals: no dialogs, no bottom sheets.
class AccentColorPage extends StatelessWidget {
  const AccentColorPage({
    super.key,
    required this.colors,
    required this.selectedIndex,
  });

  final List<Color> colors;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color de acento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (var i = 0; i < colors.length; i++)
                  AccentSwatch(
                    color: colors[i],
                    selected: i == selectedIndex,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
