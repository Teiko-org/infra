terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto em S3 para guardar o state do Terraform.
  # IMPORTANTE: o bucket precisa existir antes de rodar `terraform init`.
  backend "s3" {
    bucket = "teiko-bucket-pj"
    key    = "aws-ec2/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  # Opcional: use um profile local (ex: "teiko-lab") se quiser.
  # profile = var.aws_profile
}


