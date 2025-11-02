## Guia de Operação – Infraestrutura Teiko (EC2 públicas e privadas)

### Visão geral
- EC2 públicas: servem o frontend (Node/Express) e fazem proxy reverso para os backends via `/api`, com balanceamento round‑robin entre múltiplos backends.
- EC2 privadas: rodam o backend (Spring Boot) e dependências (MySQL, RabbitMQ) via Docker Compose.
- Comunicação: o frontend aponta para os backends por `API_UPSTREAMS` (lista de `IP_PRIVADO:8080`).

---

## 0) Pré‑requisitos
- VPC com:
  - Subnets públicas (1 por AZ) e privadas (1 por AZ).
  - NAT Gateway em cada AZ e tabelas de rota privadas com `0.0.0.0/0 → NAT` da AZ correspondente.
  - Internet Gateway anexado à VPC.
- Security Groups:
  - Públicas: porta 80 aberta para Internet.
  - Privadas: porta 8080 permitida a partir do SG das públicas (ou CIDR da VPC).
- Par de chaves (`key-carambolos.pem`).

---

## 1) Preparação local (seu computador)
```bash
# 1. Salve a chave e ajuste permissões
chmod 400 key-carambolos.pem

# 2. (Opcional) SSH para privadas via bastion automaticamente
# Host privada-teiko
#   HostName 10.0.X.Y
#   User ubuntu
#   IdentityFile ~/key-carambolos.pem
#   ProxyJump ubuntu@EC2_PUBLIC_DNS
```

---

## 2) Primeira conexão na EC2 pública (por AZ)
```bash
ssh -i key-carambolos.pem ubuntu@EC2_PUBLIC_DNS

# 1. Preparar workspace
sudo mkdir -p /opt/teiko && sudo chown -R "$USER":"$USER" /opt/teiko
cd /opt/teiko

# 2. Clonar infra
git clone https://github.com/Teiko-org/infra.git infra

# 3. (Opcional) evitar precisar de sudo no docker
sudo usermod -aG docker $USER && newgrp docker || true
```

---

## 3) Subir backend em cada EC2 privada (por AZ)
Conecte na EC2 privada (via bastion) e execute:

```bash
ssh -i key-carambolos.pem ubuntu@IP_PRIVADO

# 1. Garantir egress (NAT)
curl -sS https://api.ipify.org; echo
curl -I -m 5 https://github.com

# 2. Preparar workspace e infra
sudo mkdir -p /opt/teiko && sudo chown -R "$USER":"$USER" /opt/teiko
cd /opt/teiko
[[ -d infra ]] || git clone https://github.com/Teiko-org/infra.git infra

# 3. Subir backend (use o MESMO JWT em todas as privadas)
SHARED_JWT='COLOQUE_UM_SEGREDO_FORTE_AQUI' \
AZURE_STORAGE_CONNECTION_STRING='COLOQUE_SUA_CONNSTRING' \
AZURE_STORAGE_CONTAINER_NAME='teiko-s3' \
FORCE_INFRA_UPDATE=1 \
sudo -E bash /opt/teiko/infra/aws-ec2/setup-aws-private.sh

# 4. Validação
curl -sS http://localhost:8080/actuator/health
sudo docker logs --tail=120 teiko-backend
```

Repita para todas as privadas (todas as AZs), usando o mesmo valor de `SHARED_JWT`.

---

## 4) Subir frontend/proxy em cada EC2 pública (por AZ)
Na EC2 pública da AZ, após o passo “2)”, execute:

```bash
cd /opt/teiko/infra/aws-ec2

# 1. Defina TODOS os backends (IPs privados :8080) de todas as AZs
echo 'API_UPSTREAMS=10.0.2.57:8080,10.0.3.71:8080' | sudo tee .env.frontend

# 2. Suba o frontend/proxy
FORCE_INFRA_UPDATE=1 FORCE_FRONT_UPDATE=1 \
sudo -E bash /opt/teiko/infra/aws-ec2/setup-aws-public.sh

# 3. Validação
curl -sS -m 10 http://localhost/api/actuator/health
curl -I -m 10 http://localhost/
sudo docker logs --tail=200 teiko-frontend
```

Repita para todas as públicas (todas as AZs).

---

## 5) Teste fim‑a‑fim
- No navegador: acesse o IP público (porta 80) da pública e teste navegação, imagens e login.
- Caso veja 401 após login alternando páginas: confirme que TODAS as privadas usam o mesmo `JWT_SECRET`.

---

## 6) Operação diária (checks e comandos úteis)
- Saúde:
```bash
# privadas
curl -sS http://localhost:8080/actuator/health
# públicas
curl -sS http://localhost/api/actuator/health
```
- Logs:
```bash
sudo docker logs --tail=200 teiko-backend
sudo docker logs --tail=200 teiko-frontend
sudo docker logs --tail=100 teiko-mysql
sudo docker logs --tail=100 teiko-rabbitmq
```
- Espaço em disco:
```bash
df -h
sudo docker system prune -a -f
sudo docker volume prune -f
```
- Sincronismo de horário (recomendado):
```bash
sudo apt-get update -y && sudo apt-get install -y chrony
sudo systemctl enable --now chrony
timedatectl
```

---

## 7) Atualizações e rebuild
- Backend (privada):
```bash
cd /opt/teiko/infra/aws-ec2
sudo docker compose -f docker-compose.backend.yml --env-file ./.env.backend up -d --force-recreate api
```
- Frontend (públicas):
```bash
cd /opt/teiko
sudo git -C infra pull || true
sudo docker build -f infra/aws-ec2/dockerfiles/Dockerfile-frontend -t teiko/frontend:latest /opt/teiko
cd /opt/teiko/infra/aws-ec2
sudo docker compose --env-file ./.env.frontend -f docker-compose.frontend.yml up -d --force-recreate
```

---

## 8) Quando IPs mudarem (reinício de laboratório/ambiente)
1) Descubra os novos IPs privados das privadas.
2) Em cada pública, atualize os upstreams e recrie o proxy:
```bash
cd /opt/teiko/infra/aws-ec2
echo 'API_UPSTREAMS=NOVO_IP_PRIV_A:8080,NOVO_IP_PRIV_B:8080' | sudo tee .env.frontend
sudo docker compose --env-file ./.env.frontend -f docker-compose.frontend.yml up -d --force-recreate
curl -sS -m 10 http://localhost/api/actuator/health
```
3) Se recriar privadas do zero, repita o passo “3)” usando o MESMO `SHARED_JWT`.

---

## 9) Rede e segurança (checagem rápida)
- Privadas: porta 8080 permitida a partir do SG das públicas (ou CIDR da VPC). Tabela de rotas privada: `0.0.0.0/0 → NAT` da mesma AZ.
- Públicas: porta 80 aberta (HTTP externo).
- Testes de saída (privadas via NAT):
```bash
curl -sS https://api.ipify.org; echo
curl -I -m 5 https://github.com
```

---

## 10) Solução de problemas
- Login cai em 401 alternando entre páginas:
  - Use o MESMO `SHARED_JWT` em todas as privadas; recrie a API.
- Timeout no `/api/actuator/health` na pública:
  - Teste com GET (sem `-I`); veja logs do proxy (`teiko-frontend`).
- Erro de chave SSH:
  - `chmod 400 key-carambolos.pem`.
- Alerta “disk_almost_full” do RabbitMQ:
  - Limpe imagens/volumes (comandos de disco) ou aumente EBS depois.
- Imagens do site não carregam:
  - Assets no `frontend/carambolo-doces/public/` e referências iniciando com `/arquivo.ext`.
  - Imagens do backend: teste via `curl -I http://IP_PUBLICO/api/files/...`.

---

## 11) Reset completo (quando necessário)
Executar nas máquinas a resetar (cuidado: destrói containers/imagens/volumes):
```bash
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true
sudo docker rmi -f $(sudo docker images -q) 2>/dev/null || true
sudo docker volume prune -f
sudo docker network prune -f
sudo docker system prune -a -f
sudo rm -rf /opt/teiko
sudo mkdir -p /opt/teiko
```
Depois, refaça “3) Subir backend” e “4) Subir frontend/proxy”.

---

## 12) Checklist final
- Privadas (todas):
  - Health UP.
  - Mesmo `JWT_SECRET` em todas (confira o tamanho):
    ```bash
    sudo docker exec -it teiko-backend sh -lc "awk -F= '/^JWT_SECRET=/{print length($2)}' /app/prod.env"
    ```
  - `AZURE_STORAGE_CONNECTION_STRING` e `AZURE_STORAGE_CONTAINER_NAME` presentes.
- Públicas (todas):
  - `.env.frontend` com TODOS os backends.
  - Health via `/api` UP, index 200, imagens estáticas servindo.

# Deploy na AWS EC2 (Carambolos)

Guia para subir backend (privadas) e frontend (públicas) nas EC2 usando Docker Compose.

## Visão geral
- 2 públicas: Nginx + app Vite (frontend)
- 2 privadas: Spring Boot + MySQL + RabbitMQ (backend)
- Frontend chama `/api`; Nginx faz proxy balanceado para `API_UPSTREAMS` (lista de backends).

## Pré-requisitos
- SG das públicas: permitir HTTP 80 da Internet e saída para privadas:8080
- SG das privadas: permitir entrada 8080 a partir do SG das públicas
- Não expor 3306/5672/15672 publicamente
- Chave SSH `key-carambolos.pem`
- Instâncias (exemplo real):
  - us-east-1a: pública `ec2-54-173-236-215.compute-1.amazonaws.com`, privada `10.0.2.203`
  - us-east-1b: pública `ec2-3-95-195-143.compute-1.amazonaws.com`, privada `10.0.3.46`

## 1) Backend nas privadas
Execute em cada privada (10.0.2.203 e 10.0.3.46):
```bash
ssh -i key-carambolos.pem ubuntu@10.0.2.203

sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/Teiko-org/infra.git
cd infra/aws-ec2

# (Opcional) ajustar variáveis
sudo nano .env.backend

# Subir backend (MySQL, RabbitMQ, API)
sudo bash setup-aws-private.sh
```
Principais variáveis (`.env.backend`):
- DB: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`
- JWT: `JWT_VALIDITY`, `JWT_SECRET`
- Fila: `RABBITMQ_USERNAME`, `RABBITMQ_PASSWORD`

Teste:
```bash
curl -s http://localhost:8080/actuator/health
```

## 2) Frontend nas públicas (Nginx com balanceamento)
Execute na pública da mesma AZ e defina `API_UPSTREAMS` com um ou mais backends (IP privado:porta).

### us-east-1a
```bash
ssh -i key-carambolos.pem ubuntu@ec2-54-173-236-215.compute-1.amazonaws.com

sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/Teiko-org/infra.git
cd infra/aws-ec2

cat > .env.frontend <<EOF
API_UPSTREAMS=10.0.2.203:8080
EOF

sudo bash setup-aws-public.sh
```

### us-east-1b
```bash
ssh -i key-carambolos.pem ubuntu@ec2-3-95-195-143.compute-1.amazonaws.com

sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/Teiko-org/infra.git
cd infra/aws-ec2

cat > .env.frontend <<EOF
API_UPSTREAMS=10.0.3.46:8080
EOF

sudo bash setup-aws-public.sh
```

Para balancear as duas privadas em cada pública, use:
```bash
cat > .env.frontend <<EOF
API_UPSTREAMS=10.0.2.203:8080,10.0.3.46:8080
EOF
```

Teste no navegador:
- `http://<HOST-PUBLICO>/api/actuator/health`

## 3) Comandos úteis
```bash
# Logs do backend
docker logs -f teiko-backend

# Serviços (backend)
docker compose -f docker-compose.backend.yml ps

# Atualizar versão
git -C /opt/teiko/infra pull
sudo docker compose -f /opt/teiko/infra/aws-ec2/docker-compose.backend.yml build --no-cache
sudo docker compose -f /opt/teiko/infra/aws-ec2/docker-compose.backend.yml up -d
```

## 4) Notas
- Produção: frontend usa `/api`; Nginx envia para `API_UPSTREAMS` (obrigatório).
- Em privadas, MySQL e RabbitMQ não expostos.
- Alternativa: usar ALB interno da AWS e apontar Nginx para esse DNS na variável `API_UPSTREAMS` (um único destino).

## 5) Troubleshooting
- 502 em `/api`:
  - Verificar `API_UPSTREAMS` em `.env.frontend` e conectividade 8080 SG público -> privado.
- Backend falha por DB:
  - Checar saúde do `mysql` e credenciais do `.env.backend`.
- Permissões Docker:
  - Fazer logout/login após setup para aplicar grupo `docker`.
