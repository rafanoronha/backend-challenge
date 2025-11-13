#!/bin/bash
set -e

# Script para configurar backend S3 pela primeira vez
# Execute apenas uma vez antes do primeiro deploy

echo "🚀 Configurando backend S3 para Terraform state..."

# Verifica se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
  echo "❌ AWS CLI não está configurado. Execute: aws configure"
  exit 1
fi

echo "✅ AWS credentials válidas"

# Navega para diretório terraform
cd "$(dirname "$0")/../../terraform"

# Inicializa terraform localmente (sem backend ainda)
echo "📦 Inicializando Terraform..."
terraform init

# Provisiona apenas o bucket S3
echo "☁️  Criando bucket S3 para Terraform state..."
terraform apply -target=aws_s3_bucket.terraform_state \
                -target=aws_s3_bucket_versioning.terraform_state \
                -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                -target=aws_s3_bucket_public_access_block.terraform_state \
                -auto-approve

# Obtém nome do bucket
BUCKET_NAME=$(terraform output -raw terraform_state_bucket)
echo "✅ Bucket criado: $BUCKET_NAME"

# Reconfigura terraform para usar backend S3
echo "🔄 Migrando state local para S3..."
terraform init -backend-config=backend.hcl -migrate-state -force-copy

echo ""
echo "✅ Backend S3 configurado com sucesso!"
echo ""
echo "📝 Próximos passos:"
echo "  1. Commit e push das mudanças"
echo "  2. Configure secrets no GitHub:"
echo "     - AWS_ACCESS_KEY_ID"
echo "     - AWS_SECRET_ACCESS_KEY"
echo "  3. GitHub Actions fará o deploy automaticamente"
echo ""

