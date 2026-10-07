# Checklist de ejecución (campañas + experimentos)

Marcar en orden. Los detalles de cada paso están en `store/campaign/README.md`
y `store/campaign/experiments.md`.

## A. Semana 0 — preparación (coste $0)

- [ ] `python3 tools/check_campaign.py` sin errores.
- [ ] Subir `store/video/enfo_promo_landscape.mp4` a YouTube (público o no
      listado, sin restricción de edad, monetización desactivada).
- [ ] Pegar la URL del vídeo en Play Console → Ficha principal → Vídeo.
- [ ] Confirmar "Marketing externo" marcado (Configuración de la tienda).
- [ ] Play Console: marcar **"No contiene anuncios"** y simplificar Seguridad
      de datos (la app no recopila nada).
- [ ] Crear la cuenta de comerciante y los 5 productos de donación
      (`enfo_donate_1/3/5/10/25`) en Play Console (ver `store/fastlane/README.md`).
- [ ] Revisar la ficha en los 9 idiomas (o subirla con `store/fastlane/`).
- [ ] Crear la cuenta de Google Ads y vincularla con Play Console.

## B. Semanas 1-4 — campañas de Google App

- [ ] Campaña 1 (español, instalaciones): textos de
      `store/campaign/google_app/es-419/`, USD 10-15/día, ubicaciones MX, CO,
      CL, AR, PE, ES, "Maximizar instalaciones" sin CPI objetivo.
- [ ] Campaña 2 (portugués): textos de `pt-BR/`, USD 10-15/día, ubicación BR.
- [ ] Día 14: revisar CPI y retención a 1 día en Play Console → Adquisición
      de usuarios. Escalar solo si ambos son buenos.
- [ ] Si va bien: campañas 3 y 4 (de-DE, fr-FR) con el mismo presupuesto.
- [ ] Revisar el informe de assets de Google Ads y sustituir el peor titular
      o descripción por una variante nueva (validarla antes).
- [ ] Fijar CPI objetivo tras 2 semanas con datos reales.

## C. En paralelo — experimentos de ficha (gratis)

- [ ] Experimento 1: icono (variante de fondo lima). Mínimo 7 días.
- [ ] Aplicar ganador solo con ≥90% de confianza.
- [ ] Experimento 2: primera captura (empezar por `02_styles`).
- [ ] Experimento 3: descripción corta en el idioma con más tráfico
      (`store/campaign/experiments/short_description/<locale>.txt`).
- [ ] Experimento 4: gráfico de funciones.
- [ ] Registrar cada resultado en la tabla de `experiments.md`.

## D. Orgánico (coste $0, hacer el día del lanzamiento y la semana 2)

- [ ] Publicar en Product Hunt (tagline y descripción en `store/listing/README.md`).
- [ ] Publicar en X y LinkedIn (textos listos en el listing README).
- [ ] Publicar en r/FlutterDev y r/productivity (leer las reglas de cada sub).
- [ ] Responder comentarios durante las primeras 24 h.
- [ ] Semana 2: pedir reseñas en la comunidad y publicar el changelog.

## E. Medición semanal (15 min)

- [ ] Play Console → Adquisición de usuarios: orgánico vs pago.
- [ ] Play Console → Estadísticas: retención, instalaciones, calificación.
- [ ] Google Ads: CPI y CTR por asset.
- [ ] Anotar una decisión por semana (escalar, pausar o cambiar creatividad).
