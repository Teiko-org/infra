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

# Estrutura esperada pelo Dockerfile-frontend: ./frontend/carambolo-doces
mkdir -p frontend
if [[ ! -d frontend/carambolo-doces/.git ]]; then
  git clone --depth 1 https://github.com/Teiko-org/carambolo-doces.git frontend/carambolo-doces || {
    echo "[public] Falha ao clonar Teiko-org/carambolo-doces" >&2
    exit 1
  }
fi

# .env do frontend (somente API_UPSTREAMS)
[[ -f infra/aws-ec2/.env.frontend ]] || cat > infra/aws-ec2/.env.frontend <<'ENVF'
# Informe os backends (um ou mais):
# Ex.: API_UPSTREAMS=10.0.2.203:8080,10.0.3.46:8080
API_UPSTREAMS=
ENVF

echo "[public] Build e subida do frontend..."
docker compose -f infra/aws-ec2/docker-compose.frontend.yml build
docker compose -f infra/aws-ec2/docker-compose.frontend.yml --env-file infra/aws-ec2/.env.frontend up -d

echo "[public] Concluído. Reinicie a sessão para aplicar grupo docker se necessário."


