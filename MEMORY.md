# Enfo — project memory

Living notes for whoever (person or agent) works on this repo next: what the
app is, how it is put together, the decisions that are not obvious from the
code, the traps already hit, and what has **not** been verified. Written
from several working sessions (dependency upgrade, UI redesign, statistics,
i18n, responsive layout, clock styles, and the "modes" transformation).

## 1. What Enfo is now

Enfo started as a minimalist Pomodoro timer. It is now a **clock and timer
toolbox** where Pomodoro is one mode among six:

| Mode | What it is |
| --- | --- |
| Pomodoro | The original focus/rest timer, drawn with 63 selectable clock styles |
| Clock | A premium always-on clock: 5 designs, full screen "desk/nightstand" mode |
| Timer | Countdown with hour/minute/second wheels, saved presets, same clock styles |
| Stopwatch | Laps (best/slowest highlighted), runs to hundredths, survives restarts |
| Alarm | Repeating/one-shot alarms, snooze, rings full screen |
| World clock | Cities with real time zones and daylight saving, editable/reorderable |

A **quick-switch button** in the bottom bar cycles through the enabled modes;
a **Modes menu** lets the user turn modes on/off, drag to reorder, pick the
start mode and customize the clock. Everything that happens is recorded in a
unified **Activity** history.

Targets: Android, Windows, Linux (web exists on a separate branch). Ads and
mobile notifications are Android-only; desktop uses `local_notifier` +
`window_manager`.

## 2. Ground rules of the codebase

- **Strictly flat design.** No borders, gradients or shadows. Selection is
  shown by morphing shape (circle → squircle) or tonal fill. Focus (D-pad /
  keyboard) is a soft tinted halo, not an outline. The only gradients are the
  hue/saturation/brightness tracks of the custom color picker, which are
  functional.
- **No modals.** No dialogs, no bottom sheets, no system time/date pickers.
  Destructive actions confirm in place (`ConfirmActionRow`); pickers are
  inline (wheels, `AccentPicker`, `ColorPickerPanel`).
- **Mono font.** Geist Mono is bundled under `assets/fonts/` and used
  everywhere. Build text themes from a real `ThemeData(...).textTheme`, never
  straight from `Typography.material2021(...).englishLike` (color-less: text
  turns near-invisible).
- **Two languages.** Spanish and English, everything through
  `context.l10n` (or `currentL10n()` outside the widget tree, e.g.
  notifications). Strings live in `lib/l10n/app_en.arb` + `app_es.arb`; the
  `gen-l10n` output is committed in `lib/l10n/gen/`. Anything not Spanish
  falls back to English. Language is user-selectable (`LocaleController`).
- **Shared files are edited surgically.** Several agents/sessions worked in
  this repo at once. Prefer small targeted edits to `home.dart`,
  `home_shell.dart`, `main.dart`, `settings.dart`, `app_data.dart`, the ARBs
  (always merge JSON, never overwrite).

## 3. Layout of `lib/`

```
main.dart               boot: prefs, theme, locale, modes, tz data, controllers
home.dart               the Pomodoro screen (kept alive by ModeHost)
onboarding.dart         5-step first-run wizard, every choice applied live
settings.dart           hub: list on narrow, master-detail when >= 840 dp wide
*_page.dart             one settings page each (timers, appearance, display,
                        notifications, language, support, data, clock styles)
stats.dart              Pomodoro statistics
history.dart            PomodoroSession + SessionHistory + SessionStats
app_preferences.dart    simple toggles as ValueNotifiers (clock bar, 12/24h,
                        auto-start, haptics, UI size)
app_data.dart           the one place that wipes data (reset / erase all)
theme.dart              accent is a Color (Themes.accent), 32-color palette
modes/                  the toolbox (see below)
l10n/                   ARBs + generated code + LocaleController
ui/                     atoms / molecules / organisms / templates / design
ui/clock/               63 flat timer visuals (ClockStyle, faces, combos)
```

### `lib/modes/`

```
app_mode.dart           enum AppMode (+ icons, localized names/descriptions)
mode_prefs.dart         order, visibility, current, start mode (ValueNotifiers)
mode_host.dart          ROOT of the app; shows the current mode; 1 s heartbeat
mode_pages.dart         AppMode -> screen
mode_scaffold.dart      shell for non-Pomodoro modes (same layout as Home)
mode_actions.dart       modes menu / next mode / full screen buttons
modes_page.dart         customize modes (toggle, drag to reorder, start mode)
fullscreen.dart         immersive state, wakelock, dim levels, display history
immersive_view.dart     full-screen layout: auto-hiding controls, burn-in drift
alerts.dart             ring queue;  ringing_page.dart  the full-screen ringer
notifier.dart           immediate + scheduled OS notifications
tool_history.dart       ToolEvent log (timer/stopwatch/alarm/display)
activity_page.dart      unified history (pomodoro + tools), filters, laps
clock/                  clock designs, prefs, settings page, TimeBuilder
timer/  stopwatch/  alarm/  world/
```

## 4. Architecture decisions worth knowing

**ModeHost keeps the Pomodoro alive.** The Pomodoro countdown is driven by an
`AnimationController`; tearing it down on a mode switch would abandon a
running session (and dispose saves the session as abandoned). So once shown,
`Home` stays in the tree under `Offstage` (with `ExcludeFocus`, tickers
still running). Do **not** wrap it in `TickerMode(enabled: false)`: a muted
ticker jumps forward on unmute and the completion fires late.

**Every other tool is timestamp-driven and global.** `TimerController`,
`StopwatchController` and `AlarmService` are singletons that store absolute
times (`endsAt`, `runStart`, next occurrence) — never a ticking counter. They
therefore keep exact time while another mode is open, and are persisted to
prefs so they survive the app closing. `ModeHost` calls `check()` on them
every second, whichever mode is visible.

**Alerts.** Anything that must interrupt (timer done, alarm) calls
`Alerts.ring(RingRequest)`. `ModeHost` pushes `RingingPage`; simultaneous
alerts queue. The page repeats `SystemSound.alert` + vibration every 2 s and
gives up after 2 minutes (alarms log that as `missed`).

**Alarms have two layers.** (1) In-app: `AlarmService.check` rings when due —
this is what works on desktop and whenever the app is open. (2) OS: on
Android/iOS `Notifier.schedule` queues notifications (`AndroidScheduleMode.
alarmClock`) for the next 14 days, one id per calendar day, so it still rings
with the app closed. The 14-day window rolls forward each time the app opens.
An occurrence more than 10 minutes old is logged as missed instead of rung
late. Editing/re-enabling an alarm never rings for a time already past today.
Snoozing a one-shot alarm re-enables it until the snooze rings.

**Full screen.** `HomeShell` swaps to `ImmersiveView` when
`Fullscreen.active` — so *every* mode (Pomodoro included) gets full screen for
free. It hides all chrome, keeps the screen awake (`wakelock_plus`), can dim,
and drifts a few pixels each minute against burn-in. Desktop uses
`window_manager.setFullScreen`; mobile uses immersive system UI. Time spent
in full screen (>= 60 s) is logged as a `display` event. The Clock mode can
also keep the screen awake without full screen (pref, default on).

**Clock mode redraws sparingly.** Only the analog second hand runs at frame
rate; every other design updates once per second, aligned to the real second
boundary (`TimeBuilder`). A clock left on all night should not redraw 60×/s.
`nowProvider` (in `time_builder.dart`) is the injectable "now" used by every
mode; tests freeze it.

**Time zones.** `timezone` with `latest_10y` (compact: canonical zones only).
A few cities borrow a canonical zone (`WorldCity.zone`; Amsterdam→Brussels,
Oslo/Stockholm→Berlin, Addis Ababa→Nairobi), so identity is `WorldCity.id`,
never the zone. A test checks every zone exists.

**Data lifecycle** (`app_data.dart`). All state is `shared_preferences`; there
is no other cache. `resetSettings` removes every key except the user's
*content* (Pomodoro history, tool history, alarms, timer state/presets,
stopwatch state, world cities, onboarded flag); it removes by exclusion so
future settings are covered automatically. `eraseAll` clears everything and
lands on onboarding. Gotchas: `adaptive_theme` keeps its mode in a *separate*
store (`SharedPreferencesAsync`), so `DataPage` resets it explicitly; and
`CountdownDial.dispose` saves the running session, so `SessionHistory.clear`
stamps `_clearedAt` and `add()` drops sessions started before it.

**Responsive system** (`ui/design/responsive.dart`). `Responsive.of(context)`
classifies the window: watch (< 260 dp shortest side; kept below Windows'
310x280 minimum window), compact, medium, expanded; plus `scale` (1.0 on
phones up to 1.5, times the user's `UiSize`). `main()` multiplies text and
icon scale by it. TV/watch/car are detected by *size only*, so a 960x540 dp
TV is "expanded" and relies on the UI-size setting. Layouts: `HomeShell` is a
column (portrait), dial + side panel (wide) or dial only (watch);
`SettingsShell` caps content width and goes embedded (no Scaffold) inside the
master-detail hub. `BouncyTap` is focusable (D-pad, keyboard, rotary).
Use `appTopBar` instead of a bare `AppBar`.

**Onboarding** applies each choice immediately (language, rhythm, theme +
accent, clock combo, options). Its tests must not `pumpAndSettle` on the clock
step (a 1 h animation runs there).

**Accent color** is a `Color` (`Themes.accent`, pref `accent_color`, legacy
pref `defaultIndex` still migrates). The first 16 entries of `Themes.colors`
must never be reordered.

## 5. How to verify (no GUI available in the authoring sandbox)

- `flutter analyze` — clean except the pre-existing `admob_id` naming lint in
  the gitignored `lib/secret.dart`.
- `flutter test` — ~370 tests: logic (timers, alarms, history, world clock),
  widget flows for every mode, data wipe, i18n, onboarding, and **responsive
  matrices** that render every screen at watch / phone / landscape / tablet /
  TV / desktop sizes (normal and full screen) and fail on any overflow.
- `test/test_harness.dart` builds a MaterialApp wired like `main()` and loads
  the real Geist Mono via `FontLoader` (the default test font, Ahem, is far
  wider and reports overflows that do not exist).
- **Visual checks without a display:** render a screen in a widget test with
  `matchesGoldenFile('/tmp/shots/x.png')` and `--update-goldens`, then look at
  the PNG. Material icon glyphs appear as empty boxes there (font not loaded);
  they are fine in the real app.
- `flutter build linux --debug` compiles. Running the binary is not
  verifiable in this sandbox (Mesa/Zink fails under WSLg).

## 6. Build environment

- `lib/secret.dart` is gitignored and must define
  `const String admob_id = '...'` or nothing compiles on any platform (it is
  imported unconditionally by `support_page.dart`). Google's test interstitial
  id works for development: `ca-app-pub-3940256099942544/1033173712`.
- Linux needs `libnotify` (`sudo pacman -S libnotify` on Arch/CachyOS). A
  stale `build/linux/**/CMakeCache.txt` with `CMAKE_INSTALL_PREFIX=/usr/local`
  makes later builds try to install system-wide: `flutter clean`.
- `adaptive_theme` is pinned to exactly `3.7.2`; 3.8.0 switched to the
  standalone `material_ui` `ThemeData` type, which does not match
  `MaterialApp` on Flutter 3.47.
- `flutter_local_notifications` 22 uses named parameters everywhere;
  `circular_countdown_timer`'s `isStarted/isPaused` are `ValueNotifier`s.
- Android needs `minSdkVersion 24`.

## 7. NOT verified — check on a real machine

There is no Android SDK, no device and no GUI in the authoring environment.
Written carefully against the plugin APIs but **never run**:

1. **Everything Android**: `flutter build apk`, the new manifest entries
   (exact-alarm / full-screen / boot permissions, the three
   `flutter_local_notifications` receivers, `showWhenLocked`/`turnScreenOn`)
   and `coreLibraryDesugaringEnabled` + `desugar_jdk_libs:1.2.2`. The project's
   old AGP 7.2.0 / Gradle 7.5 may need bumping for the newer plugins.
2. **Alarms ringing with the app closed** (OS-scheduled notifications) and the
   permission flow (`Notifier.requestPermissions`). `USE_EXACT_ALARM` is
   granted automatically only to apps whose core function is an alarm clock,
   timer or calendar.
3. **Alarm/timer sound**: the ringer uses `SystemSound.alert` + haptics (no
   audio package, no custom tone). On Windows/Linux the system beep may be
   silent; the desktop toast is the reliable cue there.
4. **Full screen on real windows/devices** (`window_manager` on Linux/macOS
   is initialised lazily on first use) and **wakelock** on each platform.
5. **Every visual**, on real hardware (all checks were simulated renders).

## 8. Known limits / ideas

- **Wear OS** needs its own watch APK/module to be installable from Play; the
  manifest only declares watch/leanback/touchscreen as optional features.
  The UI adapts to small screens but that is not a Wear app.
- **Android TV** listing needs a 320x180 banner (`android:banner`); not added.
- **Android Auto / Automotive** only allow specific app categories; an
  alarm/timer app is not one of them. The wide layout works on a car-sized
  screen but distribution there is not possible.
- Desktop alarms only ring while Enfo is running.
- Alarm snooze length is fixed at 5 minutes.
- Pomodoro/timer share the chosen clock style; the clock mode has its own.
- The Clock mode's world/day faces do not use the 63 timer styles (those draw
  countdown progress, not time of day).
