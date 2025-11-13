#!/bin/bash
set -euo pipefail

REGION="us-east-1"

ALB_NAME="token-service-alb"
TG_NAME="token-service-tg"
LOG_GROUP="/ecs/token-service"
ECR_REPO="token-service"
IAM_ROLES=(
  "token-service-ecs-task-execution-role"
  "token-service-ecs-task-role"
)
ECS_CLUSTER="token-service-cluster"
ECS_SERVICE="token-service-service"

header() {
  echo "\n=============================="
  echo "$1"
  echo "=============================="
}

info() {
  echo "[info] $1"
}

warn() {
  echo "[warn] $1"
}

delete_alb() {
  header "Deleting Application Load Balancer"
  if LB_JSON=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --region "$REGION" 2>/dev/null); then
    LB_ARN=$(echo "$LB_JSON" | jq -r '.LoadBalancers[0].LoadBalancerArn')
    info "Deleting ALB $ALB_NAME ($LB_ARN)"
    aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region "$REGION"
    info "Waiting for ALB deletion..."
    aws elbv2 wait load-balancers-deleted --load-balancer-arns "$LB_ARN" --region "$REGION"
    info "ALB deleted"
  else
    warn "ALB $ALB_NAME not found, skipping"
  fi
}

delete_target_group() {
  header "Deleting Target Group"
  if TG_JSON=$(aws elbv2 describe-target-groups --names "$TG_NAME" --region "$REGION" 2>/dev/null); then
    TG_ARN=$(echo "$TG_JSON" | jq -r '.TargetGroups[0].TargetGroupArn')
    info "Deleting Target Group $TG_NAME ($TG_ARN)"
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$REGION"
    info "Target Group deleted"
  else
    warn "Target Group $TG_NAME not found, skipping"
  fi
}

delete_log_group() {
  header "Deleting CloudWatch Log Group"
  if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" | jq -e ".logGroups[] | select(.logGroupName == \"$LOG_GROUP\")" >/dev/null; then
    info "Deleting log group $LOG_GROUP"
    aws logs delete-log-group --log-group-name "$LOG_GROUP" --region "$REGION"
    info "Log group deleted"
  else
    warn "Log group $LOG_GROUP not found, skipping"
  fi
}

delete_ecs_service() {
  header "Deleting ECS Service"
  if aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --region "$REGION" | jq -e '.services[0].status' >/dev/null 2>&1; then
    STATUS=$(aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --region "$REGION" | jq -r '.services[0].status')
    if [ "$STATUS" != "INACTIVE" ]; then
      info "Updating desired count to 0 for service $ECS_SERVICE"
      aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --desired-count 0 --region "$REGION" >/dev/null
      info "Waiting for service to scale down..."
      aws ecs wait services-stable --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --region "$REGION"
      info "Deleting ECS service $ECS_SERVICE"
      aws ecs delete-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force --region "$REGION"
      info "Waiting for service deletion..."
      aws ecs wait services-inactive --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --region "$REGION"
      info "Service deleted"
    else
      warn "Service $ECS_SERVICE already inactive"
    fi
  else
    warn "ECS service $ECS_SERVICE not found, skipping"
  fi
}

delete_ecs_cluster() {
  header "Deleting ECS Cluster"
  if aws ecs describe-clusters --clusters "$ECS_CLUSTER" --region "$REGION" | jq -e '.clusters[0].status' >/dev/null 2>&1; then
    STATUS=$(aws ecs describe-clusters --clusters "$ECS_CLUSTER" --region "$REGION" | jq -r '.clusters[0].status')
    if [ "$STATUS" != "INACTIVE" ]; then
      info "Deleting ECS cluster $ECS_CLUSTER"
      aws ecs delete-cluster --cluster "$ECS_CLUSTER" --region "$REGION" >/dev/null
      info "ECS cluster deleted"
    else
      warn "ECS cluster $ECS_CLUSTER already inactive"
    fi
  else
    warn "ECS cluster $ECS_CLUSTER not found, skipping"
  fi
}

delete_ecr_repo() {
  header "Deleting ECR Repository"
  if aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$REGION" >/dev/null 2>&1; then
    info "Deleting ECR repository $ECR_REPO"
    aws ecr delete-repository --repository-name "$ECR_REPO" --force --region "$REGION"
    info "ECR repository deleted"
  else
    warn "ECR repository $ECR_REPO not found, skipping"
  fi
}

delete_iam_roles() {
  header "Deleting IAM Roles"
  for ROLE in "${IAM_ROLES[@]}"; do
    if aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
      info "Processing IAM role $ROLE"

      # Detach managed policies
      ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE" | jq -r '.AttachedPolicies[].PolicyArn')
      for POLICY_ARN in $ATTACHED_POLICIES; do
        info " Detaching managed policy $POLICY_ARN"
        aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY_ARN"
      done

      # Delete inline policies
      INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE" | jq -r '.PolicyNames[]')
      for POLICY_NAME in $INLINE_POLICIES; do
        info " Deleting inline policy $POLICY_NAME"
        aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POLICY_NAME"
      done

      # Delete instance profiles referencing the role
      INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name "$ROLE" | jq -r '.InstanceProfiles[].InstanceProfileName')
      for PROFILE in $INSTANCE_PROFILES; do
        info " Removing role from instance profile $PROFILE"
        aws iam remove-role-from-instance-profile --role-name "$ROLE" --instance-profile-name "$PROFILE"
        info " Deleting instance profile $PROFILE"
        aws iam delete-instance-profile --instance-profile-name "$PROFILE"
      done

      info "Deleting role $ROLE"
      aws iam delete-role --role-name "$ROLE"
      info "Role $ROLE deleted"
    else
      warn "IAM role $ROLE not found, skipping"
    fi
  done
}

main() {
  command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed"; exit 1; }
  command -v aws >/dev/null 2>&1 || { echo "aws CLI is required but not installed"; exit 1; }

  delete_alb
  delete_target_group
  delete_log_group
  delete_ecr_repo
  delete_iam_roles
  delete_ecs_service
  delete_ecs_cluster

  echo "\nCleanup complete. You can re-run the Terraform apply now."
}

main "$@"
