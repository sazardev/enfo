#!/usr/bin/env bash
# Copies finished marketing assets from store/ into docs/assets/ (GitHub Pages
# site) and regenerates the data the site derives from the repo:
#   store/screenshots/**      -> docs/assets/shots/**
#   store/video/*.{mp4,webm}  -> docs/assets/video/
#   store/**/feature*.png     -> docs/assets/og.png  (Open Graph / Twitter card)
#   CHANGELOG.md + assets/music/CREDITS.md -> docs/assets/js/repo-data.js
#   docs/assets/media.json    (manifest the page reads; missing files are fine)
# Idempotent: unchanged files are not rewritten. Safe to run before anything exists.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/store"
DST="$ROOT/docs/assets"
mkdir -p "$DST/shots" "$DST/video" "$DST/js"

sync_file() { # src dst
  if [ ! -f "$2" ] || ! cmp -s "$1" "$2"; then mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "  updated ${2#$ROOT/}"; fi
}

# Screenshots: the store PNGs are 1-2 MB each and there are hundreds, far too
# heavy for a web page. The site gets web-sized WebP copies of the en-US and
# es-419 sets only (max 720 px on the long side of portrait, 1280 on landscape).
n=$(python3 - "$SRC/screenshots" "$DST/shots" <<'PY'
import os, sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
count = 0
for loc in ("en-US", "es-419"):
    base = os.path.join(src, loc)
    if not os.path.isdir(base):
        continue
    for d, _, files in os.walk(base):
        for f in sorted(files):
            if not f.lower().endswith(".png"):
                continue
            rel = os.path.relpath(os.path.join(d, f), src)
            out = os.path.join(dst, os.path.splitext(rel)[0] + ".webp")
            if os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(os.path.join(d, f)):
                count += 1
                continue
            im = Image.open(os.path.join(d, f)).convert("RGB")
            long_side = 1280 if im.width > im.height else 720 * 16 // 9
            scale = min(1.0, long_side / max(im.size))
            if scale < 1:
                im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
            os.makedirs(os.path.dirname(out), exist_ok=True)
            im.save(out, "WEBP", quality=82, method=6)
            count += 1
print(count)
PY
)
echo "screenshots: $n"

v=0
if [ -d "$SRC/video" ]; then
  while IFS= read -r -d '' f; do
    sync_file "$f" "$DST/video/$(basename "$f")"; v=$((v+1))
  done < <(find "$SRC/video" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.jpg' -o -iname '*.png' \) -print0)
fi
echo "video files: $v"

# Feature graphic -> og.png (first match wins; keeps the placeholder otherwise).
fg="$SRC/graphics/og_1200x630.png"; [ -f "$fg" ] || fg="$(find "$SRC" -type f \( -iname 'feature*.png' -o -iname 'feature*.jpg' \) 2>/dev/null | sort | head -n1 || true)"
if [ -n "$fg" ]; then
  case "$fg" in *.png|*.PNG) sync_file "$fg" "$DST/og.png";; *) sync_file "$fg" "$DST/og.jpg"; echo "  note: feature graphic is a JPG, update og meta or convert to og.png";; esac
else
  echo "feature graphic: none found (keeping docs/assets/og.png placeholder)"
fi

python3 - "$ROOT" <<'PY'
import json, os, re, sys
root = sys.argv[1]; assets = os.path.join(root, 'docs', 'assets')

# ---- media manifest ----
def walk(sub, exts):
    base = os.path.join(assets, sub); out = []
    for d, _, files in os.walk(base):
        for f in sorted(files):
            if f.lower().endswith(exts) and not f.startswith('.'):
                out.append(os.path.relpath(os.path.join(d, f), assets).replace(os.sep, '/'))
    return sorted(out)
shots = walk('shots', ('.png', '.jpg', '.jpeg', '.webp'))
videos = walk('video', ('.mp4', '.webm'))
manifest = {'shots': shots, 'videos': videos}
new = json.dumps(manifest, indent=2) + '\n'
p = os.path.join(assets, 'media.json')
if not os.path.exists(p) or open(p).read() != new:
    open(p, 'w').write(new); print('  updated docs/assets/media.json')

# ---- changelog + credits ----
def changelog(path):
    rel = []; cur = None; sec = None; item = None
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        m = re.match(r'^##\s+(.*)$', line)
        if m: cur = {'version': m.group(1).strip(), 'sections': []}; rel.append(cur); sec = None; item = None; continue
        m = re.match(r'^###\s+(.*)$', line)
        if m and cur is not None: sec = {'title': m.group(1).strip(), 'items': []}; cur['sections'].append(sec); item = None; continue
        m = re.match(r'^-\s+(.*)$', line)
        if m and sec is not None: item = m.group(1).strip(); sec['items'].append(item); continue
        if line.startswith('  ') and sec is not None and sec['items']: sec['items'][-1] += ' ' + line.strip()
    return rel
def credits(path):
    rows = []
    for line in open(path, encoding='utf-8'):
        if not line.startswith('|') or line.startswith('| Song') or line.startswith('|---'): continue
        c = [x.strip() for x in line.strip().strip('|').split('|')]
        if len(c) < 4: continue
        lic = re.match(r'\[(.*?)\]\((.*?)\)', c[2]); src = re.match(r'\[(.*?)\]\((.*?)\)', c[3])
        rows.append({'song': c[0], 'artist': c[1], 'license': lic.group(1) if lic else c[2],
                     'licenseUrl': lic.group(2) if lic else '', 'url': src.group(2) if src else ''})
    return rows
data = {'changelog': changelog(os.path.join(root, 'CHANGELOG.md')),
        'credits': credits(os.path.join(root, 'assets', 'music', 'CREDITS.md'))}
js = '/* Generated by tools/sync_site_assets.sh from CHANGELOG.md and assets/music/CREDITS.md. Do not edit. */\nwindow.REPO_DATA = ' + json.dumps(data, ensure_ascii=False, indent=1) + ';\n'
p = os.path.join(assets, 'js', 'repo-data.js')
if not os.path.exists(p) or open(p, encoding='utf-8').read() != js:
    open(p, 'w', encoding='utf-8').write(js); print('  updated docs/assets/js/repo-data.js')
print('media.json: %d shots, %d videos; %d releases, %d songs' % (len(shots), len(videos), len(data['changelog']), len(data['credits'])))
PY
