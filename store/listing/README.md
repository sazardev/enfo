# Kit de ficha de Google Play: Enfo 1.1.0 (build 4)

Todo el texto de esta carpeta sale del repo (MEMORY.md, CHANGELOG.md, pubspec.yaml, `lib/`, `AndroidManifest.xml`). Nada se ha verificado en un dispositivo real. Validar límites: `python3 tools/check_listing.py`.

## 1. Archivos

- `store/fastlane/metadata/android/<locale>/{title,short_description,full_description}.txt` y `changelogs/4.txt` (versionCode 4): layout compatible con `fastlane supply`.
- `store/listing/<locale>/`: los mismos textos (`title`, `short_description`, `full_description`, `whats_new`) más `feature_graphic_tagline.txt`, `video_title.txt`, `video_description.txt`.
- `store/listing/headlines.json`: `{"_scenes": [8 ids], "<locale>": [8 titulares]}` para el compositor de capturas. `headlines_by_scene.json`: `{locale: {scene_id: titular}}`.
- Locales: en-US, es-419, es-ES (mismo texto que es-419 con "mesita de noche"; puedes omitirlo y dejar que es-419 cubra España), de-DE, fr-FR, pt-BR, hi-IN, ja-JP, ko-KR, zh-CN.
- Escenas (orden de los 8 titulares): `hero_pomodoro`, `clock_styles`, `fullscreen_clock`, `timer_stopwatch`, `intervals`, `kitchen_timers`, `breathe_music`, `world_sleep`.
- Formato de la descripción larga: texto plano con `<b>...</b>` (Play admite HTML limitado) y viñetas "•". Sin emoji.

## 2. Conteo de caracteres

| Locale | Título (30) | Corta (80) | Larga (4000) | Novedades (500) |
|---|---|---|---|---|
| en-US | 29 | 77 | 2595 | 399 |
| es-419 | 29 | 79 | 3060 | 449 |
| es-ES | 29 | 79 | 3071 | 447 |
| de-DE | 27 | 74 | 2922 | 437 |
| fr-FR | 24 | 80 | 3268 | 452 |
| pt-BR | 30 | 80 | 2910 | 429 |
| hi-IN | 27 | 75 | 2674 | 352 |
| ja-JP | 20 | 40 | 1416 | 205 |
| ko-KR | 17 | 44 | 1491 | 227 |
| zh-CN | 15 | 32 | 1051 | 155 |

Titulares de capturas: máximo 28 caracteres, verificado por el script.

## 3. Checklist de Play Console

**Ficha principal**
- [ ] Nombre de la app, descripción corta y larga por idioma (subir con fastlane o copiar de `listing/`).
- [ ] Icono 512x512 PNG (32 bits, máx. 1 MB), sin esquinas redondeadas ni sombra propia.
- [ ] Gráfico de funciones 1024x500 PNG/JPG (sin alfa); tagline en `feature_graphic_tagline.txt`.
- [ ] Capturas de teléfono: 2 a 8, PNG/JPG, lado corto >= 320 px y largo <= 3840 px, relación máx. 2:1 (16:9 o 9:16 recomendado). Para destacar en Play, mejor 1080x1920.
- [ ] Capturas de tableta de 7" y de 10": hasta 8 cada una, mismos límites (p. ej. 1200x1920 y 1600x2560).
- [ ] Vídeo promocional: URL de YouTube (público o no listado, sin anuncios ni restricción de edad); título/descripción en `video_*.txt`.
- [ ] Categoría: **Productividad** (alternativa: Herramientas). Etiquetas (hasta 5, elegir de la lista de Play): Productividad / Reloj / Temporizador / Gestión del tiempo (los nombres exactos dependen de la lista vigente).
- [ ] Contacto: correo (obligatorio), sitio web (opcional), teléfono (opcional).
- [ ] Política de privacidad: https://sazardev.github.io/enfo/#privacy (PLACEHOLDER: publicar esa página antes de enviar; debe declarar AdMob).

**Contenido de la app**
- [ ] Clasificación de contenido (IARC): cuestionario sin violencia, sexo, drogas, juego de azar ni chat/contenido de usuarios. Se espera "Para todos" (PEGI 3 / ESRB Everyone), pero el resultado lo calcula el cuestionario; responder que la app contiene anuncios no cambia la edad.
- [ ] Anuncios: marcar **"Contiene anuncios"** (AdMob, ver abajo). No afirmar "sin anuncios" en la ficha.
- [ ] Público objetivo: 13+ o "todas las edades" según decisión; si se incluye a menores de 13, aplica la política Families y AdMob debe configurarse como contenido para niños. Recomendado: NO dirigirse a niños.
- [ ] Declaración de permisos sensibles (ver Incertidumbres): `USE_FULL_SCREEN_INTENT` (alarma a pantalla completa) y `USE_EXACT_ALARM` (solo si la app es realmente de reloj/alarma, que lo es; Play pide justificarlo).
- [ ] Declaración de ID de publicidad (la app usa google_mobile_ads): marcar que sí, uso "Publicidad".
- [ ] Seguridad de datos: ver sección 4.
- [ ] Apps de noticias / COVID / gobierno / financieras / salud: No aplica. Nota: "Respirar" y "Sueño" no son apps de salud reguladas, pero evitar frases médicas en la ficha (no las hay).

## 4. Formulario de Seguridad de los datos (derivado del código; con incertidumbre)

Lo que se comprobó en el código:
- No hay cuentas, login ni backend propio. No hay cliente HTTP en `lib/` (búsqueda de `HttpClient`/`package:http`): la app no envía datos propios a ningún servidor.
- Todo lo que guarda va en almacenamiento local (`shared_preferences` y archivos de widgets en el propio dispositivo): ajustes, historial de Pomodoros y herramientas, eventos, actividades, temporizadores de cocina, alarmas.
- La app puede borrar el historial, restablecer ajustes o borrar todo (pantalla "Datos"); no hay envío, por lo que "solicitar eliminación" se resuelve desinstalando/borrando dentro de la app.
- Sí hay red por: (a) `google_mobile_ads` (AdMob), que se inicializa al arrancar en Android (`MobileAds.instance.initialize()`) y carga un anuncio intersticial que solo se MUESTRA cuando el usuario toca "Ver un anuncio" en Ajustes > Apoyar; (b) `url_launcher` para abrir el enlace del café en el navegador.

Respuestas sugeridas:

| Pregunta | Respuesta sugerida | Certeza |
|---|---|---|
| ¿Recopila o comparte datos del usuario? | Sí, por el SDK de anuncios | Media |
| Tipos de datos | "ID de dispositivo u otros" (ID de publicidad) y datos de diagnóstico/uso que recoja AdMob (dirección IP aproximada, interacciones con anuncios). Ubicación aproximada solo si AdMob la deriva de la IP | Media: los datos exactos los define el SDK de Google, hay que copiar su guía "Data disclosure" para la versión 9.x |
| Finalidad | Publicidad o marketing; análisis; prevención de fraude | Media |
| ¿Compartido con terceros? | Sí (Google AdMob) | Alta |
| ¿Datos cifrados en tránsito? | Sí (SDK de Google) | Media |
| ¿Puede el usuario pedir eliminación? | Los datos propios de la app se borran desde Ajustes > Datos; los del SDK de anuncios no dependen de la app | Media |
| Datos personales/financieros, contactos, fotos, mensajes, audio, salud | No recopila | Alta (no hay código que los use) |
| Ubicación | No la solicita la app (no hay permiso de ubicación); el world clock usa husos horarios de una lista interna | Alta |

No declarar "no recopila datos": el SDK de AdMob sí lo hace.

## 5. Incertidumbres detectadas (revisar antes de publicar)

1. **AdMob APPLICATION_ID en `AndroidManifest.xml` es un valor de ejemplo** (`ca-app-pub-1234567890123456~9876543210`). Con un ID inválido el SDK puede fallar/crashear al iniciar. Sustituir por el real antes de la build de producción. El ID de unidad va en `lib/secret.dart` (local).
2. **Permisos**: el manifiesto principal no declara INTERNET; lo añade la fusión de manifiestos del SDK de anuncios (no verificado sin compilar). `USE_FULL_SCREEN_INTENT` y `USE_EXACT_ALARM` requieren formulario de declaración en Play; el segundo se concede a apps de reloj/alarma, pero hay revisión.
3. **Alarmas con la app cerrada**: el código programa notificaciones (`alarmClock`, 14 días); no se ha probado en dispositivo. La ficha lo dice con cautela: no promete sonar "siempre". (La ficha actual no afirma nada explícito sobre esto; solo "suena a pantalla completa".)
4. **Audio (Ambiente/Música)** solo se compiló para Linux; no verificado en Android. La ficha describe las funciones, no la calidad. Música: 14 canciones (10 CC0 y 4 CC BY, créditos en Ajustes).
5. **Wear OS / Android TV**: el manifiesto los declara opcionales, pero no hay APK de reloj ni banner de TV. La ficha NO menciona TV ni Wear.
6. **Nombres de los 16 modos por idioma** salen de mi traducción natural, no de los ARB de la app: algunos difieren ligeramente de los textos dentro de la app (p. ej. "Turnos", "Actividades"). Conviene alinearlos con `lib/l10n/app_<lang>.arb` en revisión nativa.
7. Los "estilos" con nombre (pizza, lámpara de lava, frasco de galletas, ola de dígitos) corresponden a combos/estilos existentes (`pizzaNight`, `lava`, `cookieJar`, `waveText`), pero no se renderizó cada uno; las capturas deben confirmarlo.
8. "Sin cuenta ni registro" se dedujo por ausencia de código de auth; "solo verás anuncios si eliges verlos" refleja que el intersticial solo se muestra desde Ajustes > Apoyar, pero el SDK se inicializa siempre.
9. Traducciones hi/ja/ko/zh/de/fr/pt: tono de marketing natural pero sin revisión de nativos.

## 6. Requisitos de recursos gráficos

| Recurso | Especificación |
|---|---|
| Icono | 512x512 PNG, 32 bits, <= 1 MB |
| Gráfico de funciones | 1024x500 PNG o JPG, sin transparencia; texto legible en tamaño pequeño; tagline por idioma |
| Capturas teléfono | 2 a 8; 9:16 (p. ej. 1080x1920) o 16:9; PNG/JPG <= 8 MB |
| Tableta 7" y 10" | hasta 8 cada una; p. ej. 1200x1920 y 1600x2560 |
| Vídeo | YouTube, 30 s a 2 min; título/descripción en `video_*.txt` |

## 7. Plan de lanzamiento y marketing

### Secuencia
1. Publicar página de privacidad y corregir el App ID de AdMob (sección 5).
2. Prueba interna/cerrada con 12+ testers durante 14 días si la cuenta es personal nueva (requisito de Play para cuentas personales; verificar vigencia).
3. Subir ficha en los 9 idiomas (fastlane supply o consola) y el gráfico/capturas del compositor con `headlines.json`.
4. Lanzamiento escalonado (10 %, 50 %, 100 %) y revisar ANR/crashes.
5. Día de lanzamiento: Product Hunt + Reddit + X + LinkedIn (abajo). Responder comentarios las primeras 24 h.
6. Semana 2: pedir reseñas dentro de la comunidad, publicar changelog corto, actualizar según feedback.

### Palabras clave ASO por idioma
| Idioma | Palabras clave (ASO) |
|---|---|
| en-US | pomodoro timer, focus timer, clock widget, world clock, stopwatch, alarm clock, interval timer, HIIT timer, tabata, kitchen timer, breathing exercise, sleep cycle calculator, desk clock, nightstand clock, lo-fi focus music |
| es-419 / es-ES | temporizador pomodoro, reloj, cronómetro, alarma, hora mundial, temporizador de cocina, temporizador HIIT, tabata, respiración guiada, calculadora de sueño, reloj de escritorio, widget de reloj, música lo-fi para concentrarse |
| de-DE | Pomodoro Timer, Fokus Timer, Uhr Widget, Weltzeituhr, Stoppuhr, Wecker, Intervalltimer, HIIT Timer, Tabata, Küchentimer, Atemübung, Schlafzyklus Rechner, Schreibtischuhr, Nachttischuhr, Lo-Fi Musik zum Lernen |
| fr-FR | minuteur pomodoro, minuteur concentration, horloge, widget horloge, heure mondiale, chronomètre, réveil, minuteur HIIT, tabata, minuteur cuisine, cohérence cardiaque, calculateur cycles de sommeil, horloge de bureau, musique lo-fi |
| pt-BR | timer pomodoro, relógio, widget de relógio, hora mundial, cronômetro, despertador, alarme, timer HIIT, tabata, timer de cozinha, respiração guiada, calculadora de sono, relógio de mesa, música lo-fi para focar |
| hi-IN | पोमोडोरो टाइमर, टाइमर, घड़ी, अलार्म, स्टॉपवॉच, वर्ल्ड क्लॉक, घड़ी विजेट, फ़ोकस टाइमर, HIIT टाइमर, नींद कैलकुलेटर, लो-फ़ाई म्यूज़िक |
| ja-JP | ポモドーロ タイマー, 集中 タイマー, 時計 ウィジェット, 世界時計, ストップウォッチ, アラーム, インターバルタイマー, タバタ, キッチンタイマー, 呼吸, 睡眠 サイクル, デスク時計, ローファイ |
| ko-KR | 뽀모도로 타이머, 집중 타이머, 시계 위젯, 세계 시계, 스톱워치, 알람, 인터벌 타이머, 타바타, 주방 타이머, 호흡 운동, 수면 주기, 데스크 시계, 로파이 |
| zh-CN | 番茄钟, 专注计时器, 时钟小组件, 世界时钟, 秒表, 闹钟, 间歇训练计时器, Tabata, 厨房计时器, 呼吸训练, 睡眠周期, 桌面时钟, Lo-fi 音乐 |

Consejo: repetir de forma natural (sin relleno) "pomodoro", "timer/temporizador", "reloj" y "widget" en título, descripción corta y primeras líneas de la larga; ya está aplicado.

### Publicaciones cortas (inglés)
**X**: Enfo 1.1.0 is out. A clock and timer toolbox for Android: Pomodoro, timers, alarms, world clock plus 10 more tools (intervals, breathe, kitchen timers, sleep planner, lo-fi music). 63 flat clock styles, 7 widgets, 9 languages. https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**LinkedIn**: I turned my minimalist Pomodoro app into a clock and timer toolbox. Enfo now has 16 tools you can switch on one by one, 63 clock styles and 7 home-screen widgets, in 9 languages. Built with Flutter. Feedback welcome: https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**Reddit r/FlutterDev**: [Show] Enfo, a Flutter clock/timer toolbox (Android, Windows, Linux). 63 custom-painted clock styles, off-screen rendering of those styles to PNG for Android widgets, timestamp-driven timers, 9 languages via gen-l10n. Happy to answer architecture questions. Play: https://play.google.com/store/apps/details?id=com.sazarcode.enfo  Source: https://github.com/sazardev/enfo

**Reddit r/productivity**: I built a calm Pomodoro + timers app with 16 small tools (intervals, breathing, kitchen timers, sleep-cycle planner, lo-fi songs). You turn on only what you need. It has ads only if you choose to watch one. Feedback welcome: https://play.google.com/store/apps/details?id=com.sazarcode.enfo

### Publicaciones cortas (español)
**X**: Ya está Enfo 1.1.0: una caja de herramientas de relojes y temporizadores para Android. Pomodoro, alarmas, hora mundial y 10 herramientas más (intervalos, respiración, cocina, sueño, música lo-fi). 63 estilos de reloj, 7 widgets, 9 idiomas. https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**LinkedIn**: Convertí mi app Pomodoro minimalista en una caja de herramientas de relojes y temporizadores. Enfo tiene 16 herramientas que se activan una a una, 63 estilos de reloj y 7 widgets, en 9 idiomas. Hecha con Flutter. Comentarios bienvenidos: https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**Reddit (r/productivity, r/mexico u otros afines)**: Hice una app tranquila de Pomodoro y temporizadores con 16 herramientas pequeñas (intervalos, respiración, cocina, planificador de sueño, lo-fi). Activas solo lo que necesitas. Solo hay anuncios si eliges verlos. https://play.google.com/store/apps/details?id=com.sazarcode.enfo

### Product Hunt
- Tagline (<= 60): "Every clock you need, in one calm app" (37).
- Descripción: Enfo is a clock and timer toolbox for Android. Start with Pomodoro, timer, stopwatch, alarm and world clock, then switch on Intervals, Breathe, Kitchen, Sleep planner, Ambient sounds and lo-fi Music. 63 flat clock styles, 60 style/color combos, 7 home-screen widgets, full-screen desk clock, 9 languages. No account needed; your data stays on your device.
- Primer comentario: contar la historia (de Pomodoro minimalista a 16 herramientas), pedir feedback sobre qué herramienta falta.

### Nota de prensa (blurb)
Enfo, la app que empezó como un simple temporizador Pomodoro, llega a la versión 1.1.0 convertida en una caja de herramientas de relojes y temporizadores para Android. Suma nueve herramientas (eventos, intervalos HIIT y Tabata, respiración guiada, seguimiento de actividades, temporizadores de cocina, planificador de sueño por ciclos de 90 minutos, reloj de turnos, recordatorios de descanso y sonidos ambientales), un modo de música con 14 canciones lo-fi y un planificador de reuniones para la hora mundial. Incluye 63 estilos de reloj, siete widgets, tema claro u oscuro y nueve idiomas. Disponible en Google Play: https://play.google.com/store/apps/details?id=com.sazarcode.enfo
