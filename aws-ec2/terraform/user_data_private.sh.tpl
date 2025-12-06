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
AWS_S3_BUCKET_NAME="${aws_s3_bucket_name}" \
AWS_REGION="${aws_region}" \
DB_HOST="${db_host}" \
DB_NAME="${db_name}" \
DB_USERNAME="${db_username}" \
DB_PASSWORD="${db_password}" \
FORCE_INFRA_UPDATE=1 \
bash /opt/teiko/infra/aws-ec2/setup-aws-private.sh


