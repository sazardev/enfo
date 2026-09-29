# Changelog

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
