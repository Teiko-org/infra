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

cd /opt/teiko

# Executa o script padrão da infra, passando os segredos via env.
SHARED_JWT="${shared_jwt}" \
AZURE_STORAGE_CONNECTION_STRING="${azure_storage_connection_string}" \
AZURE_STORAGE_CONTAINER_NAME="${azure_storage_container_name}" \
FORCE_INFRA_UPDATE=1 \
bash /opt/teiko/infra/aws-ec2/setup-aws-private.sh


