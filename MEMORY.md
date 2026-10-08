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

Targets: Android, Windows, Linux (web exists on a separate branch). Play
Billing donations and mobile notifications are Android-only; desktop uses
`local_notifier` + `window_manager`.

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
haptics/                the vibration system (see "Haptics" below)
l10n/                   ARBs + generated code + LocaleController
ui/                     atoms / molecules / organisms / templates / design
ui/clock/               63 flat timer visuals (ClockStyle, faces, combos)
widgets/                Android home-screen widgets: snapshot, frame rendering, bridge,
                        launch actions, settings page (native half: android/.../widgets)
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

**Haptics** (`lib/haptics/`). Nothing calls `HapticFeedback` or `Vibration`
directly: every place asks for a *named event* from one vocabulary
(`Haptics.tap()`, `select()`, `confirm()`, `toggle(on)`, `lap()`, `tick()`,
`dragStart()/drop()`, `transition()`, `warning()`, `success()`,
`phaseComplete(toRest:)`, `timerDone()`, `countdown(n)`, `ringCycle()`), so the
same gesture feels the same everywhere. Events live in `haptic_events.dart`
as lists of `Pulse(at, strength, length)`. The language is two-phase like a
physical button: press-down is a light tap (`BouncyTap`), a *decision* adds a
firmer beat (start = confirm; pause/resume = touch; reset/destructive =
warning). Wheels and steppers give one `tick` per notch; the last 3 seconds of
a timer tick once each and firm up; a Pomodoro phase change *fades away* going
to rest and *builds up* going to focus. Categories (touch / motion / alerts),
master switch, strength (soft/medium/strong, one multiplier for the whole
vocabulary so proportions hold) and the alarm pattern (heartbeat, pulse,
crescendo, ripple, beacon) are user settings (Settings > Vibration).
Rendering: tiny events use the platform engine (`HapticFeedback`), composed
events use amplitude patterns from the `vibration` package and fall back to a
timed sequence of system impacts when the device has no amplitude control.
Tiny events are debounced (22 ms) so a fast wheel doesn't smear into a buzz.
**Sync:** `RingingPage` restarts the vibration pattern, the sound and the
pulse animation together every `Haptics.ringPeriod`, and the disc's scale
follows `HapticEvent.envelopeAt` — the same envelope as the buzz. The Android
notification channel id includes the pattern and strength (Android freezes a
channel's vibration at creation) and carries `Haptics.notificationPattern`, so
a notification firing with the app closed feels like the in-app ringer. Use
`AppSwitch` (not `Switch`) so toggles get their haptic. Only phones vibrate:
`Haptics.available` is false on desktop, and the Vibration settings tile is
hidden there.

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

- `flutter analyze` — clean except the pre-existing lints in the
  `tool/store/` helper tests.
- `flutter test` — ~1950 tests: logic (timers, alarms, history, world clock),
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

- No `lib/secret.dart` and no API keys: Enfo has no ads and no ad SDKs.
  Donations use Google Play Billing (`lib/donate_page.dart`, product ids
  `enfo_donate_1/3/5/10/25`, Android only); those products must exist and be
  active in Play Console for the tiers to appear.
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

**Newer modes (section 10):** none was ever seen on a screen or run on a
device. Especially: real audio output (`flutter_soloud` compiled only on
Linux; Android may kill background playback, no foreground service), whether
the beat pulse feels in sync (`musicPosition` latency), OS notification
delivery for breaks/events/intervals/kitchen with the app closed, haptic feel
of the new events, the 180-degree flipped half in the versus clock, D-pad focus
on the pager, and every translation that is not en/es (written by the model).

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
3. **How the vibration actually feels.** The vocabulary, strengths and
   patterns were designed and unit-tested (event → platform call, scaling,
   ordering, sync) but never felt on a real motor. Expect to retune the
   strengths in `haptic_events.dart` and the micro-event crossover points in
   `Haptics._micro`. Also unverified: Core Haptics on iOS (`sharpness`),
   amplitude control on real Android devices, and per-channel vibration on
   notifications.
4. **Alarm/timer sound**: the ringer uses `SystemSound.alert` + haptics (no
   audio package, no custom tone). On Windows/Linux the system beep may be
   silent; the desktop toast is the reliable cue there.
5. **Full screen on real windows/devices** (`window_manager` on Linux/macOS
   is initialised lazily on first use) and **wakelock** on each platform.
6. **Every visual**, on real hardware (all checks were simulated renders).
7. **The whole widget native side** (`android/app/src/main/kotlin/.../widgets`,
   `res/layout/w_*.xml`, `res/xml/widget_*_info.xml`, manifest receivers):
   no JDK/Android SDK here, so it was never compiled. Cross-checked only that
   every `R.*` / `@…/` reference resolves and the XML is well formed. The
   Dart side (snapshot, frame rendering of all 63 styles, launch actions,
   bridge, pin page) is tested. On a device check: widgets appear in the
   picker, `autoSize` text in `RemoteViews`, `android:alpha="@dimen/…"`,
   the light/dark swap, Chronometer countdown at zero, exact-alarm wake-ups
   (`USE_EXACT_ALARM`), and that pinning works.

## 8. Android home-screen widgets

Seven Material You widgets (Clock, Analog clock, Pomodoro, Timer, Stopwatch,
Alarms, World clock). Pomodoro and Timer are drawn in the user's chosen one
of the 63 clock styles.

**Two halves, one contract.** Dart (`lib/widgets/`) watches the app state and
pushes one JSON snapshot (`widget_snapshot.dart`) through the
`com.sazarcode.enfo/widgets` MethodChannel; native (`android/.../widgets/`)
stores it in its own prefs file (`enfo_widgets`) and draws `RemoteViews` from
it. Native never reads Flutter's prefs. All times in the snapshot are
absolute wall-clock ms, so nothing goes stale with the app closed.

**What ticks by itself (no app, no updates):** `TextClock` (clock, world),
`Chronometer` (stopwatch, countdown readouts), `AnalogClock`.

**The clock styles are pictures.** `widget_frames.dart` renders the chosen
style off-screen (`offscreen_render.dart`: private build/layout/paint pipeline
around a `RenderRepaintBoundary`) to PNGs in `filesDir/widget_frames`, in a
light *and* a dark palette. A running countdown gets a timeline (max 30
frames, whole-second steps, last frame = the finished state); native shows the
frame for "now" and `Ticker` schedules an `AlarmManager` wake-up for the next
frame / countdown end / alarm passing. Light/dark are two stacked
`ImageView`s whose `android:alpha` comes from `@dimen/w_alpha_*` (flipped in
`values-night`), so the launcher swaps them itself on a theme change.
Frames are only rendered for kinds that are actually placed
(`activeKinds`), are cached by a signature of their inputs, and old sets are
pruned after each sync. `onEnabled` asks Dart to `resync` so a widget added
while the app runs gets its pictures.

**Colors.** Layouts use `@color/w_*`; `values-v31` maps them to the system
palettes (`system_accent1_*`, `system_neutral*`) so the launcher re-tints them
live. When the user turns Material You off (or Android < 12) `Look.kt` paints
the app's own palette (in the snapshot) over the defaults with
`setColorFilter`/`setTextColor`. The face pictures use
`ColorScheme.fromSeed(system_accent1_500)` in Material You mode.
Known small gap: the analog clock's drawables cannot be re-tinted at runtime,
so before Android 12 it keeps the static default colors.

**Buttons open the app.** Widget taps are `PendingIntent`s to `MainActivity`
with `widget_mode` / `widget_action` extras (`Launch.kt`);
`WidgetChannel` hands them to Dart (`takeLaunch` on cold start, `launch`
when running) and `widget_launch.dart` does the thing (open the mode, start a
timer preset, toggle stopwatch/timer/Pomodoro, lap). The logic stays in Dart
next to the controllers instead of duplicating timer state natively. The
trade-off: a widget button brings Enfo to the front. Pomodoro has no global
state, so `CountdownDial` mirrors itself into `PomodoroLive` (read-only) and
receives toggle requests from it.

**Settings > Widgets** (Android only, `widgets_page.dart`): pin any widget
(`requestPinAppWidget`) and the Material You switch (`WidgetPrefs`).

**Add a widget:** add a `WidgetKind` value, a provider class extending
`EnfoWidget`, an entry in `Widgets.all`, a layout + `res/xml/widget_*_info.xml`
+ strings, a manifest `<receiver>`, and a row in `_describe` in
`widgets_page.dart`.

**Traps hit:** `RenderObjectToWidgetAdapter` no longer exists (see
`_Host`/`_HostElement`); detach the render tree before unmounting or the
framework asserts; `intl` date data must be initialised before formatting
(`initializeDateFormatting` in `_push`); do not put a `data:` URI on widget
intents (Flutter treats it as a deep link and routes to it).

## 9. Known limits / ideas

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

## 10. More tools (added after the first six modes)

Nine extra modes, all **off by default** (`AppMode.core == false`;
`ModePrefs` keeps a `mode_seen` list so a mode the user was never offered
starts off, and existing installs are not flooded). The onboarding lists them
under "More tools". Every one has its own dir in `lib/modes/<name>/`.

| Mode | What it does | Notes |
| --- | --- | --- |
| event | Countdown to dated events, yearly repeat, notifications | dial shows days:hours in the mm:ss fields |
| intervals | HIIT/Tabata/EMOM phases, rounds | `IntervalsService`, `HapticEvents.go`, notif id 9100 |
| breathe | Box, 4-7-8, coherent, calm, custom | pure `breatheAt(pattern, ms)`, haptic cues |
| tracker | Time-track activities, 7-day chart | logs `ToolKind.tracker`; history label = activity name (renaming orphans old history) |
| kitchen | Several named timers at once | notif ids 9200-9299 |
| sleep | 90-min cycle planner, sets real alarms | alarm ids kept in prefs `sleep_alarm_id/_wind_id` |
| versus | Two-player chess-style clock + speaker agenda | setup persisted, running game is not |
| breaks | 20-20-20 / stretch / water / posture reminders + relax sound | ids 70100+, `RingRequest.gentle` (shared with ringing_page); the relax picker plays the nature loops through `AmbientService` |
| ambient | Synth noise (white/pink/brown/rain/wind/ocean) + 20 place loops, sleep timer | `flutter_soloud`; sleep timer also stops music |
| music | 72 bundled lo-fi songs, big-title pager + clock-style dial | see below |

Plumbing worth knowing:
- `mode_services.dart`: `ModeService` (`load()` at boot, `check()` on the
  host's 1 s heartbeat) for state that outlives a page.
- `ToolKind` gained intervals/breathe/tracker/kitchen/versus; `activity_page`
  renders them generically (filter "more").
- `ToolHistory.add` is serialized (read-modify-write race). The chain is per
  zone (`_lastZone`) because a write pending in a finished test's fake-async
  zone would hang the next test; `debugResetQueue()` also exists.
- `AppData`: `eraseAll` wipes every new service; `resetSettings` keeps the
  user's content (`events`, `tracker_state`, `kitchen_timers`, sleep alarm ids).
- `tools/add_l10n.py` merges strings into all 9 ARBs under a lock and runs
  `flutter gen-l10n`. Never edit the ARBs by hand for new keys.
- `bar_buttons.dart`: Settings > Display > "Menu buttons" hides stats, clock
  style, modes, next mode and full screen in every mode's bottom bar
  (`BarButtonVisibility`). Settings itself can never be hidden.
- Theme: first run follows the system (`AdaptiveThemeMode.system`);
  `ThemeModeSelector` (System/Light/Dark) is used by onboarding + Appearance.
- Onboarding steps: language, tools, rhythm (if Pomodoro), look (theme +
  combos + accent, live preview pinned below), display, options, permissions
  (Android only: notifications + exact alarms via `Notifier`).

### Music
- 72 songs in `assets/music/` (~67 MB, ~3 h) from two collections with a
  checked license. 14 are Wikimedia Commons (10 CC0 + 4 CC BY: Kuromaru,
  Raspberrymusic, Sappheiros, Kevin MacLeod). 58 come from the Open Lo-Fi
  GitHub release (`btahir/open-lofi`: 166 tracks generated with Suno v5 and
  dedicated to CC0 by their author). Credits: `assets/music/CREDITS.md`,
  `lib/modes/ambient/music_catalog.dart`, the Settings > Music credits page
  and the docs site (regenerate with `tools/sync_site_assets.sh`).
  archive.org's "CC0" flag is NOT reliable (it lists commercial albums): only
  use Commons, a release that carries its own LICENSE, or an artist's own
  release. The catalog test allows Commons and the Open Lo-Fi repo as `source`
  hosts only.
- The 58 Open Lo-Fi tracks are deliberately degraded and tiny: mono 32 kHz,
  Vorbis q0 (~43 kbps average, under 1 MB each) after a lo-fi chain (9.5 kHz
  low-pass, tanh saturation, tape wow, a whisper of pink-noise hiss), then
  normalised per track to -15 LUFS (two ffmpeg passes). Selection favours the
  instrumental categories (focus/routines, ambient, chillhop, jazz lounge,
  Asian/zen, late night); the vocal soul/funk batches were left out.
- The Commons songs were picked from titles, never listened to. The Loyalty
  Freak tracks are more lo-fi indie than lo-fi hip hop.
- UI is deliberately minimal: `TitlePager` (swipe/wheel/arrows) + the mode's
  play/pause in the bottom bar; the dial is a normal `ClockStyle` (progress =
  song position). Rhythm is precomputed: `tools/analyze_music.py` writes
  `assets/music/envelopes/*.bin` (20 fps uint8 loudness) sampled with the
  playback position; it drives the animation clock and a subtle pulse.
  Regenerate the envelopes when songs change.

### Ambience
- 40 recorded loops in `assets/ambience/` (~15 MB, 24-75 s each): 20 nature
  (Breaks > relax sound, `natureLoops`) and 20 places (Ambient, `placeLoops`).
  All from Wikimedia Commons with a per-file checked license (CC0, public
  domain or CC BY); credits: `assets/ambience/CREDITS.md`, the generated
  `lib/modes/ambient/ambience_catalog.dart` and the Settings > music credits
  page. `tools/fetch_ambience.py` is the source of truth: it verifies the
  license, builds a *seamless* loop (tile with 0.5 s crossfades when the
  source is short, then fold a 2 s tail into the head), applies the lo-fi
  chain (40 Hz high-pass, 10 kHz low-pass, tanh saturation), normalises to
  the same RMS as `AmbientSynth` and encodes mono 32 kHz Vorbis q0. Re-run
  it (or `--catalog-only`) when the sound list changes.
- `AmbientService` now selects either a synth sound or an `AmbienceLoop`;
  the loop plays via `AmbientPlayer.startAsset` (Ogg streamed from disk,
  looping) and `ambient_loop` / `ambient_breaks_loop` are persisted
  separately, so picking a place in Ambient does not lose the Breaks choice.
  The Breaks status card has a compact play/pager for the nature loops; both
  modes share the one bed, the volume and the sleep timer.
- Labels are localized in the 9 languages (`ambience<Id>` keys in the ARBs,
  mapped by `lib/modes/ambient/ambience_labels.dart`; keep the switch and the
  keys in sync when adding a loop).

## 11. Terminal UI (`tui/`)

A separate Go module (Bubble Tea v2 / Lip Gloss v2 / Bubbles / Huh / Glamour / Harmonica / Fang / Wish)
with the same toolbox as the app, drawn in braille dots: Pomodoro (7 faces), clock (5 designs), timer,
stopwatch, alarms, world clock with a day/night braille map, breathing, plus off-by-default extras
(intervals, kitchen, event, breaks, sleep, tracker, versus), stats and settings pages, a CLI
(`enfo status --waybar`, `stats`, `doctor`, `timer 10m --start`, `serve` over SSH) and a background waker that still
notifies after the terminal is closed. **`tui/MEMORY.md` is the write-up** (architecture, decisions, traps, unverified list);
`tui/README.md` is the user-facing doc. Versioned independently (tag `tui-vX.Y.Z`, currently 0.1.0).

- Same rule as the app: engines store absolute instants, never a ticking counter.
- Module path is `github.com/sazardev/enfo/tui`. Tests: `cd tui && go test ./...` (UI render matrices at 1x1..250x70,
  engine logic, an i18n test that keeps es/en complete and checks every `i18n.T("key")` exists).
- No GUI needed to verify: `vhs` renders real screenshots (`make demo`; see `tui/demo/demo.tape`); tmux works for smoke tests.
- Gotchas: never use emoji-presentation glyphs in the TUI (terminals measure/draw them differently); slicing
  escape-coded strings with `ansi.Cut` repeatedly grows them exponentially (use `ui.stamp`, which re-parses cells);
  braille dots are square only if a terminal cell is ~2x as tall as wide.
- **Unverified:** real-terminal feel (fonts differ in how big they draw braille dots), light-terminal palette,
  sound/notification delivery on a real desktop, `enfo serve` beyond one key login, non-Linux platforms.
