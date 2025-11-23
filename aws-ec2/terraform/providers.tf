terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend local por padrão.
  # Se quiser migrar para S3 + DynamoDB depois, ajuste este bloco e faça um
  # `terraform init -migrate-state`.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  # Opcional: use um profile local (ex: "teiko-lab") se quiser.
  # profile = var.aws_profile
}


