#!/usr/bin/env bash
set -euo pipefail

echo "[public] Atualizando pacotes e instalando Docker..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release git
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER" || true
sudo systemctl enable docker --now

echo "[public] Preparando diretório /opt/teiko..."
sudo mkdir -p /opt/teiko
sudo chown -R "$USER":"$USER" /opt/teiko
cd /opt/teiko

[[ -d infra ]] || git clone https://github.com/Teiko-org/infra.git infra
if [[ "${FORCE_INFRA_UPDATE:-0}" = "1" ]]; then
  echo "[public] Atualizando repo infra (reset --hard + pull) ..."
  git -C infra reset --hard HEAD || true
  git -C infra pull || true
fi

# Estrutura esperada pelo Dockerfile-frontend: ./frontend/carambolo-doces
if [[ ! -d frontend/.git ]]; then
  echo "[public] Clonando frontend..."
  git clone https://github.com/Teiko-org/frontend.git frontend || {
    echo "[public] Falha ao clonar frontend. Se for privado, configure SSH keys na EC2." >&2
    exit 1
  }
fi
if [[ "${FORCE_FRONT_UPDATE:-0}" = "1" && -d frontend/.git ]]; then
  echo "[public] Atualizando repo frontend (reset --hard + pull) ..."
  git -C frontend reset --hard HEAD || true
  git -C frontend pull || true
fi

# Verifica se carambolo-doces existe dentro do monorepo frontend
if [[ ! -d frontend/carambolo-doces ]]; then
  echo "[public] ERRO: frontend/carambolo-doces não encontrado no repositório clonado." >&2
  exit 1
fi

# Garante que o build do Vite use o proxy /api
echo "[public] Configurando VITE_API_BASE_URL=/api para o build do frontend..."
cat > frontend/carambolo-doces/.env.production <<'ENV'
VITE_API_BASE_URL=/api
ENV

# Força o Axios a usar /api (ou VITE_API_BASE_URL) se o arquivo existir
if [[ -f frontend/carambolo-doces/src/provider/AxiosApi.js ]]; then
  sed -i 's|http://localhost:8080|/api|g' frontend/carambolo-doces/src/provider/AxiosApi.js || true
  sed -i '0,/^const baseURL/s|^const baseURL.*|const baseURL = import.meta?.env?.VITE_API_BASE_URL || "/api";|' \
    frontend/carambolo-doces/src/provider/AxiosApi.js || true
fi

# Ajusta assets estáticos: mover para public/ e corrigir referências literais
if [[ -d frontend/carambolo-doces/src/assets ]]; then
  echo "[public] Movendo assets para public/ e corrigindo referências..."
  mkdir -p frontend/carambolo-doces/public
  cp -a frontend/carambolo-doces/src/assets/* frontend/carambolo-doces/public/
  # Corrige strings literais em JSX/JS/TSX que apontam para src/assets/
  find frontend/carambolo-doces/src -type f \( -name "*.jsx" -o -name "*.js" -o -name "*.tsx" \) -print0 \
    | xargs -0 sed -i 's|src/assets/|/|g'
  # Correção específica de user_icon
  sed -i 's|/src/assets/user_icon.png|/user_icon.png|g' \
    frontend/carambolo-doces/src/components/InputImage/ProfileImageUpload.jsx \
    frontend/carambolo-doces/src/components/InputImage/ProfileImageDisplay.jsx || true
fi

# Opcional: aumentar limite de listeners do Node para evitar warning (cosmético)
if ! grep -q 'events.defaultMaxListeners' infra/aws-ec2/dockerfiles/server.js 2>/dev/null; then
  sed -i '1i const events = require("events"); events.defaultMaxListeners = 50;' infra/aws-ec2/dockerfiles/server.js || true
fi

# .env do frontend (API_UPSTREAMS e imagem)
FRONTEND_IMAGE_DEFAULT="${FRONTEND_IMAGE:-teiko/frontend:latest}"
if [[ ! -f infra/aws-ec2/.env.frontend ]]; then
  cat > infra/aws-ec2/.env.frontend <<ENVF
# Informe os backends (um ou mais):
# Ex.: API_UPSTREAMS=10.0.2.203:8080,10.0.3.46:8080
API_UPSTREAMS=

# Imagem do frontend (CI deve fazer push para este nome/tag)
FRONTEND_IMAGE=${FRONTEND_IMAGE_DEFAULT}
ENVF
else
  # Garante que FRONEND_IMAGE esteja definido no arquivo existente
  if ! grep -q '^FRONTEND_IMAGE=' infra/aws-ec2/.env.frontend; then
    echo "FRONTEND_IMAGE=${FRONTEND_IMAGE_DEFAULT}" >> infra/aws-ec2/.env.frontend
  fi
fi

# Permite passar API_UPSTREAMS via variável de ambiente na execução:
#   API_UPSTREAMS=10.0.2.228:8080 sudo -E bash setup-aws-public.sh
if [[ -n "${API_UPSTREAMS:-}" ]]; then
  sed -i "s/^API_UPSTREAMS=.*/API_UPSTREAMS=${API_UPSTREAMS}/" infra/aws-ec2/.env.frontend
fi

# Garante que o arquivo tenha valor antes de subir
if ! grep -q '^API_UPSTREAMS=' infra/aws-ec2/.env.frontend || grep -q '^API_UPSTREAMS=$' infra/aws-ec2/.env.frontend; then
  echo "[public] ERRO: API_UPSTREAMS vazio em infra/aws-ec2/.env.frontend. Exemplo:" >&2
  echo "        API_UPSTREAMS=10.0.2.228:8080 sudo -E bash setup-aws-public.sh" >&2
  exit 1
fi

echo "[public] Subindo frontend (imagem vinda do registry, sem build local)..."
docker compose -f infra/aws-ec2/docker-compose.frontend.yml --env-file infra/aws-ec2/.env.frontend pull web || true
docker compose -f infra/aws-ec2/docker-compose.frontend.yml --env-file infra/aws-ec2/.env.frontend up -d

echo "[public] Concluído. Reinicie a sessão para aplicar grupo docker se necessário."

# Validação rápida do proxy
echo "[public] Teste rápido:"
set +e
curl -I -m 10 http://localhost/api/actuator/health || true
set -e


