/* Live re-creations of the app's flat clock faces (lib/ui/clock/faces/*)
   drawn on <canvas>. Each face receives a frame { p: elapsed 0..1,
   t: seconds (animation clock), total: seconds, text: "mm:ss" } and the
   palette derived from the current accent (ClockPalette.of). Strictly flat:
   fills and strokes only. */
(function () {
  'use strict';
  var TAU = Math.PI * 2, TOP = -Math.PI / 2;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)');
  function reduced() { return !!(reduce && reduce.matches); }

  var pal = null;
  function palette() {
    var c = EnfoTheme.state.colors;
    pal = {
      accent: c.primary, onAccent: c.onPrimary, container: c.primaryContainer,
      onContainer: c.onPrimaryContainer, surface: c.surfaceContainerHigh,
      ink: c.onSurface, muted: c.onSurfaceVariant, track: c.track, tertiary: c.tertiary
    };
  }
  palette();
  EnfoTheme.onChange(palette);

  function fmt(sec) {
    sec = Math.max(0, Math.ceil(sec));
    var m = Math.floor(sec / 60), s = sec % 60;
    return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
  }
  function frame(p, t, total) {
    total = total || 1500;
    return { p: p, t: t || 0, total: total, rem: 1 - p, text: fmt(total * (1 - p)), remSec: total * (1 - p) };
  }

  /* ---------- drawing helpers ---------- */
  function stroke(ctx, color, w, cap) { ctx.strokeStyle = color; ctx.lineWidth = w; ctx.lineCap = cap || 'round'; ctx.lineJoin = 'round'; }
  function arc(ctx, cx, cy, r, a0, sweep, color, w) {
    if (sweep <= 0.0001) return;
    stroke(ctx, color, w); ctx.beginPath(); ctx.arc(cx, cy, r, a0, a0 + sweep); ctx.stroke();
  }
  function circle(ctx, cx, cy, r, fill) { ctx.fillStyle = fill; ctx.beginPath(); ctx.arc(cx, cy, r, 0, TAU); ctx.fill(); }
  function text(ctx, str, x, y, size, color, weight) {
    ctx.fillStyle = color; ctx.font = (weight || 700) + ' ' + size + 'px GeistMono, ui-monospace, monospace';
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(str, x, y);
  }
  function rrect(ctx, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath();
  }
  function wavyArc(ctx, cx, cy, r, amp, waves, phase, a0, sweep, color, w) {
    if (sweep <= 0.001) return;
    var n = Math.max(24, Math.ceil(sweep / TAU * 220));
    stroke(ctx, color, w); ctx.beginPath();
    for (var i = 0; i <= n; i++) {
      var a = a0 + sweep * i / n, rr = r + amp * Math.sin(a * waves + phase);
      var x = cx + Math.cos(a) * rr, y = cy + Math.sin(a) * rr;
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }
  function dashed(ctx, len, total, color, w) {
    stroke(ctx, color, w); ctx.setLineDash([Math.max(0.001, len), total * 2]); ctx.stroke(); ctx.setLineDash([]);
  }

  /* ---------- faces: draw(ctx, s, f, P) on an s x s square ---------- */
  var FACES = {};

  FACES.ring = function (c, s, f, P) {
    var w = s * 0.07, r = s / 2 - w * 1.2, m = s / 2;
    circle(c, m, m, r - w / 2, P.surface);
    arc(c, m, m, r, 0, TAU, P.track, w);
    arc(c, m, m, r, TOP, TAU * f.rem, P.accent, w);
    text(c, f.text, m, m, s / 6, P.ink);
  };

  FACES.wavyRing = function (c, s, f, P) {
    var w = s * 0.07, r = s / 2 - w * 1.4, m = s / 2;
    arc(c, m, m, r, 0, TAU, P.track, w);
    wavyArc(c, m, m, r, s * 0.017, 10, -f.t * 2.4, TOP, TAU * f.rem, P.accent, w * 0.8);
    text(c, f.text, m, m, s / 6, P.ink);
  };

  FACES.segments = function (c, s, f, P) {
    var n = 60, m = s / 2, outer = s / 2 - s * 0.03, ex = n * f.p, e = Math.floor(ex);
    for (var i = 0; i < n; i++) {
      var a = TOP + TAU * i / n, full = s * (i % 5 === 0 ? 0.115 : 0.085), lit = i >= e;
      var part = i === e ? 1 - (ex - e) : 1;
      var len = lit ? full * (0.4 + 0.6 * part) : full * 0.42;
      var dx = Math.cos(a), dy = Math.sin(a);
      stroke(c, lit ? P.accent : P.track, s * 0.024);
      c.beginPath(); c.moveTo(m + dx * (outer - len), m + dy * (outer - len)); c.lineTo(m + dx * outer, m + dy * outer); c.stroke();
    }
    text(c, f.text, m, m, s / 6, P.ink);
  };

  FACES.orbit = function (c, s, f, P) {
    var m = s / 2, r = s / 2 - s * 0.08, inner = r * 0.8;
    var minuteFrac = ((f.total * f.p) % 60) / 60;
    arc(c, m, m, r, 0, TAU, P.track, s * 0.02);
    arc(c, m, m, r, TOP, TAU * f.p, P.accent, s * 0.02);
    arc(c, m, m, inner, 0, TAU, P.track, s * 0.03);
    arc(c, m, m, inner, TOP, TAU * minuteFrac, EnfoTheme.alpha(P.accent, 0.55), s * 0.03);
    var a = TOP + TAU * f.p, px = m + Math.cos(a) * r, py = m + Math.sin(a) * r;
    circle(c, px, py, s * 0.075, P.container); circle(c, px, py, s * 0.05, P.accent);
    text(c, f.text, m, m, s / 6.5, P.ink);
  };

  FACES.pie = function (c, s, f, P) {
    var r = s * 0.35, cx = s / 2, cy = s * 0.42;
    circle(c, cx, cy, r, P.container);
    if (f.rem > 0.001) {
      c.fillStyle = P.accent; c.beginPath(); c.moveTo(cx, cy);
      c.arc(cx, cy, r, TOP + TAU * f.p, TOP + TAU); c.closePath(); c.fill();
    }
    text(c, f.text, s / 2, s * 0.86, s * 0.14, P.ink);
  };

  FACES.kitchen = function (c, s, f, P) {
    var m = s / 2, r = s / 2, wr = r * 0.8;
    circle(c, m, m, r, P.surface);
    var sweep = TAU * f.rem;
    c.fillStyle = P.container; c.beginPath(); c.moveTo(m, m); c.arc(m, m, wr, TOP, TOP + sweep); c.closePath(); c.fill();
    for (var i = 0; i < 12; i++) {
      var a = TOP + TAU * i / 12;
      circle(c, m + Math.cos(a) * r * 0.9, m + Math.sin(a) * r * 0.9, s * (i % 3 === 0 ? 0.017 : 0.011), P.muted);
    }
    var e = TOP + sweep;
    stroke(c, P.accent, s * 0.032); c.beginPath(); c.moveTo(m, m); c.lineTo(m + Math.cos(e) * wr, m + Math.sin(e) * wr); c.stroke();
    circle(c, m, m, s * 0.05, P.accent);
    var w = s * 0.34, h = s * 0.13;
    c.fillStyle = P.surface; rrect(c, m - w / 2, m + s * 0.2, w, h, h); c.fill();
    text(c, f.text, m, m + s * 0.2 + h / 2, s * 0.085, P.ink);
  };

  FACES.dots = function (c, s, f, P) {
    var cols = 10, rows = 6, gap = s * 0.078, x0 = s / 2 - gap * (cols - 1) / 2, y0 = s * 0.2;
    var ex = 60 * f.p, e = Math.floor(ex);
    for (var i = 0; i < 60; i++) {
      var x = x0 + (i % cols) * gap, y = y0 + Math.floor(i / cols) * gap;
      var k = i < e ? 0.28 : i === e ? 1 - (ex - e) * 0.72 : 1;
      circle(c, x, y, s * 0.032 * k, i < e ? P.track : P.accent);
    }
    text(c, f.text, s / 2, s * 0.8, s * 0.14, P.ink);
  };

  FACES.analog = function (c, s, f, P) {
    var m = s / 2, r = s / 2 - s * 0.03, d = new Date(), ms = d.getMilliseconds() / 1000;
    var sec = d.getSeconds() + ms, mi = d.getMinutes() + sec / 60, h = (d.getHours() % 12) + mi / 60;
    circle(c, m, m, r, P.surface);
    for (var i = 0; i < 60; i++) {
      var a = TOP + TAU * i / 60, big = i % 5 === 0, l = big ? s * 0.06 : s * 0.025;
      stroke(c, big ? P.ink : P.muted, big ? s * 0.014 : s * 0.007);
      c.beginPath(); c.moveTo(m + Math.cos(a) * (r - s * 0.04 - l), m + Math.sin(a) * (r - s * 0.04 - l));
      c.lineTo(m + Math.cos(a) * (r - s * 0.04), m + Math.sin(a) * (r - s * 0.04)); c.stroke();
    }
    function hand(frac, len, w, col) {
      var a = TOP + TAU * frac; stroke(c, col, w);
      c.beginPath(); c.moveTo(m - Math.cos(a) * len * 0.12, m - Math.sin(a) * len * 0.12);
      c.lineTo(m + Math.cos(a) * len, m + Math.sin(a) * len); c.stroke();
    }
    hand(h / 12, r * 0.5, s * 0.032, P.ink);
    hand(mi / 60, r * 0.74, s * 0.022, P.ink);
    hand(sec / 60, r * 0.8, s * 0.01, P.accent);
    circle(c, m, m, s * 0.03, P.accent);
  };

  FACES.rings = function (c, s, f, P) {
    var m = s / 2, w = s * 0.055, rs = [s * 0.42, s * 0.33, s * 0.24];
    var rem = f.remSec, fr = [f.rem, (rem % 3600) / 3600, (rem % 60) / 60];
    for (var i = 0; i < 3; i++) {
      arc(c, m, m, rs[i], 0, TAU, P.track, w);
      arc(c, m, m, rs[i], TOP, TAU * fr[i], i === 0 ? P.accent : i === 1 ? P.tertiary : P.container, w);
    }
    text(c, f.text, m, m, s / 9, P.ink);
  };

  function squarePerimeter(w, r) { return 4 * (w - 2 * r) + TAU * r; }
  FACES.squircle = function (c, s, f, P) {
    var w = s * 0.07, size = s - w * 2.4, x = (s - size) / 2, r = size * 0.32;
    rrect(c, x, x, size, size, r); stroke(c, P.track, w); c.stroke();
    /* start at top-centre: path begins at top-left corner, so rotate dash offset */
    var per = squarePerimeter(size, r);
    c.save(); c.translate(s / 2, s / 2); c.rotate(0); c.translate(-s / 2, -s / 2);
    c.beginPath(); c.moveTo(s / 2, x);
    c.arcTo(x + size, x, x + size, x + size, r); c.arcTo(x + size, x + size, x, x + size, r);
    c.arcTo(x, x + size, x, x, r); c.arcTo(x, x, x + size, x, r); c.lineTo(s / 2, x);
    dashed(c, per * f.rem, per, P.accent, w);
    c.restore();
    text(c, f.text, s / 2, s / 2, s / 6, P.ink);
  };

  FACES.spiral = function (c, s, f, P) {
    var m = s / 2, turns = 3.2, r0 = s * 0.06, r1 = s * 0.44, n = 260, w = s * 0.045;
    function pt(u) { var a = TOP + TAU * turns * u, r = r0 + (r1 - r0) * u; return [m + Math.cos(a) * r, m + Math.sin(a) * r]; }
    stroke(c, P.track, w); c.beginPath();
    for (var i = 0; i <= n; i++) { var q = pt(i / n); if (i) c.lineTo(q[0], q[1]); else c.moveTo(q[0], q[1]); }
    c.stroke();
    var k = Math.round(n * f.rem);
    stroke(c, P.accent, w); c.beginPath();
    for (var j = 0; j <= k; j++) { var q2 = pt(j / n); if (j) c.lineTo(q2[0], q2[1]); else c.moveTo(q2[0], q2[1]); }
    c.stroke();
    var e = pt(k / n); circle(c, e[0], e[1], s * 0.04, P.container); circle(c, e[0], e[1], s * 0.026, P.accent);
    text(c, f.text, m, s * 0.95, s * 0.075, P.ink);
  };

  FACES.hexagon = function (c, s, f, P) {
    var m = s / 2, R = s * 0.42, w = s * 0.06;
    function path() {
      c.beginPath();
      for (var i = 0; i <= 6; i++) { var a = TOP + TAU * i / 6; var x = m + Math.cos(a) * R, y = m + Math.sin(a) * R; if (i) c.lineTo(x, y); else c.moveTo(x, y); }
    }
    path(); stroke(c, P.track, w); c.stroke();
    path(); dashed(c, R * 6 * f.rem, R * 6, P.accent, w);
    text(c, f.text, m, m, s / 6, P.ink);
  };

  FACES.slices = function (c, s, f, P) {
    var m = s / 2, r = s * 0.44, n = 12, e = Math.floor(n * f.p), gap = 0.05;
    for (var i = 0; i < n; i++) {
      var a0 = TOP + TAU * i / n + gap, a1 = TOP + TAU * (i + 1) / n - gap;
      c.fillStyle = i < e ? P.track : P.accent;
      c.beginPath(); c.moveTo(m + Math.cos((a0 + a1) / 2) * s * 0.012, m + Math.sin((a0 + a1) / 2) * s * 0.012);
      c.arc(m, m, r, a0, a1); c.closePath(); c.fill();
    }
    circle(c, m, m, r * 0.5, P.surface);
    text(c, f.text, m, m, s / 8, P.ink);
  };

  FACES.gauge = function (c, s, f, P) {
    var m = s / 2, cy = s * 0.6, r = s * 0.38, w = s * 0.07, a0 = Math.PI * 0.85, sw = Math.PI * 1.3;
    arc(c, m, cy, r, a0, sw, P.track, w);
    arc(c, m, cy, r, a0, sw * f.rem, P.accent, w);
    for (var i = 0; i <= 10; i++) {
      var a = a0 + sw * i / 10;
      stroke(c, P.muted, s * 0.008);
      c.beginPath(); c.moveTo(m + Math.cos(a) * (r - w * 0.9), cy + Math.sin(a) * (r - w * 0.9));
      c.lineTo(m + Math.cos(a) * (r - w * 1.4), cy + Math.sin(a) * (r - w * 1.4)); c.stroke();
    }
    var na = a0 + sw * f.rem; stroke(c, P.ink, s * 0.016);
    c.beginPath(); c.moveTo(m, cy); c.lineTo(m + Math.cos(na) * (r - w * 1.6), cy + Math.sin(na) * (r - w * 1.6)); c.stroke();
    circle(c, m, cy, s * 0.035, P.accent);
    text(c, f.text, m, s * 0.86, s * 0.12, P.ink);
  };

  FACES.needle = function (c, s, f, P) {
    var m = s / 2, r = s * 0.4;
    circle(c, m, m, r + s * 0.05, P.surface);
    for (var i = 0; i < 48; i++) {
      var a = TOP + TAU * i / 48, big = i % 4 === 0;
      stroke(c, big ? P.ink : P.muted, big ? s * 0.012 : s * 0.006);
      c.beginPath(); c.moveTo(m + Math.cos(a) * (r - (big ? s * 0.06 : s * 0.03)), m + Math.sin(a) * (r - (big ? s * 0.06 : s * 0.03)));
      c.lineTo(m + Math.cos(a) * r, m + Math.sin(a) * r); c.stroke();
    }
    var na = TOP + TAU * f.p; stroke(c, P.accent, s * 0.02);
    c.beginPath(); c.moveTo(m - Math.cos(na) * r * 0.2, m - Math.sin(na) * r * 0.2); c.lineTo(m + Math.cos(na) * r * 0.85, m + Math.sin(na) * r * 0.85); c.stroke();
    circle(c, m, m, s * 0.04, P.accent); circle(c, m, m, s * 0.016, P.surface);
    text(c, f.text, m, m + r * 0.5, s * 0.085, P.ink);
  };

  function bar(c, s, f, P, wavy) {
    var w = s * 0.84, h = s * 0.14, x = (s - w) / 2, y = s * 0.4;
    c.fillStyle = P.track; rrect(c, x, y, w, h, h); c.fill();
    var len = w * f.rem;
    if (len > h * 0.6) {
      if (wavy) {
        var mid = y + h / 2; stroke(c, P.accent, h * 0.62); c.beginPath();
        var n = 90;
        for (var i = 0; i <= n; i++) {
          var px = x + h * 0.3 + (len - h * 0.6) * i / n, py = mid + Math.sin(px / s * 34 - f.t * 4) * h * 0.2;
          if (i) c.lineTo(px, py); else c.moveTo(px, py);
        }
        c.stroke();
      } else { c.fillStyle = P.accent; rrect(c, x, y, len, h, h); c.fill(); }
    }
    text(c, f.text, s / 2, s * 0.68, s * 0.15, P.ink);
  }
  FACES.bar = function (c, s, f, P) { bar(c, s, f, P, false); };
  FACES.wavyBar = function (c, s, f, P) { bar(c, s, f, P, true); };

  FACES.blocks = function (c, s, f, P) {
    var n = 5, g = s * 0.02, cell = (s * 0.7 - g * (n - 1)) / n, x0 = s * 0.15, y0 = s * 0.1;
    var e = Math.floor(n * n * f.p);
    for (var i = 0; i < n * n; i++) {
      var x = x0 + (i % n) * (cell + g), y = y0 + Math.floor(i / n) * (cell + g);
      c.fillStyle = i < e ? P.track : P.accent; rrect(c, x, y, cell, cell, cell * 0.3); c.fill();
    }
    text(c, f.text, s / 2, s * 0.9, s * 0.13, P.ink);
  };

  /* Display metadata: id, label, category, combo (name + accent) when the app has one. */
  var ORDER = [
    { id: 'ring', name: 'Ring' },
    { id: 'wavyRing', name: 'Wavy ring', combo: { name: 'Mint', hex: '#009688' } },
    { id: 'segments', name: 'Segments' },
    { id: 'orbit', name: 'Orbit', combo: { name: 'Deep focus', hex: '#3F51B5' } },
    { id: 'pie', name: 'Pie' },
    { id: 'kitchen', name: 'Kitchen' },
    { id: 'dots', name: 'Dots' },
    { id: 'analog', name: 'Analog', combo: { name: 'Classic clock', hex: '#607D8B' } },
    { id: 'rings', name: 'Rings', combo: { name: 'Concentric', hex: '#10B981' } },
    { id: 'squircle', name: 'Squircle', combo: { name: 'Rounded', hex: '#03A9F4' } },
    { id: 'spiral', name: 'Spiral', combo: { name: 'Hypno spiral', hex: '#E91E63' } },
    { id: 'hexagon', name: 'Hexagon', combo: { name: 'Crystal', hex: '#00BCD4' } },
    { id: 'slices', name: 'Slices', combo: { name: 'Citrus', hex: '#FF9800' } },
    { id: 'gauge', name: 'Gauge', combo: { name: 'Speedometer', hex: '#F44336' } },
    { id: 'needle', name: 'Needle', combo: { name: 'Compass', hex: '#2563EB' } },
    { id: 'wavyBar', name: 'Wavy bar', combo: { name: 'Ocean', hex: '#0EA5E9' } },
    { id: 'bar', name: 'Bar' },
    { id: 'blocks', name: 'Blocks', combo: { name: 'Retro blocks', hex: '#9C27B0' } }
  ];

  /* ---------- instances + shared rAF loop ---------- */
  var instances = [], running = false, last = 0;
  var io = 'IntersectionObserver' in window ? new IntersectionObserver(function (es) {
    es.forEach(function (e) { e.target.__ck.visible = e.isIntersecting; if (e.isIntersecting) e.target.__ck.dirty = true; });
    kick();
  }, { rootMargin: '80px' }) : null;
  var ro = 'ResizeObserver' in window ? new ResizeObserver(function (es) {
    es.forEach(function (e) { var i = e.target.__ck; if (i) { fit(i); i.dirty = true; } });
    kick();
  }) : null;

  function fit(i) {
    var cv = i.canvas, w = Math.max(20, Math.round(cv.clientWidth)), dpr = Math.min(window.devicePixelRatio || 1, 2);
    i.size = w; cv.width = Math.round(w * dpr); cv.height = Math.round(w * dpr); i.dpr = dpr;
  }

  /* opts: { style: id, fps, frame: function(now)->frame, static: bool } */
  function create(canvas, opts) {
    var i = { canvas: canvas, ctx: canvas.getContext('2d'), style: opts.style || 'ring', fps: opts.fps || 60,
      frame: opts.frame, visible: !io, dirty: true, last: 0, size: 0, dpr: 1, t0: performance.now() };
    canvas.__ck = i; instances.push(i);
    fit(i);
    if (io) io.observe(canvas);
    if (ro) ro.observe(canvas);
    kick();
    return i;
  }
  function destroy(i) {
    var k = instances.indexOf(i); if (k >= 0) instances.splice(k, 1);
    if (io) io.unobserve(i.canvas); if (ro) ro.unobserve(i.canvas);
  }
  function render(i, now) {
    if (!i.size) fit(i);
    var f = i.frame ? i.frame(now, i) : frame(0.3, now / 1000);
    var c = i.ctx; c.setTransform(i.dpr, 0, 0, i.dpr, 0, 0); c.clearRect(0, 0, i.size, i.size);
    var draw = FACES[i.style] || FACES.ring; draw(c, i.size, f, pal);
    i.dirty = false;
  }
  function tick(now) {
    running = false;
    var any = false;
    for (var n = 0; n < instances.length; n++) {
      var i = instances[n];
      if (!i.visible || document.hidden) continue;
      any = true;
      if (reduced() && !i.dirty) continue;
      if (now - i.last < 1000 / i.fps - 2 && !i.dirty) continue;
      i.last = now; render(i, now);
    }
    if (any && !reduced()) { running = true; requestAnimationFrame(tick); }
  }
  function kick() { if (!running) { running = true; requestAnimationFrame(tick); } }
  EnfoTheme.onChange(function () { instances.forEach(function (i) { i.dirty = true; }); kick(); });
  document.addEventListener('visibilitychange', kick);
  if (reduce && reduce.addEventListener) reduce.addEventListener('change', function () { instances.forEach(function (i) { i.dirty = true; }); kick(); });

  window.EnfoClock = { FACES: FACES, ORDER: ORDER, create: create, destroy: destroy, frame: frame, fmt: fmt, reduced: reduced, kick: kick, palette: function () { return pal; } };
})();
