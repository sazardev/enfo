#!/usr/bin/env python3
"""Builds the bundled ambience loops in assets/ambience/*.ogg.

For every entry in TRACKS: check the license on Wikimedia Commons, download
the original (cached under /tmp/opencode/ambience_src), decode to mono 32 kHz
with a 40 Hz high-pass and a 10 kHz low-pass, tile and fold with a crossfade
so the loop has no seam, soft-clip it at the same RMS the synthesized noises
use, and encode Ogg Vorbis at q0. The script also regenerates the Dart catalog
(lib/modes/ambient/ambience_catalog.dart) and the credits page data
(assets/ambience/CREDITS.md).

Usage: python3 tools/fetch_ambience.py [--only KEY ...] [--list] [--audit]

--list prints the manifest; --audit only checks licenses and exits.
"""
import argparse, html, json, math, os, re, subprocess, sys, time, urllib.parse, urllib.request

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets", "ambience")
CACHE = "/tmp/opencode/ambience_src"
META = "/tmp/opencode/ambience_meta.json"
UA = "enfo-ambience/1.0 (https://github.com/sazardev/enfo; contact: dev)"
API = "https://commons.wikimedia.org/w/api.php"

RATE = 32000
TARGET_RMS = 0.2        # same ballpark as AmbientSynth._targetRms
FADE = 2.0              # loop crossfade seconds
TILE_FADE = 0.5         # seams when a source is shorter than the loop
LICENSE_URLS = {
    "CC0": "http://creativecommons.org/publicdomain/zero/1.0/deed.en",
    "Public domain": "https://creativecommons.org/publicdomain/mark/1.0/",
    "CC BY 4.0": "https://creativecommons.org/licenses/by/4.0",
    "CC BY 3.0": "https://creativecommons.org/licenses/by/3.0",
}
ALLOWED = set(LICENSE_URLS)

# key, group, english title, commons file, loop seconds, optional overrides.
# A "mix" entry is built from other keys at the given gains.
TRACKS = [
    # ---------------------------------------------------------- nature (breaks)
    dict(key="stream", group="nature", title="Stream", loop=60,
         commons="File:433589 jackthemurray stream-river-water-up-close.wav"),
    dict(key="snowmelt", group="nature", title="Snowmelt", loop=60,
         commons="File:Snowmelt flowing into lake at Okanagan Mountain Provincial Park.flac"),
    dict(key="rivulet", group="nature", title="Rivulet", loop=60,
         commons="File:Welling rivulet in the woods.ogg"),
    dict(key="fountain_toulouse", group="nature", title="Fountain", loop=60,
         commons="File:Fountain in toulouse.ogg"),
    dict(key="fountain_place", group="nature", title="Plaza fountain", loop=75,
         commons="File:La fontaine de la place.ogg"),
    dict(key="geyser_anemone", group="nature", title="Geyser", loop=48,
         commons="File:Yellowstone sound library - Big Anemone Geyser - 001.mp3"),
    dict(key="geyser_beehive", group="nature", title="Bubbling geyser", loop=75,
         commons="File:Yellowstone sound library - Beehive Geyser - 001.mp3"),
    dict(key="rain_window", group="nature", title="Rain on the window", loop=75,
         commons="File:Rain against the window.ogg"),
    dict(key="rain_thunder1", group="nature", title="Rain and thunder", loop=58,
         commons="File:Rain and thunder (1).ogg"),
    dict(key="rain_uetersen", group="nature", title="Thunderstorm", loop=75,
         commons="File:Uetersen Regen und Gewitter 01.ogg"),
    dict(key="storm_thunder", group="nature", title="Thunderbolts", loop=75,
         commons="File:Storm thunderbolts.ogg"),
    dict(key="wind_killiney", group="nature", title="Storm wind", loop=66,
         commons="File:Killiney Hill Storm Floris 20250804 1537.ogg"),
    dict(key="forest_nille", group="nature", title="Forest", loop=75,
         commons="File:20090610 0 ambience.ogg"),
    dict(key="forest_gravity1", group="nature", title="Forest with birds", loop=60,
         commons="File:Forest ambience (Gravity Sound).wav"),
    dict(key="dawn_royal", group="nature", title="Dawn chorus", loop=75,
         commons="File:Royal Natal National Park dawn chorus (W1CDR0001146 BD3).ogg",
         artist="The British Library"),
    dict(key="dawn_uk", group="nature", title="Country dawn", loop=75,
         commons="File:Dawnchorus-uk.ogg"),
    dict(key="pond_dordogne", group="nature", title="Pond at dusk", loop=55,
         commons="File:Nature sounds ambience in a Dordogne pond.ogg"),
    dict(key="birds_reggeli", group="nature", title="Morning birds", loop=75,
         commons="File:Reggelirigók.ogg"),
    dict(key="campfire", group="nature", title="Campfire", loop=59,
         commons="File:Campfire sound ambience.ogg"),
    dict(key="fire_grass", group="nature", title="Fireplace", loop=24,
         commons="File:Dry grass burning in open fireplace.ogg"),
    # ----------------------------------------------------------- place (ambient)
    dict(key="lib_quiet", group="place", title="Library", loop=75,
         commons="File:20121112 TU Delft Library, quiet study room - general ambience - SoundCloud - el mar.ogg"),
    dict(key="lib_ground", group="place", title="Busy library", loop=75,
         commons="File:20121112 TU Delft Library, ground level - general ambience - SoundCloud - el mar.ogg"),
    dict(key="office", group="place", title="Office", loop=75,
         mix=[["lib_quiet", 1.0], ["computer_kb", 0.16]]),
    dict(key="classroom", group="place", title="Classroom", loop=64,
         commons="File:Ambient classroom mono.ogg"),
    dict(key="cafeteria", group="place", title="Cafeteria", loop=75,
         commons="File:High school cafeteria.ogg"),
    dict(key="restaurant", group="place", title="Restaurant", loop=75,
         commons="File:Restaurant ambience.ogg"),
    dict(key="supermarket", group="place", title="Supermarket", loop=28,
         commons="File:Supermarket prize scan packing bought stuff people.ogg"),
    dict(key="mall_berlin", group="place", title="Shopping mall", loop=59,
         commons="File:1 minute at the alexa mall in berlin.ogg"),
    dict(key="urban_rain", group="place", title="Rainy street", loop=75,
         commons="File:Urban Street on a Rainy Afternoon.flac"),
    dict(key="urban_berlin", group="place", title="Spring street", loop=75,
         commons="File:184809 qubodup first-day-of-urban-spring-in-berlin-2013-04-14.flac"),
    dict(key="ttc_museum", group="place", title="Subway", loop=75,
         commons="File:TTC Subway Line 1 Ambience - Museum to Union (Freesound).ogg"),
    dict(key="ttc_dupont", group="place", title="Subway ride", loop=75,
         commons="File:TTC Subway Line 1 Ambience - Dupont to St George (Freesound).ogg"),
    dict(key="station_tampere", group="place", title="Station tunnel", loop=75,
         commons="File:WWS TheStationTunnelOfTheTampereStation.ogg"),
    dict(key="train_northern", group="place", title="Train", loop=75,
         commons="File:Northern Trains 323239 DMSO A, on the Crewe to Manchester line, Jan 2022.ogg"),
    dict(key="train_taiwan", group="place", title="Taiwan train", loop=75,
         commons="File:Taiwan railways EP727 train cars sounds.ogg"),
    dict(key="escalator", group="place", title="Escalator", loop=40,
         commons="File:WWS Escalator.ogg"),
    dict(key="elevator", group="place", title="Elevator", loop=28,
         commons="File:Elevator ride.ogg"),
    dict(key="playground", group="place", title="Playground", loop=48,
         commons="File:Douzen kids on playground.ogg"),
    dict(key="fleamarket", group="place", title="Street market", loop=75,
         commons="File:Flea market in the rain.ogg"),
    dict(key="computer_kb", group="place", title="Keyboard", loop=75,
         commons="File:Computer keyboard.ogg"),
]


def commons_meta(title, retries=5):
    params = {"action": "query", "titles": title, "prop": "imageinfo",
              "iiprop": "url|size|mime|extmetadata", "format": "json"}
    req = urllib.request.Request(API + "?" + urllib.parse.urlencode(params),
                                 headers={"User-Agent": UA})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                d = json.load(r)
            break
        except Exception:
            if attempt == retries - 1:
                raise
            time.sleep(3 * (attempt + 1))
    page = list(d["query"]["pages"].values())[0]
    ii = page["imageinfo"][0]
    em = ii.get("extmetadata", {})

    def g(k):
        v = em.get(k, {}).get("value")
        return v if isinstance(v, str) else None

    artist = g("Artist") or g("Credit") or "Unknown"
    artist = re.sub(r"<[^>]+>", "", artist)
    artist = html.unescape(artist)
    artist = re.sub(r"\s+", " ", artist).strip()
    return {"url": ii["url"], "size": ii.get("size", 0), "license": g("LicenseShortName"),
            "artist": artist}


def load_meta():
    return json.load(open(META)) if os.path.exists(META) else {}


def save_meta(meta):
    json.dump(meta, open(META, "w"), ensure_ascii=False, indent=1)


def source_path(entry, meta):
    ext = os.path.splitext(meta[entry["commons"]]["url"])[1].split("?")[0] or ".bin"
    return os.path.join(CACHE, entry["key"] + ext)


def download(entry, meta):
    os.makedirs(CACHE, exist_ok=True)
    path = source_path(entry, meta)
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return path
    req = urllib.request.Request(meta[entry["commons"]]["url"],
                                 headers={"User-Agent": UA})
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=300) as r, open(path, "wb") as f:
                f.write(r.read())
            return path
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == 5:
                raise
            time.sleep(5 * (attempt + 1))
    return path


def decode(path):
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path,
         "-af", "highpass=f=40,lowpass=f=10000", "-ac", "1", "-ar", str(RATE),
         "-f", "f32le", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(out, dtype="<f4").copy()


def tile(x, need, fade=int(TILE_FADE * RATE)):
    while len(x) < need:
        take = np.concatenate([np.zeros(need - len(x)), x])[:need]
        head = x[-fade:].copy()
        tail = take[:fade].copy()
        ramp = np.linspace(0, math.pi / 2, fade, dtype=np.float32)
        x = np.concatenate([x[:-fade], head * np.cos(ramp) + tail * np.sin(ramp),
                            take[fade:]])
    return x


def fold(x, loop_s):
    n = int(loop_s * RATE)
    fade = int(FADE * RATE)
    x = tile(x, n + fade)
    out = x[:n].copy()
    ramp = np.linspace(0, math.pi / 2, fade, dtype=np.float32)
    out[:fade] = x[n:n + fade] * np.cos(ramp) + x[:fade] * np.sin(ramp)
    return out


def normalise(x):
    rms = float(np.sqrt(np.mean(x * x)))
    if rms < 1e-5:
        raise SystemExit("loop is silent")
    return np.tanh(x * (TARGET_RMS / rms))


def build(entry, meta, decoded):
    if "mix" in entry:
        parts = []
        for key, gain in entry["mix"]:
            y = decoded[key]
            parts.append(y * gain)
        length = min(len(p) for p in parts)
        x = sum(p[:length] for p in parts)
    else:
        x = decoded[entry["key"]]
    skip = int(5 * RATE) if len(x) > (entry["loop"] + FADE) * RATE + 5 * RATE else 0
    if len(x) - skip < (entry["loop"] + FADE) * RATE and len(x) > 10 * RATE:
        skip = 0
    x = x[skip:]
    loop = fold(x, entry["loop"])
    return normalise(loop)


def encode(pcm, path):
    p = subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "1",
         "-i", "-", "-af", "alimiter=limit=0.97", "-c:a", "libvorbis", "-q:a", "0",
         path], input=pcm.astype("<f4").tobytes(), capture_output=True)
    if p.returncode:
        raise SystemExit(p.stderr.decode())


def dart_catalog(rows):
    lines = [
        "// Generated by tools/fetch_ambience.py. Do not edit by hand.",
        "",
        "/// One recorded ambience loop bundled with the app (a seamless Ogg loop,",
        "/// mono 32 kHz at Vorbis q0 after the same deliberate lo-fi chain as the",
        "/// music bank). [group] is 'nature' (Breaks > relax sound) or 'place'",
        "/// (Ambient > environments).",
        "class AmbienceLoop {",
        "  const AmbienceLoop({",
        "    required this.asset,",
        "    required this.id,",
        "    required this.title,",
        "    required this.group,",
        "    required this.seconds,",
        "    required this.artist,",
        "    required this.license,",
        "    required this.licenseUrl,",
        "    required this.source,",
        "  });",
        "",
        "  final String asset;",
        "",
        "  /// Stable id, also the l10n label key suffix (`ambience<Id>`).",
        "  final String id;",
        "",
        "  /// Neutral English name (the UI shows the localized label).",
        "  final String title;",
        "  final String group;",
        "  final int seconds;",
        "  final String artist;",
        "  final String license;",
        "  final String licenseUrl;",
        "",
        "  /// The file's page on Wikimedia Commons.",
        "  final String source;",
        "",
        "  bool get needsCredit => license != 'CC0' && license != 'Public domain';",
        "}",
        "",
        "/// Nature loops first (1-20), then places (21-40).",
        "const List<AmbienceLoop> ambienceLoops = [",
    ]
    for r in rows:
        lines += [
            "  AmbienceLoop(",
            f"    asset: '{r['asset']}',",
            f"    id: '{r['id']}',",
            f"    title: '{r['title']}',",
            f"    group: '{r['group']}',",
            f"    seconds: {r['seconds']},",
            f"    artist: '{r['artist'].replace(chr(39), chr(92) + chr(39))}',",
            f"    license: '{r['license']}',",
            f"    licenseUrl: '{r['license_url']}',",
            f"    source: '{r['source']}',",
            "  ),",
        ]
    lines += [
        "];",
        "",
        "/// Nature loops (Breaks > relax sound).",
        "Iterable<AmbienceLoop> get natureLoops =>",
        "    ambienceLoops.where((l) => l.group == 'nature');",
        "",
        "/// Place loops (Ambient > environments).",
        "Iterable<AmbienceLoop> get placeLoops =>",
        "    ambienceLoops.where((l) => l.group == 'place');",
        "",
    ]
    path = os.path.join(ROOT, "lib", "modes", "ambient", "ambience_catalog.dart")
    open(path, "w").write("\n".join(lines))
    return path


def credits_md(rows):
    out = ["# Bundled ambience credits", "",
           "The 40 ambience loops are field recordings from [Wikimedia Commons]",
           "(https://commons.wikimedia.org), where each file's license is checked",
           "by the community. They are re-encoded to Ogg Vorbis (mono 32 kHz, q0,",
           "~30-45 kbps) after a deliberate lo-fi chain: 10 kHz low-pass, soft",
           "saturation and a two-second fold at the loop point so the loop has no",
           "seam. **CC0** and **public domain** recordings need no credit; **CC BY**",
           "recordings require the attribution below.", "",
           "| Sound | Artist | License | Source |", "|---|---|---|---|"]
    for r in rows:
        links = " · ".join(f"[Commons]({u})" for u in r["source"].split(" "))
        out.append(f"| {r['title']} | {r['artist']} | [{r['license']}]({r['license_url']}) "
                   f"| {links} |")
    path = os.path.join(ASSETS, "CREDITS.md")
    open(path, "w").write("\n".join(out) + "\n")
    return path


def entry_credits(entry, meta):
    """artist, license and source URLs for a normal or mixed entry."""
    partners = [entry] if "commons" in entry else [
        next(x for x in TRACKS if x["key"] == k) for k, _ in entry["mix"]]
    artists, licenses, sources = [], [], []
    for p in partners:
        m = meta[p["commons"]]
        artists.append(p.get("artist", m["artist"]))
        licenses.append(m["license"])
        sources.append("https://commons.wikimedia.org/wiki/" +
                       urllib.parse.quote(p["commons"][5:].replace(" ", "_")))
    license_name = next((l for l in ("CC BY 4.0", "CC BY 3.0", "CC0", "Public domain")
                         if l in licenses), licenses[0])
    return " + ".join(artists), license_name, " ".join(sources)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--audit", action="store_true")
    ap.add_argument("--catalog-only", action="store_true",
                    help="regenerate catalog and credits from existing assets")
    args = ap.parse_args()

    if args.list:
        for e in TRACKS:
            print(f"  {e['group']:6} {e['key']:18} {e.get('title') or '(mix)'}")
        return

    meta = load_meta()
    for e in TRACKS:
        if "commons" in e and e["commons"] not in meta:
            meta[e["commons"]] = commons_meta(e["commons"])
            save_meta(meta)
            time.sleep(1.0)
    bad = [e["key"] for e in TRACKS
           if "commons" in e and meta[e["commons"]]["license"] not in ALLOWED]
    if bad:
        sys.exit(f"licencias no permitidas: {bad}")
    if args.audit:
        for e in TRACKS:
            if "commons" in e:
                m = meta[e["commons"]]
                print(f"  {m['license']:14} {e['key']:18} {m['artist'][:40]}")
        return

    only = set(args.only) if args.only else None
    wanted = [] if args.catalog_only else [
        e for e in TRACKS if not only or e["key"] in only]
    os.makedirs(ASSETS, exist_ok=True)

    decoded = {}
    needed = set()
    for e in wanted:
        needed.update([p[0] for p in e["mix"]] if "mix" in e else [e["key"]])
    for e in TRACKS:
        if e["key"] in needed and "commons" in e:
            decoded[e["key"]] = decode(download(e, meta))

    rows = []
    for i, e in enumerate(TRACKS, start=1):
        asset_path = os.path.join(ASSETS, f"{i:02d}_{e['key']}.ogg")
        if not args.catalog_only and (not only or e["key"] in only):
            encode(build(e, meta, decoded), asset_path)
        dur = float(subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", asset_path], capture_output=True, text=True).stdout)
        artist, license_name, source = entry_credits(e, meta)
        rows.append({
            "asset": f"assets/ambience/{i:02d}_{e['key']}.ogg",
            "id": e["key"], "title": e["title"], "group": e["group"],
            "seconds": round(dur), "artist": artist, "license": license_name,
            "license_url": LICENSE_URLS.get(license_name, LICENSE_URLS["Public domain"]),
            "source": source,
        })
        print(f"{i:02d} {e['key']:18} {dur:5.1f}s "
              f"{os.path.getsize(asset_path) / 1e3:6.0f} KB  {artist[:40]}")

    dart_catalog(rows)
    credits_md(rows)
    total = sum(os.path.getsize(os.path.join(ASSETS, os.path.basename(r["asset"])))
                for r in rows)
    print(f"total {total / 1e6:.1f} MB")


main()
