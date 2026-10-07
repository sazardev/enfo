#!/usr/bin/env python3
"""Validate the Google Ads App campaign kit and experiment copy.

Usage: python3 tools/check_campaign.py
Exit code 1 if any check fails.
"""
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "store" / "campaign"
LOCALES = ["en-US", "es-419", "de-DE", "fr-FR", "pt-BR",
           "hi-IN", "ja-JP", "ko-KR", "zh-CN"]
DOUBLE_BYTE = {"ja-JP", "ko-KR", "zh-CN"}
HEADLINES, DESCRIPTIONS = 5, 5
SHORT_DESC_MAX = 80
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
    if text.count("!") > 1:
        errors.append(f"{label}: more than one '!'")
    if text != text.strip() or "  " in text:
        errors.append(f"{label}: stray whitespace")
    return n


def read_lines(p, expected):
    if not p.exists():
        errors.append(f"missing {p.relative_to(ROOT.parent.parent)}")
        return []
    lines = read(p).split("\n")
    if len(lines) != expected:
        errors.append(f"{p.relative_to(ROOT.parent.parent)}: {len(lines)} lines, expected {expected}")
    return lines


print(f"{'locale':8} {'head':>5} {'desc':>5} {'alt':>5}")
for loc in LOCALES:
    hl_max = 15 if loc in DOUBLE_BYTE else 30
    ds_max = 45 if loc in DOUBLE_BYTE else 90
    heads = read_lines(ROOT / "google_app" / loc / "headlines.txt", HEADLINES)
    descs = read_lines(ROOT / "google_app" / loc / "descriptions.txt", DESCRIPTIONS)
    alts = read_lines(ROOT / "experiments/short_description" / f"{loc}.txt", 1)
    hmax = max([check(f"{loc}/headlines[{i}]", h, hl_max) for i, h in enumerate(heads)] or [0])
    dmax = max([check(f"{loc}/descriptions[{i}]", d, ds_max) for i, d in enumerate(descs)] or [0])
    amax = max([check(f"{loc}/short_description_alt", a, SHORT_DESC_MAX) for a in alts] or [0])
    if len(set(heads)) != len(heads):
        errors.append(f"{loc}/headlines: duplicate lines")
    if len(set(descs)) != len(descs):
        errors.append(f"{loc}/descriptions: duplicate lines")
    print(f"{loc:8} {hmax:>5} {dmax:>5} {amax:>5}")

if errors:
    print("\nFAIL")
    print("\n".join(" - " + e for e in errors))
    sys.exit(1)
print("\nOK: campaign texts within Google Ads limits")
