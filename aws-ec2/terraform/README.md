## Terraform - AWS EC2 (Teiko)

Infraestrutura para recriar o ambiente AWS descrito neste diretório:

- VPC própria (`10.0.0.0/16`) com:
  - 2 subnets **públicas** (1 por AZ).
  - 2 subnets **privadas** (1 por AZ).
  - **Internet Gateway** e **NAT Gateway por AZ**.
- 4 instâncias EC2:
  - 2 **privadas** (backend + MySQL + RabbitMQ via `docker-compose.backend.yml`).
  - 2 **públicas** (frontend + Nginx fazendo proxy round-robin via `API_UPSTREAMS`).
- Cada EC2 executa, via `user_data`, os scripts já existentes:
  - Privadas: `setup-aws-private.sh`
  - Públicas: `setup-aws-public.sh`

### Como usar

1. Instale Terraform (>= 1.5) na sua máquina.
2. Configure as credenciais AWS (perfil ou variáveis de ambiente) apontando para a **conta do lab**.
3. Dentro de `infra/aws-ec2/terraform`, crie um arquivo `terraform.tfvars` (não commitar) com, no mínimo:

```hcl
aws_region  = "us-east-1"
azs         = ["us-east-1a", "us-east-1b"]
key_name    = "key-carambolos" # nome do key pair da conta
shared_jwt  = "COLOQUE_UM_SEGREDO_FORTE_AQUI"

# Opcional/Exemplo:
# public_ssh_cidr = "SEU_IP/32"
# azure_storage_connection_string = "..."
# azure_storage_container_name    = "teiko-s3"
```

4. No mesmo diretório, rode:

```bash
terraform init
terraform apply
```

5. Ao final do `apply`, verifique os outputs:

```bash
terraform output public_instance_public_ips
terraform output private_instance_private_ips
```

Os IPs públicos devem responder em `http://IP_PUBLICO/` (frontend) e `http://IP_PUBLICO/api/actuator/health`.  
Os IPs privados das instâncias privadas serão usados automaticamente pelos scripts nas públicas, via `API_UPSTREAMS`.


