variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name prefix for resources"
  default     = "metrics-health"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets"
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "container_port" {
  type        = number
  description = "Application container port"
  default     = 3000
}

variable "desired_count" {
  type        = number
  description = "ECS desired task count"
  default     = 1
}

variable "ecr_image_tag" {
  type        = string
  description = "ECR image tag to deploy"
  default     = "latest"
}

variable "ecs_cpu" {
  type        = number
  description = "ECS task CPU units"
  default     = 256
}

variable "ecs_memory" {
  type        = number
  description = "ECS task memory (MiB)"
  default     = 512
}

variable "app_environment" {
  type        = map(string)
  description = "Environment variables passed to the container"
  default = {
    PORT = "3000"
  }
}

variable "alb_listener_port" {
  type        = number
  description = "ALB listener port for HTTP"
  default     = 80
}

