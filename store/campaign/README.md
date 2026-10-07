# Kit de promoción de Enfo (Google Play + Google Ads)

Complementa a `store/listing/README.md` (ficha, ASO, lanzamiento orgánico) y a
`store/marketing/` (logos, banners, vídeos). Validar los textos:
`python3 tools/check_campaign.py`.

## 0. Aviso: las tarjetas de "Contenido promocional" no están disponibles

Play Console ofrece "Contenido promocional" (tarjetas de eventos, ofertas y
novedades en la ficha y en la portada de Play) a todos los juegos, pero a las
apps solo si cumplen los umbrales de las herramientas de crecimiento premium
(≈1.6 M MAU/día y 1.6 M instalaciones activas, o USD 40 k/mes en anuncios).
Enfo no califica todavía, así que las palancas reales son:

1. Campaña de Google App (Google Ads): pago, autoservicio, abierta a todos.
2. Experimentos de ficha: gratis, A/B testing de icono, capturas y textos.
3. Vídeo de YouTube en la ficha + "Marketing externo" activado.
4. Lanzamiento orgánico (sección 7 de `store/listing/README.md`).

## 1. Archivos

- `google_app/<locale>/headlines.txt`: 5 titulares, ≤30 caracteres (≤15 en ja/ko/zh).
- `google_app/<locale>/descriptions.txt`: 5 descripciones, ≤90 caracteres (≤45 en ja/ko/zh).
- `experiments/short_description/<locale>.txt`: variante B de la descripción corta.
- `experiments.md`: plan de experimentos A/B de la ficha.

Locales: en-US, es-419 (cubre España), de-DE, fr-FR, pt-BR, hi-IN, ja-JP,
ko-KR, zh-CN. Google Ads no traduce: cada campaña usa el idioma de sus textos.

## 2. Campaña de Google App (instalaciones)

### 2.1 Preparación

- Cuenta de Google Ads con facturación, vinculada a Play Console
  (Play Console → Crecer usuarios → Campañas de usuarios; o directo en ads.google.com).
- La app ya está publicada en producción: requisito cumplido.

### 2.2 Crear la campaña

- Objetivo: **Instalaciones de la app**.
- Una campaña por idioma; empezar por español y pt-BR.
- Ubicaciones: MX, CO, CL, AR, PE, ES (español) y BR (portugués); excluir el resto.
- Presupuesto: USD 10-15/día por campaña; no tocar durante 2 semanas.
- Puja: "Maximizar instalaciones" sin CPI objetivo al principio; a las 2 semanas,
  fijar CPI objetivo según el CPI real (referencia: LatAm/BR USD 0.10-0.40;
  US/DE/FR USD 0.80-3.00).
- Redes: dejar todas (Búsqueda, Play, YouTube, Discover, Display).

### 2.3 Assets

- Texto: copiar los 5 titulares y las 5 descripciones de `google_app/<locale>/`.
- Imagen 1.91:1: `store/graphics/og_1200x630.png` (1200x630).
- Imagen 1:1: `store/marketing/banners/enfo_square_1080.png` (1080x1080).
- Imagen 4:5: recorte de `store/screenshots/<locale>/phone-portrait/` (1080x1920).
- Vídeo 16:9: `store/video/enfo_promo_landscape.mp4` (47 s).
- Vídeo 9:16: `store/video/enfo_promo_portrait.mp4` (47 s).
- Vídeo 1:1 (opcional): no hay corte cuadrado de 10-60 s; exportar uno del promo
  horizontal con ffmpeg (`-vf "crop=1080:1080:(iw-1080)/2:0"`).
- Los vídeos deben estar subidos a YouTube antes de usarlos en Google Ads.

### 2.4 Reglas de los textos (las aplica `tools/check_campaign.py`)

- Cada línea debe funcionar sola (Google combina titulares y descripciones).
- Máximo un "!" por línea. Sin emoji. Sin espacios dobles.
- Palabras clave ASO de forma natural (pomodoro, timer, reloj, widget...).
- No prometer nada que la app no haga (ver incertidumbres del listing).

### 2.5 Medición

- Google Ads: instalaciones, CPI y CTR por asset (informe de assets).
- Play Console → Adquisición de usuarios: orgánico vs pago y retención a 1 día.
- Criterio para escalar: CPI bajo el objetivo **y** retención a 1 día similar a
  la orgánica. Si el CPI es bueno pero la retención cae, el anuncio atrae al
  público equivocado.

## 3. Vídeo de YouTube en la ficha

1. Subir `enfo_promo_landscape.mp4` (y/o el vertical) a YouTube.
2. Título y descripción: `store/listing/<locale>/video_title.txt` y `video_description.txt`.
3. Visibilidad pública o no listada; sin restricción de edad; "no hecha para
   niños"; monetización desactivada (la música es CC0, no habrá reclamos).
4. Pegar la URL en Play Console → Ficha principal → Vídeo promocional.

## 4. Marketing externo

Play Console → Crecer usuarios → Presencia en Play Store → Configuración de la
tienda: dejar marcado "Marketing externo" para que Google pueda usar los assets
de la ficha en sus propiedades.

## 5. Experimentos de ficha

Ver `experiments.md`. Resumen: primero icono, luego primera captura, luego
descripción corta, luego gráfico de funciones. Un experimento por tipo a la vez,
mínimo 7 días y 90% de confianza antes de aplicar un ganador.

## 6. Calendario sugerido

| Semana | Acciones |
|---|---|
| 0 | YouTube + URL en la ficha; revisar "Marketing externo"; validar el kit. |
| 1 | Experimento 1 (icono) + campañas es y pt-BR a USD 10/día. |
| 2 | No tocar campañas; revisar informe de assets; experimento 2 (captura). |
| 3 | Evaluar CPI + retención; si va bien, añadir campaña de-DE/fr-FR. |
| 4 | Aplicar ganadores; subir presupuesto en las campañas rentables. |

## 7. Lanzamiento orgánico

X, LinkedIn, Reddit, Product Hunt y nota de prensa ya están redactados en la
sección 7 de `store/listing/README.md`.
