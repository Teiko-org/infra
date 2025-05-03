#!/bin/bash

set -e

echo "🛑 Parando containers existentes..."
docker-compose down || echo "⚠️ Nenhum container para parar ou erro ao derrubar containers."

echo "🧹 Removendo imagens Docker antigas..."
docker image prune -a -f

echo "🧼 Limpando diretório antigo do projeto..."
sudo rm -rf /etc/teiko

echo "📁 Criando diretório novo e entrando nele..."
sudo mkdir -p /etc/teiko
cd /etc/teiko

echo "📥 Clonando repositórios novamente..."
git clone https://github.com/Teiko-org/frontend.git || { echo "❌ Erro ao clonar frontend"; exit 1; }
git clone https://github.com/Teiko-org/backend.git || { echo "❌ Erro ao clonar backend"; exit 1; }
git clone https://github.com/Teiko-org/infra.git || { echo "❌ Erro ao clonar infra"; exit 1; }

echo "🔐 Dando permissão e executando o script principal de setup..."
chmod +x ./infra/VM-Teiko/setup.sh
./infra/VM-Teiko/setup.sh

echo "✅ Infraestrutura reiniciada com sucesso!"
