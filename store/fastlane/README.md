# Fastlane: subir la ficha y los assets a Play

Todo se ejecuta desde `store/`. Los textos viven en
`store/fastlane/metadata/android/<locale>/` y las imágenes se generan desde
`store/graphics/` y `store/screenshots/` con `tools/sync_fastlane_images.py`
(la lane `images` lo ejecuta sola).

## 1. Instalar fastlane (una vez)

Requiere Ruby (ya está) y las gemas:

```
cd store
bundle install
```

Si `bundle` no está instalado: `gem install bundler --user-install`.

## 2. Cuenta de servicio de Play (una vez)

1. En Google Cloud Console: crear proyecto, habilitar **Google Play Android
   Developer API** y crear una cuenta de servicio.
2. Descargar la clave JSON.
3. En Play Console → Usuarios y permisos: invitar el correo de la cuenta de
   servicio con permisos de **administrador** (o al menos releases + ficha).
4. Guardar la clave en `~/.config/enfo/play-service-account.json` o exportar
   `PLAY_JSON_KEY=/ruta/clave.json`.

## 3. Comandos

| Comando (desde `store/`) | Qué hace |
|---|---|
| `bundle exec fastlane android validate` | Valida la ficha sin subir nada |
| `bundle exec fastlane android listing` | Sube títulos, descripciones y novedades |
| `bundle exec fastlane android images` | Sincroniza y sube icono, gráfico y capturas |
| `bundle exec fastlane android deploy` | Sube el AAB de release + ficha completa |

Antes de `deploy`: `flutter build appbundle --release`.

## 4. Donaciones (Google Play Billing)

La app ofrece donaciones consumibles (`enfo_donate_1`, `_3`, `_5`, `_10`,
`_25`) desde `lib/donate_page.dart`. Flujo con la API nueva
(`monetization.onetimeproducts`):

1. **La app debe declarar BILLING**: compilar y subir un AAB con
   `in_app_purchase` (`flutter build appbundle --release` y luego
   `python3 tools/upload_play_bundle.py`). Sin eso Play Console responde
   "To add one-time products, you need to add the BILLING permission".
2. **Credenciales** (una vez): `gcloud auth application-default login
   --scopes=https://www.googleapis.com/auth/androidpublisher` y un proyecto
   con la API habilitada (`gcloud config set project ...`). Alternativa:
   cuenta de servicio (`bash tools/setup_play_access.sh`) invitada en Play
   Console.
3. **Crear y activar los 5 productos**:
   `python3 tools/create_play_products.py`. Convierte 0.99/2.99/4.99/9.99/24.99
   USD a todas las regiones, publica título/descripción en 10 idiomas y activa
   la opción de compra `buy`. Opciones: `--list`, `--update`, `--dry-run`,
   `--currency`, `--amounts`.
4. Probar con una licencia de prueba (testers del track interno) antes de
   publicar.

## 5. Pendientes y notas

- **Novedades (what's new)**: `changelogs/10.txt` ya está creado (1.4.0);
  supply las sube por versionCode.
- **Capturas**: solo hay de `en-US` y `es-419`; el resto de idiomas usan las
  de la ficha por defecto (Play no exige capturas por idioma).
- **Vídeo promocional**: supply no lo sube; se pega la URL de YouTube a mano
  en Play Console → Ficha principal.
- **Marketing externo**: se activa a mano en Play Console → Configuración de
  la tienda.
- Los textos de la ficha ya están actualizados a 1.4.0 (sin anuncios, 9
  widgets y donaciones).

## 6. Estado de la cuenta (Play Console, 2026-10-07)

- Anuncios: declaración en **"No contiene anuncios"** (en revisión).
- Seguridad de datos: **No recopila datos** (verificado, sin cambios).
- Foreground services: declaración de `mediaPlayback` con vídeo demo
  (no listado): https://www.youtube.com/watch?v=VQme5O-Vw8
- Producción: 1.4.0 (versionCode 10) enviada a revisión con rollout completo.
- Track interno: mismo 1.4.0, útil para probar las donaciones con licencias de
  prueba.
- Productos: `enfo_donate_1/3/5/10/25` activos, precios en 174 regiones.
