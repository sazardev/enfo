#!/usr/bin/env bash
# One-time Google Cloud setup for the Play Developer API (service account).
#
#   1. gcloud auth login
#   2. bash tools/setup_play_access.sh
#   3. Invite the printed service account in Play Console (Users and permissions)
#   4. python3 tools/create_play_products.py
set -euo pipefail

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
  echo "No hay sesión de gcloud. Ejecuta primero:"
  echo "  gcloud auth login"
  exit 1
fi

PROJECT="${PLAY_PROJECT:-}"
if [ -z "$PROJECT" ]; then
  PROJECT=$(gcloud projects list --filter="name='Enfo Play'" --format="value(projectId)" 2>/dev/null | head -n1 || true)
fi
if [ -z "$PROJECT" ]; then
  for _ in 1 2 3; do
    ID="enfo-play-$RANDOM$RANDOM"
    if gcloud projects create "$ID" --name="Enfo Play" >/dev/null 2>&1; then
      PROJECT="$ID"
      break
    fi
  done
fi
[ -n "$PROJECT" ] || { echo "No se pudo crear el proyecto de Google Cloud."; exit 1; }
echo "Proyecto: $PROJECT"
gcloud config set project "$PROJECT" >/dev/null
gcloud services enable androidpublisher.googleapis.com --project="$PROJECT"

SA="enfo-play"
EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe "$EMAIL" --project="$PROJECT" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA" \
    --display-name "Enfo Play Publisher" --project="$PROJECT"
fi

KEY="$HOME/.config/enfo/play-service-account.json"
mkdir -p "$(dirname "$KEY")"
if [ ! -f "$KEY" ]; then
  gcloud iam service-accounts keys create "$KEY" \
    --iam-account="$EMAIL" --project="$PROJECT"
  chmod 600 "$KEY"
fi

cat <<EOF

Listo.
  Cuenta de servicio: $EMAIL
  Clave JSON:         $KEY

Único paso manual en el navegador:
  1. Play Console -> Usuarios y permisos -> Invitar nuevos usuarios
  2. Pega el correo de la cuenta de servicio
  3. En "Presencia en Play Store" marca "Administrar presencia en Play Store"
     (o dale Admin), con acceso a la app com.sazarcode.enfo
  4. Invitar

Después:
  python3 tools/create_play_products.py
EOF
