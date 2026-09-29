"""Enfo logo drawing for Pillow: static marks and the build animation, with the same
geometry and timeline as lib/ui/brand/enfo_mark.dart and tools/make_logo.py.
Used by the promo video outro, the logo reveal and the marketing banners."""
import math
from PIL import Image, ImageDraw

BOX, R, STROKE, PIVOT = 332.0, 140.0, 52.0, 44.0
SS = 4  # supersampling


def _interval(t, a, b, curve=lambda x: x):
    x = min(1.0, max(0.0, (t - a) / (b - a)))
    return x if x in (0.0, 1.0) else curve(x)


def _ease_out_cubic(x):
    return 1 - (1 - x) ** 3


def _ease_in_out_cubic(x):
    return 4 * x ** 3 if x < 0.5 else 1 - (-2 * x + 2) ** 3 / 2


def _ease_out(x):  # Curves.easeOut ~ cubic-bezier(.0,.0,.58,1)
    return 1 - (1 - x) ** 2


def _bouncy(x, mass=0.5, k=300.0, c=8.0):  # Motion.bouncy (SpringCurve)
    wn = math.sqrt(k / mass)
    z = c / (2 * math.sqrt(k * mass))
    d = math.exp(-z * wn * x)
    wd = wn * math.sqrt(1 - z * z)
    return 1 - d * (math.cos(wd * x) + (z * wn / wd) * math.sin(wd * x))


def phases(t):
    """t in 0..1 -> (ring, track, pivot, hand), as EnfoMark computes them."""
    ring = _interval(t, 0.0, 0.55, _ease_in_out_cubic)
    track = _interval(t, 0.0, 0.2, _ease_out) * (1 - _interval(t, 0.45, 0.6))
    pivot = _interval(t, 0.42, 0.7, _bouncy)
    hand = _interval(t, 0.62, 0.92, _ease_out_cubic)
    return ring, track, pivot, hand


def mix(a, b, f):
    return tuple(round(a[i] + (b[i] - a[i]) * f) for i in range(3))


def draw_mark(size, t=1.0, color=(205, 220, 57), tint=(230, 238, 156), bg=None):
    """The mark at build progress t, on `bg` (RGB) or transparent. Square `size` px."""
    ring, track, pivot, hand = phases(t)
    S = size * SS
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = S / BOX
    c = S / 2
    w = STROKE * k
    r = R * k

    def cap(x, y, col):
        d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=col)

    if track > 0:
        col = color + (round(255 * 0.14 * track),)
        o = r + w / 2  # PIL strokes inward from the bounding box
        d.ellipse((c - o, c - o, c + o, c + o), outline=col, width=round(w))
    if ring > 0:
        a0, sweep = 50.0, 310.0 * ring
        o = r + w / 2
        d.arc((c - o, c - o, c + o, c + o), a0, a0 + sweep, fill=color + (255,), width=round(w))
        for a in (a0, a0 + sweep):
            cap(c + r * math.cos(math.radians(a)), c + r * math.sin(math.radians(a)), color + (255,))
    if hand > 0:
        d.line((c, c, c + r * hand, c), fill=tint + (255,), width=round(w))
        cap(c, c, tint + (255,))
        cap(c + r * hand, c, tint + (255,))
    if pivot > 0:
        pr = PIVOT * k * pivot
        d.ellipse((c - pr, c - pr, c + pr, c + pr), fill=tint + (255,))
    im = im.resize((size, size), Image.LANCZOS)
    if bg is not None:
        base = Image.new("RGBA", (size, size), bg + (255,))
        im = Image.alpha_composite(base, im).convert("RGB")
    return im
