#!/bin/bash
set -e

# Script para verificar status do deployment

REGION="us-east-1"
ECS_CLUSTER="token-service-cluster"
ECS_SERVICE="token-service-service"

echo "🔍 Verificando status do deployment..."
echo ""

# Status do serviço
echo "📊 ECS Service Status:"
aws ecs describe-services \
  --cluster $ECS_CLUSTER \
  --services $ECS_SERVICE \
  --region $REGION \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
  --output table

echo ""

# Tasks em execução
echo "📦 Running Tasks:"
TASK_ARNS=$(aws ecs list-tasks \
  --cluster $ECS_CLUSTER \
  --service-name $ECS_SERVICE \
  --region $REGION \
  --query 'taskArns[*]' \
  --output text)

if [ -z "$TASK_ARNS" ]; then
  echo "  Nenhuma task rodando"
else
  aws ecs describe-tasks \
    --cluster $ECS_CLUSTER \
    --tasks $TASK_ARNS \
    --region $REGION \
    --query 'tasks[*].{TaskId:taskArn,Status:lastStatus,Health:healthStatus,Started:startedAt}' \
    --output table
fi

echo ""

# URL da aplicação
cd "$(dirname "$0")/../../terraform"
if [ -f terraform.tfstate ] || terraform state list &> /dev/null; then
  echo "🌐 Application URL:"
  terraform output -raw alb_url 2>/dev/null || echo "  (Terraform state não encontrado)"
  echo ""
fi

echo ""
echo "📝 Comandos úteis:"
echo "  Ver logs: aws logs tail /ecs/token-service --follow --region $REGION"
echo "  Forçar deploy: aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment --region $REGION"
echo ""

