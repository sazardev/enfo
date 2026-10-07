#!/usr/bin/env python3
"""Copy store graphics and screenshots into the fastlane supply layout.

    python3 tools/sync_fastlane_images.py

Sources of truth: store/graphics/ and store/screenshots/<locale>/.
Destination: store/fastlane/metadata/android/<locale>/images/ (git-ignored,
regenerate any time; the `images` fastlane lane runs this script first).

Fastlane expects icon.png, featureGraphic.png and the screenshot folders
phoneScreenshots/, sevenInchScreenshots/ and tenInchScreenshots/. File names
set the order inside each folder (ours already start with 01..08).
Screenshots exist only for en-US and es-419; other locales are skipped with
a warning (Play falls back to the default listing images).
"""
import shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "store"
DEST = STORE / "fastlane" / "metadata" / "android"
LOCALES = ["en-US", "es-419", "es-ES", "de-DE", "fr-FR", "pt-BR",
           "hi-IN", "ja-JP", "ko-KR", "zh-CN"]
TYPES = [("phone-portrait", "phoneScreenshots"),
         ("tablet7-portrait", "sevenInchScreenshots"),
         ("tablet10-portrait", "tenInchScreenshots")]
warnings = []


def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)


for loc in LOCALES:
    if not (DEST / loc).is_dir():
        warnings.append(f"{loc}: no fastlane metadata folder, skipped")
        continue
    images = DEST / loc / "images"
    copy(STORE / "graphics" / "icon_512.png", images / "icon.png")
    fg = STORE / "graphics" / f"feature_graphic_{loc}.png"
    if fg.exists():
        copy(fg, images / "featureGraphic.png")
    else:
        warnings.append(f"{loc}: no feature_graphic_{loc}.png")
    for src_name, dst_name in TYPES:
        src_dir = STORE / "screenshots" / loc / src_name
        out = images / dst_name
        shutil.rmtree(out, ignore_errors=True)
        if not src_dir.is_dir():
            warnings.append(f"{loc}: no {src_name} screenshots")
            continue
        for shot in sorted(src_dir.glob("*.png")):
            copy(shot, out / shot.name)
    print(f"{loc}: images synced")

print(f"Done. {len(warnings)} warning(s).")
for w in warnings:
    print(" - " + w)
sys.exit(0)
