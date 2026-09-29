#!/usr/bin/env python3
"""Writes a rhythm envelope for every song in assets/music/*.ogg.

For each song: decode to mono 8 kHz with ffmpeg, take a short-time spectrum,
and combine two things per 1/20 s frame into one byte:
  * loudness (RMS), and
  * onset strength (positive spectral change below ~1 kHz, where kicks and
    snares live).
Both are normalized per song (99th percentile -> 255), so quiet and loud
songs pulse the same. Output: assets/music/envelopes/<name>.bin, raw uint8,
ENVELOPE_FPS values per second, no header. The app samples it with the
player's playback position (lib/modes/music/music_envelope.dart).

Usage: python3 tools/analyze_music.py      (needs ffmpeg and numpy)
"""
import glob, os, subprocess
import numpy as np

FPS = 20          # keep in sync with MusicEnvelope.fps
RATE = 8000
HOP = RATE // FPS  # 400 samples
WIN = 512
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def decode(path):
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(RATE),
         "-f", "s16le", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(out, dtype="<i2").astype(np.float32) / 32768.0


def norm(x):
    hi = np.percentile(x, 99)
    return np.clip(x / hi, 0, 1) if hi > 0 else np.zeros_like(x)


def envelope(samples):
    n = len(samples) // HOP
    pad = np.concatenate([samples, np.zeros(WIN)])
    window = np.hanning(WIN)
    rms = np.empty(n, np.float32)
    spec = np.empty((n, 64), np.float32)   # bins 0..63 = 0..~1 kHz
    for i in range(n):
        seg = samples[i * HOP:(i + 1) * HOP]
        rms[i] = np.sqrt(np.mean(seg * seg)) if len(seg) else 0
        frame = pad[i * HOP:i * HOP + WIN] * window
        spec[i] = np.abs(np.fft.rfft(frame))[:64]
    spec = np.log1p(spec * 20)
    flux = np.maximum(spec[1:] - spec[:-1], 0).sum(axis=1)
    flux = np.concatenate([[0], flux])
    e = 0.4 * norm(rms) + 0.6 * norm(flux)
    # A touch of decay so a hit lingers for a few frames.
    for i in range(1, n):
        e[i] = max(e[i], e[i - 1] * 0.75)
    return np.round(norm(e) * 255).astype(np.uint8)


def main():
    out_dir = os.path.join(ROOT, "assets", "music", "envelopes")
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for path in sorted(glob.glob(os.path.join(ROOT, "assets", "music", "*.ogg"))):
        env = envelope(decode(path))
        name = os.path.splitext(os.path.basename(path))[0] + ".bin"
        with open(os.path.join(out_dir, name), "wb") as f:
            f.write(env.tobytes())
        total += len(env)
        print(f"{name}: {len(env)} bytes ({len(env) / FPS:.0f} s)")
    print(f"total {total} bytes")


main()
