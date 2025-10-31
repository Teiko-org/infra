#!/bin/sh
set -e

TEMPLATE_DIR="/etc/nginx/templates"

# Exigir API_UPSTREAMS e gerar config com upstream (compatível POSIX sh)
if [ -z "${API_UPSTREAMS:-}" ]; then
  echo "[nginx][erro] API_UPSTREAMS não definido. Ex.: API_UPSTREAMS=10.0.2.203:8080,10.0.3.46:8080"
  exit 1
fi

echo "[nginx] Usando API_UPSTREAMS=$API_UPSTREAMS"

list=$(echo "$API_UPSTREAMS" | tr ',' ' ')
UPSTREAM_SERVERS=""
for item in $list; do
  item_trim=$(echo "$item" | xargs)
  [ -z "$item_trim" ] && continue
  UPSTREAM_SERVERS="${UPSTREAM_SERVERS}$(printf '    server %s;\n' "$item_trim")"
done
export UPSTREAM_SERVERS

target="/etc/nginx/conf.d/default.conf"
echo "[envsubst] Renderizando upstream template -> $target"
envsubst '$(UPSTREAM_SERVERS)' < "$TEMPLATE_DIR/upstream.conf.template" > "$target"

exit 0


