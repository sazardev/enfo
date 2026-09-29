#!/usr/bin/env python3
"""Compose the Google Play marketing assets for Enfo from the raw app renders.

Deterministic and re-runnable:  python3 tools/compose_store_assets.py
Options: --sheets DIR   also write per device/orientation contact sheets to DIR
         --locales a,b  restrict locales (default: all in headlines.json)

Inputs : store/raw/<device>/<orientation>/<NN>_<scene>_<theme>_<lang>.png
         store/raw/manifest.json, store/listing/headlines_by_scene.json,
         store/listing/<locale>/feature_graphic_tagline.txt, assets/fonts/GeistMono-*.ttf
Outputs: store/screenshots/<locale>/<device>-<orientation>/NN_<slug>.png
         store/graphics/{feature_graphic_<locale>,icon_512,og_1200x630,montage_phone}.png

Design: strictly flat. Tonal colour fields derived from each scene accent, flat rounded
device shape with a thin flat tonal bezel, no gradients, no shadows, no borders.
"""
import argparse
import colorsys
import json
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "store" / "raw"
LISTING = ROOT / "store" / "listing"
OUT = ROOT / "store" / "screenshots"
GFX = ROOT / "store" / "graphics"
FONTS = ROOT / "assets" / "fonts"

DEVICES = {
    "phone": (1080, 1920),
    "tablet7": (1200, 1920),
    "tablet10": (1600, 2560),
}

# Listing scene id -> (slug, raw scene id). Order = Play screenshot order.
SCENES = [
    ("hero_pomodoro", "focus", "hero"),
    ("clock_styles", "styles", "styles"),
    ("fullscreen_clock", "desk_clock", "clock_night"),
    ("timer_stopwatch", "timers", "timer"),
    ("intervals", "intervals", "intervals"),
    ("kitchen_timers", "kitchen", "kitchen"),
    ("breathe_music", "breathe_music", "music"),
    ("world_sleep", "world_sleep", "world_planner"),
]

LATIN_FONT = FONTS / "GeistMono-Bold.ttf"
FALLBACK_FONTS = {  # locales whose script Geist Mono does not cover
    "ja-JP": (Path("/usr/share/fonts/noto-cjk/NotoSansCJK-Bold.ttc"), 0),
    "ko-KR": (Path("/usr/share/fonts/noto-cjk/NotoSansCJK-Bold.ttc"), 1),
    "zh-CN": (Path("/usr/share/fonts/noto-cjk/NotoSansCJK-Bold.ttc"), 2),
    "hi-IN": (Path("/usr/share/fonts/noto/NotoSansDevanagari-Bold.ttf"), 0),
}
CJK = {"ja-JP", "ko-KR", "zh-CN"}
LINE_FACTOR = {"hi-IN": 1.42, "ja-JP": 1.28, "ko-KR": 1.28, "zh-CN": 1.28}

NEUTRAL_BG = (243, 245, 244)
ICON_SIZE = 512


# ---------------------------------------------------------------- colour helpers
def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hls(h, l, s):
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (round(r * 255), round(g * 255), round(b * 255))


def hue_of(rgb):
    return colorsys.rgb_to_hls(*(c / 255 for c in rgb))[0]


def lum(rgb):
    def f(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (f(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = lum(a), lum(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)


def palette(accent_hex, theme):
    """Flat tonal palette derived from the accent."""
    h = hue_of(hex_rgb(accent_hex))
    if theme == "light":
        p = dict(bg=hls(h, .915, .60), field=hls(h, .865, .55), bezel=hls(h, .12, .30),
                 text=hls(h, .09, .45), kicker=hls(h, .28, .70))
    else:
        p = dict(bg=hls(h, .17, .34), field=hls(h, .215, .32), bezel=hls(h, .055, .30),
                 text=hls(h, .96, .55), kicker=hls(h, .78, .65))
    # guarantee WCAG AA for text on the flat background
    for key in ("text", "kicker"):
        col = p[key]
        step = 0
        while contrast(col, p["bg"]) < 4.5 and step < 40:
            l = colorsys.rgb_to_hls(*(c / 255 for c in col))
            nl = l[1] - .01 if theme == "light" else l[1] + .01
            col = hls(l[0], min(max(nl, 0), 1), l[2])
            step += 1
        p[key] = col
        assert contrast(col, p["bg"]) >= 4.5, (accent_hex, theme, key)
    return p


# ---------------------------------------------------------------- shapes
SS = 3  # supersampling for rounded shapes


def rr_mask(w, h, r):
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w * SS - 1, h * SS - 1), r * SS, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def fill_rr(canvas, box, r, color):
    x, y, w, h = box
    canvas.paste(Image.new("RGB", (w, h), color), (x, y), rr_mask(w, h, r))


def fill_circle(canvas, cx, cy, rad, color):
    d = 2 * rad
    m = Image.new("L", (d * 2, d * 2), 0)
    ImageDraw.Draw(m).ellipse((0, 0, d * 2 - 1, d * 2 - 1), fill=255)
    m = m.resize((d, d), Image.LANCZOS)
    canvas.paste(Image.new("RGB", (d, d), color), (cx - rad, cy - rad), m)


def draw_device(canvas, shot, x, y, sw, sh, bezel_color, crop_top=0.0):
    """Flat rounded device: bezel rect + rounded screen. (x, y) = top-left of the
    bezel outer edge; sw x sh = screen size. May extend beyond the canvas."""
    small = min(sw, sh)
    b = max(4, round(0.02 * small))
    r = round(0.09 * small)
    dw, dh = sw + 2 * b, sh + 2 * b
    layer = Image.new("RGB", (dw, dh), bezel_color)
    scr = fit_cover(shot, sw, sh, crop_top)
    body = Image.new("RGB", (dw, dh), (0, 0, 0))
    body.paste(Image.new("RGB", (dw, dh), bezel_color))
    body.paste(scr, (b, b), rr_mask(sw, sh, r))
    canvas.paste(body, (x, y), rr_mask(dw, dh, r + b))
    return dw, dh


def fit_cover(img, w, h, crop_top=0.0):
    """Scale img to cover w x h; crop_top in [0,1] chooses the vertical window."""
    s = max(w / img.width, h / img.height)
    nw, nh = max(w, round(img.width * s)), max(h, round(img.height * s))
    im = img.resize((nw, nh), Image.LANCZOS)
    ox = (nw - w) // 2
    oy = round((nh - h) * crop_top)
    return im.crop((ox, oy, ox + w, oy + h))


# ---------------------------------------------------------------- text
class MixedFont:
    """Devanagari font + Latin font for ASCII letters (Noto Devanagari has no Latin)."""

    def __init__(self, main, latin, size):
        self.main, self.latin, self.size = main, latin, size

    def runs(self, text):
        out = []
        for ch in text:
            f = self.latin if (ch.isascii() and ch.isalpha()) else self.main
            if out and out[-1][0] is f:
                out[-1][1] += ch
            else:
                out.append([f, ch])
        return out

    def getlength(self, text):
        return sum(f.getlength(t) for f, t in self.runs(text))

    def getbbox(self, text):
        return (0, 0, self.getlength(text), self.size)


def text_bbox(font, text):
    if isinstance(font, MixedFont):
        return font.getbbox(text)
    return ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), text, font=font)


def text_draw(draw, xy, text, font, fill):
    if isinstance(font, MixedFont):
        x, y = xy
        base = y + font.main.getmetrics()[0]
        for f, t in font.runs(text):
            draw.text((x, base), t, font=f, fill=fill, anchor="ls")
            x += f.getlength(t)
    else:
        draw.text(xy, text, font=font, fill=fill)


def load_font(locale, size):
    if locale == "hi-IN":
        return MixedFont(ImageFont.truetype(str(FALLBACK_FONTS[locale][0]), size),
                         ImageFont.truetype("/usr/share/fonts/noto/NotoSans-Bold.ttf", size), size)
    if locale in FALLBACK_FONTS:
        path, idx = FALLBACK_FONTS[locale]
        if path.exists():
            return ImageFont.truetype(str(path), size, index=idx)
        print(f"WARN: font {path} missing for {locale}; falling back to Geist Mono", file=sys.stderr)
    return ImageFont.truetype(str(LATIN_FONT), size)


def latin_font(size):
    return ImageFont.truetype(str(LATIN_FONT), size)


def tokens_for(text, locale):
    if locale in CJK:
        out, cur = [], ""
        for ch in text:
            cur += ch
            if ch in ",，、。 ":
                out.append(cur.strip())
                cur = ""
        if cur:
            out.append(cur)
        return out, ""
    return text.split(), " "


def measure(font, text):
    bb = font.getbbox(text)
    return max(font.getlength(text), bb[2] - bb[0], bb[2])


def wrap(text, font, maxw, locale):
    toks, sep = tokens_for(text, locale)
    # split over-wide tokens (CJK chunk or a very long word) into characters
    exp = []
    for t in toks:
        if measure(font, t) <= maxw:
            exp.append(t)
        elif locale in CJK:
            exp.extend(list(t))
        else:
            return None
    lines, cur = [], ""
    for t in exp:
        cand = t if not cur else cur + sep + t
        if measure(font, cand) <= maxw:
            cur = cand
        else:
            lines.append(cur)
            cur = t
    lines.append(cur)
    return lines


def fit_text(text, locale, boxw, boxh, max_size, min_size, max_lines, step=2):
    """Largest font size for which wrapped text fits the box. Returns (font, lines, lh)."""
    lf = LINE_FACTOR.get(locale, 1.16)
    size = int(max_size)
    while size >= min_size:
        font = load_font(locale, size)
        lines = wrap(text, font, boxw, locale)
        if lines and len(lines) <= max_lines and len(lines) * size * lf <= boxh:
            return font, lines, round(size * lf)
        size -= step
    raise RuntimeError(f"text does not fit: {text!r} in {boxw}x{boxh}")


def draw_lines(draw, lines, font, lh, x, y, color, boxw, boxh, align="left"):
    """Draw lines top-anchored in the box; assert real ink stays inside the box."""
    for i, ln in enumerate(lines):
        bb = text_bbox(font, ln)
        w = bb[2] - bb[0]
        ox = x
        if align == "center":
            ox = x + (boxw - w) / 2
        text_draw(draw, (ox - bb[0], y + i * lh), ln, font, color)
        assert w <= boxw + 1, ("overflow", ln, w, boxw)
    assert len(lines) * lh <= boxh + 1, ("overflow-h", lines)


# ---------------------------------------------------------------- data
def load_data():
    manifest = json.load(open(RAW / "manifest.json"))
    scenes = {s["id"]: s for s in manifest["scenes"]}
    hb = json.load(open(LISTING / "headlines_by_scene.json"))
    hs = json.load(open(LISTING / "headlines.json"))
    return scenes, hb, hs


def raw_path(device, orient, scene, lang):
    name = f"{scene['n']:02d}_{scene['id']}_{scene['theme']}_{lang}.png"
    p = RAW / device / orient / name
    if not p.exists():
        raise FileNotFoundError(p)
    return p


def lang_of(locale):
    return "es" if locale.startswith("es") else "en"


# ---------------------------------------------------------------- screenshots
def compose_shot(device, orient, locale, scene, headline, lang, size_cap=None):
    W, H = DEVICES[device]
    if orient == "landscape":
        W, H = H, W
    pal = palette(scene["accent"], scene["theme"])
    canvas = Image.new("RGB", (W, H), pal["bg"])
    shot = Image.open(raw_path(device, orient, scene, lang)).convert("RGB")
    draw = ImageDraw.Draw(canvas)

    if orient == "portrait":
        m = round(0.08 * W)
        # flat tonal field behind the device
        fill_circle(canvas, W // 2, round(0.66 * H), round(0.62 * W), pal["field"])
        ks = round(0.026 * W)
        ky = round(0.05 * H)
        draw.text((m, ky), "ENFO", font=latin_font(ks), fill=pal["kicker"])
        hy = ky + round(ks * 1.9)
        boxw, boxh = W - 2 * m, round(0.255 * H) - hy - round(0.012 * H)
        font, lines, lh = fit_text(headline, locale, boxw, boxh, size_cap or 0.105 * W, 0.04 * W, 3)
        draw_lines(draw, lines, font, lh, m, hy, pal["text"], boxw, boxh)
        dw = round(0.73 * W)
        b = max(4, round(0.02 * dw))
        sw = dw - 2 * b
        sh = round(sw * shot.height / shot.width)
        draw_device(canvas, shot, (W - dw) // 2, round(0.255 * H), sw, sh, pal["bezel"])
    else:
        mx = round(0.055 * W)
        fill_circle(canvas, round(0.675 * W), H // 2, round(0.50 * H), pal["field"])
        colw = round(0.30 * W)
        colh = round(0.62 * H)
        ks = round(0.026 * H)
        font, lines, lh = fit_text(headline, locale, colw, colh, size_cap or 0.115 * H, 0.04 * H, 4)
        block = round(ks * 1.9) + len(lines) * lh
        y0 = (H - block) // 2
        draw.text((mx, y0), "ENFO", font=latin_font(ks), fill=pal["kicker"])
        draw_lines(draw, lines, font, lh, mx, y0 + round(ks * 1.9), pal["text"], colw, colh)
        dw = round(0.575 * W)
        b = max(4, round(0.02 * dw * H / W))
        sw = dw - 2 * b
        sh = round(sw * shot.height / shot.width)
        dh = sh + 2 * b
        draw_device(canvas, shot, round(0.385 * W), (H - dh) // 2, sw, sh, pal["bezel"])
    return canvas


def common_size(device, orient, locale, hb):
    """One headline font size for the whole set (largest that fits every headline)."""
    W, H = DEVICES[device]
    if orient == "landscape":
        W, H = H, W
    best = None
    for lid, _, _ in SCENES:
        if orient == "portrait":
            m = round(0.08 * W)
            ks = round(0.026 * W)
            hy = round(0.05 * H) + round(ks * 1.9)
            boxw, boxh = W - 2 * m, round(0.255 * H) - hy - round(0.012 * H)
            f, _, _ = fit_text(hb[locale][lid], locale, boxw, boxh, 0.105 * W, 0.04 * W, 3)
        else:
            f, _, _ = fit_text(hb[locale][lid], locale, round(0.30 * W), round(0.62 * H), 0.115 * H, 0.04 * H, 4)
        best = f.size if best is None else min(best, f.size)
    return best


def save_png(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(path, "PNG", optimize=True)


def contact_sheet(paths, out, cols=4, thumb=360):
    ims = [Image.open(p).convert("RGB") for p in paths]
    w, h = ims[0].size
    tw = thumb
    th = round(tw * h / w)
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (tw + 10) + 10, rows * (th + 10) + 10), (128, 128, 128))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((tw, th), Image.LANCZOS), (10 + (i % cols) * (tw + 10), 10 + (i // cols) * (th + 10)))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)


# ---------------------------------------------------------------- icon
def draw_icon(size=ICON_SIZE):
    """Redraw the flat launcher icon (192px source) at high resolution. Coordinates are
    in a 768-unit design space measured from the 192px launcher PNG."""
    k = 4
    S = size * k
    u = S / 768
    bg, olive, lime = (243, 245, 244), (133, 139, 0), (207, 228, 47)
    pill, white = (163, 192, 6), (244, 255, 255)
    im = Image.new("RGB", (S, S), bg)
    d = ImageDraw.Draw(im)

    def P(x, y):
        return (x * u, y * u)

    def circ(cx, cy, r, col):
        d.ellipse((cx * u - r * u, cy * u - r * u, cx * u + r * u, cy * u + r * u), fill=col)

    def thick(p0, p1, wd, col):
        d.line((P(*p0), P(*p1)), fill=col, width=round(wd * u))
        circ(*p0, wd / 2, col)
        circ(*p1, wd / 2, col)

    # outer arc (ringing arc) with round caps
    import math
    acx, acy, ar, aw = 390, 385, 351, 22
    d.arc((P(acx - ar, acy - ar), P(acx + ar, acy + ar)), -88, 46, fill=lime, width=round(aw * u))
    for ang in (-88, 46):
        cx = acx + (ar - aw / 2) * math.cos(math.radians(ang))
        cy = acy + (ar - aw / 2) * math.sin(math.radians(ang))
        circ(cx, cy, aw / 2, lime)
    # side / bottom pills
    d.rounded_rectangle((*P(25, 318), *P(70, 440)), radius=22 * u, fill=pill)
    d.rounded_rectangle((*P(328, 695), *P(448, 738)), radius=21 * u, fill=pill)
    # clock body
    circ(385, 385, 305, olive)
    circ(385, 385, 272, lime)
    circ(265, 222, 18, white)
    circ(217, 270, 20, white)
    # hands: olive outline first, then white fill
    hub = (388, 388)
    thick(hub, (540, 262), 84, olive)
    thick(hub, (490, 478), 84, olive)
    thick(hub, (540, 262), 54, white)
    thick(hub, (490, 478), 54, white)
    circ(*hub, 68, olive)
    circ(*hub, 48, white)
    return im.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------- banners
def banner(W, H, locale, tagline, accent, theme, shots, name_size, tag_size, text_w, dev_specs, icon):
    """Feature graphic / OG card: flat field, icon + app name + tagline, devices right."""
    pal = palette(accent, theme)
    canvas = Image.new("RGB", (W, H), pal["bg"])
    fill_circle(canvas, round(0.80 * W), round(0.62 * H), round(0.55 * H), pal["field"])
    draw = ImageDraw.Draw(canvas)
    mx = round(0.045 * W)
    isz = round(0.16 * H)
    canvas.paste(icon.resize((isz, isz), Image.LANCZOS), (mx, round(0.10 * H)),
                 rr_mask(isz, isz, round(isz * 0.22)))
    ny = round(0.10 * H) + isz + round(0.04 * H)
    draw.text((mx, ny), "Enfo", font=latin_font(name_size), fill=pal["text"])
    ty = ny + round(name_size * 1.25)
    boxh = H - ty - round(0.07 * H)
    font, lines, lh = fit_text(tagline, locale, text_w, boxh, tag_size, 12, 4)
    draw_lines(draw, lines, font, lh, mx, ty, pal["text"], text_w, boxh)
    for shot, (x, y, sw) in zip(shots, dev_specs):
        sh = round(sw * shot.height / shot.width)
        draw_device(canvas, shot, x, y, sw, sh, pal["bezel"])
    return canvas


def load_shot(scenes, sid, lang, device="phone", orient="portrait"):
    return Image.open(raw_path(device, orient, scenes[sid], lang)).convert("RGB")


def make_graphics(scenes, hb, locales, icon):
    GFX.mkdir(parents=True, exist_ok=True)
    save_png(icon, GFX / "icon_512.png")
    for locale in locales:
        tag = (LISTING / locale / "feature_graphic_tagline.txt").read_text(encoding="utf-8").strip()
        lang = lang_of(locale)
        shots = [load_shot(scenes, s, lang) for s in ("hero", "styles", "clock_night")]
        # three flat portrait devices, bleeding off the bottom (and right) edge
        specs = []
        widths = [150, 178, 150]
        x = 520
        for w in widths:
            sh = round(w * 16 / 9)
            b = max(4, round(0.02 * w))
            y = 500 - (sh + 2 * b) + 8 + (0 if w == widths[1] else 40)
            specs.append((x, y, w - 2 * b))
            x += w + 14
        fg = banner(1024, 500, locale, tag, scenes["hero"]["accent"], "dark", shots, 76, 30, 430, specs, icon)
        save_png(fg, GFX / f"feature_graphic_{locale}.png")
        # OG card (only en-US, the site default)
    tag = (LISTING / "en-US" / "feature_graphic_tagline.txt").read_text(encoding="utf-8").strip()
    shots = [load_shot(scenes, s, "en") for s in ("hero", "styles")]
    specs = []
    x = 700
    for w, dy in ((210, 0), (210, 40)):
        sh = round(w * 16 / 9)
        b = max(4, round(0.02 * w))
        specs.append((x, 630 - (sh + 2 * b) + 8 + dy, w - 2 * b))
        x += w + 20
    og = banner(1200, 630, "en-US", tag, scenes["hero"]["accent"], "dark", shots, 96, 36, 560, specs, icon)
    save_png(og, GFX / "og_1200x630.png")


def make_montage(paths, out):
    tw, th, gap = 300, 533, 36
    n = len(paths)
    W = n * tw + (n + 1) * gap
    H = th + 2 * gap
    m = Image.new("RGB", (W, H), NEUTRAL_BG)
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGB").resize((tw, th), Image.LANCZOS)
        m.paste(im, (gap + i * (tw + gap), gap), rr_mask(tw, th, 22))
    save_png(m, out)


# ---------------------------------------------------------------- validation
def validate(locales):
    problems = []
    count = 0
    for locale in locales:
        for device, (w, h) in DEVICES.items():
            for orient in ("portrait", "landscape"):
                size = (w, h) if orient == "portrait" else (h, w)
                d = OUT / locale / f"{device}-{orient}"
                files = sorted(d.glob("*.png"))
                if len(files) != len(SCENES):
                    problems.append(f"{d}: {len(files)} files")
                for f in files:
                    count += 1
                    im = Image.open(f)
                    if im.size != size:
                        problems.append(f"{f}: size {im.size} != {size}")
                    if im.mode != "RGB":
                        problems.append(f"{f}: mode {im.mode}")
                    if f.stat().st_size >= 8 * 1024 * 1024:
                        problems.append(f"{f}: {f.stat().st_size} bytes")
    checks = {"icon_512.png": (512, 512), "og_1200x630.png": (1200, 630), "montage_phone.png": None}
    for locale in locales:
        checks[f"feature_graphic_{locale}.png"] = (1024, 500)
    for n, sz in checks.items():
        p = GFX / n
        if not p.exists():
            problems.append(f"missing {p}")
            continue
        im = Image.open(p)
        if sz and im.size != sz:
            problems.append(f"{p}: {im.size}")
        if im.mode != "RGB":
            problems.append(f"{p}: mode {im.mode}")
        if p.stat().st_size >= 8 * 1024 * 1024:
            problems.append(f"{p}: too big")
    return count, problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheets", default=None)
    ap.add_argument("--locales", default=None)
    a = ap.parse_args()
    scenes, hb, hs = load_data()
    locales = a.locales.split(",") if a.locales else [k for k in hs if not k.startswith("_")]
    for listing_id, _, _ in SCENES:
        assert listing_id in hs["_scenes"], listing_id

    for locale in locales:
        lang = lang_of(locale)
        for device in DEVICES:
            for orient in ("portrait", "landscape"):
                outs = []
                cap = common_size(device, orient, locale, hb)
                for i, (lid, slug, rid) in enumerate(SCENES, 1):
                    img = compose_shot(device, orient, locale, scenes[rid], hb[locale][lid], lang, cap)
                    p = OUT / locale / f"{device}-{orient}" / f"{i:02d}_{slug}.png"
                    save_png(img, p)
                    outs.append(p)
                if a.sheets:
                    contact_sheet(outs, Path(a.sheets) / f"{locale}_{device}-{orient}.png",
                                  cols=4 if orient == "portrait" else 2,
                                  thumb=360 if orient == "portrait" else 720)
        print("done", locale)

    icon = draw_icon()
    make_graphics(scenes, hb, locales, icon)
    make_montage([OUT / "en-US" / "phone-portrait" / f"{i:02d}_{s[1]}.png" for i, s in enumerate(SCENES, 1)],
                 GFX / "montage_phone.png")
    count, problems = validate(locales)
    print(f"{count} screenshots validated")
    if problems:
        print("PROBLEMS:")
        print("\n".join(problems))
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
