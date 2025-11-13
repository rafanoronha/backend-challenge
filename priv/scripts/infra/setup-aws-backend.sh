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

# Cria bucket S3 diretamente via AWS CLI
BUCKET_NAME="${PROJECT_NAME:-token-service}-terraform-state"
REGION="us-east-1"

echo "☁️  Criando bucket S3 para Terraform state..."

# Verifica se bucket já existe
if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
  echo "✅ Bucket já existe: $BUCKET_NAME"
else
  # Cria bucket
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    2>/dev/null || echo "⚠️  Erro ao criar bucket (pode já existir)"
  
  # Habilita versionamento
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
  
  # Habilita criptografia
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
  
  # Bloqueia acesso público
  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  
  echo "✅ Bucket criado e configurado: $BUCKET_NAME"
fi

# Inicializa terraform localmente (sem backend ainda)
echo "📦 Inicializando Terraform..."
terraform init

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

