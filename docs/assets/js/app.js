/* Enfo site: wires theme controls, the live dial, the tools showcase, the clock
   playground and every generated section. Vanilla JS, no dependencies. */
(function () {
  'use strict';
  var T = function (k) { return EnfoI18n.t(k); };
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var esc = function (s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
  var ico = function (n, c) { return EnfoIcons.svg(n, c); };
  var reduced = function () { return EnfoClock.reduced(); };
  var SITE = window.SITE;

  /* The app's 32 accent colors (lib/theme.dart Themes.colors, same order). */
  var APP_COLORS = ['#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39', '#FFC107', '#FF9800', '#FF5722', '#795548', '#607D8B',
    '#E11D48', '#F43F5E', '#D946EF', '#7C3AED', '#6366F1', '#2563EB', '#0EA5E9', '#14B8A6', '#10B981', '#84CC16', '#F59E0B', '#EA580C', '#8B5E3C', '#64748B', '#334155', '#111827'];
  var HERO_SWATCHES = ['#CDDC39', '#F44336', '#FF5722', '#FFC107', '#4CAF50', '#009688', '#0EA5E9', '#3F51B5', '#673AB7', '#D946EF', '#E91E63', '#8B5E3C'];

  /* ---------- platform ---------- */
  function platform() {
    var ua = navigator.userAgent || '', p = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || '';
    if (/android/i.test(ua)) return 'android';
    if (/iphone|ipad|ipod/i.test(ua) || (/mac/i.test(p) && navigator.maxTouchPoints > 1)) return 'ios';
    if (/win/i.test(p) || /windows/i.test(ua)) return 'windows';
    if (/mac/i.test(p)) return 'mac';
    if (/linux|x11/i.test(p + ua) && !/cros/i.test(ua)) return 'linux';
    return 'other';
  }
  var PLAT = platform();
  var REC = { android: 'play', windows: 'gh', linux: 'gh' }[PLAT] || 'src';

  /* ---------- links ---------- */
  function wireLinks() {
    $$('[data-link]').forEach(function (a) { a.href = SITE.urls[a.getAttribute('data-link')]; });
    $('#ver').textContent = SITE.version;
    $('#clFull').href = SITE.urls.changelog;
  }

  /* ---------- theme controls ---------- */
  var MODES = [['system', 'auto'], ['light', 'light'], ['dark', 'dark']];
  function buildModeSegs() {
    ['#modeSeg', '#modeSeg2'].forEach(function (sel) {
      var box = $(sel); if (!box) return;
      box.innerHTML = MODES.map(function (m) {
        return '<button type="button" data-mode="' + m[0] + '" aria-pressed="false" title="' + esc(T('theme.' + m[0])) + '">' + ico(m[1]) + '<span class="seg-l">' + esc(T('theme.' + m[0])) + '</span></button>';
      }).join('');
    });
    markModes();
  }
  function markModes() {
    $$('[data-mode]').forEach(function (b) { b.setAttribute('aria-pressed', b.getAttribute('data-mode') === EnfoTheme.state.mode ? 'true' : 'false'); });
  }
  function labelModes() { MODES.forEach(function (m) { $$('[data-mode="' + m[0] + '"]').forEach(function (b) { b.title = T('theme.' + m[0]); var l = $('.seg-l', b); if (l) l.textContent = T('theme.' + m[0]); }); }); }

  /* ---------- swatches ---------- */
  function swatchHtml(hex, name) {
    var fg = EnfoTheme.hexToLch(hex).L > 62 ? '#1b1b1b' : '#ffffff';
    return '<button type="button" class="swatch" style="--sw:' + hex + ';--swfg:' + fg + '" data-hex="' + hex + '" aria-pressed="false" aria-label="' + esc(name || hex) + '">' + ico('check') + '</button>';
  }
  function markSwatches() {
    var cur = EnfoTheme.state.accent.toLowerCase();
    $$('.swatch').forEach(function (s) {
      var on = s.dataset.hex.toLowerCase() === cur;
      s.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var cc = $('#customColor'); if (cc) cc.value = EnfoTheme.state.accent.toLowerCase();
  }
  function buildSwatches() {
    $('#heroSwatches').innerHTML = HERO_SWATCHES.map(function (h) { return swatchHtml(h); }).join('');
    $('#swatchGrid').innerHTML = APP_COLORS.map(function (h) { return swatchHtml(h); }).join('');
    $$('.swatch').forEach(function (b) { b.addEventListener('click', function () { EnfoTheme.setAccent(b.dataset.hex); }); });
    markSwatches();
  }

  /* ---------- role preview ---------- */
  var ROLES = ['primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer', 'secondaryContainer', 'tertiaryContainer', 'surfaceContainerHighest', 'surfaceContainerHigh', 'surfaceContainer', 'surfaceContainerLow', 'surface', 'onSurface'];
  function buildRoles() {
    $('#roles').innerHTML = ROLES.map(function (r) {
      var k = r.replace(/[A-Z]/g, function (m) { return '-' + m.toLowerCase(); });
      return '<div class="role" style="background:var(--' + k + ');color:var(--' + (/^on/.test(r) ? 'surface' : /primary$|onSurface$/.test(r) ? 'on-primary' : /Container/.test(r) ? 'on-surface' : 'on-surface') + ')"><span>' + r + '</span></div>';
    }).join('');
    $$('.role').forEach(function (el, i) {
      var r = ROLES[i];
      var fg = r === 'primary' ? 'on-primary' : r === 'onPrimary' ? 'primary' : r === 'primaryContainer' ? 'on-primary-container' : r === 'onPrimaryContainer' ? 'primary-container' : r === 'onSurface' ? 'surface' : /^tertiary/.test(r) ? 'on-tertiary-container' : /^secondary/.test(r) ? 'on-secondary-container' : 'on-surface';
      el.style.color = 'var(--' + fg + ')';
    });
  }

  /* ---------- reveal, nav ---------- */
  function setupReveal() {
    var els = $$('.reveal');
    if (!('IntersectionObserver' in window) || reduced()) { els.forEach(function (e) { e.classList.add('in'); }); return; }
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.05 });
    els.forEach(function (e) { io.observe(e); });
  }
  function observeNew(root) {
    var els = $$('.reveal:not(.in)', root);
    if (!('IntersectionObserver' in window) || reduced()) { els.forEach(function (e) { e.classList.add('in'); }); return; }
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.05 });
    els.forEach(function (e) { io.observe(e); });
  }
  function setupNav() {
    var btn = $('#menuBtn'), nav = $('#nav');
    btn.innerHTML = ico('menu');
    btn.addEventListener('click', function () {
      var open = nav.classList.toggle('open'); btn.setAttribute('aria-expanded', open ? 'true' : 'false'); btn.innerHTML = ico(open ? 'close' : 'menu');
    });
    nav.addEventListener('click', function (e) { if (e.target.closest('a')) { nav.classList.remove('open'); btn.setAttribute('aria-expanded', 'false'); btn.innerHTML = ico('menu'); } });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && nav.classList.contains('open')) { nav.classList.remove('open'); btn.setAttribute('aria-expanded', 'false'); btn.innerHTML = ico('menu'); btn.focus(); } });
    var links = $$('.nav a[href^="#"]'), map = {};
    links.forEach(function (a) { map[a.getAttribute('href').slice(1)] = a; });
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (es) {
        es.forEach(function (e) { var a = map[e.target.id]; if (a && e.isIntersecting) { links.forEach(function (l) { l.classList.remove('cur'); }); a.classList.add('cur'); } });
      }, { rootMargin: '-40% 0px -55% 0px' });
      Object.keys(map).forEach(function (id) { var s = document.getElementById(id); if (s) io.observe(s); });
    }
  }

  /* ---------- hero dial ---------- */
  var hero = { i: 0, timer: 0, inst: null, hold: false };
  function heroFrame(now) {
    var period = 26000, p = reduced() ? 0.35 : (now % period) / period;
    return EnfoClock.frame(p, now / 1000, 1500);
  }
  function heroSet(i, fromUser) {
    var O = EnfoClock.ORDER; hero.i = (i + O.length) % O.length; var s = O[hero.i];
    hero.inst.style = s.id; hero.inst.dirty = true; EnfoClock.kick();
    $('#heroStyleName').textContent = s.name;
    var cb = $('#heroComboName');
    if (s.combo) { cb.hidden = false; cb.textContent = T('styles.combo') + ': ' + s.combo.name; cb.dataset.hex = s.combo.hex; } else cb.hidden = true;
    $$('#heroDots i').forEach(function (d, k) { d.classList.toggle('on', k === hero.i); });
    var card = $('.dial-card'); card.classList.remove('pop'); void card.offsetWidth; if (!reduced()) card.classList.add('pop');
    if (fromUser) startHeroTimer();
  }
  function startHeroTimer() {
    clearInterval(hero.timer);
    if (reduced()) return;
    hero.timer = setInterval(function () { if (!hero.hold && !document.hidden) heroSet(hero.i + 1); }, 5200);
  }
  function setupHero() {
    $('#heroPrev').innerHTML = ico('prev'); $('#heroNext').innerHTML = ico('next');
    $('#heroDots').innerHTML = EnfoClock.ORDER.map(function () { return '<i></i>'; }).join('');
    hero.inst = EnfoClock.create($('#heroCanvas'), { style: 'ring', fps: 60, frame: heroFrame });
    heroSet(0);
    $('#heroPrev').addEventListener('click', function () { heroSet(hero.i - 1, true); });
    $('#heroNext').addEventListener('click', function () { heroSet(hero.i + 1, true); });
    $('#heroComboName').addEventListener('click', function () { EnfoTheme.setAccent(this.dataset.hex); });
    var card = $('.dial-card');
    ['pointerenter', 'focusin'].forEach(function (e) { card.addEventListener(e, function () { hero.hold = true; }); });
    ['pointerleave', 'focusout'].forEach(function (e) { card.addEventListener(e, function () { hero.hold = false; }); });
    startHeroTimer();
    EnfoI18n.onChange(function () { $('#heroPrev').setAttribute('aria-label', T('hero.prev')); $('#heroNext').setAttribute('aria-label', T('hero.next')); heroSet(hero.i); });
  }

  /* ---------- downloads ---------- */
  var DL = [
    { id: 'play', ico: 'store', url: function () { return SITE.urls.play; } },
    { id: 'gh', ico: 'download', url: function () { return SITE.urls.releases; } },
    { id: 'src', ico: 'terminal', url: function () { return '#build'; } }
  ];
  function detectedText() { return T('det.' + ({ android: 'android', windows: 'windows', linux: 'linux', ios: 'ios' }[PLAT] || 'other')); }
  function buildDownloads() {
    var order = DL.slice().sort(function (a, b) { return (a.id === REC ? -1 : 0) - (b.id === REC ? -1 : 0); });
    $('#dlGrid').innerHTML = order.map(function (d) {
      var rec = d.id === REC, ext = d.id !== 'src';
      return '<a class="dl-card' + (rec ? ' rec' : '') + '" href="' + d.url() + '"' + (ext ? ' target="_blank" rel="noopener"' : '') + '>' +
        '<span class="dl-ico">' + ico(d.ico) + '</span><span class="dl-txt"><b>' + esc(T('dl.' + d.id + '.t')) + '</b><small>' + esc(T('dl.' + d.id + '.s')) + '</small>' +
        (rec ? '<em>' + esc(T('cta.rec')) + '</em>' : '') + '</span>' + (ext ? ico('external', 'ext') : ico('down2')) + '</a>';
    }).join('');
    var main = DL.filter(function (d) { return d.id === REC; })[0];
    var label = { play: T('cta.play'), gh: T('cta.gh'), src: T('cta.src') }[REC];
    var second = REC === 'play' ? DL[1] : DL[0];
    var secLabel = REC === 'play' ? T('dl.gh.t') : T('dl.play.t');
    $('#heroCta').innerHTML = '<a class="btn big" href="' + main.url() + '"' + (REC !== 'src' ? ' target="_blank" rel="noopener"' : '') + '>' + ico(main.ico) + '<span>' + esc(label) + '</span></a>' +
      '<a class="btn tonal big" href="' + second.url() + '" target="_blank" rel="noopener">' + ico(second.ico) + '<span>' + esc(secLabel) + '</span></a>';
    $('#detected').textContent = detectedText(); $('#detected2').textContent = detectedText();
  }
  function buildSource() {
    var lines = [
      'git clone https://github.com/' + SITE.githubSlug + '.git',
      'cd enfo',
      "echo \"const String admob_id = 'ca-app-pub-3940256099942544/1033173712';\" > lib/secret.dart",
      'flutter pub get',
      'flutter run -d linux     # or: -d windows, or a connected Android device'
    ];
    $('#buildCode').textContent = lines.join('\n');
    var b = $('#copyBuild'); b.textContent = T('copy');
    b.onclick = function () {
      var txt = lines.join('\n');
      var done = function () { b.textContent = T('copied'); setTimeout(function () { b.textContent = T('copy'); }, 1600); };
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(txt).then(done, done); else done();
    };
  }

  /* ---------- static-ish generated sections ---------- */
  function buildWhy() {
    var icons = ['flat', 'lock', 'offline', 'anim', 'palette', 'devices'];
    $('#whyCards').innerHTML = icons.map(function (n, i) {
      return '<article class="card reveal" style="--i:' + i + '"><span class="card-ico">' + ico(n) + '</span><h3>' + esc(T('why.c' + (i + 1) + '.t')) + '</h3><p>' + esc(T('why.c' + (i + 1) + '.d')) + '</p></article>';
    }).join('');
    observeNew($('#whyCards'));
  }
  function buildDevices() {
    var D = [['watch', 'watch'], ['phone', 'phone'], ['tablet', 'tablet'], ['desktop', 'laptop'], ['tv', 'tv']];
    $('#deviceCards').innerHTML = D.map(function (d, i) {
      return '<article class="card dev reveal" style="--i:' + i + '"><div class="sil sil-' + d[0] + '" aria-hidden="true"><i></i></div><h3>' + ico(d[1]) + ' ' + esc(T('dev.' + d[0] + '.t')) + '</h3><p>' + esc(T('dev.' + d[0] + '.d')) + '</p></article>';
    }).join('');
    $$('.sil i').forEach(function (el, i) { var c = document.createElement('canvas'); c.setAttribute('aria-hidden', 'true'); el.appendChild(c); mk(c, { style: ['ring', 'orbit', 'wavyRing', 'segments', 'rings'][i] || 'ring', fps: 20, frame: function (now) { return EnfoClock.frame(reduced() ? 0.4 : (now % 12000) / 12000, now / 1000, 1500); } }); });
    observeNew($('#deviceCards'));
  }
  function kbd(keys) { return keys.map(function (k) { return '<kbd>' + esc(k) + '</kbd>'; }).join(''); }
  function buildKeys() {
    var K = [[['Space'], 'key.playpause'], [['R'], 'key.reset'], [['L'], 'key.lap'], [['1', '…', '9'], 'key.jump'], [['[', ']'], 'key.step'], [['F', 'F11'], 'key.full'], [['D'], 'key.dim'],
      [['S', 'Ctrl+,'], 'key.settings'], [['M'], 'key.modes'], [['?', 'F1'], 'key.help'], [['Esc'], 'key.back']];
    $('#keyList').innerHTML = K.map(function (k) { return '<div class="key-row"><span class="caps">' + kbd(k[0]) + '</span><span>' + esc(T(k[1])) + '</span></div>'; }).join('') +
      '<div class="key-row wide"><span class="caps">' + ico('tv') + '</span><span>' + esc(T('key.media')) + '</span></div>';
    /* fix the Space label in the current language */
    var first = $('#keyList kbd'); if (first) first.textContent = T('key.space');
  }
  function buildLangs() {
    var L = ['English', 'Español', 'Deutsch', 'Français', 'हिन्दी', '日本語', '한국어', 'Português', '中文'];
    $('#langChips').innerHTML = L.map(function (l) { return '<span class="chip on-hover" lang="' + ({ English: 'en', 'Español': 'es', Deutsch: 'de', 'Français': 'fr', 'हिन्दी': 'hi', '日本語': 'ja', '한국어': 'ko', 'Português': 'pt', '中文': 'zh' }[l]) + '">' + l + '</span>'; }).join('');
  }
  function buildWidgets() {
    var W = [['clock', 'clock'], ['analog', 'analog'], ['pomodoro', 'ring'], ['timer', 'wavyRing'], ['stopwatch', 'sw'], ['alarms', 'al'], ['world', 'wd']];
    $('#widgetList').innerHTML = W.map(function (w) { return '<div class="wg" data-k="' + w[1] + '"><div class="wg-body"></div><span>' + esc(T('wg.' + w[0])) + '</span></div>'; }).join('');
    $$('#widgetList .wg').forEach(function (el) {
      var k = el.dataset.k, b = $('.wg-body', el);
      if (FACE_KEYS[k]) { var c = document.createElement('canvas'); c.setAttribute('aria-hidden', 'true'); b.appendChild(c); mk(c, { style: FACE_KEYS[k], fps: 20, frame: function (now) { return EnfoClock.frame(reduced() ? 0.4 : (now % 15000) / 15000, now / 1000, 1500); } }); }
      else if (k === 'clock') { b.innerHTML = '<b class="wg-t" data-tick="clock"></b>'; }
      else if (k === 'sw') { b.innerHTML = '<b class="wg-t" data-tick="sw"></b>'; }
      else if (k === 'al') { b.innerHTML = '<div class="wg-l"><b>06:45</b><small>' + esc(T('d.wake')) + '</small></div><div class="wg-l off"><b>13:30</b><small>' + esc(T('d.lunch')) + '</small></div>'; }
      else if (k === 'wd') { b.innerHTML = '<div class="wg-l"><b data-tick="ny"></b><small>New York</small></div><div class="wg-l"><b data-tick="ldn"></b><small>London</small></div>'; }
    });
  }
  var dyn = [];
  function mk(c, o) { var i = EnfoClock.create(c, o); dyn.push(i); return i; }
  var FACE_KEYS = { analog: 'analog', ring: 'ring', wavyRing: 'wavyRing' };
  function tickWidgets() {
    var d = new Date(), p = function (n) { return (n < 10 ? '0' : '') + n; };
    $$('[data-tick="clock"]').forEach(function (e) { e.textContent = p(d.getHours()) + ':' + p(d.getMinutes()); });
    $$('[data-tick="sw"]').forEach(function (e) { var s = (performance.now() / 1000) % 3600; e.textContent = p(Math.floor(s / 60)) + ':' + p(Math.floor(s % 60)) + '.' + p(Math.floor((s % 1) * 100)); });
    function tz(z) { return new Intl.DateTimeFormat('en-GB', { timeZone: z, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(d); }
    $$('[data-tick="ny"]').forEach(function (e) { e.textContent = tz('America/New_York'); });
    $$('[data-tick="ldn"]').forEach(function (e) { e.textContent = tz('Europe/London'); });
  }
  function buildPrivacy() {
    $('#privList').innerHTML = [1, 2, 3, 4, 5, 6].map(function (i) { return '<li>' + ico('check') + '<span>' + esc(T('priv.' + i)) + '</span></li>'; }).join('');
  }
  function md(s) {
    return esc(s).replace(/`([^`]+)`/g, '<code>$1</code>').replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  }
  function buildChangelog() {
    var R = (window.REPO_DATA && REPO_DATA.changelog) || [];
    $('#changelogBox').innerHTML = R.map(function (r) {
      return '<article class="rel"><h3><span class="chip on">' + esc(r.version) + '</span></h3>' + r.sections.map(function (s) {
        return '<h4>' + esc(s.title) + '</h4><ul>' + s.items.map(function (i) { return '<li>' + md(i) + '</li>'; }).join('') + '</ul>';
      }).join('') + '</article>';
    }).join('') + (EnfoI18n.lang() !== 'en' ? '<p class="hint">' + esc(T('cl.note')) + '</p>' : '');
  }
  function buildCredits() {
    var C = (window.REPO_DATA && REPO_DATA.credits) || [];
    $('#creditList').innerHTML = C.map(function (c) {
      var by = /BY/.test(c.license);
      return '<div class="credit"><div><b>' + esc(c.song) + '</b><small>' + esc(c.artist) + '</small></div><a class="chip' + (by ? ' on' : '') + '" href="' + esc(c.licenseUrl) + '" target="_blank" rel="noopener">' + esc(c.license) + '</a>' +
        '<a class="ibtn" href="' + esc(c.url) + '" target="_blank" rel="noopener" aria-label="Wikimedia Commons: ' + esc(c.song) + '">' + ico('external') + '</a></div>';
    }).join('');
  }
  function buildFaq() {
    $('#faqList').innerHTML = [1, 2, 3, 4, 5, 6, 7, 8].map(function (i) {
      return '<details class="qa"><summary><span>' + esc(T('faq.q' + i)) + '</span>' + ico('more') + '</summary><p>' + esc(T('faq.a' + i)) + '</p></details>';
    }).join('');
  }

  /* ---------- tools showcase ---------- */
  var MODE_IDS = ['pomodoro', 'clock', 'timer', 'stopwatch', 'alarm', 'world', 'event', 'intervals', 'breathe', 'tracker', 'kitchen', 'sleep', 'versus', 'breaks', 'ambient', 'music'];
  var MODE_CORE = 6;
  var tools = { cur: 'pomodoro', demo: null, visible: false };
  function buildModeList() {
    $('#modeList').innerHTML = MODE_IDS.map(function (id, i) {
      return '<button type="button" role="tab" class="mode-tab" id="tab-' + id + '" data-id="' + id + '" aria-selected="false" tabindex="-1" aria-controls="modePanel">' +
        '<span class="mode-ico">' + ico(id) + '</span><span class="mode-lbl">' + esc(T('mode.' + id)) + '</span></button>';
    }).join('');
    selectMode(tools.cur, true);
  }
  function selectMode(id, quiet) {
    tools.cur = id;
    $$('.mode-tab').forEach(function (b) { var on = b.dataset.id === id; b.setAttribute('aria-selected', on ? 'true' : 'false'); b.tabIndex = on ? 0 : -1; });
    $('#modePanel').setAttribute('aria-labelledby', 'tab-' + id);
    $('#modeBadge').innerHTML = ico(id);
    $('#modeName').textContent = T('mode.' + id);
    $('#modeDesc').textContent = T('modeDesc.' + id);
    $('#modeTag').textContent = MODE_IDS.indexOf(id) < MODE_CORE ? T('tools.core') : T('tools.more');
    startDemo();
  }
  function startDemo() {
    if (tools.demo) { tools.demo.stop(); tools.demo = null; }
    var box = $('#modeDemo'); box.innerHTML = '';
    if (!tools.visible) return;
    var el = document.createElement('div'); el.className = 'demo-host'; box.appendChild(el);
    tools.demo = EnfoDemos.render(tools.cur, el);
    el.classList.add('enter');
  }
  function setupTools() {
    buildModeList();
    var list = $('#modeList');
    list.addEventListener('click', function (e) { var b = e.target.closest('.mode-tab'); if (b) selectMode(b.dataset.id); });
    list.addEventListener('keydown', function (e) {
      var k = e.key, i = MODE_IDS.indexOf(tools.cur), n = MODE_IDS.length, cols = getComputedStyle(list).gridTemplateColumns.split(' ').length || 4;
      var ni = null;
      if (k === 'ArrowRight') ni = (i + 1) % n; else if (k === 'ArrowLeft') ni = (i + n - 1) % n;
      else if (k === 'ArrowDown') ni = Math.min(n - 1, i + cols); else if (k === 'ArrowUp') ni = Math.max(0, i - cols);
      else if (k === 'Home') ni = 0; else if (k === 'End') ni = n - 1;
      if (ni === null) return; e.preventDefault(); selectMode(MODE_IDS[ni]); $('#tab-' + MODE_IDS[ni]).focus();
    });
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (es) {
        var v = es[0].isIntersecting; if (v === tools.visible) return; tools.visible = v; startDemo();
      }, { rootMargin: '100px' }).observe($('#modePanel'));
    } else { tools.visible = true; startDemo(); }
    EnfoI18n.onChange(function () { var keep = tools.cur; buildModeList(); selectMode(keep); });
  }

  /* ---------- clock playground ---------- */
  var play = { i: 0, p: 0.35, auto: true, inst: null, tiles: [] };
  function playFrame(now) {
    if (play.auto && !reduced()) play.p = (now % 20000) / 20000 * 0.98;
    var s = $('#playP'); if (play.auto && !reduced() && document.activeElement !== s) s.value = Math.round(play.p * 1000);
    return EnfoClock.frame(play.p, now / 1000, 1500);
  }
  function playSelect(i) {
    var O = EnfoClock.ORDER; play.i = (i + O.length) % O.length; var s = O[play.i];
    play.inst.style = s.id; play.inst.dirty = true; EnfoClock.kick();
    $$('.tile').forEach(function (t, k) { t.setAttribute('aria-selected', k === play.i ? 'true' : 'false'); });
    $('#playName').textContent = T('styles.now') + ': ' + s.name + (s.combo ? ' · ' + T('styles.combo') + ': ' + s.combo.name : '');
  }
  function labelPlay() {
    $('#playShuffle').innerHTML = ico('shuffle') + '<span>' + esc(T('styles.shuffle')) + '</span>';
    $('#playAuto').innerHTML = ico(play.auto ? 'pause' : 'play') + '<span>' + esc(play.auto ? T('styles.auto') : T('styles.autoOff')) + '</span>';
    $('#playAuto').setAttribute('aria-pressed', play.auto ? 'true' : 'false');
  }
  function setupPlay() {
    var O = EnfoClock.ORDER;
    $('#tiles').innerHTML = O.map(function (s, i) {
      return '<button type="button" class="tile" role="option" aria-selected="false" data-i="' + i + '" aria-label="' + esc(s.name) + '"><canvas aria-hidden="true"></canvas><span>' + esc(s.name) + '</span></button>';
    }).join('');
    $$('.tile').forEach(function (b, i) {
      EnfoClock.create($('canvas', b), { style: O[i].id, fps: 20, frame: function (now) { return EnfoClock.frame(reduced() ? 0.4 : (now % 14000) / 14000 * 0.97, now / 1000, 1500); } });
      b.addEventListener('click', function () { play.auto = false; labelPlay(); playSelect(i); });
    });
    play.inst = EnfoClock.create($('#playCanvas'), { style: 'ring', fps: 60, frame: playFrame });
    var combos = O.filter(function (s) { return s.combo; });
    $('#combos').innerHTML = '<span class="lab">' + esc(T('styles.combosTitle')) + '</span>' + combos.map(function (s) {
      return '<button type="button" class="chip combo" data-id="' + s.id + '"><i style="background:' + s.combo.hex + '"></i>' + esc(s.combo.name) + '</button>';
    }).join('');
    $('#combos').addEventListener('click', function (e) {
      var b = e.target.closest('.combo'); if (!b) return;
      var idx = O.findIndex(function (s) { return s.id === b.dataset.id; });
      playSelect(idx); EnfoTheme.setAccent(O[idx].combo.hex);
    });
    $('#playP').addEventListener('input', function () { play.auto = false; labelPlay(); play.p = this.value / 1000; play.inst.dirty = true; EnfoClock.kick(); });
    $('#playAuto').addEventListener('click', function () { play.auto = !play.auto; labelPlay(); });
    $('#playShuffle').addEventListener('click', function () {
      var pick = O.filter(function (s) { return s.combo; }), c = pick[Math.floor(Math.random() * pick.length)];
      var idx = O.indexOf(c); if (idx === play.i) idx = (idx + 1) % O.length;
      playSelect(idx); EnfoTheme.setAccent(APP_COLORS[Math.floor(Math.random() * 30)]);
    });
    labelPlay(); playSelect(0);
    EnfoI18n.onChange(function () { labelPlay(); playSelect(play.i); $('#combos .lab').textContent = T('styles.combosTitle'); });
  }

  /* ---------- screenshots and video (graceful when missing) ---------- */
  var PLACEHOLDERS = [['phone', 'ring', 'Pomodoro'], ['phone', 'orbit', 'Timer'], ['tablet', 'wavyRing', 'Clock']];
  function frameHtml(kind, inner, cap) {
    return '<figure class="shot ' + kind + '"><div class="dev-frame ' + kind + '"><div class="dev-screen">' + inner + '</div></div>' + (cap ? '<figcaption>' + esc(cap) + '</figcaption>' : '') + '</figure>';
  }
  function placeholderShots(box) {
    box.innerHTML = '<div class="ph-row">' + PLACEHOLDERS.map(function (p) {
      return frameHtml(p[0], '<div class="ph"><canvas aria-hidden="true"></canvas><span class="ph-name">' + p[2] + '</span></div>', '');
    }).join('') + '</div>' + '<p class="hint span">' + esc(T('shots.soon')) + '</p>';
    $$('.ph canvas', box).forEach(function (c, i) {
      EnfoClock.create(c, { style: PLACEHOLDERS[i][1], fps: 20, frame: function (now) { return EnfoClock.frame(reduced() ? 0.4 : ((now + i * 4000) % 16000) / 16000, now / 1000, 1500); } });
    });
  }
  var gal = { media: null, dev: 'phone', ori: 'portrait' };
  var LOCALES = { en: 'en-US', es: 'es-419' };
  var DEVS = [['phone', 'gal.phone'], ['tablet7', 'gal.tablet7'], ['tablet10', 'gal.tablet10']];
  function galleryFiles() {
    var loc = LOCALES[EnfoI18n.lang()] || 'en-US', all = (gal.media && gal.media.shots) || [];
    var have = all.filter(function (f) { return f.indexOf('shots/' + loc + '/') === 0; });
    if (!have.length) { var first = all[0] && all[0].split('/')[1]; have = all.filter(function (f) { return f.split('/')[1] === first; }); }
    return have;
  }
  function buildGallery() {
    var box = $('#shots'), all = galleryFiles();
    if (!all.length) { placeholderShots(box); return; }
    var sets = {}; all.forEach(function (f) { var k = f.split('/')[2]; (sets[k] = sets[k] || []).push(f); });
    var set = gal.dev + '-' + gal.ori;
    if (!sets[set]) { var ks = Object.keys(sets).sort(); set = ks[0]; gal.dev = set.split('-')[0]; gal.ori = set.split('-')[1]; }
    var devOk = DEVS.filter(function (d) { return sets[d[0] + '-portrait'] || sets[d[0] + '-landscape']; });
    var files = sets[set].slice().sort();
    box.innerHTML = '<div class="gal-ctl"><div class="seg" role="group" aria-label="' + esc(T('gal.device')) + '">' + devOk.map(function (d) {
      return '<button type="button" data-dev="' + d[0] + '" aria-pressed="' + (d[0] === gal.dev) + '">' + esc(T(d[1])) + '</button>'; }).join('') + '</div>' +
      '<div class="seg" role="group" aria-label="' + esc(T('gal.orient')) + '">' + ['portrait', 'landscape'].map(function (o) {
        return '<button type="button" data-ori="' + o + '" aria-pressed="' + (o === gal.ori) + '"' + (sets[gal.dev + '-' + o] ? '' : ' disabled') + '>' + esc(T('gal.' + o)) + '</button>'; }).join('') + '</div></div>' +
      '<div class="car-wrap"><button type="button" class="ibtn car-prev" aria-label="' + esc(T('hero.prev')) + '">' + ico('prev') + '</button>' +
      '<div class="car ' + gal.ori + '" tabindex="0" role="region" aria-roledescription="carousel" aria-label="' + esc(T('see.title')) + '">' + files.map(function (f, i) {
        return '<figure class="cshot"><img src="assets/' + esc(f) + '" alt="' + esc(T('gal.shot') + ' ' + (i + 1) + '/' + files.length) + '" ' + (i < 2 ? '' : 'loading="lazy" ') + 'decoding="async" draggable="false"></figure>'; }).join('') + '</div>' +
      '<button type="button" class="ibtn car-next" aria-label="' + esc(T('hero.next')) + '">' + ico('next') + '</button></div>';
    var car = $('.car', box);
    var step = function (d) { var f = $('.cshot', car); car.scrollBy({ left: d * (f.offsetWidth + 16), behavior: reduced() ? 'auto' : 'smooth' }); };
    $('.car-prev', box).addEventListener('click', function () { step(-1); });
    $('.car-next', box).addEventListener('click', function () { step(1); });
    car.addEventListener('keydown', function (e) { if (e.key === 'ArrowRight') { e.preventDefault(); step(1); } else if (e.key === 'ArrowLeft') { e.preventDefault(); step(-1); } });
    $$('[data-dev]', box).forEach(function (b) { b.addEventListener('click', function () { gal.dev = b.dataset.dev; buildGallery(); }); });
    $$('[data-ori]', box).forEach(function (b) { b.addEventListener('click', function () { gal.ori = b.dataset.ori; buildGallery(); }); });
    var down = false, sx = 0, sl = 0, moved = false;
    car.addEventListener('pointerdown', function (e) { if (e.pointerType !== 'mouse') return; down = true; moved = false; sx = e.clientX; sl = car.scrollLeft; car.classList.add('drag'); });
    window.addEventListener('pointermove', function (e) { if (!down) return; var dx = e.clientX - sx; if (Math.abs(dx) > 3) moved = true; car.scrollLeft = sl - dx; });
    window.addEventListener('pointerup', function () { if (down) { down = false; car.classList.remove('drag'); } });
    car.addEventListener('click', function (e) { if (moved) { e.preventDefault(); moved = false; } }, true);
  }
  function loadMedia() {
    var box = $('#shots');
    fetch(SITE.mediaManifest, { cache: 'no-cache' }).then(function (r) { if (!r.ok) throw 0; return r.json(); }).then(function (m) {
      gal.media = m; buildGallery(); buildVideos(m.videos || []);
    }).catch(function () { placeholderShots(box); });
    EnfoI18n.onChange(function () { if (gal.media) buildGallery(); });
  }
  function buildVideos(list) {
    var slot = $('#videoSlot'); if (!list.length) return;
    var groups = {};
    list.forEach(function (f) { var base = f.replace(/\.[^.]+$/, ''); (groups[base] = groups[base] || []).push(f); });
    var names = Object.keys(groups).sort(function (a, b) { return (/hero_loop/.test(b) ? 1 : 0) - (/hero_loop/.test(a) ? 1 : 0); });
    function show(base) {
      var srcs = groups[base].sort(function (a) { return /\.webm$/.test(a) ? -1 : 1; });
      var hero = /hero_loop/.test(base);
      slot.innerHTML = '<div class="dev-frame video"><div class="dev-screen"><video muted playsinline preload="metadata" ' + (hero ? 'loop ' : 'controls ') + (reduced() ? 'controls' : '') + ' aria-label="' + esc(T('shots.video')) + '">' +
        srcs.map(function (s) { return '<source src="assets/' + esc(s) + '" type="' + (/webm$/.test(s) ? 'video/webm' : 'video/mp4') + '">'; }).join('') + '</video></div></div>' +
        (names.length > 1 ? '<div class="chips vids">' + names.map(function (n) { return '<button type="button" class="chip' + (n === base ? ' on' : '') + '" data-v="' + esc(n) + '">' + esc(n.split('/').pop().replace(/^enfo_/, '').replace(/_/g, ' ')) + '</button>'; }).join('') + '</div>' : '');
      var v = $('video', slot);
      v.addEventListener('loadedmetadata', function () { if (v.videoWidth > v.videoHeight) $('.dev-frame', slot).classList.add('land'); });
      $$('.vids .chip', slot).forEach(function (c) { c.addEventListener('click', function () { show(c.dataset.v); }); });
      if (hero && !reduced() && 'IntersectionObserver' in window) {
        new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) v.play().catch(function () {}); else v.pause(); }); }, { threshold: 0.3 }).observe(v);
      }
    }
    slot.hidden = false; show(names[0]);
  }

  /* ---------- init ---------- */
  function bindHeader() {
    document.addEventListener('click', function (e) {
      var l = e.target.closest('[data-lang]'); if (l) { EnfoI18n.set(l.getAttribute('data-lang')); return; }
      var m = e.target.closest('[data-mode]'); if (m) EnfoTheme.setMode(m.getAttribute('data-mode'));
    });
    $('#customColor').addEventListener('input', function () { EnfoTheme.setAccent(this.value); });
    $('#resetAccent').addEventListener('click', function () { EnfoTheme.setAccent(EnfoTheme.DEFAULT_ACCENT); });
    EnfoTheme.onChange(function () { markSwatches(); markModes(); });
  }

  function renderI18nSections() {
    dyn.forEach(function (i) { EnfoClock.destroy(i); }); dyn = [];
    buildWhy(); buildDevices(); buildKeys(); buildPrivacy(); buildChangelog(); buildFaq(); buildDownloads(); buildSource(); labelModes(); buildWidgets();
    tickWidgets();
  }

  function init() {
    EnfoI18n.init();
    wireLinks();
    buildModeSegs();
    buildSwatches();
    buildRoles();
    buildLangs();
    buildCredits();
    bindHeader();
    setupNav();
    setupHero();
    setupTools();
    setupPlay();
    renderI18nSections();
    loadMedia();
    setupReveal();
    var top = $('#top'); var sc = function () { top.classList.toggle('scrolled', window.scrollY > 8); }; sc(); window.addEventListener('scroll', sc, { passive: true });
    setInterval(function () { if (!document.hidden) tickWidgets(); }, 400);
    EnfoI18n.onChange(function () {
      /* full-DOM re-render of generated sections; static ones are handled by data-i18n */
      $('#whyCards').innerHTML = ''; $('#deviceCards').innerHTML = '';
      renderI18nSections(); labelModes(); wireLinks();
      $('#shots .hint.span') && ($('#shots .hint.span').textContent = T('shots.soon'));
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
