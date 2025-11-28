variable "aws_region" {
  description = "Região AWS onde o ambiente será criado."
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "Lista de AZs usadas (duas AZs para públicas/privadas)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "project_name" {
  description = "Nome do projeto para tags."
  type        = string
  default     = "teiko"
}

variable "environment" {
  description = "Identificador do ambiente (ex: lab, dev, prod)."
  type        = string
  default     = "lab"
}

variable "instance_type_public" {
  description = "Tipo das instâncias públicas (frontend/proxy)."
  type        = string
  default     = "t3.small"
}

variable "instance_type_private" {
  description = "Tipo das instâncias privadas (backend)."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size_public" {
  description = "Tamanho (GB) do disco root das instâncias públicas."
  type        = number
  default     = 20
}

variable "root_volume_size_private" {
  description = "Tamanho (GB) do disco root das instâncias privadas."
  type        = number
  default     = 50
}

variable "instance_type_db" {
  description = "Tipo da instância dedicada ao banco de dados (MySQL/MariaDB)."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size_db" {
  description = "Tamanho (GB) do disco root da instância de banco de dados."
  type        = number
  default     = 50
}

variable "key_name" {
  description = "Nome do key pair já criado na conta AWS (ex: key-carambolos)."
  type        = string
  default     = "key-carambolos"
}

variable "public_ssh_cidr" {
  description = "CIDR liberado para SSH nas instâncias públicas."
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  description = "Nome do banco de dados padrão da aplicação."
  type        = string
  default     = "teiko"
}

variable "db_username" {
  description = "Usuário do banco de dados padrão da aplicação."
  type        = string
  default     = "teiko"
}

variable "db_password" {
  description = "Senha do banco de dados padrão da aplicação."
  type        = string
  default     = "teiko123"
  sensitive   = true
}

variable "shared_jwt" {
  description = "Segredo JWT compartilhado entre todas as privadas (não commitar em git)."
  type        = string
  sensitive   = true
}

variable "azure_storage_connection_string" {
  description = "Connection string do Azure Storage usada pelo backend."
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_storage_container_name" {
  description = "Nome do container do Azure Storage usado pelo backend."
  type        = string
  default     = "teiko-s3"
}


