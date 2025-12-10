# Infraestrutura - Teiko

Infraestrutura como Código (IaC) para o projeto Teiko usando **Terraform** na **AWS EC2**. Este repositório contém toda a configuração necessária para provisionar e gerenciar a infraestrutura do projeto, incluindo VPC, instâncias EC2, RDS MySQL, Security Groups e configuração de CI/CD.

## 📋 Visão Geral

A infraestrutura do Teiko é provisionada na AWS usando Terraform e consiste em:

- **VPC multi-AZ** com subnets públicas e privadas
- **2 instâncias EC2 públicas** (frontend + Nginx proxy)
- **2 instâncias EC2 privadas** (backend Spring Boot)
- **1 instância RDS MySQL** (banco de dados gerenciado)
- **NAT Gateways** por AZ para acesso à internet das instâncias privadas
- **Elastic IPs** fixos para as instâncias públicas
- **Security Groups** configurados para segurança em camadas

## 🏗️ Arquitetura

```
Internet
   │
   ▼
[Elastic IPs] ──► [EC2 Públicas (Frontend + Nginx)]
                          │
                          │ /api (proxy)
                          ▼
                   [EC2 Privadas (Backend)]
                          │
                          │ MySQL
                          ▼
                   [RDS MySQL]
```

### Componentes Principais

- **EC2 Públicas**: Servem o frontend (React/Vite) e fazem proxy reverso para os backends via `/api` com balanceamento round-robin
- **EC2 Privadas**: Rodam o backend Spring Boot, RabbitMQ e Redis via Docker Compose
- **RDS MySQL**: Banco de dados gerenciado na AWS, acessível apenas pelas instâncias privadas
- **VPC**: Rede isolada com subnets públicas (10.0.0.0/24, 10.0.1.0/24) e privadas (10.0.2.0/24, 10.0.3.0/24)

## 🚀 Início Rápido

### Pré-requisitos

- **AWS CLI** configurado com credenciais válidas
- **Terraform** >= 1.5.0 instalado
- **Key Pair** criado na AWS (ex: `key-teiko`)
- **Bucket S3** para armazenar o state do Terraform (ex: `teiko-bucket-pj`)

### Instalação Rápida

```bash
# 1. Clone o repositório
git clone https://github.com/Teiko-org/infra.git
cd infra/aws-ec2/terraform

# 2. Configure as variáveis
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com suas configurações

# 3. Inicialize e aplique
terraform init
terraform plan
terraform apply
```

## 📁 Estrutura do Repositório

```
infra/
├── aws-ec2/                    # Configuração principal da infraestrutura
│   ├── terraform/              # Código Terraform
│   │   ├── providers.tf        # Configuração de providers e backend
│   │   ├── variables.tf        # Variáveis do Terraform
│   │   ├── network.tf          # VPC, subnets, NAT Gateways
│   │   ├── security_groups.tf  # Security Groups
│   │   ├── ec2.tf              # Instâncias EC2 e RDS
│   │   ├── outputs.tf          # Outputs do Terraform
│   │   ├── user_data_*.sh.tpl  # Scripts de inicialização
│   │   └── terraform.tfvars.example  # Exemplo de variáveis
│   │
│   ├── docker-compose.*.yml    # Docker Compose para backend/frontend/DB
│   ├── dockerfiles/            # Dockerfiles customizados
│   ├── nginx/                  # Configurações do Nginx
│   ├── setup-aws-*.sh          # Scripts de setup das instâncias
│   └── bd/                     # Scripts de banco de dados
│
└── .github/
    └── workflows/
        └── terraform-ci.yml    # CI/CD para Terraform
```

## 🛠️ Tecnologias Utilizadas

### Infraestrutura
- **Terraform** - Infrastructure as Code
- **AWS EC2** - Instâncias de computação
- **AWS VPC** - Rede virtual privada
- **AWS RDS** - Banco de dados MySQL gerenciado
- **AWS S3** - Armazenamento de state do Terraform
- **Elastic IPs** - IPs públicos fixos

### Containerização
- **Docker** - Containerização de aplicações
- **Docker Compose** - Orquestração de containers

### Proxy e Balanceamento
- **Nginx** - Proxy reverso e balanceamento de carga

### CI/CD
- **GitHub Actions** - Automação de pipelines
- **Terraform Cloud/CLI** - Execução automatizada

## 📖 Guia Detalhado

### 1. Configuração Inicial

#### 1.1. Configurar AWS CLI

```bash
aws configure
# AWS Access Key ID: [sua-access-key]
# AWS Secret Access Key: [sua-secret-key]
# Default region name: us-east-1
# Default output format: json
```

#### 1.2. Criar Key Pair na AWS

```bash
# Via AWS Console ou CLI
aws ec2 create-key-pair --key-name key-teiko --query 'KeyMaterial' --output text > key-teiko.pem
chmod 400 key-teiko.pem
```

#### 1.3. Criar Bucket S3 para State

```bash
aws s3 mb s3://teiko-bucket-pj --region us-east-1
aws s3api put-bucket-versioning --bucket teiko-bucket-pj --versioning-configuration Status=Enabled
```

### 2. Configuração do Terraform

#### 2.1. Variáveis do Terraform

Crie um arquivo `terraform.tfvars` na pasta `aws-ec2/terraform/`:

```hcl
# Região AWS
aws_region = "us-east-1"
azs        = ["us-east-1a", "us-east-1b"]

# Nome do projeto
project_name = "teiko"
environment  = "lab"

# Key Pair
key_name = "key-teiko"

# Segurança
public_ssh_cidr = "0.0.0.0/0"  # Restrinja para seu IP em produção

# Banco de dados
db_name     = "teiko"
db_username = "teiko"
db_password = "senha_segura_aqui"  # NÃO commitar

# JWT compartilhado (mesmo em todas as instâncias privadas)
shared_jwt = "segredo_jwt_muito_forte_aqui"  # NÃO commitar

# S3
aws_s3_bucket_name = "teiko-bucket-pj"

# Tipos de instância (opcional)
instance_type_public  = "t3.small"
instance_type_private = "t3.medium"
instance_type_db      = "db.t3.micro"
```

**⚠️ IMPORTANTE:** O arquivo `terraform.tfvars` contém informações sensíveis e **NÃO deve ser commitado** no Git.

#### 2.2. Backend do Terraform

O backend está configurado em `providers.tf` para usar S3:

```hcl
backend "s3" {
  bucket = "teiko-bucket-pj"
  key    = "aws-ec2/terraform.tfstate"
  region = "us-east-1"
}
```

### 3. Provisionamento da Infraestrutura

#### 3.1. Inicializar Terraform

```bash
cd infra/aws-ec2/terraform
terraform init
```

#### 3.2. Planejar Mudanças

```bash
terraform plan
```

#### 3.3. Aplicar Infraestrutura

```bash
terraform apply
```

Confirme quando solicitado. O processo pode levar 10-15 minutos.

#### 3.4. Verificar Outputs

```bash
# IPs públicos das instâncias públicas (frontend)
terraform output public_instance_public_ips

# IPs privados das instâncias privadas (backend)
terraform output private_instance_private_ips

# Endpoint do RDS
terraform output db_endpoint
```

### 4. Recursos Criados

#### 4.1. Rede (VPC)

- **VPC**: `10.0.0.0/16`
- **Subnets Públicas**: 
  - `10.0.0.0/24` (us-east-1a)
  - `10.0.1.0/24` (us-east-1b)
- **Subnets Privadas**:
  - `10.0.2.0/24` (us-east-1a)
  - `10.0.3.0/24` (us-east-1b)
- **Internet Gateway**: Para acesso público
- **NAT Gateways**: Um por AZ para acesso à internet das instâncias privadas

#### 4.2. Instâncias EC2

- **2 EC2 Públicas** (t3.small):
  - Frontend React/Vite
  - Nginx como proxy reverso
  - Elastic IPs fixos
  
- **2 EC2 Privadas** (t3.medium):
  - Backend Spring Boot
  - RabbitMQ
  - Redis

#### 4.3. Banco de Dados

- **RDS MySQL 8.0** (db.t3.micro):
  - Acessível apenas pelas instâncias privadas
  - Storage: 20GB (auto-scaling até 100GB)
  - Backup diário habilitado

#### 4.4. Security Groups

- **Public SG**: HTTP (80), SSH (22)
- **Private SG**: Backend (8080), RabbitMQ (5672, 15672), SSH (22)
- **DB SG**: MySQL (3306) apenas a partir das privadas

### 5. User Data e Setup Automático

As instâncias EC2 executam automaticamente scripts de inicialização:

- **Públicas**: `user_data_public.sh.tpl` → executa `setup-aws-public.sh`
- **Privadas**: `user_data_private.sh.tpl` → executa `setup-aws-private.sh`

Esses scripts:
- Instalam Docker e Docker Compose
- Clonam o repositório `infra`
- Configuram variáveis de ambiente
- Sobe os containers via Docker Compose

## 🔄 CI/CD

### Visão Geral do CI/CD

O projeto utiliza **GitHub Actions** para automação de CI/CD:

1. **CI (Continuous Integration)**: Executado automaticamente em push/PR
2. **CD (Continuous Deployment)**: Executado manualmente via GitHub Actions

### Fluxo de CI

O CI é executado automaticamente nos repositórios `backend` e `frontend`:

#### Backend CI
- Roda testes (`mvn test`)
- Builda JAR do Spring Boot
- Builda imagem Docker
- Push da imagem para registry (se merge em `main-teiko`)

#### Frontend CI
- Instala dependências (`npm ci`)
- Builda aplicação (`npm run build`)
- Builda imagem Docker
- Push da imagem para registry (se merge em `main-teiko`)

### Fluxo de CD

O CD é **manual** e executado via GitHub Actions:

#### Deploy Backend para EC2

1. Conecta via SSH em uma instância pública (bastion)
2. Atualiza o repositório `infra` no bastion
3. Para cada instância privada:
   - Conecta via SSH usando o bastion como proxy
   - Exporta variáveis de ambiente
   - Executa `setup-aws-private.sh`
   - Sobe/atualiza containers do backend

**Secrets necessários no GitHub (`backend`):**
- `BASTION_HOSTS` - IPs públicos das EC2 públicas
- `BASTION_SSH_KEY` - Chave SSH privada
- `BACKEND_PRIVATE_HOSTS` - IPs privados das EC2 privadas
- `DB_HOST` - Endpoint do RDS
- `DB_USERNAME`, `DB_PASSWORD` - Credenciais do banco
- `SHARED_JWT` - Segredo JWT compartilhado
- `AWS_S3_BUCKET_NAME`, `AWS_REGION` - Configurações S3
- `REGISTRY_USERNAME`, `REGISTRY_TOKEN` - Credenciais Docker Registry

#### Deploy Frontend para EC2

1. Conecta diretamente nas EC2 públicas
2. Atualiza o repositório `infra`
3. Configura `.env.frontend` com `API_UPSTREAMS`
4. Executa `setup-aws-public.sh`
5. Sobe/atualiza containers do frontend

**Secrets necessários no GitHub (`frontend`):**
- `FRONTEND_EC2_HOSTS` - IPs públicos das EC2 públicas
- `FRONTEND_EC2_SSH_KEY` - Chave SSH privada
- `API_UPSTREAMS` - Lista de backends (ex: `10.0.2.34:8080,10.0.3.9:8080`)
- `REGISTRY_USERNAME`, `REGISTRY_TOKEN` - Credenciais Docker Registry

### Workflow Prático

1. **Desenvolvimento**: Fazer alterações e abrir PR
2. **CI Automático**: GitHub Actions roda testes e build
3. **Merge**: Após aprovação, merge na `main-teiko`
4. **CI Final**: Builda e publica imagens Docker
5. **CD Manual**: Executar workflows de deploy no GitHub Actions
6. **Validação**: Testar aplicação nos IPs públicos

### Terraform CI

O repositório `infra` também possui CI para Terraform (`.github/workflows/terraform-ci.yml`):

- Valida sintaxe do Terraform
- Executa `terraform fmt --check`
- Executa `terraform plan` (não aplica automaticamente)

## 🔐 Secrets e Variáveis de Ambiente

### Secrets do GitHub

#### Backend Repository

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `BASTION_HOSTS` | IPs públicos das EC2 públicas | `54.123.45.67,98.76.54.32` |
| `BASTION_SSH_KEY` | Conteúdo do arquivo `.pem` | `-----BEGIN PRIVATE KEY-----...` |
| `BACKEND_PRIVATE_HOSTS` | IPs privados das EC2 privadas | `10.0.2.34,10.0.3.9` |
| `DB_HOST` | Endpoint do RDS | `teiko-db.xxx.rds.amazonaws.com` |
| `DB_USERNAME` | Usuário do banco | `teiko` |
| `DB_PASSWORD` | Senha do banco | `senha_segura` |
| `SHARED_JWT` | Segredo JWT (mesmo em todas) | `segredo_forte_32_chars+` |
| `AWS_S3_BUCKET_NAME` | Nome do bucket S3 | `teiko-bucket-pj` |
| `AWS_REGION` | Região AWS | `us-east-1` |
| `REGISTRY_USERNAME` | Usuário Docker Registry | `teiko` |
| `REGISTRY_TOKEN` | Token Docker Registry | `token_aqui` |

#### Frontend Repository

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `FRONTEND_EC2_HOSTS` | IPs públicos das EC2 públicas | `54.123.45.67,98.76.54.32` |
| `FRONTEND_EC2_SSH_KEY` | Conteúdo do arquivo `.pem` | `-----BEGIN PRIVATE KEY-----...` |
| `API_UPSTREAMS` | Lista de backends | `10.0.2.34:8080,10.0.3.9:8080` |
| `REGISTRY_USERNAME` | Usuário Docker Registry | `teiko` |
| `REGISTRY_TOKEN` | Token Docker Registry | `token_aqui` |

### Variáveis de Ambiente nas Instâncias

As instâncias EC2 usam variáveis de ambiente configuradas via scripts de setup:

**Backend (Privadas):**
```bash
DB_URL=jdbc:mysql://[RDS_ENDPOINT]:3306/teiko
DB_USERNAME=teiko
DB_PASSWORD=senha_segura
JWT_SECRET=segredo_jwt_compartilhado
AWS_S3_BUCKET_NAME=teiko-bucket-pj
AWS_REGION=us-east-1
REDIS_HOST=localhost
RABBITMQ_HOST=localhost
```

**Frontend (Públicas):**
```bash
API_UPSTREAMS=10.0.2.34:8080,10.0.3.9:8080
```

## 🧪 Validação e Testes

### Verificar Saúde da Infraestrutura

```bash
# Health check da API via proxy
curl http://[IP_PUBLICO]/api/actuator/health

# Health check direto no backend (via bastion)
ssh -i key-teiko.pem ubuntu@[IP_PUBLICO]
ssh ubuntu@[IP_PRIVADO]
curl http://localhost:8080/actuator/health
```

### Verificar Containers

```bash
# Nas instâncias públicas
sudo docker ps
sudo docker logs teiko-frontend

# Nas instâncias privadas
sudo docker ps
sudo docker logs teiko-backend
sudo docker logs teiko-mysql
sudo docker logs teiko-rabbitmq
```

### Testes Fim a Fim

1. Acessar `http://[IP_PUBLICO]/` no navegador
2. Verificar se a página inicial carrega
3. Testar login
4. Testar fluxo de pedido (Bolo e Fornada)
5. Verificar dashboard administrativo

## 🔧 Operação e Manutenção

### Atualizar Infraestrutura

```bash
cd infra/aws-ec2/terraform
terraform plan
terraform apply
```

### Destruir Infraestrutura

⚠️ **CUIDADO**: Isso apagará todos os recursos!

```bash
terraform destroy
```

### Atualizar Aplicações

Use os workflows de CD no GitHub Actions ou execute manualmente:

```bash
# Nas instâncias privadas
cd /opt/teiko/infra/aws-ec2
sudo docker compose -f docker-compose.backend.yml pull
sudo docker compose -f docker-compose.backend.yml up -d

# Nas instâncias públicas
cd /opt/teiko/infra/aws-ec2
sudo docker compose -f docker-compose.frontend.yml pull
sudo docker compose -f docker-compose.frontend.yml up -d
```

### Logs e Monitoramento

```bash
# Logs do backend
sudo docker logs -f teiko-backend

# Logs do frontend
sudo docker logs -f teiko-frontend

# Logs do banco
sudo docker logs -f teiko-mysql

# Espaço em disco
df -h
sudo docker system df
```

## 🐛 Troubleshooting

### Problema: Terraform não consegue acessar S3

**Solução**: Verifique se o bucket existe e as credenciais AWS estão configuradas:
```bash
aws s3 ls s3://teiko-bucket-pj
aws configure list
```

### Problema: Instâncias não conseguem acessar internet

**Solução**: Verifique NAT Gateways e route tables:
```bash
# Nas instâncias privadas
curl https://api.ipify.org
```

### Problema: Backend não consegue conectar ao RDS

**Solução**: Verifique Security Group do RDS e endpoint:
```bash
# Verificar endpoint
terraform output db_endpoint

# Testar conectividade (nas privadas)
telnet [RDS_ENDPOINT] 3306
```

### Problema: Frontend retorna 502 Bad Gateway

**Solução**: Verifique `API_UPSTREAMS` e conectividade:
```bash
# Verificar configuração
cat /opt/teiko/infra/aws-ec2/.env.frontend

# Testar conectividade
curl http://[IP_PRIVADO]:8080/actuator/health
```

### Problema: IPs mudaram após recriar instâncias

**Solução**: Atualize os secrets no GitHub:
1. Execute `terraform output` para obter novos IPs
2. Atualize `BASTION_HOSTS`, `FRONTEND_EC2_HOSTS`, `BACKEND_PRIVATE_HOSTS`
3. Atualize `API_UPSTREAMS` com novos IPs privados
4. Execute workflows de deploy novamente

## 📚 Documentação Adicional

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 📝 Notas Importantes

- ⚠️ **Nunca commite** arquivos `terraform.tfvars` ou chaves `.pem`
- ⚠️ **Elastic IPs** são fixos, mas custam quando não estão associados
- ⚠️ **NAT Gateways** têm custo por hora e por GB transferido
- ⚠️ **RDS** tem custo mesmo quando parado (exceto se usar snapshot)
- ✅ Use **tags** consistentes para facilitar gerenciamento de custos
- ✅ Monitore custos regularmente no AWS Cost Explorer

## 🤝 Contribuição

Para contribuir com a infraestrutura:

1. Faça fork do repositório
2. Crie uma branch para sua feature
3. Teste localmente com `terraform plan`
4. Abra um Pull Request
5. Aguarde revisão e aprovação

---

**Desenvolvido como parte do projeto Teiko - 3º semestre SPTech**

