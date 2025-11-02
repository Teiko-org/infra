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
if [[ ! -d frontend/.git ]]; then
  echo "[public] Clonando frontend..."
  git clone https://github.com/Teiko-org/frontend.git frontend || {
    echo "[public] Falha ao clonar frontend. Se for privado, configure SSH keys na EC2." >&2
    exit 1
  }
fi

# Verifica se carambolo-doces existe dentro do monorepo frontend
if [[ ! -d frontend/carambolo-doces ]]; then
  echo "[public] ERRO: frontend/carambolo-doces não encontrado no repositório clonado." >&2
  exit 1
fi

# .env do frontend (somente API_UPSTREAMS)
if [[ ! -f infra/aws-ec2/.env.frontend ]]; then
  cat > infra/aws-ec2/.env.frontend <<'ENVF'
# Informe os backends (um ou mais):
# Ex.: API_UPSTREAMS=10.0.2.203:8080,10.0.3.46:8080
API_UPSTREAMS=
ENVF
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

echo "[public] Build e subida do frontend..."
docker compose -f infra/aws-ec2/docker-compose.frontend.yml build
docker compose -f infra/aws-ec2/docker-compose.frontend.yml --env-file infra/aws-ec2/.env.frontend up -d

echo "[public] Concluído. Reinicie a sessão para aplicar grupo docker se necessário."

# Validação rápida do proxy
echo "[public] Teste rápido:"
set +e
curl -I -m 10 http://localhost/api/actuator/health || true
set -e


