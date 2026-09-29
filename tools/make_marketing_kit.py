#!/usr/bin/env python3
"""Builds the downloadable marketing kit.

    python3 tools/make_logo.py                       # logo sources (if the logo changed)
    python3 tools/compose_store_assets.py --graphics-only
    python3 tools/make_marketing_kit.py [--no-video]

1. store/marketing/logo/      logo + mark in SVG and PNG (light/dark/mono, many sizes)
2. store/marketing/banners/   cover banners (16:9, 3:1 social header, 16:9 4K, square)
3. store/marketing/video/     logo build animation (mp4 dark, mp4 wide, webm with alpha)
4. docs/assets/press/enfo-marketing-kit.zip   everything above + store graphics,
   screenshots (en-US, es-419), promo videos, fonts and a README.
Needs Pillow and ffmpeg (libx264, libvpx-vp9).
"""
import argparse, json, shutil, subprocess, sys, zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from PIL import Image, ImageDraw
import brand_draw as bd
import compose_store_assets as cs
import make_logo as ml

ROOT = cs.ROOT
MK = ROOT / "store" / "marketing"
ZIP = ROOT / "docs" / "assets" / "press" / "enfo-marketing-kit.zip"
INK, LIME, LIGHT, DARK = (22, 20, 26), (205, 220, 57), (230, 238, 156), "#16141a"
WHITE = (255, 255, 255)


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


# ------------------------------------------------------------------ logo
def make_logo():
    out = MK / "logo"
    shutil.rmtree(out, ignore_errors=True)
    (out / "svg").mkdir(parents=True)
    # SVG sources
    (out / "svg/enfo_icon_rounded.svg").write_text(ml.svg(ml.mark(), rx=112, scale=1.1))
    (out / "svg/enfo_icon_square.svg").write_text(ml.svg(ml.mark(), rx=0, scale=1.25))
    (out / "svg/enfo_mark.svg").write_text(ml.svg(ml.mark(), bg=None))
    (out / "svg/enfo_mark_white.svg").write_text(ml.svg(ml.mark("#ffffff", "#ffffff"), bg=None))
    (out / "svg/enfo_mark_black.svg").write_text(ml.svg(ml.mark(DARK, DARK), bg=None))
    (out / "svg/enfo_mark_two_tone_dark.svg").write_text(ml.svg(ml.mark(DARK, "#5a5f1c"), bg=None))
    # PNGs
    for s in (16, 32, 48, 64, 96, 128, 180, 192, 256, 384, 512, 1024):
        ml.png(ml.svg(ml.mark(), rx=112, scale=1.1), out / f"icon_rounded/enfo_icon_{s}.png", s)
    for s in (512, 1024, 2048):
        ml.png(ml.svg(ml.mark(), rx=0, scale=1.25), out / f"icon_square/enfo_icon_square_{s}.png", s)
    for name, svg_text in (("lime", ml.svg(ml.mark(), bg=None)),
                           ("white", ml.svg(ml.mark("#ffffff", "#ffffff"), bg=None)),
                           ("black", ml.svg(ml.mark(DARK, DARK), bg=None))):
        for s in (256, 512, 1024, 2048):
            ml.png(svg_text, out / f"mark_transparent/enfo_mark_{name}_{s}.png", s)
    # Horizontal lockups (mark + wordmark) on dark / light / transparent
    for name, bg, col, tint, txt in (("dark", INK, LIME, LIGHT, WHITE),
                                     ("light", (243, 245, 244), INK, (110, 118, 20), INK),
                                     ("transparent", None, LIME, LIGHT, LIME)):
        im = lockup(2400, 800, bg, col, tint, txt)
        (out / "lockup").mkdir(exist_ok=True)
        im.save(out / f"lockup/enfo_lockup_{name}.png")
    return out


def wordmark(draw, text, x, cy, size, fill, spacing):
    f = cs.ImageFont.truetype(str(cs.FONTS / "GeistMono-Bold.ttf"), size)
    for ch in text:
        draw.text((x, cy), ch, font=f, fill=fill, anchor="lm")
        x += draw.textlength(ch, font=f) + spacing
    return x


def lockup(W, H, bg, col, tint, txt):
    im = Image.new("RGBA", (W, H), (bg + (255,)) if bg else (0, 0, 0, 0))
    m = bd.draw_mark(round(H * 0.62), 1.0, color=col, tint=tint)
    d = ImageDraw.Draw(im)
    size = round(H * 0.3)
    f = cs.ImageFont.truetype(str(cs.FONTS / "GeistMono-Bold.ttf"), size)
    sp = size * .18
    tw = sum(d.textlength(c, font=f) + sp for c in "enfo") - sp
    gap = H * 0.08
    x0 = (W - (m.width + gap + tw)) / 2
    im.alpha_composite(m, (round(x0), (H - m.height) // 2))
    wordmark(d, "enfo", x0 + m.width + gap, H / 2 + size * .04, size, txt + (255,), sp)
    return im


# ------------------------------------------------------------------ banners
def cover(W, H, out, shots_ids=("hero", "styles", "clock_night"), locale="en-US"):
    scenes, hb, hs = cs.load_data()
    accent = scenes["hero"]["accent"]
    tag = (cs.LISTING / locale / "feature_graphic_tagline.txt").read_text(encoding="utf-8").strip()
    icon = cs.draw_icon()
    shots = [cs.load_shot(scenes, s, "en") for s in shots_ids]
    s = H / 500 if W / H > 2.5 else min(W / 1200, H / 630)
    wide = W / H > 2.5
    widths = [150, 178, 150] if wide else [180, 215, 180]
    specs, x = [], (W * 0.5 if wide else W * 0.56)
    for w, dy in zip(widths, (40, 0, 40)):
        w = round(w * s)
        sh = round(w * 16 / 9)
        b = max(4, round(0.02 * w))
        specs.append((round(x), round(H - (sh + 2 * b) + 8 * s + dy * s), w - 2 * b))
        x += w + 14 * s
    if not wide:  # keep the trio inside the canvas
        overflow = x - 14 * s - W
        if overflow > 0:
            specs = [(sx - round(overflow), sy, sw) for sx, sy, sw in specs]
    name_size = round((76 if wide else 96) * s * (1 if wide else .95))
    img = cs.banner(W, H, locale, tag, accent, "dark", shots, name_size,
                    round((30 if wide else 36) * s), round((430 if wide else 500) * s), specs, icon)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)


def make_banners():
    b = MK / "banners"
    shutil.rmtree(b, ignore_errors=True)
    cover(1920, 1080, b / "enfo_cover_1920x1080.png")
    cover(2560, 1440, b / "enfo_cover_4k_2560x1440.png")
    cover(1500, 500, b / "enfo_social_header_1500x500.png")
    # Square post: mark + wordmark + tagline on the brand dark
    scenes, hb, hs = cs.load_data()
    pal = cs.palette(scenes["hero"]["accent"], "dark")
    S = 1080
    sq = Image.new("RGB", (S, S), pal["bg"])
    cs.fill_circle(sq, round(S * .78), round(S * .86), round(S * .62), pal["field"])
    m = bd.draw_mark(560, 1.0, color=LIME, tint=LIGHT)
    sq.paste(m, ((S - 560) // 2, 150), m)
    d = ImageDraw.Draw(sq)
    tw = sum(d.textlength(c, font=cs.latin_font(130)) + 24 for c in "enfo") - 24
    wordmark(d, "enfo", (S - tw) / 2, 800, 130, pal["text"], 24)
    tag = (cs.LISTING / "en-US" / "feature_graphic_tagline.txt").read_text(encoding="utf-8").strip()
    f = cs.latin_font(36)
    d.text((S / 2, 920), tag, font=f, fill=pal["kicker"], anchor="mm")
    sq.save(b / "enfo_square_1080.png", optimize=True)
    # Web version of the 16:9 cover, for the site's "In your pocket" section
    web = Image.open(b / "enfo_cover_1920x1080.png").convert("RGB").resize((1280, 720), Image.LANCZOS)
    web.save(ROOT / "docs" / "assets" / "cover-banner.webp", "WEBP", quality=86, method=6)


# ------------------------------------------------------------------ logo animation
def frames_to(dirp, W, H, n, bg, transparent=False):
    dirp.mkdir(parents=True, exist_ok=True)
    msz = round(min(W, H) * 0.5)
    for i in range(n):
        t = i / (n - 1)
        build = min(1, max(0, (t - 0.06) / 0.5))
        word = min(1, max(0, (t - 0.55) / 0.2))
        sub = min(1, max(0, (t - 0.68) / 0.2))
        out = min(1, max(0, (t - 0.94) / 0.06)) if False else 0
        canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0) if transparent else bg + (255,))
        m = bd.draw_mark(msz, build, color=LIME, tint=LIGHT)
        my = round(H * 0.5 - msz * 0.62)
        canvas.alpha_composite(m, ((W - msz) // 2, my))
        d = ImageDraw.Draw(canvas)
        size = round(msz * 0.27)
        f = cs.ImageFont.truetype(str(cs.FONTS / "GeistMono-Bold.ttf"), size)
        sp = size * .22
        tw = sum(d.textlength(c, font=f) + sp for c in "enfo") - sp
        lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(lay)
        wordmark(ld, "enfo", (W - tw) / 2, my + msz + size * .95 + (1 - word) * 18, size, WHITE + (round(255 * word),), sp)
        f2 = cs.ImageFont.truetype(str(cs.FONTS / "GeistMono-Medium.ttf"), round(size * .27))
        ld.text((W / 2, my + msz + size * 1.85 + (1 - sub) * 12), "a clock & timer toolbox", font=f2,
                fill=LIGHT + (round(255 * sub),), anchor="mm")
        canvas.alpha_composite(lay)
        canvas.save(dirp / f"f_{i:04d}.png", compress_level=1)


def make_video():
    v = MK / "video"
    shutil.rmtree(v, ignore_errors=True)
    v.mkdir(parents=True)
    tmp = Path("/tmp/enfo_logo_frames")
    shutil.rmtree(tmp, ignore_errors=True)
    n = 150  # 5 s
    for name, (W, H) in (("square_1080", (1080, 1080)), ("wide_1920x1080", (1920, 1080))):
        frames_to(tmp / name, W, H, n, INK)
        # hold the last frame for 1 s
        last = tmp / name / f"f_{n - 1:04d}.png"
        for k in range(30):
            shutil.copy(last, tmp / name / f"f_{n + k:04d}.png")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-i", str(tmp / name / "f_%04d.png"),
                        "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p",
                        "-movflags", "+faststart", str(v / f"enfo_logo_reveal_{name}.mp4")], check=True)
    # Transparent (WebM/VP9 with alpha): the mark and wordmark only, to drop over anything
    frames_to(tmp / "alpha", 1080, 1080, n, INK, transparent=True)
    last = tmp / "alpha" / f"f_{n - 1:04d}.png"
    for k in range(30):
        shutil.copy(last, tmp / "alpha" / f"f_{n + k:04d}.png")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-i", str(tmp / "alpha" / "f_%04d.png"),
                    "-c:v", "libvpx-vp9", "-pix_fmt", "yuva420p", "-crf", "24", "-b:v", "0", "-auto-alt-ref", "0",
                    str(v / "enfo_logo_reveal_transparent.webm")], check=True)


# ------------------------------------------------------------------ zip
README = """ENFO - MARKETING KIT
====================
Enfo is a flat, calm clock & timer toolbox for Android, Windows and Linux.
Site: https://sazardev.github.io/enfo/   Source: https://github.com/sazardev/enfo

WHAT IS INSIDE
  logo/            svg/ (vector), icon_rounded/, icon_square/ (store icons, no
                   rounding), mark_transparent/ (lime, white, black), lockup/
                   (mark + wordmark on dark, light and transparent)
  banners/         enfo_cover_1920x1080, enfo_cover_4k_2560x1440,
                   enfo_social_header_1500x500, enfo_square_1080
  store_graphics/  Google Play feature graphics (1024x500) in 10 languages,
                   Play icon 512, Open Graph card 1200x630, phone montage
  screenshots/     Play screenshots (en-US, es-419): phone, 7" and 10" tablets,
                   portrait and landscape, 8 scenes each
  video/           promo videos (portrait 1080x1920, landscape 1920x1080, with
                   music), hero loop (mp4/webm), logo reveal animations
                   (square, wide, and transparent WebM)
  fonts/           Geist Mono (SIL OFL 1.1), the app and logo typeface

BRAND
  Mark:      a lowercase "e" drawn as a timer ring; the crossbar is the clock
             hand, with a pivot dot at the centre.
  Colours:   lime #CDDC39 (mark), soft lime #E6EE9C (hand), ink #16141A (background).
             Inside the app the mark follows the user's accent colour.
  Typeface:  Geist Mono Bold, lowercase "enfo", wide tracking.
  Clear space: at least the width of the hand's stroke (about 16% of the mark).
  Please do not: stretch or rotate the mark, recolour it outside the supplied
  variants, or put it on low-contrast backgrounds.

TAGLINES
  Every clock you need, in one calm app.
  Focus, one calm dial.
  A clock & timer toolbox: 16 tools, 63 clock styles, 9 languages.

CREDITS
  Promo video soundtrack: "Chill Beat" by Maddy, CC0 (public domain).
  Screenshots show the real app.
"""


def make_zip():
    ZIP.parent.mkdir(parents=True, exist_ok=True)
    if ZIP.exists():
        ZIP.unlink()
    root = "enfo-marketing-kit"
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        def add(src, arc):
            z.write(src, f"{root}/{arc}")

        def add_dir(src, arc, pats=("*",)):
            for pat in pats:
                for p in sorted(Path(src).rglob(pat)):
                    if p.is_file():
                        add(p, f"{arc}/{p.relative_to(src)}")
        z.writestr(f"{root}/README.txt", README)
        add_dir(MK / "logo", "logo")
        add_dir(MK / "banners", "banners")
        add_dir(cs.GFX, "store_graphics", ("feature_graphic_*.png", "icon_512.png", "og_1200x630.png", "montage_phone.png"))
        for loc in ("en-US", "es-419"):
            add_dir(cs.OUT / loc, f"screenshots/{loc}", ("*.png",))
        add_dir(ROOT / "store" / "video", "video", ("*.mp4", "*.webm"))
        add_dir(MK / "video", "video", ("*.mp4", "*.webm"))
        add_dir(cs.FONTS, "fonts", ("GeistMono-*.ttf", "OFL.txt"))
    print(f"{ZIP.relative_to(ROOT)}: {ZIP.stat().st_size / 1e6:.1f} MB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-video", action="store_true", help="reuse store/marketing/video")
    a = ap.parse_args()
    MK.mkdir(parents=True, exist_ok=True)
    make_logo()
    make_banners()
    if not a.no_video:
        make_video()
    make_zip()


if __name__ == "__main__":
    main()
