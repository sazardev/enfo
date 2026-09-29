/* Small live demos for the 16 modes (HTML + a shared animation loop).
   Nothing here plays audio or vibrates; it only mimics what the mode looks like.
   render(id, root) returns { stop() }. All text goes through EnfoI18n.t. */
(function () {
  'use strict';
  var t = function (k) { return EnfoI18n.t(k); };
  var pad = function (n, w) { n = String(Math.floor(n)); while (n.length < (w || 2)) n = '0' + n; return n; };
  var mmss = function (s) { s = Math.max(0, Math.ceil(s)); return pad(s / 60) + ':' + pad(s % 60); };
  var $ = function (root, sel) { return root.querySelector(sel); };
  var $$ = function (root, sel) { return Array.prototype.slice.call(root.querySelectorAll(sel)); };

  function makeApi(root) {
    var stops = [], calm = EnfoClock.reduced();
    return {
      calm: calm,
      loop: function (fn, fps) {
        var stopped = false, last = 0, raf = 0, iv = 0;
        var step = function (now) {
          if (stopped) return;
          if (now - last >= 1000 / fps - 2) { last = now; fn(now); }
          raf = requestAnimationFrame(step);
        };
        if (calm) { fn(performance.now()); iv = setInterval(function () { if (!document.hidden) fn(performance.now()); }, 1000); }
        else raf = requestAnimationFrame(step);
        stops.push(function () { stopped = true; cancelAnimationFrame(raf); clearInterval(iv); });
      },
      canvas: function (cv, style, frameFn, fps) {
        var inst = EnfoClock.create(cv, { style: style, fps: fps || 60, frame: frameFn });
        stops.push(function () { EnfoClock.destroy(inst); });
        return inst;
      },
      on: function (el, ev, fn) { el.addEventListener(ev, fn); stops.push(function () { el.removeEventListener(ev, fn); }); },
      stop: function () { stops.forEach(function (f) { f(); }); stops = []; }
    };
  }

  var D = {};

  /* 1. Pomodoro: sped-up focus/rest cycle on a real face */
  D.pomodoro = function (root, api) {
    root.innerHTML = '<div class="demo demo-dial"><div class="demo-canvas"><canvas aria-hidden="true"></canvas></div>' +
      '<div class="demo-row"><span class="chip on" data-phase></span><span class="demo-dots" data-dots></span></div>' +
      '<p class="demo-hint">' + t('d.tapdial') + '</p></div>';
    var cv = $(root, 'canvas'), phase = $(root, '[data-phase]'), dots = $(root, '[data-dots]');
    var paused = false, base = 0, acc = 0, total = 16000; /* sped up: 25 min -> 16 s */
    var p0 = performance.now();
    function cycle(now) { if (paused) return acc; return acc + (now - base); }
    base = p0;
    api.canvas(cv, 'ring', function (now) {
      var e = cycle(now) % (total + 4000), focus = e < total, p = focus ? e / total : (e - total) / 4000;
      return EnfoClock.frame(p, now / 1000, focus ? 1500 : 300);
    });
    api.loop(function (now) {
      var e = cycle(now), n = Math.floor(e / (total + 4000)), focus = (e % (total + 4000)) < total;
      phase.textContent = paused ? t('d.paused') : focus ? t('d.focus') : t('d.rest');
      var h = ''; for (var i = 0; i < 4; i++) h += '<i class="' + (i <= n % 4 && (i < n % 4 || !focus) ? 'on' : '') + '"></i>';
      dots.innerHTML = h;
    }, 5);
    api.on(cv, 'click', function () {
      var now = performance.now(); if (paused) { base = now; paused = false; } else { acc += now - base; paused = true; }
    });
  };

  /* 2. Clock */
  D.clock = function (root, api) {
    root.innerHTML = '<div class="demo demo-clock"><div class="demo-canvas sm"><canvas aria-hidden="true"></canvas></div>' +
      '<div class="demo-bigtime" data-time>--:--</div><div class="demo-sub" data-date></div></div>';
    api.canvas($(root, 'canvas'), 'analog', function (now) { return EnfoClock.frame(0, now / 1000); }, 30);
    var time = $(root, '[data-time]'), date = $(root, '[data-date]'), lang = EnfoI18n.lang();
    api.loop(function () {
      var d = new Date();
      time.innerHTML = pad(d.getHours()) + '<span class="blink">:</span>' + pad(d.getMinutes()) + '<small>' + pad(d.getSeconds()) + '</small>';
      date.textContent = d.toLocaleDateString(lang, { weekday: 'long', day: 'numeric', month: 'long' });
    }, 4);
  };

  /* 3. Timer with wheels */
  D.timer = function (root, api) {
    var v = [0, 5, 0], running = false, end = 0;
    root.innerHTML = '<div class="demo demo-timer"><div class="wheels">' + ['h', 'm', 's'].map(function (u, i) {
      return '<div class="wheel"><button class="ibtn" data-up="' + i + '" aria-label="+ ' + u + '">' + EnfoI18n.icon('up') + '</button><output data-v="' + i + '"></output><small>' + u + '</small>' +
        '<button class="ibtn" data-dn="' + i + '" aria-label="- ' + u + '">' + EnfoI18n.icon('down') + '</button></div>';
    }).join('') + '</div><div class="demo-row"><button class="btn" data-go></button><button class="btn tonal" data-reset></button></div></div>';
    var outs = $$(root, '[data-v]'), go = $(root, '[data-go]'), reset = $(root, '[data-reset]');
    var max = [23, 59, 59];
    function show(arr) { outs.forEach(function (o, i) { o.textContent = pad(arr[i]); }); }
    function labels() { go.textContent = running ? t('d.pause') : t('d.start'); reset.textContent = t('d.reset'); }
    api.on(root, 'click', function (e) {
      var b = e.target.closest('button'); if (!b || running && (b.dataset.up || b.dataset.dn)) return;
      if (b.dataset.up != null) { var i = +b.dataset.up; v[i] = (v[i] + (i ? 1 : 1)) % (max[i] + 1); show(v); }
      else if (b.dataset.dn != null) { var j = +b.dataset.dn; v[j] = (v[j] + max[j]) % (max[j] + 1); show(v); }
      else if (b.hasAttribute('data-go')) {
        if (!running) { var tot = v[0] * 3600 + v[1] * 60 + v[2]; if (!tot) return; end = performance.now() + tot * 1000; running = true; }
        else { var left = Math.ceil((end - performance.now()) / 1000); v = [Math.floor(left / 3600), Math.floor(left % 3600 / 60), left % 60]; running = false; show(v); }
        labels();
      } else if (b.hasAttribute('data-reset')) { running = false; v = [0, 5, 0]; show(v); labels(); }
    });
    show(v); labels();
    api.loop(function (now) {
      if (!running) return;
      var left = Math.ceil((end - now) / 1000);
      if (left <= 0) { running = false; v = [0, 0, 0]; show(v); labels(); root.firstChild.classList.add('done'); setTimeout(function () { root.firstChild && root.firstChild.classList.remove('done'); }, 1400); return; }
      show([Math.floor(left / 3600), Math.floor(left % 3600 / 60), left % 60]);
    }, 8);
  };

  /* 4. Stopwatch with laps */
  D.stopwatch = function (root, api) {
    var run = false, start = 0, acc = 0, laps = [];
    root.innerHTML = '<div class="demo demo-sw"><div class="demo-bigtime" data-t>00:00<small>.00</small></div><div class="demo-row">' +
      '<button class="btn" data-go></button><button class="btn tonal" data-lap></button><button class="btn tonal" data-reset></button></div><ol class="laps" data-laps></ol></div>';
    var out = $(root, '[data-t]'), ol = $(root, '[data-laps]'), go = $(root, '[data-go]'), lap = $(root, '[data-lap]'), rs = $(root, '[data-reset]');
    function el(now) { return acc + (run ? now - start : 0); }
    function fmt(ms) { return pad(ms / 60000) + ':' + pad(ms / 1000 % 60) + '<small>.' + pad(ms % 1000 / 10) + '</small>'; }
    function labels() { go.textContent = run ? t('d.pause') : t('d.start'); lap.textContent = t('d.lap'); rs.textContent = t('d.reset'); }
    function drawLaps() {
      if (!laps.length) { ol.innerHTML = ''; return; }
      var min = Math.min.apply(null, laps), max = Math.max.apply(null, laps);
      ol.innerHTML = laps.map(function (l, i) { return { l: l, i: i }; }).reverse().map(function (o) {
        var cls = laps.length > 1 ? (o.l === min ? 'best' : o.l === max ? 'worst' : '') : '';
        return '<li class="' + cls + '"><span>' + t('d.lap') + ' ' + (o.i + 1) + '</span><b>' + fmt(o.l).replace(/<[^>]+>/g, '') + '</b></li>';
      }).join('');
    }
    api.on(root, 'click', function (e) {
      var b = e.target.closest('button'); if (!b) return; var now = performance.now();
      if (b.hasAttribute('data-go')) { if (run) { acc += now - start; run = false; } else { start = now; run = true; } labels(); }
      else if (b.hasAttribute('data-lap')) { var tot = el(now); if (!tot) return; var prev = laps.reduce(function (a, c) { return a + c; }, 0); laps.push(tot - prev); drawLaps(); }
      else if (b.hasAttribute('data-reset')) { run = false; acc = 0; laps = []; drawLaps(); out.innerHTML = fmt(0); labels(); }
    });
    labels();
    /* start running so the visitor sees it move */
    start = performance.now(); run = true; labels();
    setTimeout(function () { if (run && !laps.length) { var tot = el(performance.now()); laps.push(tot); drawLaps(); } }, 2200);
    api.loop(function (now) { out.innerHTML = fmt(el(now)); }, 30);
  };

  /* 5. Alarm */
  D.alarm = function (root, api) {
    var A = [['06:45', 'd.wake', [1, 1, 1, 1, 1, 0, 0], true], ['13:30', 'd.lunch', [1, 1, 1, 1, 1, 1, 1], true], ['22:15', 'd.stretch', [0, 0, 0, 0, 1, 0, 0], false]];
    var days = t('d.days').split(',');
    root.innerHTML = '<div class="demo demo-alarm">' + A.map(function (a, i) {
      return '<div class="alarm-row"><div><div class="alarm-time">' + a[0] + '</div><div class="alarm-label">' + t(a[1]) + '</div>' +
        '<div class="alarm-days">' + a[2].map(function (on, k) { return '<i class="' + (on ? 'on' : '') + '">' + days[k] + '</i>'; }).join('') + '</div></div>' +
        '<button class="switch" role="switch" aria-checked="' + a[3] + '" data-i="' + i + '"><span></span></button></div>';
    }).join('') + '</div>';
    api.on(root, 'click', function (e) {
      var b = e.target.closest('.switch'); if (!b) return; b.setAttribute('aria-checked', b.getAttribute('aria-checked') === 'true' ? 'false' : 'true');
    });
  };

  /* 6. World clock + meeting planner */
  D.world = function (root, api) {
    var C = [['Mexico City', 'America/Mexico_City'], ['New York', 'America/New_York'], ['London', 'Europe/London'], ['Tokyo', 'Asia/Tokyo']];
    root.innerHTML = '<div class="demo demo-world">' + C.map(function (c, i) {
      return '<div class="city"><span class="sun" data-sun="' + i + '"></span><b>' + c[0] + '</b><span class="tz" data-tz="' + i + '"></span><output data-c="' + i + '"></output></div>';
    }).join('') + '<div class="planner"><div class="planner-title">' + t('d.meeting') + '</div><div class="planner-bar" data-plan></div><div class="planner-axis"><span>0</span><span>6</span><span>12</span><span>18</span><span>24</span></div></div></div>';
    var fm = C.map(function (c) { return new Intl.DateTimeFormat('en-GB', { timeZone: c[1], hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }); });
    var hr = C.map(function (c) { return new Intl.DateTimeFormat('en-GB', { timeZone: c[1], hour: 'numeric', hourCycle: 'h23' }); });
    var outs = $$(root, '[data-c]'), suns = $$(root, '[data-sun]'), tzs = $$(root, '[data-tz]'), plan = $(root, '[data-plan]');
    function update() {
      var now = new Date();
      C.forEach(function (c, i) {
        outs[i].textContent = fm[i].format(now);
        var h = +hr[i].format(now); suns[i].className = 'sun ' + (h >= 7 && h < 19 ? 'day' : 'night');
        var off = Math.round((new Date(now.toLocaleString('en-US', { timeZone: c[1] })) - new Date(now.toLocaleString('en-US', { timeZone: 'UTC' }))) / 3600000);
        tzs[i].textContent = 'UTC' + (off >= 0 ? '+' : '') + off;
      });
      var cells = '', base = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
      for (var u = 0; u < 24; u++) {
        var at = new Date(base.getTime() + u * 3600000), ok = 0;
        for (var i = 0; i < 3; i++) { var lh = +hr[i].format(at); if (lh >= 9 && lh < 18) ok++; }
        cells += '<i class="' + (ok === 3 ? 'all' : ok === 2 ? 'some' : '') + '"></i>';
      }
      plan.innerHTML = cells;
    }
    update(); api.loop(update, 1);
  };

  /* 7. Event countdown */
  D.event = function (root, api) {
    root.innerHTML = '<div class="demo demo-event"><div class="chip on" data-name></div><div class="demo-bigtime" data-t></div><div class="demo-sub" data-sub></div><div class="chip">' + EnfoI18n.icon('repeat') + ' ' + t('d.yearly') + '</div></div>';
    var out = $(root, '[data-t]'), name = $(root, '[data-name]'), sub = $(root, '[data-sub]');
    name.textContent = t('d.newyear');
    var lang = EnfoI18n.lang();
    api.loop(function () {
      var n = new Date(), target = new Date(n.getFullYear() + 1, 0, 1), ms = target - n;
      var d = Math.floor(ms / 864e5), h = Math.floor(ms % 864e5 / 36e5), m = Math.floor(ms % 36e5 / 6e4), s = Math.floor(ms % 6e4 / 1000);
      out.innerHTML = d + '<small>' + t('d.days1') + '</small> ' + pad(h) + ':' + pad(m) + ':' + pad(s);
      sub.textContent = target.toLocaleDateString(lang, { day: 'numeric', month: 'long', year: 'numeric' });
    }, 2);
  };

  /* 8. Intervals (HIIT) */
  D.intervals = function (root, api) {
    var W = 10, R = 5, ROUNDS = 8;
    root.innerHTML = '<div class="demo demo-int"><div class="int-phase" data-phase></div><div class="demo-bigtime" data-t></div>' +
      '<div class="pillbar"><i data-bar></i></div><div class="int-rounds" data-rounds></div></div>';
    var box = root.firstChild, ph = $(root, '[data-phase]'), out = $(root, '[data-t]'), bar = $(root, '[data-bar]'), rd = $(root, '[data-rounds]');
    var t0 = performance.now();
    api.loop(function (now) {
      var e = (now - t0) / 1000, per = W + R, round = Math.floor(e / per) % ROUNDS, x = e % per, work = x < W;
      var len = work ? W : R, left = len - (work ? x : x - W);
      box.className = 'demo demo-int ' + (work ? 'work' : 'rest');
      ph.textContent = work ? t('d.work') : t('d.restp'); out.textContent = mmss(left * 4);
      bar.style.width = (100 * (1 - left / len)) + '%';
      var h = ''; for (var i = 0; i < ROUNDS; i++) h += '<i class="' + (i < round ? 'on' : i === round ? 'cur' : '') + '"></i>';
      rd.innerHTML = h + '<span>' + t('d.round') + ' ' + (round + 1) + '/' + ROUNDS + '</span>';
    }, 20);
  };

  /* 9. Breathe */
  D.breathe = function (root, api) {
    var PAT = { box: [4, 4, 4, 4], relax: [4, 7, 8, 0], calm: [5, 0, 5, 0] };
    var cur = 'box', t0 = performance.now();
    root.innerHTML = '<div class="demo demo-breathe"><div class="breath-stage"><div class="breath" data-b></div><div class="breath-label" data-l></div></div>' +
      '<div class="chips" role="group">' + Object.keys(PAT).map(function (k) { return '<button class="chip' + (k === cur ? ' on' : '') + '" data-p="' + k + '">' + t('d.p.' + k) + '</button>'; }).join('') + '</div></div>';
    var b = $(root, '[data-b]'), l = $(root, '[data-l]');
    api.on(root, 'click', function (e) {
      var c = e.target.closest('[data-p]'); if (!c) return; cur = c.dataset.p; t0 = performance.now();
      $$(root, '[data-p]').forEach(function (x) { x.classList.toggle('on', x === c); });
    });
    api.loop(function (now) {
      var p = PAT[cur], total = p[0] + p[1] + p[2] + p[3], x = ((now - t0) / 1000) % total, k = 0, acc = 0;
      while (k < 4 && x >= acc + p[k]) { acc += p[k]; k++; }
      if (k > 3) k = 3;
      var u = p[k] ? (x - acc) / p[k] : 1, ease = function (v) { return v * v * (3 - 2 * v); };
      var size = k === 0 ? ease(u) : k === 1 ? 1 : k === 2 ? 1 - ease(u) : 0;
      var s = api.calm ? 0.7 : 0.38 + 0.62 * size;
      b.style.transform = 'scale(' + s + ')';
      b.style.borderRadius = (50 - 22 * size) + '%';
      l.textContent = [t('d.inhale'), t('d.hold'), t('d.exhale'), t('d.hold')][k] + ' ' + Math.ceil(p[k] * (1 - u) + 0.001);
    }, 30);
  };

  /* 10. Tracker */
  D.tracker = function (root, api) {
    var bars = [42, 65, 30, 80, 55, 20, 0], days = t('d.days').split(',');
    root.innerHTML = '<div class="demo demo-tracker"><div class="tracker-now"><span class="chip on">' + t('d.reading') + '</span><output class="demo-bigtime" data-t></output></div>' +
      '<div class="bars">' + bars.map(function (v, i) { return '<div class="barcol"><i style="height:' + v + '%" data-i="' + i + '"></i><span>' + days[(i + 1) % 7] + '</span></div>'; }).join('') + '</div></div>';
    var out = $(root, '[data-t]'), today = $(root, '[data-i="6"]'), t0 = performance.now() - 754000;
    api.loop(function (now) {
      var s = (now - t0) / 1000; out.textContent = pad(s / 3600) + ':' + pad(s % 3600 / 60) + ':' + pad(s % 60);
      today.style.height = Math.min(100, 8 + s / 60 * 2) + '%';
    }, 4);
  };

  /* 11. Kitchen */
  D.kitchen = function (root, api) {
    var K = [['d.pasta', 40], ['d.eggs', 24], ['d.bread', 60]];
    root.innerHTML = '<div class="demo demo-kitchen">' + K.map(function (k, i) {
      return '<div class="ktimer"><div class="ktop"><b>' + t(k[0]) + '</b><output data-o="' + i + '"></output></div><div class="pillbar"><i data-k="' + i + '"></i></div></div>';
    }).join('') + '</div>';
    var o = $$(root, '[data-o]'), b = $$(root, '[data-k]'), rows = $$(root, '.ktimer'), t0 = performance.now();
    api.loop(function (now) {
      var e = (now - t0) / 1000;
      K.forEach(function (k, i) {
        var x = e % (k[1] + 4), left = k[1] - x, done = left <= 0;
        o[i].textContent = done ? t('d.done') : mmss(left * 20);
        b[i].style.width = (done ? 100 : 100 * (1 - left / k[1])) + '%';
        rows[i].classList.toggle('done', done);
      });
    }, 12);
  };

  /* 12. Sleep planner */
  D.sleep = function (root, api) {
    var wake = 7 * 60;
    root.innerHTML = '<div class="demo demo-sleep"><div class="sleep-wake"><button class="ibtn" data-d="-30" aria-label="-30">' + EnfoI18n.icon('down') + '</button>' +
      '<div><small>' + t('d.wakeat') + '</small><output class="demo-bigtime" data-w></output></div><button class="ibtn" data-d="30" aria-label="+30">' + EnfoI18n.icon('up') + '</button></div>' +
      '<div class="sleep-list" data-list></div><p class="demo-hint">' + t('d.cycles') + '</p></div>';
    var w = $(root, '[data-w]'), list = $(root, '[data-list]');
    function f(m) { m = ((m % 1440) + 1440) % 1440; return pad(m / 60) + ':' + pad(m % 60); }
    function draw() {
      w.textContent = f(wake);
      list.innerHTML = [6, 5, 4].map(function (c, i) {
        return '<div class="sleep-row' + (i === 0 ? ' best' : '') + '"><b>' + f(wake - c * 90 - 15) + '</b><span>' + c + ' ' + t('d.cyc') + ' · ' + (c * 1.5) + ' h</span></div>';
      }).join('');
    }
    api.on(root, 'click', function (e) { var b = e.target.closest('[data-d]'); if (!b) return; wake = (wake + +b.dataset.d + 1440) % 1440; draw(); });
    draw();
  };

  /* 13. Turns (versus) */
  D.versus = function (root, api) {
    var T = [300, 300], turn = 0, last = performance.now();
    root.innerHTML = '<div class="demo demo-versus"><button class="side a" data-s="0"><small data-n="0"></small><b data-v="0"></b></button><button class="side b" data-s="1"><small data-n="1"></small><b data-v="1"></b></button></div>';
    var vs = $$(root, '[data-v]'), ss = $$(root, '[data-s]'), ns = $$(root, '[data-n]');
    ns[0].textContent = t('d.player1'); ns[1].textContent = t('d.player2');
    api.on(root, 'click', function (e) { var b = e.target.closest('[data-s]'); if (!b) return; if (+b.dataset.s === turn) { turn = 1 - turn; } });
    api.loop(function (now) {
      T[turn] = Math.max(0, T[turn] - (now - last) / 1000); last = now;
      if (T[turn] <= 0) { T = [300, 300]; }
      vs.forEach(function (v, i) { v.textContent = mmss(T[i]); ss[i].classList.toggle('active', i === turn); });
    }, 10);
    last = performance.now();
    var auto = setInterval(function () { turn = 1 - turn; }, 5200); /* plays itself until touched */
    api.on(root, 'pointerdown', function () { clearInterval(auto); });
    var stopAuto = function () { clearInterval(auto); };
    api.on(window, 'pagehide', stopAuto);
    root.__cleanup = stopAuto;
  };

  /* 14. Breaks */
  D.breaks = function (root, api) {
    root.innerHTML = '<div class="demo demo-breaks"><div class="break-card"><div class="break-ico">' + EnfoI18n.icon('eye') + '</div><b>20 · 20 · 20</b><p>' + t('d.b2020') + '</p>' +
      '<div class="pillbar"><i data-bar></i></div><output class="demo-sub" data-t></output></div>' +
      '<div class="switches">' + ['d.stretch2', 'd.water', 'd.posture'].map(function (k, i) {
        return '<div class="sw-row"><span>' + t(k) + '</span><button class="switch" role="switch" aria-checked="' + (i !== 2) + '"><span></span></button></div>';
      }).join('') + '</div></div>';
    var bar = $(root, '[data-bar]'), out = $(root, '[data-t]'), t0 = performance.now();
    api.on(root, 'click', function (e) { var b = e.target.closest('.switch'); if (b) b.setAttribute('aria-checked', b.getAttribute('aria-checked') === 'true' ? 'false' : 'true'); });
    api.loop(function (now) {
      var x = ((now - t0) / 1000) % 20; bar.style.width = (x / 20 * 100) + '%'; out.textContent = t('d.nextbreak') + ' ' + mmss((20 - x) * 60);
    }, 10);
  };

  /* 15. Ambient */
  D.ambient = function (root, api) {
    var N = ['white', 'pink', 'brown', 'rain', 'wind', 'ocean'], cur = 'rain', n = 22;
    root.innerHTML = '<div class="demo demo-ambient"><div class="eq" data-eq>' + new Array(n + 1).join('<i></i>') + '</div>' +
      '<div class="chips">' + N.map(function (k) { return '<button class="chip' + (k === cur ? ' on' : '') + '" data-n="' + k + '">' + t('d.n.' + k) + '</button>'; }).join('') + '</div>' +
      '<div class="chips small"><span class="lab">' + t('d.sleeptimer') + '</span>' + [15, 30, 60].map(function (m, i) { return '<button class="chip' + (i === 1 ? ' on' : '') + '" data-m="' + m + '">' + m + ' min</button>'; }).join('') + '</div>' +
      '<p class="demo-hint">' + t('d.silent') + '</p></div>';
    var bars = $$(root, '.eq i');
    api.on(root, 'click', function (e) {
      var c = e.target.closest('[data-n]'), m = e.target.closest('[data-m]');
      if (c) { cur = c.dataset.n; $$(root, '[data-n]').forEach(function (x) { x.classList.toggle('on', x === c); }); }
      if (m) { $$(root, '[data-m]').forEach(function (x) { x.classList.toggle('on', x === m); }); }
    });
    var prof = { white: 1, pink: 0.85, brown: 0.55, rain: 0.9, wind: 0.6, ocean: 0.7 };
    api.loop(function (now) {
      var s = now / 1000, k = prof[cur];
      bars.forEach(function (b, i) {
        var v;
        if (cur === 'ocean') v = 0.5 + 0.45 * Math.sin(s * 1.1 + i * 0.25);
        else if (cur === 'wind') v = 0.35 + 0.3 * Math.sin(s * 0.8 + i * 0.5) + 0.2 * Math.sin(s * 2.1 + i);
        else if (cur === 'brown') v = (1 - i / n) * (0.6 + 0.4 * Math.sin(s * 3 + i));
        else v = 0.3 + 0.7 * Math.abs(Math.sin(s * (2 + (i % 5) * 0.7) + i * 1.7)) * k;
        b.style.height = (api.calm ? 30 + (i % 7) * 8 : Math.max(8, Math.min(100, v * 100))) + '%';
      });
    }, 24);
  };

  /* 16. Music */
  D.music = function (root, api) {
    var S = (window.REPO_DATA && REPO_DATA.credits && REPO_DATA.credits.length ? REPO_DATA.credits : [{ song: 'Chill Beat', artist: 'Maddy' }, { song: 'Softly', artist: 'Loyalty Freak Music' }]);
    S = S.map(function (s) { return { title: s.song.replace(/^Loyalty Freak Music - \d+ - /, '').replace(/ \(.*?\)$/, '').replace(/ by Kevin MacLeod$/, ''), artist: s.artist }; });
    var i = 0, t0 = performance.now();
    root.innerHTML = '<div class="demo demo-music"><div class="demo-canvas sm"><canvas aria-hidden="true"></canvas></div>' +
      '<div class="pager"><button class="ibtn" data-d="-1" aria-label="prev">' + EnfoI18n.icon('prev') + '</button><div class="pager-title"><b data-title></b><small data-artist></small></div><button class="ibtn" data-d="1" aria-label="next">' + EnfoI18n.icon('next') + '</button></div>' +
      '<p class="demo-hint">' + t('d.songs') + '</p></div>';
    var title = $(root, '[data-title]'), art = $(root, '[data-artist]');
    function draw() { title.textContent = S[i].title; art.textContent = S[i].artist; }
    api.on(root, 'click', function (e) { var b = e.target.closest('[data-d]'); if (!b) return; i = (i + +b.dataset.d + S.length) % S.length; t0 = performance.now(); draw(); });
    draw();
    api.canvas($(root, 'canvas'), 'wavyRing', function (now) {
      var e = (now - t0) / 1000, p = (e % 180) / 180 * 0.999;
      return EnfoClock.frame(p, e * (0.6 + 0.4 * Math.sin(e * 3.1)), 180);
    });
  };

  window.EnfoDemos = {
    ids: Object.keys(D),
    render: function (id, root) {
      var api = makeApi(root), fn = D[id];
      root.innerHTML = '';
      if (fn) fn(root, api);
      return { stop: function () { api.stop(); if (root.__cleanup) { root.__cleanup(); root.__cleanup = null; } } };
    }
  };
})();
