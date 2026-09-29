import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/settings_row.dart';
import '../../ui/templates/settings_shell.dart';
import 'cities.dart';
import 'world_prefs.dart';

/// Search the city list and add one to the world clock.
class CityPickerPage extends StatefulWidget {
  const CityPickerPage({super.key});

  @override
  State<CityPickerPage> createState() => _CityPickerPageState();
}

class _CityPickerPageState extends State<CityPickerPage> {
  String _query = '';

  bool _matches(WorldCity c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.en.toLowerCase().contains(q) ||
        c.es.toLowerCase().contains(q) ||
        c.id.toLowerCase().contains(q.replaceAll(' ', '_'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<List<String>>(
      valueListenable: WorldPrefs.cities,
      builder: (context, added, _) {
        final results = worldCities
            .where((c) => !added.contains(c.id) && _matches(c))
            .toList()
          ..sort((a, b) => cityName(a).compareTo(cityName(b)));

        return SettingsShell(
          title: l10n.worldAdd,
          loaded: true,
          children: [
            TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l10n.worldSearch,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.mdRadius,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.worldNoResults,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            for (final city in results)
              SettingsRow(
                label: cityName(city),
                subtitle: city.id.replaceAll('_', ' '),
                trailing: const Icon(Icons.add_rounded),
                onTap: () async {
                  await WorldPrefs.add(city.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }
}
