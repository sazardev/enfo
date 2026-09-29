#!/usr/bin/env python3
"""Composites captions / touch dots / outro card over the frames recorded by
tool/store/video_test.dart and encodes the promo videos with ffmpeg.

  python3 tool/store/make_video.py            # both orientations + hero loop
Inputs : /tmp/enfo_video/<orient>/app/frame_*.png + meta.json
Outputs: store/video/enfo_promo_{portrait,landscape}.mp4,
         store/video/enfo_hero_loop.{mp4,webm}
"""
import json, os, subprocess, sys, shutil
from multiprocessing import Pool
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'tools'))
from brand_draw import draw_mark

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TMP = '/tmp/enfo_video'
OUT = os.path.join(ROOT, 'store', 'video')
FONT = lambda w, s: ImageFont.truetype(os.path.join(ROOT, 'assets/fonts', f'GeistMono-{w}.ttf'), s)
SONG = os.path.join(ROOT, 'assets/music/01_chill_beat.ogg')
OUTRO = 120  # frames of outro card (wipe, logo build, wordmark)
FADE = 6

CFG = {
    'portrait': dict(size=(1080, 1920), band=280, title=100, sub=38, margin=64),
    'landscape': dict(size=(1920, 1080), band=150, title=64, sub=28, margin=72),
}


def lum(c):
    r, g, b = c[:3]
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255


def accent_of(im):
    """Most common clearly-coloured pixel (the dial colour) of a frame."""
    small = im.convert('RGB').resize((120, 120))
    counts = {}
    for px in small.getdata():
        mx, mn = max(px), min(px)
        if mx == 0 or (mx - mn) / mx < .45 or mx < 60:
            continue
        q = tuple(v // 12 * 12 for v in px)
        counts[q] = counts.get(q, 0) + 1
    if not counts:
        return (0, 107, 95)
    q = max(counts, key=counts.get)
    # refine: average of original pixels in that bucket
    sel = [p for p in small.getdata() if tuple(v // 12 * 12 for v in p) == q]
    return tuple(sum(p[i] for p in sel) // len(sel) for i in range(3))


def caption_layer(cfg, title, sub, fg, alpha):
    W = cfg['size'][0]
    band = cfg['band']
    layer = Image.new('RGBA', (W, band), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    ft, fs = FONT('Bold', cfg['title']), FONT('Medium', cfg['sub'])
    th, sh = cfg['title'], cfg['sub']
    gap = int(th * .18)
    total = th + gap + sh
    y = (band - total) // 2 - 4
    a = int(255 * alpha)
    d.text((cfg['margin'], y - th * .12), title, font=ft, fill=fg + (a,))
    d.text((cfg['margin'], y + th + gap), sub, font=fs, fill=fg + (int(a * .62),))
    return layer


def compose(args):
    (orient, i, src, dst, caps, touches, total, opts) = args
    cfg = CFG[orient]
    W, H = cfg['size']
    band = cfg['band']
    scale = opts['scale']
    app = Image.open(src).convert('RGB')
    bg = app.getpixel((3, 3))
    fg = (28, 27, 31) if lum(bg) > .5 else (240, 234, 231)
    canvas = Image.new('RGBA', (W, H), bg + (255,))
    canvas.paste(app, (0, band))
    # captions (cross-fade between consecutive ones)
    idx = max([k for k, c in enumerate(caps) if c['f'] <= i] or [0])
    cur = caps[idx]
    t = i - cur['f']
    layers = []
    if t < FADE and idx > 0:
        prev = caps[idx - 1]
        layers.append((prev, 1 - t / FADE))
        layers.append((cur, t / FADE))
    else:
        layers.append((cur, min(1, t / FADE)))
    if opts.get('static'):
        layers = [(caps[-1], 1)]
    for c, a in layers:
        canvas.alpha_composite(caption_layer(cfg, c['title'], c['sub'], fg, max(0, min(1, a))), (0, 0))
    d = ImageDraw.Draw(canvas, 'RGBA')
    if not opts.get('static'):
        # progress bar along the bottom of the band
        bh = 6 if orient == 'portrait' else 5
        d.rectangle([0, band - bh, W, band], fill=fg + (40,))
        d.rectangle([0, band - bh, int(W * min(1, i / total)), band], fill=fg + (200,))
        # touch dot
        tp = touches.get(i)
        if tp:
            r = int(46 * scale / 2.5 * (W / 1080 if orient == 'portrait' else .9))
            x, y = tp[0], tp[1] + band
            d.ellipse([x - r, y - r, x + r, y + r], fill=(128, 128, 128, 90), outline=(128, 128, 128, 200), width=4)
    canvas.convert('RGB').save(dst, optimize=False, compress_level=1)


def outro(args):
    (orient, k, last, dst, accent) = args
    cfg = CFG[orient]
    W, H = cfg['size']
    base = Image.open(last).convert('RGB')
    cv = Image.new('RGB', (W, H))
    cv.paste(base, (0, cfg['band']))
    bg = base.getpixel((3, 3))
    cv.paste(Image.new('RGB', (W, cfg['band']), bg), (0, 0))
    WIPE = 14
    p = min(1, k / WIPE)
    e = 1 - (1 - p) ** 3
    d = ImageDraw.Draw(cv)
    if orient == 'portrait':
        d.rectangle([0, int(H * (1 - e)), W, H], fill=accent)
    else:
        d.rectangle([int(W * (1 - e)), 0, W, H], fill=accent)
    if p >= 1:
        cv = Image.new('RGB', (W, H), accent)
    fg = (255, 255, 255) if lum(accent) < .62 else (28, 27, 31)
    portrait = orient == 'portrait'
    # The logo builds itself (same timeline as the in-app splash), then the wordmark.
    tb = (k - WIPE) / 38  # 0..1 over frames 14..52
    if tb > 0:
        lay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(lay)
        msz = 470 if portrait else 400
        tint = tuple(round(fg[i] + (accent[i] - fg[i]) * .35) for i in range(3))
        mark = draw_mark(msz, min(1, tb), color=fg, tint=tint)
        wf, tf, sf = FONT('Bold', 120 if portrait else 104), FONT('Medium', 44 if portrait else 38), FONT('Regular', 30 if portrait else 26)
        gap = 46
        total = msz + gap + wf.size + 34 + tf.size + 44 + sf.size
        y0 = (H - total) // 2
        lay.paste(mark, ((W - msz) // 2, y0), mark)

        def line(text, font, y, al, spacing=0):
            if al <= 0:
                return
            widths = [dd.textlength(ch, font=font) + spacing for ch in text]
            x = (W - (sum(widths) - spacing)) / 2
            for ch, wch in zip(text, widths):
                dd.text((x, y + (1 - al) * 16), ch, font=font, fill=fg + (int(255 * al),))
                x += wch

        def fade(a0, a1):
            return max(0, min(1, (k - a0) / (a1 - a0)))
        y = y0 + msz + gap
        line('enfo', wf, y, fade(44, 56), spacing=22)
        y += wf.size + 34
        line('a clock & timer toolbox', tf, y, fade(52, 64))
        y += tf.size + 44
        line('63 clock styles  /  60 combos  /  9 languages', sf, y, fade(58, 70) * .7)
        cv = Image.alpha_composite(cv.convert('RGBA'), lay).convert('RGB')
    cv.save(dst, compress_level=1)


def run(cmd):
    print(' '.join(cmd)[:200]); subprocess.run(cmd, check=True)


def build(orient, pool):
    d = f'{TMP}/{orient}'
    meta = json.load(open(f'{d}/meta.json'))
    assert meta['stride'] == 1, 'record with STRIDE=1'
    n = meta['heroEnd']
    caps = meta['captions']
    touches = {t['f']: (t['x'], t['y']) for t in meta['touches']}
    out = f'{d}/out'
    shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
    opts = dict(scale=meta['scale'])
    jobs = [(orient, i, f'{d}/app/frame_{i:05d}.png', f'{out}/frame_{i:05d}.png', caps, touches, n, opts)
            for i in range(1, n + 1)]
    pool.map(compose, jobs, chunksize=8)
    last = f'{d}/app/frame_{n:05d}.png'
    accent = accent_of(Image.open(last).crop((0, 0, 400, 400)) if False else Image.open(last))
    print('accent', accent)
    pool.map(outro, [(orient, k, last, f'{out}/frame_{n + 1 + k:05d}.png', accent) for k in range(OUTRO)])
    total = n + OUTRO
    dur = total / 30
    mp4 = f'{OUT}/enfo_promo_{orient}.mp4'
    af = (f'loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=in:st=0:d=1.2,'
          f'afade=t=out:st={dur - 2.5:.2f}:d=2.5')
    run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', '30', '-start_number', '1',
         '-i', f'{out}/frame_%05d.png', '-ss', '2', '-i', SONG,
         '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p',
         '-af', af, '-c:a', 'aac', '-b:a', '160k', '-t', f'{dur:.3f}', '-shortest',
         '-movflags', '+faststart', mp4])
    return meta


def hero(pool):
    orient = 'landscape'
    d = f'{TMP}/{orient}'
    meta = json.load(open(f'{d}/meta.json'))
    caps = meta['captions']
    S, L, X = meta['heroEnd'] - 60, 240, 30
    out = f'{d}/hero'
    shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
    opts = dict(scale=meta['scale'], static=True)
    jobs = [(orient, 10**9, f'{d}/app/frame_{S + i:05d}.png', f'{out}/seg_{i:05d}.png', caps, {}, 1, opts)
            for i in range(L + X)]
    pool.map(compose, jobs, chunksize=8)
    for i in range(L):
        a = Image.open(f'{out}/seg_{i:05d}.png')
        if i < X:
            b = Image.open(f'{out}/seg_{i + L:05d}.png')
            a = Image.blend(b, a, i / X)
        a.save(f'{out}/frame_{i + 1:05d}.png', compress_level=1)
    run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', '30', '-i', f'{out}/frame_%05d.png',
         '-c:v', 'libx264', '-preset', 'slow', '-crf', '22', '-pix_fmt', 'yuv420p', '-an',
         '-movflags', '+faststart', f'{OUT}/enfo_hero_loop.mp4'])
    run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', '30', '-i', f'{out}/frame_%05d.png',
         '-c:v', 'libvpx-vp9', '-crf', '34', '-b:v', '0', '-pix_fmt', 'yuv420p', '-an',
         f'{OUT}/enfo_hero_loop.webm'])


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    with Pool(12) as pool:
        for o in (sys.argv[1:] or ['portrait', 'landscape']):
            if o == 'hero':
                hero(pool)
            else:
                build(o, pool)
        if not sys.argv[1:]:
            hero(pool)
