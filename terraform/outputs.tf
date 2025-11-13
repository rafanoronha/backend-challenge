output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "alb_security_group_id" {
  description = "ID do Security Group do ALB"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "ID do Security Group das ECS Tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_task_execution_role_arn" {
  description = "ARN da IAM Role para ECS Task Execution"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN da IAM Role para ECS Task"
  value       = aws_iam_role.ecs_task.arn
}

output "alb_dns_name" {
  description = "DNS público do Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL completa da aplicação"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_arn" {
  description = "ARN do Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN do Target Group"
  value       = aws_lb_target_group.main.arn
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_name" {
  description = "Nome do repositório ECR"
  value       = aws_ecr_repository.main.name
}

