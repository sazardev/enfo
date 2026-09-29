import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../design/motion.dart';
import 'settings_row.dart';
import '../../haptics/haptics.dart';

/// A destructive action that confirms in place (the app allows no dialogs):
/// the row swaps for a "Confirm" row plus a "Cancel" row. Nothing runs
/// until the confirm row is tapped.
class ConfirmActionRow extends StatefulWidget {
  const ConfirmActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.confirmLabel,
    required this.hint,
    required this.onConfirmed,
  });

  final IconData icon;
  final String label;

  /// Label of the second-step row, e.g. "Confirm: delete all sessions".
  final String confirmLabel;

  /// One line of what will (and won't) happen; shown in both steps.
  final String hint;
  final Future<void> Function() onConfirmed;

  @override
  State<ConfirmActionRow> createState() => _ConfirmActionRowState();
}

class _ConfirmActionRowState extends State<ConfirmActionRow> {
  bool _confirming = false;
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    Haptics.warning();
    setState(() => _busy = true);
    try {
      await widget.onConfirmed();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return AnimatedSize(
      duration: Motion.medium,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !_confirming
          ? SettingsRow(
              label: widget.label,
              subtitle: widget.hint,
              trailing: Icon(widget.icon, color: error),
              onTap: () => setState(() => _confirming = true),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsRow(
                  label: widget.confirmLabel,
                  subtitle: widget.hint,
                  labelColor: error,
                  trailing: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.check_rounded, color: error),
                  onTap: _busy ? null : _confirm,
                ),
                SettingsRow(
                  label: context.l10n.cancel,
                  trailing: const Icon(Icons.close_rounded),
                  onTap:
                      _busy ? null : () => setState(() => _confirming = false),
                ),
              ],
            ),
    );
  }
}
