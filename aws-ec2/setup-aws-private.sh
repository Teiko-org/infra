#!/usr/bin/env bash
set -euo pipefail

echo "[private] Atualizando pacotes e instalando Docker..."
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

echo "[private] Preparando diretório /opt/teiko..."
sudo mkdir -p /opt/teiko
sudo chown -R "$USER":"$USER" /opt/teiko
cd /opt/teiko

[[ -d infra ]] || git clone https://github.com/Teiko-org/infra.git infra

# Função para clonar repositório privado com token (opcional)
clone_repo() {
  local url_noauth="$1" target_dir="$2"
  if [[ -n "${GIT_TOKEN:-${GITHUB_TOKEN:-}}" && -n "${GIT_USER:-}" ]]; then
    local token="${GIT_TOKEN:-${GITHUB_TOKEN}}"
    local url_auth="https://${GIT_USER}:${token}@${url_noauth#https://}"
    git clone --depth 1 "$url_auth" "$target_dir"
  else
    git clone --depth 1 "$url_noauth" "$target_dir"
  fi
}

mkdir -p backend
if [[ ! -d backend/.git ]]; then
  git clone --depth 1 https://github.com/Teiko-org/backend.git backend || true
fi

if [[ ! -d backend/carambolos-api ]]; then
  clone_repo "https://github.com/Teiko-org/carambolos-api.git" "backend/carambolos-api" || {
    echo "[private] Aviso: não foi possível obter 'carambolos-api'. Se o repo for privado, exporte GIT_USER e GIT_TOKEN e rode novamente:" >&2
    echo "         GIT_USER=seu_usuario GIT_TOKEN=seu_token sudo -E bash setup-aws-private.sh" >&2
    exit 1
  }
fi

# .env do backend (preenchido com defaults seguros)
[[ -f infra/aws-ec2/.env.backend ]] || cat > infra/aws-ec2/.env.backend <<'ENVB'
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=teiko
DB_USERNAME=teiko
DB_PASSWORD=teiko123
DB_URL=jdbc:mysql://mysql:3306/teiko?createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=America/Sao_Paulo

JWT_VALIDITY=3600000
JWT_SECRET=CHANGE_ME_32_CHARS_MIN

RABBITMQ_USERNAME=teiko
RABBITMQ_PASSWORD=teiko123
RABBITMQ_CONCURRENCY=2
RABBITMQ_MAX_CONCURRENCY=4
RABBITMQ_PREFETCH=10

AZURE_STORAGE_CONNECTION_STRING=
AZURE_STORAGE_CONTAINER_NAME=
ENVB

echo "[private] Build e subida do backend (subindo em etapas)..."
docker compose -f infra/aws-ec2/docker-compose.backend.yml build

# Sobe apenas MySQL e RabbitMQ primeiro
docker compose -f infra/aws-ec2/docker-compose.backend.yml --env-file infra/aws-ec2/.env.backend up -d mysql rabbitmq

# Aguarda healthchecks
echo "[private] Aguardando MySQL e RabbitMQ ficarem healthy..."
for i in {1..60}; do
  MYSQL_H=$(docker inspect -f '{{.State.Health.Status}}' teiko-mysql 2>/dev/null || echo starting)
  RABBIT_H=$(docker inspect -f '{{.State.Health.Status}}' teiko-rabbitmq 2>/dev/null || echo starting)
  if [[ "$MYSQL_H" == "healthy" && "$RABBIT_H" == "healthy" ]]; then
    break
  fi
  sleep 2
done

# Sobe API e aguarda ficar UP
docker compose -f infra/aws-ec2/docker-compose.backend.yml --env-file infra/aws-ec2/.env.backend up -d api
echo "[private] Aguardando API responder health..."
for i in {1..60}; do
  if docker exec teiko-backend wget -qO- http://localhost:8080/actuator/health | grep -q 'UP'; then
    break
  fi
  sleep 2
done

# Sobe o worker por último
docker compose -f infra/aws-ec2/docker-compose.backend.yml --env-file infra/aws-ec2/.env.backend up -d worker

echo "[private] Concluído. Reinicie a sessão para aplicar grupo docker se necessário."


