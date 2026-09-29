# Capturas de pantalla y gráficos de Google Play

Todo este directorio (y `store/graphics/`) se genera con un solo script determinista:

```bash
python3 tools/compose_store_assets.py              # todo (10 idiomas, ~3 min)
python3 tools/compose_store_assets.py --locales en-US,es-419   # solo algunos idiomas
python3 tools/compose_store_assets.py --sheets /tmp/sheets     # ademas, hojas de contacto para revisar
```

El script valida al final: tamano exacto en pixeles, modo RGB (sin alfa), peso < 8 MB, y que
el texto no se desborda (el titular se ajusta y se parte en lineas automaticamente; el
contraste titular/fondo se fuerza a WCAG >= 4.5). Requiere Pillow con raqm (para hindi) y las
fuentes Noto CJK / Noto Sans Devanagari del sistema para ja-JP, ko-KR, zh-CN y hi-IN
(Geist Mono, incluida en `assets/fonts/`, no cubre esos alfabetos).

## De donde salen las imagenes base (raws)

Las capturas crudas de la app real se renderizan en `flutter test` y NO se editan a mano:

```bash
TZ=America/New_York flutter test tool/store/shots_test.dart --update-goldens
```

Salen en `store/raw/<dispositivo>/<orientacion>/<NN>_<escena>_<tema>_<idioma>.png`
(`store/raw/manifest.json` describe escenas, tema y color de acento). Si se regeneran los raws,
basta con volver a ejecutar `python3 tools/compose_store_assets.py`.

Solo existen raws de UI en ingles y espanol. Para los demas idiomas (de-DE, fr-FR, pt-BR,
hi-IN, ja-JP, ko-KR, zh-CN) se usa la UI en ingles con el titular localizado; es-ES usa la UI
en espanol. Los textos dentro del telefono no estan traducidos en esos idiomas.

## Estructura

```
store/screenshots/<locale>/<dispositivo>-<orientacion>/NN_<slug>.png
```

Locales: en-US, es-419, es-ES, de-DE, fr-FR, pt-BR, hi-IN, ja-JP, ko-KR, zh-CN.
8 capturas por carpeta (Play acepta de 2 a 8), 60 carpetas, 480 PNG en total.

| Carpeta | Tamano | Ranura en Play Console |
|---|---|---|
| `phone-portrait` | 1080x1920 | Capturas de telefono |
| `phone-landscape` | 1920x1080 | Capturas de telefono (horizontal, opcional) |
| `tablet7-portrait` | 1200x1920 | Capturas de tableta de 7 pulgadas |
| `tablet7-landscape` | 1920x1200 | Capturas de tableta de 7 pulgadas (horizontal) |
| `tablet10-portrait` | 1600x2560 | Capturas de tableta de 10 pulgadas |
| `tablet10-landscape` | 2560x1600 | Capturas de tableta de 10 pulgadas (horizontal) |

Orden y correspondencia entre titular del listing (`store/listing/headlines_by_scene.json`) y
escena cruda:

| NN_slug | Titular (id en el listing) | Raw usado |
|---|---|---|
| 01_focus | hero_pomodoro | 01_hero (oscuro) |
| 02_styles | clock_styles | 02_styles (claro) |
| 03_desk_clock | fullscreen_clock | 03_clock_night (oscuro) |
| 04_timers | timer_stopwatch | 04_timer (claro) |
| 05_intervals | intervals | 08_intervals (oscuro) |
| 06_kitchen | kitchen_timers | 09_kitchen (claro) |
| 07_breathe_music | breathe_music | 11_music (oscuro) |
| 08_world_sleep | world_sleep | 19_world_planner (claro) |

Los fondos alternan oscuro/claro/oscuro... por escena y usan el acento de cada escena.

## Graficos (`store/graphics/`)

| Archivo | Tamano | Uso |
|---|---|---|
| `feature_graphic_<locale>.png` | 1024x500 | Grafico de funciones (uno por idioma, con `feature_graphic_tagline.txt`) |
| `icon_512.png` | 512x512 | Icono de la app en Play. Redibujado en vectorial plano a partir del launcher (el original solo tiene 192 px) |
| `og_1200x630.png` | 1200x630 | Tarjeta Open Graph / redes |
| `montage_phone.png` | 2724x605 | Las 8 capturas de telefono (en-US) en fila, para README/redes |

## Diseno

Estrictamente plano: campos de color tonales derivados del acento de cada escena (claro o
oscuro segun el tema de la captura), titular Geist Mono Bold, insignia "ENFO", circulo tonal
de fondo, dispositivo redondeado con bisel plano fino. Sin degradados, sombras ni bordes.
El tamano del titular es el mismo dentro de cada conjunto de 8 capturas.
