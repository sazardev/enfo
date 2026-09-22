import 'package:flutter/material.dart';

import '../../presets.dart';
import '../molecules/minutes_slider.dart';
import '../molecules/preset_card.dart';

typedef PresetSelection = ({int workMinutes, int restMinutes});

/// Grid of Pomodoro presets plus a "Manual" option revealing custom
/// work/rest sliders. Used by both onboarding and settings.
class PresetPicker extends StatefulWidget {
  final int initialWorkMinutes;
  final int initialRestMinutes;
  final ValueChanged<PresetSelection> onChanged;

  const PresetPicker({
    super.key,
    required this.initialWorkMinutes,
    required this.initialRestMinutes,
    required this.onChanged,
  });

  @override
  State<PresetPicker> createState() => _PresetPickerState();
}

class _PresetPickerState extends State<PresetPicker> {
  late int _workMinutes = widget.initialWorkMinutes;
  late int _restMinutes = widget.initialRestMinutes;
  int? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = _matchingPresetIndex();
  }

  @override
  void didUpdateWidget(covariant PresetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialWorkMinutes != oldWidget.initialWorkMinutes ||
        widget.initialRestMinutes != oldWidget.initialRestMinutes) {
      _workMinutes = widget.initialWorkMinutes;
      _restMinutes = widget.initialRestMinutes;
      _selectedPreset = _matchingPresetIndex();
    }
  }

  int? _matchingPresetIndex() {
    for (var i = 0; i < Presets.all.length; i++) {
      final preset = Presets.all[i];
      if (preset.workMinutes == _workMinutes &&
          preset.restMinutes == _restMinutes) {
        return i;
      }
    }
    return null;
  }

  void _selectPreset(int index) {
    final preset = Presets.all[index];
    setState(() {
      _selectedPreset = index;
      _workMinutes = preset.workMinutes;
      _restMinutes = preset.restMinutes;
    });
    widget.onChanged((workMinutes: _workMinutes, restMinutes: _restMinutes));
  }

  void _setCustom({int? workMinutes, int? restMinutes}) {
    setState(() {
      _selectedPreset = null;
      if (workMinutes != null) _workMinutes = workMinutes;
      if (restMinutes != null) _restMinutes = restMinutes;
    });
    widget.onChanged((workMinutes: _workMinutes, restMinutes: _restMinutes));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCustom = _selectedPreset == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (var i = 0; i < Presets.all.length; i++)
              PresetCard(
                label: Presets.all[i].label,
                subtitle:
                    '${Presets.all[i].workMinutes}/${Presets.all[i].restMinutes} min',
                selected: _selectedPreset == i,
                onTap: () => _selectPreset(i),
              ),
            PresetCard(
              label: 'Manual',
              subtitle: '$_workMinutes/$_restMinutes min',
              selected: isCustom,
              onTap: () => _setCustom(),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: isCustom
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MinutesSlider(
                        label: 'Enfoque',
                        color: colorScheme.primary,
                        minutes: _workMinutes,
                        min: 5,
                        max: 120,
                        divisions: 23,
                        onChanged: (value) => _setCustom(workMinutes: value),
                      ),
                      const SizedBox(height: 12),
                      MinutesSlider(
                        label: 'Descanso',
                        color: colorScheme.tertiary,
                        minutes: _restMinutes,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        onChanged: (value) => _setCustom(restMinutes: value),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
