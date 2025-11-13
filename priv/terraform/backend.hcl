# Configuração do backend S3
# Usado por GitHub Actions e (se necessário) runs locais
bucket  = "token-service-terraform-state"
key     = "prod/terraform.tfstate"
region  = "us-east-1"
encrypt = true

