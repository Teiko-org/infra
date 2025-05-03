#!/bin/bash

echo "🔧 Atualizando o sistema e instalando pacotes essenciais..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose npm openjdk-21-jdk git curl || {
  echo "❌ Erro na instalação de pacotes. Verifique a conexão com a internet e tente novamente."
  exit 1
}

echo "🐳 Habilitando e iniciando o serviço Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "📁 Preparando o diretório do projeto..."
sudo mkdir -p /etc/teiko
cd /etc/teiko || exit 1

echo "📥 Clonando repositórios..."
git clone https://github.com/Teiko-org/frontend.git || { echo "❌ Erro ao clonar frontend"; exit 1; }
git clone https://github.com/Teiko-org/backend.git || { echo "❌ Erro ao clonar backend"; exit 1; }
git clone https://github.com/Teiko-org/infra.git || { echo "❌ Erro ao clonar infra"; exit 1; }

# Verificar se os arquivos SQL existem
if [ ! -f ./infra/VM-Teiko/bd/create_user.sql ] || [ ! -f ./infra/VM-Teiko/bd/script-bd.sql ]; then
  echo "❌ Arquivos SQL não encontrados! Certifique-se de que 'create_user.sql' e 'script-bd.sql' estão no diretório './infra/sql'."
  exit 1
fi

# Ambiente
echo "🔐 Gerando arquivo .env com variáveis sensíveis..."
cat <<EOL > .env
# 🌱 Variáveis de ambiente - Teiko
JWT_VALIDITY=3600000
JWT_SECRET=xxxx
EOL

# Gerar o JAR do backend localmente
echo "☕ Gerando o JAR do backend localmente..."
cd backend/carambolos-api || { echo "❌ Diretório do backend não encontrado"; exit 1; }
./mvnw clean package -DskipTests || { echo "❌ Erro ao gerar o JAR do backend"; exit 1; }
cd - || exit 1

# Dockerfile do backend Java
echo "⚙️ Criando Dockerfile para o backend Java com Amazon Corretto 21..."
cat <<EOF > Dockerfile-java
FROM amazoncorretto:21-alpine
WORKDIR /app
COPY ./backend/carambolos-api/target/*.jar /app/app.jar
EXPOSE 8080
CMD ["java", "-jar", "/app/app.jar"]
EOF
echo "✅ Dockerfile-java criado!"

# Frontend Dockerfile
echo "🎨 Criando Dockerfile-react (frontend)..."
cat <<EOF > Dockerfile-react
FROM node:20-alpine as build
WORKDIR /app
COPY ./frontend/carambolo-doces /app
RUN npm install && npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Compose file
echo "📦 Criando docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: TeikoMySQL
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: 123456
    volumes:
      - mysql_data:/var/lib/mysql
      - ./infra/VM-Teiko/bd:/docker-entrypoint-initdb.d

  java:
    build:
      context: .
      dockerfile: Dockerfile-java
    container_name: TeikoBackend
    depends_on:
      - mysql
    ports:
      - "8080:8080"
    env_file:
      - .env

  react:
    build:
      context: .
      dockerfile: Dockerfile-react
    container_name: TeikoFrontend
    ports:
      - "80:80"
    depends_on:
      - java

volumes:
  mysql_data:
EOF

echo "✅ Setup completo!"
echo "🔧 Agora você pode rodar: docker-compose up --build"
