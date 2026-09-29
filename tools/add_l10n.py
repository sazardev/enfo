#!/usr/bin/env python3
"""Merge new strings into every ARB and regenerate the localizations.

Usage: python3 tools/add_l10n.py strings.json
strings.json: {"key": {"en": "...", "es": "...", "de": "...", "fr": "...",
               "pt": "...", "hi": "...", "ja": "...", "ko": "...", "zh": "..."}}
A key whose value needs placeholders/plurals may carry an "@meta" entry:
{"key": {...langs...}, "@key": {...ARB metadata, written to en only...}}
All 9 languages are required for each key. Safe to run from several
processes at once (it takes a lock). Existing keys are overwritten.
"""
import collections, fcntl, json, os, subprocess, sys

LANGS = ["en", "es", "de", "fr", "pt", "hi", "ja", "ko", "zh"]
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def main(path):
    new = json.load(open(path), object_pairs_hook=collections.OrderedDict)
    keys = [k for k in new if not k.startswith("@")]
    for k in keys:
        missing = [l for l in LANGS if l not in new[k]]
        if missing:
            sys.exit(f"{k}: missing languages {missing}")
    with open(os.path.join(ROOT, "tools", ".l10n.lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        for lang in LANGS:
            p = os.path.join(ROOT, f"lib/l10n/app_{lang}.arb")
            d = json.load(open(p), object_pairs_hook=collections.OrderedDict)
            for k in keys:
                d[k] = new[k][lang]
                if lang == "en" and "@" + k in new:
                    d["@" + k] = new["@" + k]
            with open(p, "w") as f:
                json.dump(d, f, ensure_ascii=False, indent=2)
                f.write("\n")
        r = subprocess.run(["flutter", "gen-l10n"], cwd=ROOT,
                           capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit(r.stdout + r.stderr)
    print(f"added {len(keys)} keys")

main(sys.argv[1])
