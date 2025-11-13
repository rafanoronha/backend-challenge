terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 - configurado via backend.hcl
  # GitHub Actions usa: terraform init -backend-config=backend.hcl
  # IMPORTANTE: Sempre use GitHub Actions para apply (concurrency control)
  backend "s3" {
    # Configuração via backend.hcl (não hardcoded para segurança)
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

