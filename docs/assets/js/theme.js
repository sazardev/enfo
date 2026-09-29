/* Enfo site theming: Material You tonal surfaces generated from one accent,
   mirroring the app (ColorScheme.fromSeed -> tonal spot scheme).
   Loaded synchronously in <head> so the first paint already has the right
   colors. Tones are CIE L* (HCT tone == L*), hue is taken from the seed in
   LCH. Chroma values follow the tonal-spot recipe (primary 36, secondary 16,
   tertiary 24 at hue+60, neutral 6, neutral variant 8). This is an
   approximation of the CAM16-based HCT the app uses, not a bit-exact port. */
(function () {
  'use strict';

  /* The app's 32-colour palette (lib/theme.dart). The site offers a handful. */
  var PALETTE = [
    { id: 'lime', hex: '#CDDC39', name: 'Lime' },            /* app default */
    { id: 'red', hex: '#F44336', name: 'Red' },
    { id: 'deepOrange', hex: '#FF5722', name: 'Deep orange' },
    { id: 'amber', hex: '#FFC107', name: 'Amber' },
    { id: 'green', hex: '#4CAF50', name: 'Green' },
    { id: 'teal', hex: '#009688', name: 'Teal' },
    { id: 'sky', hex: '#0EA5E9', name: 'Sky' },
    { id: 'indigo', hex: '#3F51B5', name: 'Indigo' },
    { id: 'deepPurple', hex: '#673AB7', name: 'Deep purple' },
    { id: 'fuchsia', hex: '#D946EF', name: 'Fuchsia' },
    { id: 'pink', hex: '#E91E63', name: 'Pink' },
    { id: 'cocoa', hex: '#8B5E3C', name: 'Cocoa' }
  ];
  var DEFAULT_ACCENT = '#CDDC39';

  /* ---------- colour math ---------- */
  function lin(c) { c /= 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
  function delin(c) { c = c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; return c; }
  var XN = 0.95047, YN = 1, ZN = 1.08883;
  function fLab(t) { return t > 216 / 24389 ? Math.cbrt(t) : (24389 / 27 * t + 16) / 116; }
  function fInv(t) { var t3 = t * t * t; return t3 > 216 / 24389 ? t3 : (116 * t - 16) / (24389 / 27); }

  function hexToRgb(h) {
    h = h.replace('#', '');
    return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
  }
  function rgbToHex(r, g, b) {
    function p(v) { v = Math.max(0, Math.min(255, Math.round(v))); return (v < 16 ? '0' : '') + v.toString(16); }
    return '#' + p(r) + p(g) + p(b);
  }
  function hexToLch(hex) {
    var c = hexToRgb(hex), r = lin(c[0]), g = lin(c[1]), b = lin(c[2]);
    var x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
    var y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    var z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b;
    var fx = fLab(x / XN), fy = fLab(y / YN), fz = fLab(z / ZN);
    var L = 116 * fy - 16, a = 500 * (fx - fy), bb = 200 * (fy - fz);
    var C = Math.sqrt(a * a + bb * bb), h = Math.atan2(bb, a) * 180 / Math.PI;
    return { L: L, C: C, h: (h + 360) % 360 };
  }
  function lchToRgbRaw(L, C, h) {
    var hr = h * Math.PI / 180, a = C * Math.cos(hr), b = C * Math.sin(hr);
    var fy = (L + 16) / 116, fx = fy + a / 500, fz = fy - b / 200;
    var x = XN * fInv(fx), y = YN * fInv(fy), z = ZN * fInv(fz);
    return [
      delin(3.2404542 * x - 1.5371385 * y - 0.4985314 * z),
      delin(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z),
      delin(0.0556434 * x - 0.2040259 * y + 1.0572252 * z)
    ];
  }
  function inGamut(v) { return v[0] >= -0.0005 && v[0] <= 1.0005 && v[1] >= -0.0005 && v[1] <= 1.0005 && v[2] >= -0.0005 && v[2] <= 1.0005; }
  /* tone(hue, chroma, L*) -> hex, reducing chroma until it fits sRGB. */
  function tone(h, C, L) {
    if (L >= 100) return '#ffffff';
    if (L <= 0) return '#000000';
    var v = lchToRgbRaw(L, C, h);
    if (!inGamut(v)) {
      var lo = 0, hi = C;
      for (var i = 0; i < 18; i++) {
        var mid = (lo + hi) / 2;
        if (inGamut(lchToRgbRaw(L, mid, h))) lo = mid; else hi = mid;
      }
      v = lchToRgbRaw(L, lo, h);
    }
    return rgbToHex(v[0] * 255, v[1] * 255, v[2] * 255);
  }
  function alpha(hex, a) {
    var c = hexToRgb(hex);
    return 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + a + ')';
  }

  /* ---------- scheme ---------- */
  function scheme(seed, dark) {
    var h = hexToLch(seed).h;
    var ht = (h + 60) % 360;
    function P(L) { return tone(h, 36, L); }
    function S(L) { return tone(h, 16, L); }
    function T(L) { return tone(ht, 24, L); }
    function N(L) { return tone(h, 6, L); }
    function NV(L) { return tone(h, 8, L); }
    function E(L) { return tone(25, 84, L); }
    var s;
    if (!dark) {
      s = {
        primary: P(40), onPrimary: '#ffffff', primaryContainer: P(90), onPrimaryContainer: P(10),
        secondary: S(40), onSecondary: '#ffffff', secondaryContainer: S(90), onSecondaryContainer: S(10),
        tertiary: T(40), onTertiary: '#ffffff', tertiaryContainer: T(90), onTertiaryContainer: T(10),
        surface: N(98), onSurface: N(10), onSurfaceVariant: NV(30),
        surfaceContainerLowest: '#ffffff', surfaceContainerLow: N(96), surfaceContainer: N(94),
        surfaceContainerHigh: N(92), surfaceContainerHighest: N(90),
        error: E(40), onError: '#ffffff', errorContainer: E(90), onErrorContainer: E(10),
        inverseSurface: N(20), onInverseSurface: N(95), inversePrimary: P(80)
      };
    } else {
      s = {
        primary: P(80), onPrimary: P(20), primaryContainer: P(30), onPrimaryContainer: P(90),
        secondary: S(80), onSecondary: S(20), secondaryContainer: S(30), onSecondaryContainer: S(90),
        tertiary: T(80), onTertiary: T(20), tertiaryContainer: T(30), onTertiaryContainer: T(90),
        surface: N(6), onSurface: N(90), onSurfaceVariant: NV(80),
        surfaceContainerLowest: N(4), surfaceContainerLow: N(10), surfaceContainer: N(12),
        surfaceContainerHigh: N(17), surfaceContainerHighest: N(22),
        error: E(80), onError: E(20), errorContainer: E(30), onErrorContainer: E(90),
        inverseSurface: N(90), onInverseSurface: N(20), inversePrimary: P(40)
      };
    }
    s.track = alpha(s.primary, 0.14);   /* ClockPalette.track */
    s.halo = alpha(s.primary, 0.28);    /* focus halo */
    s.hover = alpha(s.primary, 0.09);
    return s;
  }

  function kebab(k) { return k.replace(/[A-Z]/g, function (m) { return '-' + m.toLowerCase(); }); }

  /* ---------- state ---------- */
  var KEY_ACCENT = 'enfo_site_accent', KEY_MODE = 'enfo_site_theme';
  var root = document.documentElement;
  root.classList.add('js');
  var mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
  var state = { accent: DEFAULT_ACCENT, mode: 'system', dark: false, colors: null };
  var listeners = [];

  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* private mode */ } }
  function load(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }

  function apply() {
    state.dark = state.mode === 'dark' || (state.mode === 'system' && !!(mq && mq.matches));
    var s = scheme(state.accent, state.dark);
    state.colors = s;
    var st = root.style;
    for (var k in s) st.setProperty('--' + kebab(k), s[k]);
    root.setAttribute('data-theme', state.dark ? 'dark' : 'light');
    root.setAttribute('data-theme-mode', state.mode);
    root.style.colorScheme = state.dark ? 'dark' : 'light';
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', s.surface);
    for (var i = 0; i < listeners.length; i++) listeners[i](state);
  }

  var a = load(KEY_ACCENT), m = load(KEY_MODE);
  if (a && /^#[0-9a-fA-F]{6}$/.test(a)) state.accent = a;
  if (m === 'light' || m === 'dark' || m === 'system') state.mode = m;
  try { var q = new URLSearchParams(location.search).get('theme'); if (q === 'dark' || q === 'light') state.mode = q; } catch (e) { /* ignore */ }
  apply();
  if (mq) {
    var onChange = function () { if (state.mode === 'system') apply(); };
    if (mq.addEventListener) mq.addEventListener('change', onChange); else if (mq.addListener) mq.addListener(onChange);
  }

  window.EnfoTheme = {
    PALETTE: PALETTE,
    DEFAULT_ACCENT: DEFAULT_ACCENT,
    state: state,
    scheme: scheme,
    tone: tone,
    hexToLch: hexToLch,
    alpha: alpha,
    setAccent: function (hex, persist) { state.accent = hex; if (persist !== false) store(KEY_ACCENT, hex); apply(); },
    setMode: function (mode) { state.mode = mode; store(KEY_MODE, mode); apply(); },
    onChange: function (fn) { listeners.push(fn); }
  };
})();
