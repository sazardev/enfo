# Enfo on Android TV / Google TV

This is the working checklist for the TV build. It mirrors the official
[Create and run a TV app](https://developer.android.com/training/tv/get-started/create),
[TV apps checklist](https://developer.android.com/training/tv/publishing/checklist)
and [Distribute to Android TV](https://developer.android.com/training/tv/publishing/distribute)
pages.

## Manifest (done)

- `android.software.leanback` — `required="false"` (Enfo ships on phones,
  tablets and TV with one bundle).
- `android.hardware.touchscreen` — `required="false"`.
- `CATEGORY_LEANBACK_LAUNCHER` on `MainActivity`.
- `android:banner="@drawable/tv_banner"` on `<application>`.
- Banner: `android/app/src/main/res/drawable-xhdpi/tv_banner.png`, 320 × 180 px,
  with the “enfo” wordmark (language-neutral).

The activity deliberately does **not** force `android:screenOrientation="landscape"`.
A TV runs it in landscape anyway, while the same APK must keep portrait working
on phones. The Flutter layout is landscape-first on TV (960 × 540 dp).

## TV behaviour (done in code)

- `lib/tv/tv_mode.dart` asks the Android side (`MainActivity.kt`, channel
  `com.sazarcode.enfo/tv`) whether the device is a TV. Detection uses
  `FEATURE_LEANBACK`, `FEATURE_TELEVISION` and `UiModeManager`.
- TV gets 5% / 3.5% overscan-safe padding, merged with the system insets, and
  starts at the `large` UI size unless the user already saved one.
- `BouncyTap` now has a high-contrast focus ring (2.5 dp) and a stronger halo
  on TV. It also scrolls the focused control into view.
- `TvHintBar` (TV only) shows the focused control’s label plus **OK Select**
  and **Back**; it hides in full screen.
- Full screen: any D-pad key reveals the controls; hidden controls are
  `ExcludeFocus`d so focus cannot land on an invisible button.
- `TitlePager` no longer eats Up/Down on TV; the remote can leave the music /
  ambient pager for the action rail.
- Modes and World clock get focusable up/down buttons on TV instead of a
  drag-only handle.
- Timer presets get an explicit remove button on TV (long-press is not a
  remote action).
- Splash / onboarding: the first focus is the forward button, and off-screen
  wizard pages are excluded from focus.
- Settings uses a single column on TV (Back returns to the list) and hides
  phone-only sections: home-screen widgets, haptics, review/share/donations.
- Sliders show a focus overlay on TV; `SliderTheme` keeps the flat look on
  phones.
- Clock-style grids pre-build extra rows on TV so D-pad traversal can reach
  the next item.

## Play Console status

- **Android TV form factor added** on 2026-10-21 in
  Setup → Advanced Settings → Form factors.
- The TV form factor uses the **same release track and artifacts as mobile**
  (one AAB for phone + TV). A dedicated TV track was tried first, but it
  requires `android.software.leanback required="true"`; the shared track is
  the right choice for this adaptive app.
- **1.9.0 (version code 15) is live on internal testing**, and the track
  summary now includes Android TV. Internal testers can install it on Google
  TV.
- The default (es-419) store listing has the **1280×720 TV banner** and
  **5 TV screenshots** (Pomodoro, Timer, Settings, Modes, full-screen Clock);
  the full description mentions Android TV. English also has the Android TV
  paragraph and inherits the TV graphics.
- The listing changes are in **Publishing overview** waiting for the quick
  checks to finish before they can be submitted for review. The Advertising
  ID declaration was corrected to **No** (no ads/analytics SDKs).
- Still pending: submit the four listing changes, then complete **Opt-in to
  Android TV and agree to the review policy**. The opt-in task remains locked
  until every store listing has TV graphics and the listing changes are
  submitted/published.
- **16 KB page size verified** in the AAB: `libflutter.so` and `libapp.so`
  have 64 KB LOAD alignment; `libflutter_soloud_plugin.so` has 16 KB.

## Play Console (to do once, with the next AAB)

1. **Build and upload** an AAB that includes the TV manifest/banner.
2. **Store listing → Android TV**
   - Add at least one TV screenshot: 1920 × 1080 or 1280 × 720, 16:9, no alpha.
   - The TV banner is in the app bundle; keep `store/tv/banner-320x180.png` as
     the source asset.
   - Mention “Android TV” in the full description.
3. **Setup → Advanced Settings → Form Factors**
   - **Add release type → Android TV**.
   - Accept the TV review policy.
4. **Pricing and distribution → Android TV** — watch the review state:
   pending, approved, not approved.
5. The same package name (`com.sazarcode.enfo`) and AAB are used for phone and
   TV; Play keeps separate tracks.

## Quality gates

- 64-bit **and 16 KB page size** support (Play requirement since 2026-08-01).
  The current bundle targets API 36 and includes `arm64-v8a`; verify with
  `bundletool`/Play pre-launch before rollout.
- D-pad only: no interaction may require touch, long-press or drag.
- 10-foot UI: focus ring visible before the first key press; text readable
  from ~3 m; overscan safe.
- Ambient Mode: the Clock mode keeps the screen awake with a wakelock; full
  screen drifts and dims to avoid burn-in.
- Alarm: verify with the app closed and the TV asleep. `fullScreenIntent` is
  set for alarms; TV has no notification shade, so this is the critical path.
- Performance: test a low-end Google TV device (Chromecast/TCL class), not
  only an emulator. The style picker previews are the heaviest screen.

## Test commands

```bash
flutter analyze
flutter test

# Emulator (TV 1080p, Google TV image)
adb shell input keyevent 19   # up
adb shell input keyevent 20   # down
adb shell input keyevent 21   # left
adb shell input keyevent 22   # right
adb shell input keyevent 23   # OK
adb shell input keyevent 4    # Back
adb shell input keyevent 85   # play/pause
```

The current emulator used for this work is `Enfo_TV`
(`system-images;android-36;google-tv;x86_64`, `tv_1080p`).

## Store assets

- `store/tv/banner-320x180.png` — exact banner bundled in `drawable-xhdpi`.
- `store/tv/banner-1280x720.png` — the 1280×720 banner Play Console asks for.
- `store/tv/screenshots/<lang>/` — 1920×1080 TV screenshots for English and
  Spanish.

Regenerate the screenshots with the real app (no debug banner, real TV
padding, focus ring and hint bar):

```bash
flutter test tool/store/tv_shots_test.dart \
  --dart-define=TV_SHOTS_LANGS=en,es
```

The generated PNGs are RGBA; convert them to RGB (no alpha) before uploading:

```bash
python3 - <<'PY'
from PIL import Image
import glob
for p in glob.glob('store/tv/screenshots/*/*.png'):
    Image.open(p).convert('RGB').save(p)
PY
```

## Known follow-ups

- Real-hardware test of alarm audio and full-screen intent on TV.
- 16 KB page-size build verification.
- Optional: Android TV `DreamService` (Enfo as the TV screensaver).
