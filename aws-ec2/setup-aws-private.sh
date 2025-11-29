#!/usr/bin/env bash
set -euo pipefail

echo "[private] Atualizando pacotes e instalando Docker..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

# Configuração idempotente do repositório Docker (evita interações com /dev/tty).
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  echo "[private] Instalando chave GPG do Docker (primeira vez)..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
else
  echo "[private] Chave GPG do Docker já existe, mantendo arquivo atual."
fi

if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
  echo "[private] Registrando repositório Docker no APT..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER" || true
sudo systemctl enable docker --now

echo "[private] Preparando diretório /opt/teiko..."
sudo mkdir -p /opt/teiko
sudo chown -R "$USER":"$USER" /opt/teiko
cd /opt/teiko

[[ -d infra ]] || git clone https://github.com/Teiko-org/infra.git infra
if [[ "${FORCE_INFRA_UPDATE:-0}" = "1" ]]; then
  echo "[private] Atualizando repo infra (reset --hard + pull) ..."
  git -C infra reset --hard HEAD || true
  git -C infra pull || true
fi

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

# Definir segredo JWT (aceita override via SHARED_JWT/JWT_SECRET)
JWT_SECRET_HEX=${SHARED_JWT:-${JWT_SECRET:-$(openssl rand -hex 48)}}

# Parâmetros de banco de dados (permitem apontar para uma instância dedicada)
DB_HOST_DEFAULT="${DB_HOST:-mysql}"
DB_NAME_DEFAULT="${DB_NAME:-teiko}"
DB_USERNAME_DEFAULT="${DB_USERNAME:-teiko}"
DB_PASSWORD_DEFAULT="${DB_PASSWORD:-teiko123}"

# Garante o arquivo de env consumido pela API/worker (Dotenv lê dev.env)
DEVENV="/opt/teiko/backend/dev.env"
cat > "$DEVENV" <<ENVDEV
DB_USERNAME=${DB_USERNAME_DEFAULT}
DB_PASSWORD=${DB_PASSWORD_DEFAULT}
DB_URL=jdbc:mysql://${DB_HOST_DEFAULT}:3306/${DB_NAME_DEFAULT}?createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=America/Sao_Paulo

JWT_VALIDITY=3600000
JWT_SECRET=$JWT_SECRET_HEX

AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING:-}
AZURE_STORAGE_CONTAINER_NAME=${AZURE_STORAGE_CONTAINER_NAME:-}

# extra (não usado diretamente agora, mas útil)
CRYPTO_SECRET_B64=$(openssl rand -base64 32)
ENVDEV

# .env do backend para docker compose (valores coerentes)
BACKEND_IMAGE_DEFAULT="${BACKEND_IMAGE:-teiko/backend:latest}"
cat > infra/aws-ec2/.env.backend <<ENVB
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=${DB_NAME_DEFAULT}
DB_USERNAME=${DB_USERNAME_DEFAULT}
DB_PASSWORD=${DB_PASSWORD_DEFAULT}
DB_URL=jdbc:mysql://${DB_HOST_DEFAULT}:3306/${DB_NAME_DEFAULT}?createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=America/Sao_Paulo

JWT_VALIDITY=3600000
JWT_SECRET=$JWT_SECRET_HEX

RABBITMQ_USERNAME=teiko
RABBITMQ_PASSWORD=teiko123
RABBITMQ_CONCURRENCY=2
RABBITMQ_MAX_CONCURRENCY=4
RABBITMQ_PREFETCH=10

AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING:-}
AZURE_STORAGE_CONTAINER_NAME=${AZURE_STORAGE_CONTAINER_NAME:-}

# Imagem do backend (CI deve fazer push para este nome/tag)
BACKEND_IMAGE=${BACKEND_IMAGE_DEFAULT}
ENVB

# Ajustes no docker-compose: remover sobrescritas de JWT e garantir mapeamento para /app/prod.env
sed -i '/JWT_SECRET:/d;/JWT_VALIDITY:/d' infra/aws-ec2/docker-compose.backend.yml
sed -i 's#/app/dev.env#/app/prod.env#g' infra/aws-ec2/docker-compose.backend.yml

echo "[private] Subindo backend (imagens vindas do registry, sem build local)..."

# Garante que a imagem do backend esteja atualizada (se existir em registry público/privado)
docker compose -f infra/aws-ec2/docker-compose.backend.yml --env-file infra/aws-ec2/.env.backend pull api worker || true

# Sobe apenas RabbitMQ primeiro (banco passa a ser remoto)
docker compose -f infra/aws-ec2/docker-compose.backend.yml --env-file infra/aws-ec2/.env.backend up -d rabbitmq

# Aguarda healthcheck do RabbitMQ
echo "[private] Aguardando RabbitMQ ficar healthy..."
for i in {1..60}; do
  RABBIT_H=$(docker inspect -f '{{.State.Health.Status}}' teiko-rabbitmq 2>/dev/null || echo starting)
  if [[ "$RABBIT_H" == "healthy" ]]; then
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

# Infos úteis pós-instalação
echo "[private] Verificações:" && \
  echo " - NAT/egresso: $(curl -sS https://api.ipify.org || echo fail)" && \
  echo " - JWT_LEN: $(awk -F= '/^JWT_SECRET=/{print length($2)}' /opt/teiko/backend/dev.env 2>/dev/null || echo 0)" && \
  echo " - HEALTH: $(curl -sS -m 5 http://localhost:8080/actuator/health 2>/dev/null || echo fail)"


