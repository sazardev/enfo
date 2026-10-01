import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'appearance_page.dart';
import 'data_page.dart';
import 'display_page.dart';
import 'haptics/haptics.dart';
import 'haptics/haptics_page.dart';
import 'language_page.dart';
import 'l10n/locale_controller.dart';
import 'modes/mode_prefs.dart';
import 'modes/modes_page.dart';
import 'notifications_page.dart';
import 'presets.dart';
import 'shortcuts_page.dart';
import 'support_page.dart';
import 'timers_page.dart';
import 'modes/music/music_credits_page.dart';
import 'ui/design/motion.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/responsive.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/app_top_bar.dart';
import 'ui/molecules/settings_nav_tile.dart';
import 'ui/templates/settings_shell.dart';
import 'widgets/widget_bridge.dart';
import 'widgets/widgets_page.dart';

class _Section {
  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
}

/// Settings hub: a concise list of sections, each opening its own page.
/// On wide screens it becomes master-detail: the list stays on the left and
/// the chosen page shows on the right. Subtitles summarise the current value.
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;
  bool _notificationsEnabled = true;
  bool _loaded = false;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preset = await Presets.load();
    final notificationsEnabled = await Presets.loadNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _workMinutes = preset.workMinutes;
      _restMinutes = preset.restMinutes;
      _notificationsEnabled = notificationsEnabled;
      _loaded = true;
    });
  }

  List<_Section> _sections(BuildContext context, Responsive r) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language =
        languageNames[LocaleController.locale.value?.languageCode] ??
            l10n.languageSystem;

    return [
      _Section(
        icon: Icons.timer_outlined,
        title: l10n.timersTitle,
        subtitle: l10n.timersSubtitle(_workMinutes, _restMinutes),
        page: const TimersPage(),
      ),
      _Section(
        icon: Icons.apps_rounded,
        title: l10n.modesTitle,
        subtitle: l10n.modesSubtitle(ModePrefs.enabled.length),
        page: const ModesPage(),
      ),
      _Section(
        icon: Icons.palette_outlined,
        title: l10n.appearanceTitle,
        subtitle: isDark ? l10n.appearanceDark : l10n.appearanceLight,
        page: const AppearancePage(),
      ),
      _Section(
        icon: Icons.phone_android_rounded,
        title: l10n.displayTitle,
        subtitle: AppPreferences.showClock.value
            ? l10n.displayClockShown
            : l10n.displayClockHidden,
        page: const DisplayPage(),
      ),
      if (Haptics.available)
        _Section(
          icon: Icons.vibration_rounded,
          title: l10n.hapticsTitle,
          subtitle: Haptics.enabled.value
              ? hapticStrengthLabel(l10n, Haptics.strength.value)
              : l10n.hapticsOff,
          page: const HapticsPage(),
        ),
      // Home-screen widgets exist on Android only.
      if (WidgetBridge.supported)
        _Section(
          icon: Icons.widgets_outlined,
          title: l10n.widgetsTitle,
          subtitle: l10n.widgetsSubtitle,
          page: const WidgetsPage(),
        ),
      _Section(
        icon: Icons.notifications_none_rounded,
        title: l10n.notificationsTitle,
        subtitle: _notificationsEnabled
            ? l10n.notificationsOn
            : l10n.notificationsOff,
        page: const NotificationsPage(),
      ),
      _Section(
        icon: Icons.language_rounded,
        title: l10n.languageTitle,
        subtitle: language,
        page: const LanguagePage(),
      ),
      _Section(
        icon: Icons.keyboard_rounded,
        title: l10n.shortcutsTitle,
        subtitle: l10n.shortcutsSubtitle,
        page: const ShortcutsPage(),
      ),
      _Section(
        icon: Icons.library_music_rounded,
        title: l10n.ambientMusicCredits,
        subtitle: l10n.musicCreditsSubtitle,
        page: const MusicCreditsPage(),
      ),
      _Section(
        icon: Icons.storage_rounded,
        title: l10n.dataTitle,
        subtitle: l10n.dataSubtitle,
        page: const DataPage(),
      ),
      // The coffee link makes no sense on a watch.
      if (!r.isWatch)
        _Section(
          icon: Icons.coffee_outlined,
          title: l10n.supportTitle,
          subtitle: l10n.supportSubtitleNoAds,
          page: const SupportPage(),
        ),
    ];
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(appPageRoute((_) => page));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppPreferences.showClock,
        AppPreferences.uiSize,
        LocaleController.locale,
        ModePrefs.changes,
        Haptics.changes,
      ]),
      builder: (context, _) {
        final sections = _sections(context, r);
        final selected = _selected.clamp(0, sections.length - 1);

        Widget tiles({required bool detail}) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < sections.length; i++)
                  SettingsNavTile(
                    icon: sections[i].icon,
                    title: sections[i].title,
                    subtitle: sections[i].subtitle,
                    selected: detail && i == selected,
                    onTap: () {
                      if (detail) {
                        setState(() => _selected = i);
                        _load();
                      } else {
                        _open(sections[i].page);
                      }
                    },
                  ),
              ],
            );

        if (!r.isExpanded) {
          return SettingsShell(
            title: context.l10n.settingsTitle,
            loaded: _loaded,
            children: [tiles(detail: false)],
          );
        }

        // Master-detail. The detail pages render embedded (no Scaffold) and
        // report changes back so the list's subtitles stay current.
        final listWidth = (r.size.width * 0.34).clamp(300.0, 420.0 * r.scale);
        return Scaffold(
          appBar: appTopBar(context, title: Text(context.l10n.settingsTitle)),
          body: SafeArea(
            top: false,
            child: Row(
              children: [
                SizedBox(
                  width: listWidth,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      r.pagePadding,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: tiles(detail: true),
                  ),
                ),
                Expanded(
                  child: SettingsPaneScope(
                    onChanged: _load,
                    child: AnimatedSwitcher(
                      duration: Motion.medium,
                      // Pin pages to the top; the default stack centers them.
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(selected),
                        child: sections[selected].page,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
