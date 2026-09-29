import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_switch.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/confirm_action_row.dart';
import '../../ui/molecules/settings_row.dart';
import '../clock/time_builder.dart';
import 'date_time_wheels.dart';
import 'event_logic.dart';
import 'event_service.dart';

/// The icons an event can wear (index into this list is what is stored).
const List<IconData> eventIcons = [
  Icons.event_rounded,
  Icons.cake_rounded,
  Icons.favorite_rounded,
  Icons.flight_takeoff_rounded,
  Icons.celebration_rounded,
  Icons.school_rounded,
  Icons.work_rounded,
  Icons.star_rounded,
];

IconData eventIconOf(int index) =>
    eventIcons[index.clamp(0, eventIcons.length - 1)];

/// Inline add / edit form: name, icon, date and time wheels, yearly repeat,
/// notifications, and (when editing) a confirmed delete.
class EventEditor extends StatefulWidget {
  const EventEditor({super.key, this.event, required this.onDone});

  /// Null to create a new event.
  final CountdownEvent? event;

  /// Called after save, delete or cancel, with the saved event (or null).
  final ValueChanged<CountdownEvent?> onDone;

  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.event?.name ?? '');
  late DateTime _target = widget.event?.target ?? _defaultTarget();
  late int _icon = widget.event?.icon ?? 0;
  late bool _yearly = widget.event?.yearly ?? false;
  late bool _notify = widget.event?.notify ?? false;
  late bool _dayBefore = widget.event?.dayBefore ?? false;

  static DateTime _defaultTarget() {
    final now = nowProvider();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid) return;
    final existing = widget.event;
    final name = _name.text.trim();
    final base =
        existing ?? EventService.instance.create(name: name, target: _target);
    final event = base.copyWith(
      name: name,
      targetMs: _target.millisecondsSinceEpoch,
      // Moving the date restarts the progress from now.
      createdMs: existing != null &&
              existing.targetMs == _target.millisecondsSinceEpoch
          ? existing.createdMs
          : nowProvider().millisecondsSinceEpoch,
      icon: _icon,
      yearly: _yearly,
      notify: _notify,
      dayBefore: _notify && _dayBefore,
    );
    await EventService.instance.upsert(event);
    Haptics.success();
    widget.onDone(event);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final extent = r.isWatch ? 30.0 : 46.0;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.isWatch ? 200 : 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!r.isWatch)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.md,
                  ),
                  child: Text(
                    widget.event == null ? l10n.eventAdd : l10n.eventEdit,
                    style: textTheme.titleLarge,
                  ),
                ),
              TextField(
                controller: _name,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.eventName,
                  hintText: r.isWatch ? null : l10n.eventNameHint,
                  counterText: '',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (!r.isWatch) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < eventIcons.length; i++)
                      _IconChoice(
                        icon: eventIcons[i],
                        selected: i == _icon,
                        onTap: () {
                          Haptics.select();
                          setState(() => _icon = i);
                        },
                      ),
                  ],
                ),
              ],
              SizedBox(height: r.isWatch ? AppSpacing.sm : AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  '${DateFormat.yMMMEd(locale).format(_target)}  ·  '
                  '${DateFormat.Hm(locale).format(_target)}',
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              DateTimeWheels(
                value: _target,
                extent: extent,
                onChanged: (t) => setState(() => _target = t),
              ),
              if (!r.isWatch) ...[
                const SizedBox(height: AppSpacing.lg),
                SettingsRow(
                  label: l10n.eventYearly,
                  subtitle: l10n.eventYearlyHint,
                  trailing: AppSwitch(
                    value: _yearly,
                    onChanged: (v) => setState(() => _yearly = v),
                  ),
                  onTap: () => setState(() {
                    Haptics.toggle(!_yearly);
                    _yearly = !_yearly;
                  }),
                ),
                SettingsRow(
                  label: l10n.eventNotify,
                  subtitle: l10n.eventNotifyHint,
                  trailing: AppSwitch(
                    value: _notify,
                    onChanged: (v) => setState(() => _notify = v),
                  ),
                  onTap: () => setState(() {
                    Haptics.toggle(!_notify);
                    _notify = !_notify;
                  }),
                ),
                if (_notify)
                  SettingsRow(
                    label: l10n.eventDayBefore,
                    trailing: AppSwitch(
                      value: _dayBefore,
                      onChanged: (v) => setState(() => _dayBefore = v),
                    ),
                    onTap: () => setState(() {
                      Haptics.toggle(!_dayBefore);
                      _dayBefore = !_dayBefore;
                    }),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _valid ? _save : null,
                child: Text(l10n.eventSave),
              ),
              TextButton(
                onPressed: () => widget.onDone(null),
                child: Text(l10n.cancel),
              ),
              if (widget.event != null && !r.isWatch) ...[
                const SizedBox(height: AppSpacing.sm),
                ConfirmActionRow(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.eventDelete,
                  confirmLabel: l10n.eventConfirmDelete,
                  hint: l10n.eventDeleteHint,
                  onConfirmed: () async {
                    await EventService.instance.remove(widget.event!);
                    widget.onDone(null);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.92,
      focusBorderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          // Selection morphs the circle into a squircle.
          borderRadius: BorderRadius.circular(selected ? 16 : 24),
        ),
        child: Icon(
          icon,
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    );
  }
}
