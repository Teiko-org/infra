#!/usr/bin/env bash
set -euo pipefail

echo "[db] Atualizando pacotes e instalando Docker..."
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

echo "[db] Preparando diretório /opt/teiko..."
sudo mkdir -p /opt/teiko
sudo chown -R "$USER":"$USER" /opt/teiko
cd /opt/teiko

[[ -d infra ]] || git clone https://github.com/Teiko-org/infra.git infra
if [[ "${FORCE_INFRA_UPDATE:-0}" = "1" ]]; then
  echo "[db] Atualizando repo infra (reset --hard + pull) ..."
  git -C infra reset --hard HEAD || true
  git -C infra pull || true
fi

mkdir -p backend
if [[ ! -d backend/.git ]]; then
  git clone --depth 1 https://github.com/Teiko-org/backend.git backend || true
fi

if [[ ! -d backend/carambolos-api ]]; then
  echo "[db] Clonando carambolos-api para obter script de criação de banco..."
  git clone --depth 1 https://github.com/Teiko-org/carambolos-api.git backend/carambolos-api || {
    echo "[db] Aviso: não foi possível obter 'carambolos-api'. O MySQL subirá sem rodar script-bd.sql." >&2
  }
fi

DB_NAME_DEFAULT="${DB_NAME:-teiko}"
DB_USERNAME_DEFAULT="${DB_USERNAME:-teiko}"
DB_PASSWORD_DEFAULT="${DB_PASSWORD:-teiko123}"

cat > infra/aws-ec2/.env.backend <<ENVB
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=${DB_NAME_DEFAULT}
DB_USERNAME=${DB_USERNAME_DEFAULT}
DB_PASSWORD=${DB_PASSWORD_DEFAULT}
DB_URL=jdbc:mysql://localhost:3306/${DB_NAME_DEFAULT}?createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=America/Sao_Paulo
ENVB

echo "[db] Subindo apenas o MySQL (instância dedicada de banco)..."
docker compose -f infra/aws-ec2/docker-compose.db.yml --env-file infra/aws-ec2/.env.backend up -d mysql

echo "[db] Aguardando MySQL ficar healthy..."
for i in {1..60}; do
  MYSQL_H=$(docker inspect -f '{{.State.Health.Status}}' teiko-mysql 2>/dev/null || echo starting)
  if [[ "$MYSQL_H" == "healthy" ]]; then
    break
  fi
  sleep 2
done

echo "[db] Concluído. Banco de dados disponível em localhost:3306 dentro da VPC."


