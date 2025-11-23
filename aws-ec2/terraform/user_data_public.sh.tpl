#!/bin/bash
set -xe

export DEBIAN_FRONTEND=noninteractive

# Garantir git para clonar o repo de infra.
apt-get update -y
apt-get install -y git

mkdir -p /opt/teiko
cd /opt/teiko

if [ ! -d "infra" ]; then
  git clone https://github.com/Teiko-org/infra.git infra
else
  cd infra
  git pull || true
  cd ..
fi

cd /opt/teiko/infra/aws-ec2

# Cria/atualiza o .env.frontend com todos os upstreams vindos do Terraform.
cat > .env.frontend <<EOF
API_UPSTREAMS=${api_upstreams}
EOF

# Executa o script padrão da infra para subir frontend + Nginx.
FORCE_INFRA_UPDATE=1 \
FORCE_FRONT_UPDATE=1 \
bash /opt/teiko/infra/aws-ec2/setup-aws-public.sh


