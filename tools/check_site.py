#!/usr/bin/env python3
"""Static checks for the GitHub Pages site in docs/ (no browser needed):
   - every local href/src/url() in index.html and site.css exists
   - JS syntax (node --check) for every docs/assets/js/*.js and site-config.js
   - every data-i18n key in index.html has a Spanish entry
   - the GitHub slug appears only where it must (site-config.js + static meta)
Run: python3 tools/check_site.py"""
import glob, os, re, subprocess, sys
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'docs')
root = os.path.abspath(root)
bad = 0
def fail(m):
    global bad; bad += 1; print('FAIL', m)

html = open(os.path.join(root, 'index.html'), encoding='utf-8').read()
refs = re.findall(r'(?:href|src)="([^"#][^"]*)"', html)
css = open(os.path.join(root, 'assets/css/site.css'), encoding='utf-8').read()
refs += ['assets/css/' + u for u in re.findall(r'url\(\'?([^)\']+)\'?\)', css)]
for r in refs:
    if re.match(r'^(https?:|mailto:|data:)', r): continue
    p = os.path.normpath(os.path.join(root, r.split('?')[0]))
    if not os.path.exists(p): fail('missing local file: ' + r)
ids = set(re.findall(r'id="([^"]+)"', html))
for a in re.findall(r'href="#([^"]+)"', html):
    if a not in ids: fail('dangling anchor #' + a)
# JS icons/dictionary references inside JS files
for f in glob.glob(os.path.join(root, 'assets/**/*.js'), recursive=True):
    r = subprocess.run(['node', '--check', f], capture_output=True, text=True)
    if r.returncode: fail('syntax ' + f + '\n' + r.stderr)
# i18n
i18n = open(os.path.join(root, 'assets/js/i18n.js'), encoding='utf-8').read()
es = i18n[i18n.index('var es = {'):]
keys = set(re.findall(r'data-i18n="([^"]+)"', html))
for k in sorted(keys):
    if "'" + k + "'" not in es: fail('no Spanish string for ' + k)
used = set(re.findall(r"\bT\('([^']+)'\)", open(os.path.join(root, 'assets/js/app.js')).read()))
used |= set(re.findall(r"\bt\('([^']+)'\)", open(os.path.join(root, 'assets/js/demos.js')).read()))
en_dyn = i18n[:i18n.index('var es = {')]
for k in sorted(used):
    if "'" + k + "'" not in en_dyn and k not in keys: fail('no English string for ' + k)
    if "'" + k + "'" not in es: fail('no Spanish string for ' + k)
# icons
icons = open(os.path.join(root, 'assets/js/icons.js')).read()
have = set(re.findall(r'"([a-z0-9]+)":"M', icons))
for f in ('app.js', 'demos.js'):
    src = open(os.path.join(root, 'assets/js', f)).read()
    for n in set(re.findall(r"\bico\('([a-z0-9]+)'", src) + re.findall(r"icon\('([a-z0-9]+)'", src)):
        if n not in have: fail('icon missing: ' + n)
# slug
slug = re.search(r"GITHUB_SLUG = '([^']+)'", open(os.path.join(root, 'assets/site-config.js')).read()).group(1)
owner = slug.split('/')[0]
for f in glob.glob(os.path.join(root, '**/*'), recursive=True):
    if os.path.isdir(f) or f.endswith(('.ttf', '.png', '.jpg', '.webp', '.mp4', '.webm')): continue
    txt = open(f, encoding='utf-8', errors='ignore').read()
    if f.endswith('site-config.js') or f.endswith('OFL.txt'): continue
    for m in re.finditer(r'github\.com/([\w.-]+/[\w.-]+)|([\w.-]+)\.github\.io', txt):
        s = m.group(1) or m.group(2)
        if s not in (slug, owner): fail('%s mentions %s (config says %s)' % (os.path.relpath(f, root), s, slug))
print('checked %d refs, %d i18n keys; %s' % (len(refs), len(keys), 'OK' if not bad else '%d problems' % bad))
sys.exit(1 if bad else 0)
