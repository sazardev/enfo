"""Enfo logo: a lowercase "e" drawn as the timer ring, whose crossbar is the clock hand
(with a pivot dot). Regenerates every icon from one geometry. Needs rsvg-convert + ImageMagick.

    python3 tools/make_logo.py

Writes store/graphics/logo/*.svg, the Android launcher PNGs + adaptive/monochrome
icon, the Windows .ico, the Play icon and the site favicons.
"""
import math, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BG, LIME, LIGHT = "#16141a", "#cddc39", "#e6ee9c"
R, W = 140, 52  # ring radius / stroke


def pt(r, a):
    t = math.radians(a)
    return 256 + r * math.sin(t), 256 - r * math.cos(t)


def mark(c1=LIME, c2=LIGHT):
    """The "e" in a 512 space, centred on (256, 256)."""
    x0, y0 = pt(R, 140)
    x1, y1 = pt(R, 450)
    return (
        f'<path d="M{x0:.2f} {y0:.2f} A{R} {R} 0 1 1 {x1:.2f} {y1:.2f}" fill="none" stroke="{c1}" '
        f'stroke-width="{W}" stroke-linecap="round"/>'
        f'<line x1="256" y1="256" x2="{256 + R}" y2="256" stroke="{c2}" stroke-width="{W}" stroke-linecap="round"/>'
        f'<circle cx="256" cy="256" r="44" fill="{c2}"/>'
    )


def svg(body, bg=BG, rx=0, scale=1.0):
    b = f'<rect width="512" height="512" rx="{rx}" fill="{bg}"/>' if bg else ""
    g = f'<g transform="translate(256 256) scale({scale}) translate(-256 -256)">{body}</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">{b}{g}</svg>'


def png(svg_text, out, size):
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", str(out)],
                   input=svg_text.encode(), check=True)


def main():
    logo = ROOT / "store/graphics/logo"
    logo.mkdir(parents=True, exist_ok=True)
    (logo / "enfo_logo.svg").write_text(svg(mark(), rx=112, scale=1.1))
    (logo / "enfo_mark.svg").write_text(svg(mark(), bg=None))
    (logo / "enfo_mark_mono.svg").write_text(svg(mark("#000", "#000"), bg=None))

    square = svg(mark(), rx=0, scale=1.25)      # Play icon: store applies its own mask
    rounded = svg(mark(), rx=112, scale=1.1)    # legacy launcher, site, drawable

    png(square, ROOT / "store/graphics/icon_512.png", 512)
    res = ROOT / "android/app/src/main/res"
    for d, s in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        png(rounded, res / f"mipmap-{d}/ic_launcher.png", s)
    for d in ("drawable", "drawable-v21"):
        png(rounded, res / d / "icon.png", 192)
    docs = ROOT / "docs/assets"
    png(rounded, docs / "icon-192.png", 192)
    png(rounded, docs / "favicon-32.png", 32)

    tmp = ROOT / "build/_ico"
    sizes = [16, 24, 32, 48, 64, 128, 256]
    files = []
    for s in sizes:
        p = tmp / f"{s}.png"
        png(rounded, p, s)
        files.append(str(p))
    subprocess.run(["magick", *files, str(ROOT / "windows/runner/resources/app_icon.ico")], check=True)

    # Adaptive icon (API 26+): 108dp canvas, ~58dp mark inside the 66dp safe zone.
    k = 58 / 332
    off = 54 - 256 * k

    def vec(c1, c2):
        x0, y0 = pt(R, 140)
        x1, y1 = pt(R, 450)
        return f'''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <group android:translateX="{off:.3f}" android:translateY="{off:.3f}" android:scaleX="{k:.5f}" android:scaleY="{k:.5f}">
        <path android:pathData="M{x0:.2f},{y0:.2f} A{R},{R} 0 1,1 {x1:.2f},{y1:.2f}"
            android:strokeColor="{c1}" android:strokeWidth="{W}" android:strokeLineCap="round"/>
        <path android:pathData="M256,256 L{256 + R},256"
            android:strokeColor="{c2}" android:strokeWidth="{W}" android:strokeLineCap="round"/>
        <path android:pathData="M212,256 a44,44 0 1,0 88,0 a44,44 0 1,0 -88,0" android:fillColor="{c2}"/>
    </group>
</vector>
'''

    (res / "drawable/ic_launcher_foreground.xml").write_text(vec(LIME, LIGHT))
    (res / "drawable/ic_launcher_monochrome.xml").write_text(vec("#FF000000", "#FF000000"))
    (res / "drawable/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<shape xmlns:android="http://schemas.android.com/apk/res/android">\n'
        f'    <solid android:color="{BG}"/>\n</shape>\n')
    any26 = res / "mipmap-anydpi-v26"
    any26.mkdir(exist_ok=True)
    (any26 / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n</adaptive-icon>\n')


if __name__ == "__main__":
    main()
