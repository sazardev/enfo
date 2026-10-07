/* Site i18n. English strings for elements that carry data-i18n in index.html are
   captured from the DOM at start-up (the HTML is the English source, which is
   also what search engines see). Everything else, and every other language, lives
   in the dictionaries below. To add a language: add a block to LANGS + a dictionary
   here (missing keys fall back to English), then add a button in the header. */
(function () {
  'use strict';
  var LANGS = { en: 'English', es: 'Español' };

  var en = {
    'skip': 'Skip to content',
    'theme.system': 'System', 'theme.light': 'Light', 'theme.dark': 'Dark',
    'lang': 'Language',
    'tools.core': 'On by default', 'tools.more': 'Optional tool',
    'hero.swatchName': 'Accent',
    'hero.prev': 'Previous style', 'hero.next': 'Next style',
    'cta.play': 'Get it on Google Play', 'cta.gh': 'Download for Windows / Linux',
    'cta.src': 'Build from source', 'cta.rec': 'Recommended for your device',
    'det.android': 'We think you are on Android: Google Play is the easiest way.',
    'det.windows': 'We think you are on Windows: grab the Windows build from GitHub Releases.',
    'det.linux': 'We think you are on Linux: grab the Linux build from GitHub Releases.',
    'det.other': 'Enfo runs on Android, Windows and Linux. On other systems you can build it from source.',
    'det.ios': 'Enfo does not have an iOS build. It runs on Android, Windows and Linux; you can also build it from source.',
    'gal.phone': 'Phone', 'gal.tablet7': 'Tablet 7"', 'gal.tablet10': 'Tablet 10"', 'gal.portrait': 'Portrait', 'gal.landscape': 'Landscape', 'gal.device': 'Device', 'gal.orient': 'Orientation', 'gal.shot': 'Screenshot',
    'shots.phone': 'Phone screenshot', 'shots.tablet': 'Tablet screenshot',
    'shots.soon': 'Screenshots are on their way. The dial below is drawn live in your browser.',
    'shots.video': 'Watch it in motion',
    'brand.tag': 'A lowercase e drawn as a timer ring: the crossbar is the clock hand.',
    'kit.btn': 'Download the press kit',
    'kit.contents': 'ZIP, 28 MB: logo (SVG and PNG), cover banners, Play graphics, screenshots in every size and the promo videos.',
    'why.c1.t': 'Flat on purpose', 'why.c1.d': 'No borders, no shadows, no gradients. Selection is shown by shape (circle to squircle) and tone; presses spring back.',
    'why.c2.t': 'Private by default', 'why.c2.d': 'No account and no sign-in. Your settings and history live on your device only.',
    'why.c3.t': 'Works offline', 'why.c3.d': 'Timers, alarms, world time and even the 72 lo-fi songs are bundled; nothing needs a connection.',
    'why.c4.t': 'Made to be looked at', 'why.c4.d': '63 flat clock styles and 60 style-and-color combos, from a quiet ring to gears, flowers and fireflies.',
    'why.c5.t': 'Your colors', 'why.c5.d': 'Pick an accent from 32 colors or mix your own; light, dark or follow the system.',
    'why.c6.t': 'Everywhere you keep time', 'why.c6.d': 'Android, Windows and Linux, with layouts for phones, tablets, TVs, desktops and tiny windows.',
    'dev.watch.t': 'Tiny windows', 'dev.watch.d': 'Below about 260 dp the layout drops to the essentials: dial and two buttons.',
    'dev.phone.t': 'Phone', 'dev.phone.d': 'A calm column: dial on top, controls and the bottom bar within thumb reach.',
    'dev.tablet.t': 'Tablet', 'dev.tablet.d': 'Dial next to a side panel; Settings becomes master-detail.',
    'dev.desktop.t': 'Desktop', 'dev.desktop.d': 'Windows and Linux with notifications, full screen and global keyboard shortcuts.',
    'dev.tv.t': 'TV', 'dev.tv.d': 'Big text, D-pad focus with soft halos, remote play/pause and channel keys.',
    'key.space': 'Space', 'key.playpause': 'Start or pause', 'key.reset': 'Reset', 'key.lap': 'Lap (stopwatch)',
    'key.jump': 'Jump to tool 1 to 9', 'key.step': 'Previous / next tool', 'key.full': 'Full screen', 'key.dim': 'Dim the screen (full screen)',
    'key.settings': 'Settings', 'key.modes': 'Modes menu', 'key.help': 'Show the shortcut list', 'key.back': 'Back / leave full screen',
    'key.media': 'Media keys and TV remote keys also work',
    'wg.clock': 'Clock', 'wg.analog': 'Analog clock', 'wg.pomodoro': 'Pomodoro', 'wg.timer': 'Timer', 'wg.stopwatch': 'Stopwatch', 'wg.alarms': 'Alarms', 'wg.world': 'World clock', 'wg.music': 'Music', 'wg.focus': 'Focus',
    'priv.1': 'No account, no sign-in. Enfo does not ask for your name or email.',
    'priv.2': 'Your settings, timers, alarms and history are stored on your device (local preferences) and never uploaded by Enfo.',
    'priv.3': 'Notifications and alarms are scheduled locally by your system.',
    'priv.4': 'Enfo shows no ads and includes no ad SDKs: there is nothing to track you across apps or sites.',
    'priv.5': 'The music and sounds are bundled in the app; nothing is streamed.',
    'priv.6': 'This website uses no cookies and no analytics. It saves your theme, accent and language choice in your browser (localStorage) only.',
    'cl.note': 'The changelog is kept in English.',
    'copy': 'Copy', 'copied': 'Copied',
    'dl.play.s': 'Android · Google Play', 'dl.gh.s': 'Windows and Linux · GitHub Releases', 'dl.src.s': 'Any platform Flutter supports',
    'dl.play.t': 'Google Play', 'dl.gh.t': 'GitHub Releases', 'dl.src.t': 'Build from source',
    'dl.gh.hint': 'Open the latest release and pick the file for your system. Assets depend on what was published.',
    'styles.shuffle': 'Shuffle combo', 'styles.auto': 'Auto-play', 'styles.autoOff': 'Paused',
    'styles.now': 'Style', 'styles.combo': 'Combo', 'styles.tileHint': 'Click a style to preview it',
    'styles.combosTitle': 'A few of the 60 combos',
    'themes.lime': 'Back to lime',
    'faq.q1': 'Is Enfo free?', 'faq.a1': 'Yes, you can download and use it for free, with no ads. If you want to support it, the app has a one-time donation through Google Play and a tip jar.',
    'faq.q2': 'Which platforms does it run on?', 'faq.a2': 'Android (Google Play), Windows and Linux (GitHub Releases or build from source). There is no iOS or macOS build.',
    'faq.q3': 'Does it work offline?', 'faq.a3': 'Yes. Everything, including the music and ambient sounds, is bundled or generated on your device. Everything works offline.',
    'faq.q4': 'Will alarms ring with the app closed?', 'faq.a4': 'On Android, alarms are also scheduled with the system for the next 14 days, so they ring with the app closed. Delivery of notifications has not been verified on every device and vendor; check your battery and notification settings. On desktop, Enfo must be running.',
    'faq.q5': 'Where is my data?', 'faq.a5': 'On your device only. Settings > Data lets you reset settings or erase everything.',
    'faq.q6': 'Can I turn tools off?', 'faq.a6': 'Yes. Six tools are on by default; the other ten are off until you enable them in the Modes menu. You can also reorder them, choose the start tool and hide bottom-menu buttons.',
    'faq.q7': 'How do I add a clock style or a language?', 'faq.a7': 'The project is open source: styles live in lib/ui/clock and strings in the ARB files. Open an issue or a pull request on GitHub.',
    'faq.q8': 'Why is the whole page one color?', 'faq.a8': 'Because Enfo does the same: one accent seeds every surface. Try the color swatches at the top.',
    'foot.copyright': 'Enfo is open source software.',
    'd.tapdial': 'Sped up: 25 minutes in 16 seconds. Tap the dial to pause.',
    'd.paused': 'Paused', 'd.focus': 'Focus', 'd.rest': 'Rest',
    'd.start': 'Start', 'd.pause': 'Pause', 'd.reset': 'Reset', 'd.lap': 'Lap',
    'd.days': 'M,T,W,T,F,S,S', 'd.wake': 'Wake up', 'd.lunch': 'Lunch break', 'd.stretch': 'Stretch',
    'd.meeting': 'Meeting planner: hours when all three cities are at work',
    'd.newyear': 'New Year', 'd.yearly': 'Repeats yearly', 'd.days1': 'd',
    'd.work': 'Work', 'd.restp': 'Rest', 'd.round': 'Round',
    'd.inhale': 'Inhale', 'd.exhale': 'Exhale', 'd.hold': 'Hold',
    'd.p.box': 'Box 4-4-4-4', 'd.p.relax': '4-7-8', 'd.p.calm': 'Calm 5-5',
    'd.reading': 'Reading', 'd.pasta': 'Pasta', 'd.eggs': 'Eggs', 'd.bread': 'Bread', 'd.done': 'Done',
    'd.wakeat': 'Wake up at', 'd.cyc': 'cycles', 'd.cycles': 'Bedtimes include about 15 minutes to fall asleep. One sleep cycle is about 90 minutes.',
    'd.player1': 'Player 1', 'd.player2': 'Player 2',
    'd.b2020': 'Every 20 minutes, look at something 20 feet (6 m) away for 20 seconds.', 'd.stretch2': 'Stretch', 'd.water': 'Drink water', 'd.posture': 'Posture', 'd.nextbreak': 'Next break in',
    'd.n.white': 'White', 'd.n.pink': 'Pink', 'd.n.brown': 'Brown', 'd.n.rain': 'Rain', 'd.n.wind': 'Wind', 'd.n.ocean': 'Ocean', 'd.sleeptimer': 'Sleep timer', 'd.silent': 'This preview is silent; the app synthesizes the sounds on your device.',
    'd.songs': 'Swipe through 72 bundled songs; the dial follows the song and its rhythm.',
    'mode.pomodoro': 'Pomodoro', 'modeDesc.pomodoro': 'Focus and rest cycles',
    'mode.clock': 'Clock', 'modeDesc.clock': 'A beautiful, always-on clock',
    'mode.timer': 'Timer', 'modeDesc.timer': 'Count down from any time',
    'mode.stopwatch': 'Stopwatch', 'modeDesc.stopwatch': 'Measure time, with laps',
    'mode.alarm': 'Alarm', 'modeDesc.alarm': 'Wake up or get reminded',
    'mode.world': 'World clock', 'modeDesc.world': 'The time in cities around the world',
    'mode.event': 'Events', 'modeDesc.event': 'Count the days to what matters',
    'mode.intervals': 'Intervals', 'modeDesc.intervals': 'Work and rest rounds, like HIIT',
    'mode.breathe': 'Breathe', 'modeDesc.breathe': 'Guided breathing to calm down',
    'mode.tracker': 'Tracker', 'modeDesc.tracker': 'Time what you do, see the totals',
    'mode.kitchen': 'Kitchen', 'modeDesc.kitchen': 'Several named timers at once',
    'mode.sleep': 'Sleep', 'modeDesc.sleep': 'Plan bedtime and wake-up in sleep cycles',
    'mode.versus': 'Turns', 'modeDesc.versus': 'Two-player clock for chess, games and debates',
    'mode.breaks': 'Breaks', 'modeDesc.breaks': 'Reminders to rest your eyes and stretch',
    'mode.ambient': 'Ambient', 'modeDesc.ambient': 'Background sounds with a sleep timer',
    'mode.music': 'Music', 'modeDesc.music': 'Lo-fi songs to focus to'
  };

  var es = {
    'skip': 'Saltar al contenido',
    'nav.why': 'Por qué Enfo', 'nav.tools': 'Herramientas', 'nav.styles': 'Estilos de reloj', 'nav.themes': 'Colores', 'nav.devices': 'Dispositivos', 'nav.faq': 'Preguntas', 'nav.download': 'Descargar',
    'theme.system': 'Sistema', 'theme.light': 'Claro', 'theme.dark': 'Oscuro',
    'lang': 'Idioma',
    'hero.eyebrow': 'Caja de herramientas de reloj y tiempo',
    'hero.title': 'Todo tipo de tiempo, en una app plana y tranquila.',
    'hero.sub': 'Enfo empezó como un temporizador Pomodoro. Hoy son 16 herramientas, desde temporizadores y alarmas hasta respiración, ciclos de sueño y música lo-fi, dibujadas en 63 estilos de reloj que siguen tu color.',
    'hero.swatchHint': 'Elige un color: toda la página se re-tematiza, igual que la app.',
    'facts.tools': 'herramientas', 'facts.styles': 'estilos de reloj', 'facts.langs': 'idiomas', 'facts.widgets': 'widgets de Android',
    'tools.core': 'Activa por defecto', 'tools.more': 'Herramienta opcional',
    'hero.prev': 'Estilo anterior', 'hero.next': 'Estilo siguiente',
    'cta.play': 'Consíguela en Google Play', 'cta.gh': 'Descargar para Windows / Linux',
    'cta.src': 'Compilar desde el código', 'cta.rec': 'Recomendado para tu dispositivo',
    'det.android': 'Parece que usas Android: Google Play es lo más fácil.',
    'det.windows': 'Parece que usas Windows: descarga la versión de Windows en GitHub Releases.',
    'det.linux': 'Parece que usas Linux: descarga la versión de Linux en GitHub Releases.',
    'det.other': 'Enfo funciona en Android, Windows y Linux. En otros sistemas puedes compilarla desde el código.',
    'det.ios': 'Enfo no tiene versión para iOS. Funciona en Android, Windows y Linux; también puedes compilarla desde el código.',
    'see.eyebrow': 'En tu bolsillo', 'see.title': 'Míralo en movimiento',
    'see.lead': 'Pantallas reales de la app, para teléfono y tableta. Todo es plano: el tono, la forma y el movimiento hacen el trabajo.',
    'gal.phone': 'Teléfono', 'gal.tablet7': 'Tableta 7"', 'gal.tablet10': 'Tableta 10"', 'gal.portrait': 'Vertical', 'gal.landscape': 'Horizontal', 'gal.device': 'Dispositivo', 'gal.orient': 'Orientación', 'gal.shot': 'Captura',
    'shots.phone': 'Captura de teléfono', 'shots.tablet': 'Captura de tableta',
    'shots.soon': 'Las capturas están en camino. El reloj de abajo se dibuja en vivo en tu navegador.',
    'shots.video': 'Míralo en movimiento',
    'brand.tag': 'Una e minúscula dibujada como el anillo de un temporizador: la barra es la aguja del reloj.',
    'kit.btn': 'Descargar el kit de prensa',
    'kit.contents': 'ZIP, 28 MB: logo (SVG y PNG), banners de portada, gráficos de Play, capturas en todos los tamaños y los videos promocionales.',
    'why.eyebrow': 'Por qué Enfo', 'why.title': 'Pequeña por fuera, profunda por dentro',
    'why.ads': 'Nota honesta: Enfo no tiene anuncios, ni cuenta, ni inicio de sesión. La pantalla de apoyo de la app tiene una donación única con Google Play y una propina por si quieres colaborar.',
    'why.c1.t': 'Plana a propósito', 'why.c1.d': 'Sin bordes, sin sombras, sin degradados. La selección se muestra con la forma (de círculo a squircle) y el tono; al pulsar, todo rebota.',
    'why.c2.t': 'Privada por defecto', 'why.c2.d': 'Sin cuenta ni inicio de sesión. Tus ajustes e historial viven solo en tu dispositivo.',
    'why.c3.t': 'Funciona sin conexión', 'why.c3.d': 'Temporizadores, alarmas, la hora mundial e incluso las 72 canciones lo-fi vienen incluidas; nada necesita conexión.',
    'why.c4.t': 'Hecha para mirarse', 'why.c4.d': '63 estilos de reloj planos y 60 combinaciones de estilo y color, desde un anillo silencioso hasta engranes, flores y luciérnagas.',
    'why.c5.t': 'Tus colores', 'why.c5.d': 'Elige un acento entre 32 colores o mezcla el tuyo; claro, oscuro o el del sistema.',
    'why.c6.t': 'Donde midas el tiempo', 'why.c6.d': 'Android, Windows y Linux, con diseños para teléfonos, tabletas, TV, escritorio y ventanas diminutas.',
    'tools.eyebrow': '16 herramientas', 'tools.title': 'Una app, dieciséis maneras de aprovechar el tiempo',
    'tools.lead': 'Seis herramientas están activas desde el inicio; las otras diez están a un toque en el menú de modos. Prueba las demos en vivo (son silenciosas y corren solo en tu navegador).',
    'styles.eyebrow': '63 estilos de reloj · 60 combos', 'styles.title': 'Tu temporizador puede verse como quieras',
    'styles.lead': 'Anillos, ondas, pasteles, esferas, medidores, espirales, dígitos, flores, engranes. Un combo une un estilo con un color en un toque. Aquí tienes algunos, vivos; mueve el tiempo y mezcla.',
    'styles.progress': 'Progreso', 'styles.shuffle': 'Mezclar combo', 'styles.auto': 'Reproducción automática', 'styles.autoOff': 'En pausa',
    'styles.now': 'Estilo', 'styles.combo': 'Combo', 'styles.tileHint': 'Haz clic en un estilo para verlo', 'styles.combosTitle': 'Algunos de los 60 combos',
    'themes.eyebrow': 'Material You, en plano', 'themes.title': 'Un color entra. Toda una paleta tonal sale.',
    'themes.lead': 'Elige un acento y Enfo deriva de él cada superficie, contenedor y color de texto, en claro y oscuro. Sin bordes, sin sombras, sin degradados: la selección es una forma que pasa de círculo a squircle.',
    'themes.custom': 'Color personalizado', 'themes.reset': 'Volver a lima',
    'devices.eyebrow': 'Adaptable', 'devices.title': 'Desde una ventana del tamaño de un reloj hasta una TV',
    'devices.lead': 'Un diseño adaptable: una columna en teléfonos, un reloj con panel lateral en pantallas anchas, ajustes maestro-detalle en tabletas, y todo enfocable con teclado y control remoto.',
    'devices.note': 'Los diseños se prueban en tamaños de reloj, teléfono, tableta, TV y escritorio. Enfo se publica para Android, Windows y Linux; todavía no hay fichas separadas para Wear OS o Android TV.',
    'dev.watch.t': 'Ventanas diminutas', 'dev.watch.d': 'Por debajo de unos 260 dp el diseño se reduce a lo esencial: reloj y dos botones.',
    'dev.phone.t': 'Teléfono', 'dev.phone.d': 'Una columna tranquila: el reloj arriba, los controles y la barra inferior al alcance del pulgar.',
    'dev.tablet.t': 'Tableta', 'dev.tablet.d': 'El reloj junto a un panel lateral; los ajustes pasan a maestro-detalle.',
    'dev.desktop.t': 'Escritorio', 'dev.desktop.d': 'Windows y Linux con notificaciones, pantalla completa y atajos de teclado globales.',
    'dev.tv.t': 'TV', 'dev.tv.d': 'Texto grande, foco con halos suaves para el D-pad, teclas de reproducción y canal del control.',
    'keys.eyebrow': 'Teclado y control remoto', 'keys.title': 'Se maneja sin tocar la pantalla',
    'keys.lead': 'Las flechas o el D-pad del control mueven el foco, Enter u OK presiona. Estos atajos hacen el resto. Pulsa ? o F1 en la app para ver esta lista.',
    'key.space': 'Espacio', 'key.playpause': 'Iniciar o pausar', 'key.reset': 'Reiniciar', 'key.lap': 'Vuelta (cronómetro)',
    'key.jump': 'Ir a la herramienta 1 a 9', 'key.step': 'Herramienta anterior / siguiente', 'key.full': 'Pantalla completa', 'key.dim': 'Atenuar la pantalla (pantalla completa)',
    'key.settings': 'Ajustes', 'key.modes': 'Menú de modos', 'key.help': 'Mostrar la lista de atajos', 'key.back': 'Atrás / salir de pantalla completa',
    'key.media': 'También funcionan las teclas multimedia y las del control de TV',
    'langs.eyebrow': '9 idiomas', 'langs.title': 'Habla tu idioma',
    'langs.lead': 'Elígelo en la bienvenida o en Ajustes. Los nombres de ciudades de la hora mundial siguen solo en inglés y español. Este sitio está en inglés y español.',
    'widgets.eyebrow': 'Widgets de Android', 'widgets.title': 'Nueve widgets Material You',
    'widgets.lead': 'Reloj, reloj analógico, Pomodoro, temporizador, cronómetro, alarmas, hora mundial, música y enfoque. Los widgets de Pomodoro y temporizador se dibujan en el estilo de reloj que elijas.',
    'wg.clock': 'Reloj', 'wg.analog': 'Reloj analógico', 'wg.pomodoro': 'Pomodoro', 'wg.timer': 'Temporizador', 'wg.stopwatch': 'Cronómetro', 'wg.alarms': 'Alarmas', 'wg.world': 'Hora mundial', 'wg.music': 'Música', 'wg.focus': 'Enfoque',
    'dl.eyebrow': 'Descarga gratuita', 'dl.title': 'Descargar Enfo · Download Enfo now',
    'dl.lead': 'Consíguela en Android desde Google Play, o descarga las últimas versiones de Windows y Linux en GitHub Releases.',
    'dl.buildTitle': 'Compilar desde el código',
    'dl.buildLead': 'Necesitas el SDK de Flutter. Clona el repositorio, ejecuta flutter pub get y flutter run; no hacen falta secretos ni claves de API.',
    'dl.buildLinux': 'En Linux también necesitas el paquete de desarrollo de libnotify (por ejemplo libnotify-dev en Debian/Ubuntu).',
    'dl.play.s': 'Android · Google Play', 'dl.gh.s': 'Windows y Linux · GitHub Releases', 'dl.src.s': 'Cualquier plataforma que Flutter soporte',
    'dl.play.t': 'Google Play', 'dl.gh.t': 'GitHub Releases', 'dl.src.t': 'Compilar desde el código',
    'dl.gh.hint': 'Abre la última versión y elige el archivo para tu sistema. Los archivos dependen de lo publicado.',
    'priv.eyebrow': 'Privacidad', 'priv.title': 'Qué hace Enfo con tus datos',
    'priv.1': 'Sin cuenta ni inicio de sesión. Enfo no te pide nombre ni correo.',
    'priv.2': 'Tus ajustes, temporizadores, alarmas e historial se guardan en tu dispositivo (preferencias locales) y Enfo nunca los sube.',
    'priv.3': 'Las notificaciones y alarmas las programa tu sistema localmente.',
    'priv.4': 'Enfo no muestra anuncios y no incluye SDKs de publicidad: no hay nada que te rastree entre apps o sitios.',
    'priv.5': 'La música y los sonidos vienen incluidos en la app; nada se transmite por internet.',
    'priv.6': 'Este sitio no usa cookies ni analítica. Solo guarda tu tema, acento e idioma en tu navegador (localStorage).',
    'cl.eyebrow': 'Novedades', 'cl.title': 'Historial de cambios', 'cl.full': 'Historial completo en GitHub', 'cl.note': 'El historial de cambios se mantiene en inglés.',
    'music.eyebrow': 'Créditos musicales', 'music.title': '72 canciones lo-fi, con sus créditos',
    'music.lead': 'Canciones de Wikimedia Commons y de la colección Open Lo-Fi, recodificadas a Ogg Vorbis. La mayoría son CC0; cuatro son CC BY y requieren los créditos de abajo.',
    'faq.eyebrow': 'Preguntas', 'faq.title': 'Preguntas y respuestas',
    'faq.q1': '¿Enfo es gratis?', 'faq.a1': 'Sí, puedes descargarla y usarla gratis, sin anuncios. Si quieres apoyarla, la app tiene una donación única con Google Play y una propina.',
    'faq.q2': '¿En qué plataformas funciona?', 'faq.a2': 'Android (Google Play), Windows y Linux (GitHub Releases o compilando desde el código). No hay versión para iOS ni macOS.',
    'faq.q3': '¿Funciona sin conexión?', 'faq.a3': 'Sí. Todo, incluida la música y los sonidos ambientales, viene incluido o se genera en tu dispositivo. Todo funciona sin conexión.',
    'faq.q4': '¿Las alarmas suenan con la app cerrada?', 'faq.a4': 'En Android, las alarmas también se programan con el sistema para los próximos 14 días, así que suenan con la app cerrada. La entrega de notificaciones no se ha verificado en todos los dispositivos y fabricantes; revisa los ajustes de batería y notificaciones. En escritorio, Enfo debe estar abierta.',
    'faq.q5': '¿Dónde están mis datos?', 'faq.a5': 'Solo en tu dispositivo. En Ajustes > Datos puedes restablecer los ajustes o borrar todo.',
    'faq.q6': '¿Puedo desactivar herramientas?', 'faq.a6': 'Sí. Seis herramientas vienen activas; las otras diez están apagadas hasta que las actives en el menú de modos. También puedes reordenarlas, elegir la de inicio y ocultar botones del menú inferior.',
    'faq.q7': '¿Cómo agrego un estilo de reloj o un idioma?', 'faq.a7': 'El proyecto es de código abierto: los estilos viven en lib/ui/clock y los textos en los archivos ARB. Abre un issue o un pull request en GitHub.',
    'faq.q8': '¿Por qué toda la página es de un solo color?', 'faq.a8': 'Porque Enfo hace lo mismo: un acento da origen a cada superficie. Prueba los colores de arriba.',
    'foot.tag': 'Una caja de herramientas de reloj y tiempo, plana y tranquila.', 'foot.issues': 'Reportar un problema', 'foot.coffee': 'Apoyar al desarrollador',
    'foot.font': 'Tipografía Geist Mono, © The Geist Project Authors, SIL Open Font License 1.1 (<a href="assets/fonts/OFL.txt">licencia</a>). Iconos: Material Icons, Apache 2.0.',
    'foot.ver': 'Versión', 'foot.made': 'Hecha con Flutter. Google Play y el logotipo de Google Play son marcas de Google LLC.',
    'copy': 'Copiar', 'copied': 'Copiado',
    'd.tapdial': 'Acelerado: 25 minutos en 16 segundos. Toca el reloj para pausar.',
    'd.paused': 'En pausa', 'd.focus': 'Enfoque', 'd.rest': 'Descanso',
    'd.start': 'Iniciar', 'd.pause': 'Pausar', 'd.reset': 'Reiniciar', 'd.lap': 'Vuelta',
    'd.days': 'L,M,X,J,V,S,D', 'd.wake': 'Despertar', 'd.lunch': 'Hora de comer', 'd.stretch': 'Estirarse',
    'd.meeting': 'Planificador de reuniones: horas en que las tres ciudades trabajan',
    'd.newyear': 'Año Nuevo', 'd.yearly': 'Se repite cada año', 'd.days1': ' d',
    'd.work': 'Trabajo', 'd.restp': 'Descanso', 'd.round': 'Ronda',
    'd.inhale': 'Inhala', 'd.exhale': 'Exhala', 'd.hold': 'Sostén',
    'd.p.box': 'Caja 4-4-4-4', 'd.p.relax': '4-7-8', 'd.p.calm': 'Calma 5-5',
    'd.reading': 'Lectura', 'd.pasta': 'Pasta', 'd.eggs': 'Huevos', 'd.bread': 'Pan', 'd.done': 'Listo',
    'd.wakeat': 'Despertar a las', 'd.cyc': 'ciclos', 'd.cycles': 'Las horas de dormir incluyen unos 15 minutos para quedarte dormido. Un ciclo de sueño dura unos 90 minutos.',
    'd.player1': 'Jugador 1', 'd.player2': 'Jugador 2',
    'd.b2020': 'Cada 20 minutos, mira algo a 6 m (20 pies) de distancia durante 20 segundos.', 'd.stretch2': 'Estirar', 'd.water': 'Beber agua', 'd.posture': 'Postura', 'd.nextbreak': 'Próxima pausa en',
    'd.n.white': 'Blanco', 'd.n.pink': 'Rosa', 'd.n.brown': 'Marrón', 'd.n.rain': 'Lluvia', 'd.n.wind': 'Viento', 'd.n.ocean': 'Océano', 'd.sleeptimer': 'Apagado', 'd.silent': 'Esta vista previa es silenciosa; la app sintetiza los sonidos en tu dispositivo.',
    'd.songs': 'Desliza entre 72 canciones incluidas; el reloj sigue la canción y su ritmo.',
    'mode.pomodoro': 'Pomodoro', 'modeDesc.pomodoro': 'Ciclos de enfoque y descanso',
    'mode.clock': 'Reloj', 'modeDesc.clock': 'Un reloj hermoso, siempre visible',
    'mode.timer': 'Temporizador', 'modeDesc.timer': 'Cuenta regresiva desde cualquier tiempo',
    'mode.stopwatch': 'Cronómetro', 'modeDesc.stopwatch': 'Mide el tiempo, con vueltas',
    'mode.alarm': 'Alarma', 'modeDesc.alarm': 'Despierta o recibe recordatorios',
    'mode.world': 'Hora mundial', 'modeDesc.world': 'La hora en ciudades del mundo',
    'mode.event': 'Eventos', 'modeDesc.event': 'Cuenta los días hasta lo importante',
    'mode.intervals': 'Intervalos', 'modeDesc.intervals': 'Rondas de trabajo y descanso, como HIIT',
    'mode.breathe': 'Respirar', 'modeDesc.breathe': 'Respiración guiada para calmarte',
    'mode.tracker': 'Registro', 'modeDesc.tracker': 'Mide lo que haces y mira los totales',
    'mode.kitchen': 'Cocina', 'modeDesc.kitchen': 'Varios temporizadores con nombre a la vez',
    'mode.sleep': 'Sueño', 'modeDesc.sleep': 'Planea dormir y despertar por ciclos de sueño',
    'mode.versus': 'Turnos', 'modeDesc.versus': 'Reloj de dos para ajedrez, juegos y debates',
    'mode.breaks': 'Pausas', 'modeDesc.breaks': 'Recordatorios para descansar la vista y estirarte',
    'mode.ambient': 'Ambiente', 'modeDesc.ambient': 'Sonidos de fondo con temporizador de apagado',
    'mode.music': 'Música', 'modeDesc.music': 'Canciones lo-fi para concentrarte'
  };

  var dict = { en: en, es: es };
  var cur = 'en';
  var listeners = [];

  function captureEnglish() {
    var nodes = document.querySelectorAll('[data-i18n]');
    for (var i = 0; i < nodes.length; i++) {
      var k = nodes[i].getAttribute('data-i18n');
      if (!(k in en)) en[k] = nodes[i].innerHTML;
    }
  }
  function t(key) {
    var d = dict[cur];
    if (d && key in d) return d[key];
    return key in en ? en[key] : key;
  }
  function apply() {
    document.documentElement.lang = cur;
    var nodes = document.querySelectorAll('[data-i18n]');
    for (var i = 0; i < nodes.length; i++) nodes[i].innerHTML = t(nodes[i].getAttribute('data-i18n'));
    document.title = cur === 'es'
      ? 'Enfo – una caja de herramientas de reloj y tiempo, plana y tranquila (Pomodoro, temporizador, alarmas, hora mundial y más)'
      : 'Enfo – a flat, calm clock & timer toolbox (Pomodoro, timers, alarms, world clock and more)';
    var md = document.querySelector('meta[name="description"]');
    if (md) md.setAttribute('content', cur === 'es'
      ? 'Enfo es una caja de herramientas de reloj y tiempo, plana y minimalista, para Android, Windows y Linux: Pomodoro, temporizador, cronómetro, alarma, hora mundial y 10 herramientas más, 63 estilos de reloj, colores Material You y 9 idiomas.'
      : 'Enfo is a flat, minimal clock and timer toolbox for Android, Windows and Linux: Pomodoro, timer, stopwatch, alarm, world clock and 10 more tools, 63 clock styles, Material You colors, 9 languages.');
    var segs = document.querySelectorAll('[data-lang]');
    for (var j = 0; j < segs.length; j++) segs[j].setAttribute('aria-pressed', segs[j].getAttribute('data-lang') === cur ? 'true' : 'false');
    for (var k = 0; k < listeners.length; k++) listeners[k](cur);
  }
  function set(lang) {
    if (!dict[lang]) lang = 'en';
    cur = lang;
    try { localStorage.setItem('enfo_site_lang', lang); } catch (e) { /* ignore */ }
    apply();
  }
  function detect() {
    try { var q = new URLSearchParams(location.search).get('lang'); if (q && dict[q]) return q; } catch (e) { /* ignore */ }
    var s = null; try { s = localStorage.getItem('enfo_site_lang'); } catch (e) { /* ignore */ }
    if (s && dict[s]) return s;
    var n = (navigator.languages && navigator.languages[0]) || navigator.language || 'en';
    n = n.slice(0, 2).toLowerCase();
    return dict[n] ? n : 'en';
  }

  window.EnfoI18n = {
    LANGS: LANGS, t: t, lang: function () { return cur; }, set: set,
    onChange: function (fn) { listeners.push(fn); },
    icon: function (n, c) { return window.EnfoIcons ? EnfoIcons.svg(n, c) : ''; },
    init: function () { captureEnglish(); cur = detect(); apply(); }
  };
})();
