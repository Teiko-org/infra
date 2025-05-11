#!/bin/bash

set -euo pipefail

echo "⚠️  Iniciando processo de reset completo do ambiente Teiko..."

PROJECT_DIR="$HOME/teiko"

# Parar e remover containers, volumes e imagens Docker
echo "🧹 Removendo containers, volumes e imagens Docker..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" down --volumes --rmi all || echo "⚠️ docker-compose não executado ou já parado"
docker system prune -a -f || echo "⚠️ docker system prune falhou"

# Remover arquivos e diretórios do projeto
echo "🗑️  Removendo diretórios do projeto..."
rm -rf "$PROJECT_DIR"

# Remover swap temporário se existir
if grep -q "/swapfile" /proc/swaps; then
  echo "💾 Removendo swap temporária..."
  sudo swapoff /swapfile
  sudo rm -f /swapfile
  echo "✅ Swap removida"
else
  echo "ℹ️ Nenhuma swap temporária ativa encontrada"
fi

echo "✅ Reset completo!"
echo "🧼 Ambiente limpo e pronto para novo setup"
