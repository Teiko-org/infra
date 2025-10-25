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

[[ -d backend ]] || git clone https://github.com/Teiko-org/backend.git backend
[[ -d infra ]] || git clone https://github.com/Teiko-org/infra.git infra

# .env do backend (preenchido com defaults seguros)
[[ -f infra/aws-ec2/.env.backend ]] || cat > infra/aws-ec2/.env.backend <<'ENVB'
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=teiko
DB_USERNAME=teiko
DB_PASSWORD=teiko123
DB_URL=jdbc:mysql://mysql:3306/teiko?createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=America/Sao_Paulo

JWT_VALIDITY=3600000
JWT_SECRET=CHANGE_ME_32_CHARS_MIN

RABBITMQ_USERNAME=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_CONCURRENCY=2
RABBITMQ_MAX_CONCURRENCY=4
RABBITMQ_PREFETCH=10

AZURE_STORAGE_CONNECTION_STRING=
AZURE_STORAGE_CONTAINER_NAME=
ENVB

echo "[private] Build e subida do backend..."
docker compose -f infra/aws-ec2/docker-compose.backend.yml build
docker compose -f infra/aws-ec2/docker-compose.backend.yml --env-file infra/aws-ec2/.env.backend up -d

echo "[private] Concluído. Reinicie a sessão para aplicar grupo docker se necessário."


