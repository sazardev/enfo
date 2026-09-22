import 'package:flutter/material.dart';

import '../design/layout.dart';
import '../design/spacing.dart';

/// Scaffold layout for a scrollable, sectioned settings-style screen. Caps
/// content to a readable column width so rows/grids don't stretch edge-to-
/// edge (and oversize) on wide desktop windows or landscape screens.
class SettingsShell extends StatelessWidget {
  const SettingsShell({
    super.key,
    required this.title,
    required this.loaded,
    required this.children,
  });

  final String title;
  final bool loaded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
    );
  }
}
