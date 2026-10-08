# Changelog

## 1.6.0 (build 12)

### New
- **40 ambience loops** recorded from Wikimedia Commons (CC0, public domain
  and CC BY), seamless and tiny (mono 32 kHz Vorbis q0 after the same
  deliberate lo-fi chain as the music bank): 20 nature sounds for the Breaks
  mode (stream, forest, rain, campfire, geysers…) and 20 places for Ambient
  (office, library, city, café, subway, train…).
- **Breaks > relax sound**: a compact picker with the nature loops and its
  own play/stop; the sound keeps playing in other modes and follows the
  ambient volume and sleep timer.

### Changed
- Ambient's list now mixes the six synthesized noises with the 20 place
  loops; a recorded loop streams from disk and loops gaplessly.
- The music credits page, `assets/ambience/CREDITS.md` and the store listing
  cover the new sounds.

### Developer notes
- `tools/fetch_ambience.py` verifies each Commons license, builds the
  seamless loops (tile + fold crossfades), encodes them and regenerates the
  Dart catalog; `upload_play_bundle.py` gained `--notes`-less localized
  release notes in the previous release.

## 1.5.0 (build 11)

### New
- **72 lo-fi songs** in the music mode, up from 14: 58 new tracks from the
  Open Lo-Fi collection (CC0, generated with Suno v5 and dedicated to the
  public domain), spanning focus, ambient, chillhop, jazz lounge, Asian and
  late-night moods.
- The new tracks get a deliberate lo-fi treatment (9.5 kHz low-pass, tape
  saturation and wow, a whisper of pink-noise hiss, mono 32 kHz, Vorbis q0)
  that leaves each one under 1 MB, so eight times the music adds far less
  than eight times the size.

### Changed
- Music credits cover both collections in Settings, `assets/music/CREDITS.md`
  and the website; the store listing now says 72 songs.

## 1.4.0 (build 10)

### New
- **Donations**: support Enfo with a one-time donation through Google Play
  Billing, in five amounts with prices localized by Google Play. The Support
  page gains a Donate entry on Android; the coffee link stays for everyone.
- Donation strings in all nine languages.

### Changed
- Enfo remains completely ad-free: no ad SDKs and no trackers are bundled.

## 1.3.3 (build 9)

### New
- **No more ads**: Enfo is completely ad-free. The ad SDK is gone; the
  support page keeps only the coffee link, and the app no longer needs
  `lib/secret.dart`.
- **Live notification cards**: ongoing timer and Pomodoro notifications with a
  live countdown, progress bar, monochrome icon and lock-screen visibility.
- **Lock-screen media session** for the lo-fi player: MediaStyle notification
  with generated cover art, play/pause/next/previous, and playback with the
  screen off.
- **Two new home-screen widgets**: Music and Focus (nine widgets in total).

### Developer notes
- Android build migrated to declarative Gradle plugins (AGP 9, Gradle 9.3,
  compileSdk 37) with release signing wired.
- `keep.xml` keeps the notification icons through the release resource
  shrinker.

## 1.2.0 (build 5)

### New
- **New logo**: a lowercase "e" drawn as the timer ring, its crossbar the clock
  hand with a pivot dot. Replaces the cartoon watch everywhere: Android
  launcher (adaptive and themed/monochrome icon), Windows icon, Play icon,
  feature graphics, website and favicon.
- **Splash screen**: the logo builds itself and the wordmark settles in (about
  2 s, tap to skip, respects reduced motion). Shown on every launch after the
  first.
- **Welcome step** at the start of the onboarding: the same build animation,
  then the greeting and tagline (all 9 languages). The language step is now
  titled "Your language".
- **Marketing kit** on the website: a ZIP with the logo (SVG, PNG in every size,
  light/dark/mono, lockups), cover banners, Play graphics, screenshots, promo
  videos and logo reveal animations (including a transparent WebM).

### Changed
- Promo videos end with the logo build instead of plain text.
- The website shows the animated logo and a cover banner in "In your pocket".

### Developer notes
- `tools/make_logo.py` regenerates every icon from one geometry;
  `tools/make_marketing_kit.py` builds the kit; `tools/brand_draw.py` draws the
  mark and its animation in Pillow, matching `lib/ui/brand/enfo_mark.dart`.

## 1.1.0 (build 4)

### New
- **Nine more tools**, off by default (turn them on in the onboarding's
  "More tools" or the Modes menu): Events (countdown to a date), Intervals
  (HIIT / Tabata), Breathe, Tracker (time your activities), Kitchen (several
  named timers), Sleep (90-minute cycle planner that sets alarms), Turns
  (two-player clock and speaker agenda), Breaks (20-20-20, stretch, water,
  posture reminders) and Ambient (noise and soundscapes with a sleep timer).
- **Music mode**: 14 bundled lo-fi songs (CC0 and CC BY; credits in
  Settings) with a minimal swipe-through-titles UI and a clock-style dial that
  follows the song's time and rhythm.
- **Meeting planner** in the World clock: find the hours when every city is at
  work.
- **Menu buttons** setting (Settings > Display): hide statistics, clock style,
  modes, next mode or full screen from the bottom menu.
- **Onboarding** rewritten: language, tools, rhythm, look (theme + clock combos
  + custom color, with a live preview), display, options and, on Android,
  notification permissions.
- Theme mode System / Light / Dark; first run follows the system.

### Changed
- Statistics and activity history also cover the new tools.
- Resetting settings keeps what you created (events, tracked activities,
  kitchen timers, sleep alarms).
- `ToolHistory` writes are serialized so simultaneous events are not lost.

### Developer notes
- New strings go through `tools/add_l10n.py` (all 9 languages).
- `tools/analyze_music.py` regenerates the rhythm envelopes in
  `assets/music/envelopes/` when songs change.
- Not verified on a device: audio playback (`flutter_soloud` was only built for
  Linux), notification delivery, haptics, rhythm sync. See `MEMORY.md`.
