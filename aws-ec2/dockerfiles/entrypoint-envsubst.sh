#!/bin/sh
set -e

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

target="/etc/nginx/conf.d/default.conf"
echo "[render] Escrevendo Nginx config -> $target"
cat > "$target" <<EOF
upstream backend {
${UPSTREAM_SERVERS}
}

server {
    listen 8080;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 120s;
        proxy_connect_timeout 10s;
        proxy_send_timeout 120s;
    }
}
EOF

exit 0


