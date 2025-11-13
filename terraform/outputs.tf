output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
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

