#!/bin/bash

set -euo pipefail

echo "🔧 Atualizando o sistema e instalando pacotes essenciais..."

sudo apt update -y && sudo apt upgrade -y

REQUIRED_PACKAGES=(docker.io docker-compose npm openjdk-21-jdk git curl maven)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    echo "✅ $pkg já está instalado"
  else
    echo "📦 Instalando $pkg..."
    sudo apt install -y "$pkg" || {
      echo "❌ Falha ao instalar $pkg"
      exit 1
    }
  fi
done

echo "🐳 Habilitando e iniciando o serviço Docker..."
sudo systemctl enable docker || true
sudo systemctl start docker || true

echo "📁 Preparando o diretório do projeto..."
PROJECT_DIR="$HOME/teiko"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || {
  echo "❌ Falha ao acessar $PROJECT_DIR"
  exit 1
}

echo "📥 Clonando repositórios..."
declare -A REPOS=(
  ["frontend"]="https://github.com/Teiko-org/frontend.git"
  ["backend"]="https://github.com/Teiko-org/backend.git"
  ["infra"]="https://github.com/Teiko-org/infra.git"
)

for dir in "${!REPOS[@]}"; do
  if [ -d "$dir" ]; then
    echo "✅ Repositório '$dir' já clonado"
  else
    git clone "${REPOS[$dir]}" "$dir" || {
      echo "❌ Erro ao clonar $dir"
      exit 1
    }
  fi
done

# Convertendo application.properties para UTF-8
APP_PROPS="$PROJECT_DIR/backend/carambolos-api/src/main/resources/application.properties"
if [ -f "$APP_PROPS" ]; then
  echo "🌐 Convertendo application.properties para UTF-8..."
  iconv -f ISO-8859-1 -t UTF-8 "$APP_PROPS" -o "$APP_PROPS.utf8" && mv "$APP_PROPS.utf8" "$APP_PROPS"
else
  echo "⚠️  application.properties não encontrado para conversão"
fi

# Ambiente
if [ ! -f ".env" ]; then
  echo "🔐 Gerando arquivo .env com variáveis sensíveis..."
  cat <<EOL >.env
# 🌱 Variáveis de ambiente - Teiko
JWT_VALIDITY=3600000
JWT_SECRET=RXhpc3RlIHVtYSB0ZW9yaWEgcXVlIGRpeiBxdWUsIHNlIHVtIGRpYSBhbGd16W0gZGVzY29icmlyIGV4YXRhbWVudGUgcGFyYSBxdWUg...
EOL
else
  echo "✅ Arquivo .env já existe"
fi

# Gerar o JAR do backend localmente
BACKEND_DIR="$PROJECT_DIR/backend/carambolos-api"
if [ -d "$BACKEND_DIR" ]; then
  echo "☕ Gerando o JAR do backend localmente..."
  cd "$BACKEND_DIR" || exit 1
  mvn clean package -DskipTests || {
    echo "❌ Erro ao gerar o JAR do backend"
    exit 1
  }
  cd - >/dev/null
else
  echo "❌ Diretório do backend não encontrado em $BACKEND_DIR"
  exit 1
fi

# Dockerfile Java
DOCKERFILE_JAVA="$PROJECT_DIR/Dockerfile-java"
if [ ! -f "$DOCKERFILE_JAVA" ]; then
  echo "⚙️ Criando $DOCKERFILE_JAVA..."
  cat <<EOF >"$DOCKERFILE_JAVA"
FROM amazoncorretto:21-alpine
WORKDIR /app
COPY ./backend/carambolos-api/target/*.jar /app/app.jar
EXPOSE 8080
CMD ["java", "-jar", "/app/app.jar"]
EOF
else
  echo "✅ $DOCKERFILE_JAVA já existe"
fi

# Dockerfile React
DOCKERFILE_REACT="$PROJECT_DIR/Dockerfile-react"
if [ ! -f "$DOCKERFILE_REACT" ]; then
  echo "🎨 Criando $DOCKERFILE_REACT..."
  cat <<EOF >"$DOCKERFILE_REACT"
FROM node:20-alpine as build
WORKDIR /app
COPY ./frontend/carambolo-doces /app
RUN npm install && npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY ./infra/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/src/assets /usr/share/nginx/html/src/assets
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
else
  echo "✅ $DOCKERFILE_REACT já existe"
fi

# docker-compose.yml
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "📦 Criando $COMPOSE_FILE..."
  cat <<EOF >"$COMPOSE_FILE"
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: TeikoMySQL
    ports:
      - "3306:3306"
    networks:
      - teiko-net
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: teiko
    volumes:
      - mysql_data:/var/lib/mysql
      - ./infra/VM-Teiko/bd/script-bd.sql:/docker-entrypoint-initdb.d/script-bd.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-p123456"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  java:
    build:
      context: .
      dockerfile: Dockerfile-java
    container_name: TeikoBackend
    depends_on:
      mysql:
        condition: service_healthy
    ports:
      - "8080:8080"
    networks:
      - teiko-net
    env_file:
      - .env
    restart: unless-stopped

  react:
    build:
      context: .
      dockerfile: Dockerfile-react
    container_name: TeikoFrontend
    ports:
      - "80:80"
    networks:
      - teiko-net
    depends_on:
      - java
    restart: unless-stopped

volumes:
  mysql_data:

networks:
  teiko-net:
    name: teiko-net
    driver: bridge
EOF
else
  echo "✅ $COMPOSE_FILE já existe"
fi

echo "✅ Setup completo!"
echo "🚀 Você pode iniciar a aplicação com:"
echo "cd $PROJECT_DIR && docker-compose up --build"
