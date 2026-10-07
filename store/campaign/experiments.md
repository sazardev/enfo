# Experimentos de ficha (A/B) — Enfo

Herramienta gratuita: Play Console → Crecer usuarios → Experimentos de ficha.

## Reglas

- Se puede tener **un experimento de gráficos** y **uno localizado** a la vez.
- Hasta 3 variantes; empezar con 1 (control vs variante).
- Reparto 50/50. Mínimo **7 días** (cubre una semana completa).
- Aplicar un ganador solo con **≥90% de confianza** y el intervalo sin cruzar cero.
- Cambiar una sola cosa por experimento.
- Métrica: instalaciones de nuevos usuarios (si Play ofrece la variante con
  retención, mejor: evita ganar con creatividades de clickbait).
- Tráfico bajo (<100 visitas/día): esperar 2-4 semanas; "faltan datos" no es un
  resultado y no se declara ganador.

## Orden de pruebas

### 1. Icono (experimento de gráficos)

- Hipótesis: un icono con más contraste mejora el CTR en búsqueda y listas.
- Variante B: invertir fondo (lima) y marca (tinta) con `tools/make_logo.py`
  (`ml.svg(ml.mark(DARK, "#5a5f1c"), rx=112, scale=1.1, bg=LIME)`), 512x512.
- Si el tráfico no da para significancia, saltar a la prueba 2: las capturas
  suelen producir efectos mayores.

### 2. Primera captura (experimento de gráficos)

- Hipótesis: abrir con la rejilla de "63 estilos" explica mejor la app que el
  Pomodoro y sube la conversión.
- Variante B: reordenar las escenas para que `02_styles` sea la primera y
  regenerar con `python3 tools/compose_store_assets.py`.

### 3. Descripción corta (experimento localizado, por idioma)

- Hipótesis: una frase centrada en el beneficio ("una app tranquila para cada
  reloj") convierte mejor que la lista de funciones.
- Variante B: `experiments/short_description/<locale>.txt`.
- Hacerlo por idioma solo donde haya tráfico; si no, aplicar la variante a mano
  y medir con el siguiente experimento.

### 4. Gráfico de funciones (experimento de gráficos)

- Hipótesis: menos elementos y tagline más grande se lee mejor en tamaños
  pequeños.

### 5. Descripción larga (experimento localizado)

- Solo si las anteriores no bastan; abrir con el beneficio y las 3 primeras
  funciones, no con la historia.

## Registro

| # | Experimento | Inicio | Fin | Variante | Confianza | Resultado | Decisión |
|---|---|---|---|---|---|---|---|
| 1 | Icono | | | Fondo lima | | | |
| 2 | Primera captura | | | styles primero | | | |
| 3 | Desc. corta (es) | | | beneficio | | | |
| 3 | Desc. corta (en) | | | beneficio | | | |
| 4 | Gráfico de funciones | | | simple | | | |
| 5 | Desc. larga | | | beneficio primero | | | |
