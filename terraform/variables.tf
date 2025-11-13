variable "aws_region" {
  description = "AWS region para provisionar recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "token-service"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block para VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones para ALB (mínimo 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ecs_availability_zone" {
  description = "Availability Zone para ECS tasks (single AZ)"
  type        = string
  default     = "us-east-1a"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "container_port" {
  description = "Porta do container"
  type        = number
  default     = 4000
}

variable "container_cpu" {
  description = "CPU do container (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memória do container em MB"
  type        = number
  default     = 512
}

variable "app_count" {
  description = "Número de tasks do ECS"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "Path do health check"
  type        = string
  default     = "/health"
}

variable "ecr_image_tag" {
  description = "Tag da imagem Docker no ECR"
  type        = string
  default     = "latest"
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs no CloudWatch"
  type        = number
  default     = 7
}

