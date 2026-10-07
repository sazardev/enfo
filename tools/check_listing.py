#!/usr/bin/env python3
"""Validate the Play Store listing kit against Play Console limits.

Usage: python3 tools/check_listing.py
Exit code 1 if any check fails.
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "store"
LOCALES = ["en-US", "es-419", "es-ES", "de-DE", "fr-FR", "pt-BR",
           "hi-IN", "ja-JP", "ko-KR", "zh-CN"]
LIMITS = {"title": 30, "short_description": 80, "full_description": 4000,
          "whats_new": 500, "feature_graphic_tagline": 80,
          "video_title": 100, "video_description": 5000}
HEADLINE_MAX, HEADLINES = 28, 8
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿️]")
errors = []


def read(p):
    return p.read_text(encoding="utf-8").rstrip("\n")


def check(label, text, limit):
    n = len(text)
    if n > limit:
        errors.append(f"{label}: {n} > {limit}")
    if n == 0:
        errors.append(f"{label}: empty")
    if EMOJI.search(text):
        errors.append(f"{label}: contains emoji")
    return n


print(f"{'locale':8} " + " ".join(f"{k[:9]:>9}" for k in LIMITS))
for loc in LOCALES:
    row = []
    for name, lim in LIMITS.items():
        p = ROOT / "listing" / loc / f"{name}.txt"
        if not p.exists():
            errors.append(f"missing {p}")
            row.append("-")
            continue
        row.append(str(check(f"{loc}/{name}", read(p), lim)))
    print(f"{loc:8} " + " ".join(f"{c:>9}" for c in row))
    fl = ROOT / "fastlane/metadata/android" / loc
    pairs = [("title.txt", "title.txt"), ("short_description.txt", "short_description.txt"),
             ("full_description.txt", "full_description.txt"),
             ("changelogs/10.txt", "whats_new.txt")]
    for fa, li in pairs:
        a, b = fl / fa, ROOT / "listing" / loc / li
        if not a.exists() or read(a) != read(b):
            errors.append(f"fastlane/{loc}/{fa} missing or differs from listing/{loc}/{li}")
    full = read(ROOT / "listing" / loc / "full_description.txt")
    if full.count("<b>") != full.count("</b>"):
        errors.append(f"{loc}: unbalanced <b> tags")
    if re.search(r"<(?!/?b>)", full):
        errors.append(f"{loc}: unsupported HTML tag in full description")

data = json.loads((ROOT / "listing/headlines.json").read_text(encoding="utf-8"))
scenes = data.get("_scenes", [])
if len(scenes) != HEADLINES:
    errors.append("headlines.json: _scenes must list 8 ids")
for loc in LOCALES:
    hs = data.get(loc)
    if not hs or len(hs) != HEADLINES:
        errors.append(f"headlines.json[{loc}]: need {HEADLINES}")
        continue
    for i, h in enumerate(hs):
        if len(h) > HEADLINE_MAX:
            errors.append(f"headlines[{loc}][{i}] '{h}': {len(h)} > {HEADLINE_MAX}")
        if EMOJI.search(h):
            errors.append(f"headlines[{loc}][{i}]: emoji")

if errors:
    print("\nFAIL")
    print("\n".join(" - " + e for e in errors))
    sys.exit(1)
print("\nOK: all listing texts within Play limits")
