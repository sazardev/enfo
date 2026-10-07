# Kit de ficha de Google Play: Enfo 1.4.0 (build 10)

Todo el texto de esta carpeta sale del repo (MEMORY.md, CHANGELOG.md, pubspec.yaml, `lib/`, `AndroidManifest.xml`). Nada se ha verificado en un dispositivo real. Validar límites: `python3 tools/check_listing.py`.

## 1. Archivos

- `store/fastlane/metadata/android/<locale>/{title,short_description,full_description}.txt` y `changelogs/10.txt` (versionCode 10): layout compatible con `fastlane supply`.
- `store/listing/<locale>/`: los mismos textos (`title`, `short_description`, `full_description`, `whats_new`) más `feature_graphic_tagline.txt`, `video_title.txt`, `video_description.txt`.
- `store/listing/headlines.json`: `{"_scenes": [8 ids], "<locale>": [8 titulares]}` para el compositor de capturas. `headlines_by_scene.json`: `{locale: {scene_id: titular}}`.
- Locales: en-US, es-419, es-ES (mismo texto que es-419 con "mesita de noche"; puedes omitirlo y dejar que es-419 cubra España), de-DE, fr-FR, pt-BR, hi-IN, ja-JP, ko-KR, zh-CN.
- Escenas (orden de los 8 titulares): `hero_pomodoro`, `clock_styles`, `fullscreen_clock`, `timer_stopwatch`, `intervals`, `kitchen_timers`, `breathe_music`, `world_sleep`.
- Formato de la descripción larga: texto plano con `<b>...</b>` (Play admite HTML limitado) y viñetas "•". Sin emoji.

## 2. Conteo de caracteres

| Locale | Título (30) | Corta (80) | Larga (4000) | Novedades (500) |
|---|---|---|---|---|
| en-US | 29 | 77 | 2563 | 384 |
| es-419 | 29 | 79 | 3037 | 432 |
| es-ES | 29 | 79 | 3048 | 432 |
| de-DE | 27 | 74 | 2866 | 414 |
| fr-FR | 24 | 80 | 3216 | 444 |
| pt-BR | 30 | 80 | 2876 | 390 |
| hi-IN | 27 | 75 | 2632 | 361 |
| ja-JP | 20 | 40 | 1395 | 171 |
| ko-KR | 17 | 44 | 1466 | 196 |
| zh-CN | 15 | 32 | 1034 | 129 |

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
- [ ] Política de privacidad: https://sazardev.github.io/enfo/#privacy y el PDF `politica_de_privacidad_enfo.pdf` (actualizado: sin anuncios y con las donaciones procesadas por Google Play).

**Contenido de la app**
- [ ] Clasificación de contenido (IARC): cuestionario sin violencia, sexo, drogas, juego de azar ni chat/contenido de usuarios. Se espera "Para todos" (PEGI 3 / ESRB Everyone), pero el resultado lo calcula el cuestionario; la app no contiene anuncios ni contenido sensible.
- [ ] Anuncios: marcar **"No contiene anuncios"**. AdMob se eliminó en 1.3.3 (ver sección 4).
- [ ] Compras dentro de la app: **Sí** (donaciones consumibles `enfo_donate_1/3/5/10/25`). Crear los productos en Play Console → Monetizar con Play → Productos → Productos dentro de la app, tipo consumible; títulos, descripciones y precios por país se configuran allí (ver `store/fastlane/README.md`).
- [ ] Público objetivo: 13+ o "todas las edades" según decisión; si se incluye a menores de 13, aplica la política Families. Recomendado: NO dirigirse a niños.
- [ ] Declaración de permisos sensibles (ver Incertidumbres): `USE_FULL_SCREEN_INTENT` (alarma a pantalla completa) y `USE_EXACT_ALARM` (solo si la app es realmente de reloj/alarma, que lo es; Play pide justificarlo).
- [ ] Declaración de ID de publicidad: no aplica, la app no usa ID de publicidad.
- [ ] Seguridad de datos: ver sección 4.
- [ ] Apps de noticias / COVID / gobierno / financieras / salud: No aplica. Nota: "Respirar" y "Sueño" no son apps de salud reguladas, pero evitar frases médicas en la ficha (no las hay).

## 4. Formulario de Seguridad de los datos (derivado del código)

AdMob se eliminó en 1.3.3: no hay SDK de anuncios ni cliente HTTP en `lib/`.
La app no recopila ni comparte datos.

| Pregunta | Respuesta sugerida | Certeza |
|---|---|---|
| ¿Recopila o comparte datos del usuario? | No | Alta (no hay código de red) |
| Tipos de datos | Ninguno | Alta |
| ¿Datos cifrados en tránsito? | No aplica (no hay transmisión) | Alta |
| ¿Puede el usuario pedir eliminación? | Los datos se borran desde Ajustes > Datos | Alta |
| Ubicación | No la solicita (no hay permiso de ubicación) | Alta |
| Datos personales/financieros, contactos, fotos, mensajes, audio, salud | No recopila | Alta |

Las donaciones se pagan con Google Play Billing; la app no recibe ni almacena
datos de pago, así que la seguridad de datos no cambia.

Verificar en Play Console que "Contiene anuncios" esté en **No**, que la
seguridad de datos no declare el ID de publicidad y que los 5 productos de
donación existan y estén activos.

## 5. Incertidumbres detectadas (revisar antes de publicar)

1. **AdMob eliminado (1.3.3)**: resuelto. Ya no hay SDK de anuncios, `lib/secret.dart` ni ID de publicidad que configurar.
2. **Permisos**: sin SDK de anuncios no debería declararse INTERNET; verificar el manifiesto final. `USE_FULL_SCREEN_INTENT` y `USE_EXACT_ALARM` requieren formulario de declaración en Play; el segundo se concede a apps de reloj/alarma, pero hay revisión.
3. **Alarmas con la app cerrada**: el código programa notificaciones (`alarmClock`, 14 días); no se ha probado en dispositivo. La ficha lo dice con cautela: no promete sonar "siempre". (La ficha actual no afirma nada explícito sobre esto; solo "suena a pantalla completa".)
4. **Audio (Ambiente/Música)** solo se compiló para Linux; no verificado en Android. La ficha describe las funciones, no la calidad. Música: 72 canciones (68 CC0 y 4 CC BY, créditos en Ajustes); las 58 de Open Lo-Fi van mono 32 kHz con cadena lo-fi deliberada.
5. **Wear OS / Android TV**: el manifiesto los declara opcionales, pero no hay APK de reloj ni banner de TV. La ficha NO menciona TV ni Wear.
6. **Nombres de los 16 modos por idioma** salen de mi traducción natural, no de los ARB de la app: algunos difieren ligeramente de los textos dentro de la app (p. ej. "Turnos", "Actividades"). Conviene alinearlos con `lib/l10n/app_<lang>.arb` en revisión nativa.
7. Los "estilos" con nombre (pizza, lámpara de lava, frasco de galletas, ola de dígitos) corresponden a combos/estilos existentes (`pizzaNight`, `lava`, `cookieJar`, `waveText`), pero no se renderizó cada uno; las capturas deben confirmarlo.
8. "Sin cuenta ni registro" y "sin anuncios" se deducen del código: no hay auth ni SDK de anuncios.
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
1. Publicar/actualizar la página de privacidad (ya sin AdMob) y verificar la declaración de anuncios en Play Console.
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
**X**: Enfo 1.3.3 is out, now ad-free. A clock and timer toolbox for Android: Pomodoro, timers, alarms, world clock plus 10 more tools (intervals, breathe, kitchen timers, sleep planner, lo-fi music). 63 flat clock styles, 9 widgets, 9 languages. https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**LinkedIn**: I turned my minimalist Pomodoro app into a clock and timer toolbox. Enfo now has 16 tools you can switch on one by one, 63 clock styles and 9 home-screen widgets, in 9 languages, with no ads. Built with Flutter. Feedback welcome: https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**Reddit r/FlutterDev**: [Show] Enfo, a Flutter clock/timer toolbox (Android, Windows, Linux). 63 custom-painted clock styles, off-screen rendering of those styles to PNG for Android widgets, timestamp-driven timers, 9 languages via gen-l10n. Happy to answer architecture questions. Play: https://play.google.com/store/apps/details?id=com.sazarcode.enfo  Source: https://github.com/sazardev/enfo

**Reddit r/productivity**: I built a calm Pomodoro + timers app with 16 small tools (intervals, breathing, kitchen timers, sleep-cycle planner, lo-fi songs). You turn on only what you need. It has ads only if you choose to watch one. Feedback welcome: https://play.google.com/store/apps/details?id=com.sazarcode.enfo

### Publicaciones cortas (español)
**X**: Ya está Enfo 1.3.3, ahora sin anuncios: una caja de herramientas de relojes y temporizadores para Android. Pomodoro, alarmas, hora mundial y 10 herramientas más (intervalos, respiración, cocina, sueño, música lo-fi). 63 estilos de reloj, 9 widgets, 9 idiomas. https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**LinkedIn**: Convertí mi app Pomodoro minimalista en una caja de herramientas de relojes y temporizadores. Enfo tiene 16 herramientas que se activan una a una, 63 estilos de reloj y 9 widgets, en 9 idiomas y sin anuncios. Hecha con Flutter. Comentarios bienvenidos: https://play.google.com/store/apps/details?id=com.sazarcode.enfo

**Reddit (r/productivity, r/mexico u otros afines)**: Hice una app tranquila de Pomodoro y temporizadores con 16 herramientas pequeñas (intervalos, respiración, cocina, planificador de sueño, lo-fi). Activas solo lo que necesitas. Solo hay anuncios si eliges verlos. https://play.google.com/store/apps/details?id=com.sazarcode.enfo

### Product Hunt
- Tagline (<= 60): "Every clock you need, in one calm app" (37).
- Descripción: Enfo is a clock and timer toolbox for Android. Start with Pomodoro, timer, stopwatch, alarm and world clock, then switch on Intervals, Breathe, Kitchen, Sleep planner, Ambient sounds and lo-fi Music. 63 flat clock styles, 60 style/color combos, 9 home-screen widgets, full-screen desk clock, 9 languages. No ads and no account needed; your data stays on your device.
- Primer comentario: contar la historia (de Pomodoro minimalista a 16 herramientas), pedir feedback sobre qué herramienta falta.

### Kit de campañas y experimentos

Textos para Google App campaigns (5 titulares y 5 descripciones por idioma), plan
de experimentos A/B de la ficha y variantes de descripción corta: `store/campaign/`.
Validar con `python3 tools/check_campaign.py`. Las tarjetas de "Contenido
promocional" de Play Console no están disponibles para apps que no cumplen los
umbrales de crecimiento premium (ver `store/campaign/README.md`, sección 0).

### Nota de prensa (blurb)
Enfo, la app que empezó como un simple temporizador Pomodoro, llega a la versión 1.3.3 convertida en una caja de herramientas de relojes y temporizadores para Android. Suma nueve herramientas (eventos, intervalos HIIT y Tabata, respiración guiada, seguimiento de actividades, temporizadores de cocina, planificador de sueño por ciclos de 90 minutos, reloj de turnos, recordatorios de descanso y sonidos ambientales), un modo de música con 14 canciones lo-fi y un planificador de reuniones para la hora mundial. Incluye 63 estilos de reloj, nueve widgets, tema claro u oscuro, nueve idiomas y ningún anuncio. Disponible en Google Play: https://play.google.com/store/apps/details?id=com.sazarcode.enfo
