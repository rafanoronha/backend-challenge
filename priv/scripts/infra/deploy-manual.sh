#!/bin/bash
set -e

# Script para deploy manual (use GitHub Actions sempre que possível)
# Este script é útil apenas para debugging

echo "⚠️  ATENÇÃO: Use GitHub Actions para deploy sempre que possível!"
echo "   Este script bypassa o concurrency control do GitHub."
echo ""
read -p "Continuar mesmo assim? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# Verifica AWS CLI
if ! aws sts get-caller-identity &> /dev/null; then
  echo "❌ AWS CLI não está configurado"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_REPOSITORY="token-service"
ECS_CLUSTER="token-service-cluster"
ECS_SERVICE="token-service-service"
IMAGE_TAG=$(git rev-parse --short HEAD)

echo "🔧 Configurações:"
echo "  Account: $ACCOUNT_ID"
echo "  Region: $REGION"
echo "  Image tag: $IMAGE_TAG"
echo ""

# Login no ECR
echo "🔐 Login no ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build da imagem
echo "🐳 Building Docker image..."
cd "$(dirname "$0")/../../.."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag para ECR
ECR_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY"
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_IMAGE:$IMAGE_TAG
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_IMAGE:latest

# Push para ECR
echo "📤 Pushing to ECR..."
docker push $ECR_IMAGE:$IMAGE_TAG
docker push $ECR_IMAGE:latest

# Update ECS service
echo "🚀 Updating ECS service..."
aws ecs update-service \
  --cluster $ECS_CLUSTER \
  --service $ECS_SERVICE \
  --force-new-deployment \
  --region $REGION

echo ""
echo "✅ Deploy iniciado!"
echo ""
echo "Acompanhe o progresso:"
echo "  aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE"
echo ""

