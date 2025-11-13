# CloudWatch Log Group para logs da aplicação
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# CloudWatch Alarm - CPU alta
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-cpu-utilization-high"
  alarm_description   = "Alerta quando CPU ultrapassa 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = {
    Name = "${var.project_name}-alarm-cpu"
  }
}

# CloudWatch Alarm - Memória alta
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-memory-utilization-high"
  alarm_description   = "Alerta quando memória ultrapassa 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = {
    Name = "${var.project_name}-alarm-memory"
  }
}

# CloudWatch Alarm - Target unhealthy
resource "aws_cloudwatch_metric_alarm" "target_unhealthy" {
  alarm_name          = "${var.project_name}-target-unhealthy"
  alarm_description   = "Alerta quando target está unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    TargetGroup  = aws_lb_target_group.main.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alarm-unhealthy"
  }
}

