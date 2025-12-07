## Guia de Infra e CI/CD – Teiko

### Objetivo
- **Explicar como subir a infra do zero** (Terraform + EC2 + Docker).
- **Documentar os secrets/variáveis** necessários nos repositórios do GitHub.
- **Descrever o fluxo de CI/CD** (o que é automático e o que é manual).
- **Orientar o que fazer se o laboratório/ambiente for resetado** (IPs e secrets mudarem).

---

## Visão geral da arquitetura

- **VPC única / multi‑AZ**:
  - Subnets **públicas**: instâncias para **frontend + proxy /api** (bastion).
  - Subnets **privadas**: instâncias para **backends Spring Boot**.
  - Instância privada dedicada para **MySQL/MariaDB**.
- **Rede e acesso**:
  - Frontend recebe tráfego HTTP 80 da internet.
  - Frontend/proxy fala com backends via `API_UPSTREAMS` (lista `IP_PRIVADO:8080`).
  - Backends falam com o banco via IP privado da instância de DB.
- **Repositório `infra`**:
  - Pasta [`infra/aws-ec2/terraform`](terraform/README.md): Terraform que cria VPC, subnets, security groups e EC2 públicas/privadas/DB.
  - Scripts [`infra/aws-ec2/setup-aws-public.sh`](setup-aws-public.sh) e [`infra/aws-ec2/setup-aws-private.sh`](setup-aws-private.sh):
    - **Privadas**: sobem Docker Compose com backend API, worker, RabbitMQ e Redis (`docker-compose.backend.yml`).
    - **Públicas**: sobem Docker Compose com frontend (Vite buildado) e proxy `/api` (`docker-compose.frontend.yml`).

---

## Subir a infra do zero (Terraform)

### Pré‑requisitos na máquina local
- Conta AWS com permissões para EC2/VPC.
- **AWS CLI** configurada (`aws configure`).
- **Terraform** instalado (1.6+).
- Um **key pair** criado na AWS (por exemplo `key-teiko`) – o `.pem` fica **fora** do repositório.

### Passo a passo
1. Clonar o repositório de infra:
   ```bash
   git clone https://github.com/Teiko-org/infra.git
   cd infra/aws-ec2/terraform
   ```
2. Configurar as variáveis de Terraform:
   - Use `variables.tf` como referência.
   - Crie um arquivo `terraform.tfvars` (NÃO commitar) com, por exemplo:
     ```hcl
     aws_region  = "us-east-1"
     environment = "lab"
     project_name = "teiko"

     key_name  = "key-teiko"
     shared_jwt = "UM_SEGREDO_BEM_GRANDE_AQUI"

     db_name     = "teiko"
     db_username = "teiko"
     db_password = "teiko123"

     azure_storage_connection_string = "CONNSTRING_DO_AZURE"
     azure_storage_container_name    = "teiko-s3"
     ```
3. Inicializar e aplicar:
   ```bash
   terraform init
   terraform plan   # opcional, para revisar
   terraform apply  # confirma quando pedir
   ```
4. Anotar os **outputs importantes** (aparecem ao final do `apply` ou via `terraform output`):
   - `public_instance_public_ips` → IPs públicos das EC2 **públicas** (frontend/bastion).
   - `private_instance_private_ips` → IPs privados das EC2 **privadas** (backends).
   - `db_endpoint` → endpoint DNS do banco RDS MySQL.

Esses IPs serão usados depois nos **secrets do GitHub** (`BASTION_HOSTS`, `FRONTEND_EC2_HOSTS`, `BACKEND_PRIVATE_HOSTS`, `API_UPSTREAMS`).  

> Dica: uma vez que tudo está funcionando, **evite `terraform destroy`** durante o laboratório para não perder IPs/estado à toa.

---

## Secrets / variáveis nos repositórios GitHub

### Backend (`Teiko-org/backend`)

- **Docker / registry**
  - `REGISTRY_USERNAME` – usuário do Docker Hub (ou outro registry).
  - `REGISTRY_TOKEN` – token ou senha para `docker login`.
  - `REGISTRY_IMAGE` – nome da imagem (ex: `teiko/backend`).

- **Banco de dados**
  - `DB_HOST` – endpoint do RDS (output `db_endpoint`).
  - `DB_NAME` – normalmente `teiko`.
  - `DB_USERNAME` – usuário do DB (ex: `teiko`).
  - `DB_PASSWORD` – senha do DB.

- **JWT / segurança**
  - `SHARED_JWT` – segredo JWT compartilhado entre TODOS os backends.
  - (Opcional) `JWT_SECRET`/`JWT_VALIDITY` se existirem no backend.

- **Storage de arquivos (Azure)**
  - `AZURE_STORAGE_CONNECTION_STRING` – connection string do Storage.
  - `AZURE_STORAGE_CONTAINER_NAME` – nome do container (ex: `teiko-s3`).

- **SSH / EC2**
  - `BASTION_HOSTS` – lista de IPs públicos das EC2 **públicas** (`public_instance_public_ips`), ex: `54.x.x.x,98.x.x.x`.
  - `BASTION_USER` – normalmente `ubuntu`.
  - `BASTION_SSH_KEY` – **conteúdo** do `.pem` usado no Terraform (`key-teiko.pem`), inteiro, começando em `-----BEGIN PRIVATE KEY-----`.
  - `BACKEND_PRIVATE_HOSTS` – IPs privados das EC2 **privadas** (`private_instance_private_ips`), ex: `10.0.2.34,10.0.3.9`.
  - `BACKEND_EC2_SSH_KEY` – mesma chave privada usada para entrar nas privadas (normalmente igual à `BASTION_SSH_KEY`).

### Frontend (`Teiko-org/frontend`)

- **Docker / registry**
  - `REGISTRY_USERNAME`
  - `REGISTRY_TOKEN`
  - `REGISTRY_IMAGE` – ex: `teiko/frontend`.

- **SSH / EC2 públicas**
  - `FRONTEND_EC2_HOSTS` – IPs públicos das instâncias públicas (`public_instance_public_ips`), ex: `54.x.x.x,98.x.x.x`.
  - `FRONTEND_EC2_USER` – normalmente `ubuntu`.
  - `FRONTEND_EC2_SSH_KEY` – conteúdo do `.pem` correspondente (`key-teiko.pem`).

- **API upstreams (opcional)**
  - `API_UPSTREAMS` – lista `IP_PRIVADO:8080` dos backends; se não setar aqui, o script `setup-aws-public.sh` usa `.env.frontend` no servidor.

### Infra (`Teiko-org/infra`, se usar CI pra Terraform)

- **AWS**
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` – ex: `us-east-1`.

- (Opcional) `TF_VAR_*` para popular variáveis como `shared_jwt`, `azure_storage_connection_string` via pipeline em vez de `terraform.tfvars` commitado.

---

## Fluxo de CI (build/test)

- **Disparo automático (CI)**:
  - Workflows de CI do **backend** e **frontend** rodam em:
    - `push` na branch `main-teiko`.
    - `pull_request` direcionado para `main-teiko`.

- **O que o CI do backend faz (resumido)**:
  - Baixa dependências e roda testes (`mvn test` ou similar).
  - Builda o jar Spring Boot e depois a **imagem Docker** do backend.
  - Se for push/merge na `main-teiko`, faz **push da imagem** para o registry configurado.

- **O que o CI do frontend faz**:
  - Instala dependências (`npm ci`) e roda `npm run build` do Vite.
  - Builda a imagem Docker do frontend/proxy (usando `Dockerfile-frontend`).
  - Se for push/merge na `main-teiko`, faz push da imagem para o registry.

> Resultado: após o merge de um PR na `main-teiko`, você tem **imagens novas** no registry, prontas para serem deployadas via workflows de CD.

---

## Fluxo de CD (deploy para EC2)

- **CD é manual**: os workflows de deploy (por exemplo `Deploy Backend to EC2` e `Deploy Frontend to EC2`) são executados via **Actions → Run workflow** no GitHub.

### Deploy Backend to EC2 (privadas)

Resumo do que o workflow faz:

1. Conecta via SSH em uma instância **pública** (bastion) listada em `BASTION_HOSTS` usando `appleboy/ssh-action` + `BASTION_SSH_KEY`.
2. No bastion, garante `/opt/teiko/infra` atualizado (`git clone` ou `git pull`).
3. Cria um arquivo temporário com a chave SSH das privadas (`BACKEND_EC2_SSH_KEY`).
4. Para cada IP em `BACKEND_PRIVATE_HOSTS`:
   - Abre SSH `ubuntu@IP_PRIVADO` usando o bastion como proxy.
   - Exporta variáveis (`SHARED_JWT`, `DB_*`, `AZURE_*`, `REDIS_*`) e roda:
     ```bash
     sudo -E bash /opt/teiko/infra/aws-ec2/setup-aws-private.sh
     ```
5. Cada privada sobe/atualiza os containers do backend (`docker-compose.backend.yml`), apontando para o mesmo banco e usando o **mesmo JWT**.

### Deploy Frontend to EC2 (públicas)

Resumo do workflow:

1. Conecta **direto** nas EC2 públicas listadas em `FRONTEND_EC2_HOSTS` (usuário `FRONTEND_EC2_USER`, chave `FRONTEND_EC2_SSH_KEY`).  
2. Em cada pública:
   - Garante `/opt/teiko/infra` atualizado (`git clone`/`git pull`).
   - Garante `.env.frontend` com `API_UPSTREAMS` (via secret ou echo):
     ```bash
     echo "API_UPSTREAMS=10.0.2.34:8080,10.0.3.9:8080" | sudo tee /opt/teiko/infra/aws-ec2/.env.frontend
     ```
   - Roda:
     ```bash
     FORCE_INFRA_UPDATE=1 FORCE_FRONT_UPDATE=1 \
     sudo -E bash /opt/teiko/infra/aws-ec2/setup-aws-public.sh
     ```
   - O script builda/atualiza a imagem `teiko/frontend:latest` e sobe o `docker-compose.frontend.yml`.

### Fluxo prático no dia a dia

1. Abrir PR para `main-teiko` → **CI** roda automaticamente (backend e frontend).
2. CI verde → fazer **merge**.
3. Ir em **GitHub Actions**:
   - Rodar `Deploy Backend to EC2` (se houve mudanças no backend/infraback).
   - Rodar `Deploy Frontend to EC2` (se houve mudanças no frontend/proxy).
4. Validar healthcheck e fluxo da aplicação (ver checklist no final deste README).

---

## Reset de lab / recriar ambiente

### Quando secrets do GitHub forem apagados

1. Recriar, nos repositórios correspondentes, todos os secrets listados na seção **Secrets / variáveis**.
2. Para cada secret:
   - Recuperar valores no lugar certo:
     - IPs de EC2 → console AWS (EC2 → Instances).
     - Usuário SSH quase sempre `ubuntu`.
     - Chave `.pem` → key pair criado na AWS (baixado uma vez; guardar fora do Git).
     - Credenciais do Docker Hub e Azure Storage → contas correspondentes.
3. Depois de recriar secrets, rodar novamente **Deploy Backend** e **Deploy Frontend**.

### Quando instâncias EC2 forem destruídas / recriadas

1. Na pasta `infra/aws-ec2/terraform`:
   ```bash
   terraform apply
   ```
   - Isso recria as EC2 e, possivelmente, muda IPs públicos/privados.
2. Rodar `terraform output` e **atualizar**:
   - `BASTION_HOSTS` e `FRONTEND_EC2_HOSTS` com os **novos IPs públicos**.
   - `BACKEND_PRIVATE_HOSTS` com os **novos IPs privados das privadas**.
   - `API_UPSTREAMS` (secret ou `.env.frontend`) com os novos `IP_PRIVADO:8080`.
3. Rodar `Deploy Backend to EC2` e `Deploy Frontend to EC2` para reprovisionar containers.
4. Se o banco for destruído também:
   - Atualizar `DB_HOST` e demais `DB_*` se necessário.
   - Aplicar novamente o script de criação de schema/dados iniciais (se existir). 

> Em resumo: depois de um reset grande, **sempre** atualizar IPs nos secrets e então rodar ambos os workflows de deploy.

---

## Checklist rápido de validação pós‑deploy

- **Healthcheck da API via proxy** (em cada pública):
  ```bash
  curl -sS http://IP_PUBLICO/api/actuator/health
  ```
  - Esperado: `{"status":"UP"}`.

- **Teste via navegador** (usar IP público de uma das instâncias públicas):
  - Acessar `http://IP_PUBLICO/`.
  - Verificar:
    - Página inicial carrega (banners, logo, imagens de produtos).
    - Login funciona (incluindo F5 sem deslogar).
    - Fluxo de pedido **Bolo** até o final.
    - Fluxo de pedido **Fornada** até o final.

- **Dashboard admin**:
  - Aba de pedidos **Carambolos mais pedidos** carregando.
  - Aba **Produção** sem lentidão/erros visíveis.
  - Drag‑and‑drop alterando status sem 401/500.

- **Logs básicos** (em uma pública e uma privada):
  ```bash
  # na pública
  sudo docker ps
  sudo docker logs --tail=80 teiko-frontend

  # na privada
  sudo docker ps
  sudo docker logs --tail=80 teiko-backend
  ```

Se tudo isso estiver ok, a infra + CI/CD estão funcionando para o laboratório.

---

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
