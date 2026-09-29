# Promo videos

| File | What | Size |
| --- | --- | --- |
| `enfo_promo_portrait.mp4` | 1080x1920, 30 fps, 47.4 s, AAC audio | ~4.9 MB |
| `enfo_promo_landscape.mp4` | 1920x1080, 30 fps, 47.4 s, AAC audio | ~4.1 MB |
| `enfo_hero_loop.mp4` / `.webm` | 1920x1080, 8 s seamless-ish loop, no audio | ~0.1 MB each |

The footage is the real app (`ModeHost`) driven by a widget test with taps and
swipes; time is frozen but advances 1/30 s per rendered frame. Captions, touch
dots, progress bar and the outro card are composited afterwards (flat, Geist
Mono). Pomodoro is set to 2 minutes only so the dial visibly moves.

## Soundtrack credit

"Chill Beat" by Maddy, CC0 (public domain), from Wikimedia Commons
(`assets/music/01_chill_beat.ogg`). CC0 needs no attribution; listed here for
completeness. Fade in/out and loudness normalisation (-16 LUFS) via ffmpeg.

## Regenerate

```
ORIENT=portrait  flutter test tool/store/video_test.dart
ORIENT=landscape flutter test tool/store/video_test.dart
python3 tool/store/make_video.py        # needs ffmpeg (libx264, libvpx-vp9) + Pillow
```

Frames go to `/tmp/enfo_video/<orient>/` (not the repo). `STRIDE=15` records
every 15th frame for a quick look (the compositor needs the default STRIDE=1).
