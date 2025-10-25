#!/bin/sh
set -e

TEMPLATE_DIR="/etc/nginx/templates"

if [ -d "$TEMPLATE_DIR" ]; then
  for template in $TEMPLATE_DIR/*.template; do
    target="/etc/nginx/conf.d/$(basename "$template" .template)"
    echo "[envsubst] Renderizando $template -> $target"
    envsubst '$(API_BASE_URL)' < "$template" > "$target"
  done
fi

exit 0


