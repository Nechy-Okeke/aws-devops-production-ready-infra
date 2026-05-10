variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ECS tasks"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL"
}

variable "ecr_image_tag" {
  type        = string
  description = "Image tag to deploy"
}

variable "container_port" {
  type        = number
  description = "Container port"
}

variable "desired_count" {
  type        = number
  description = "ECS desired count"
}

variable "ecs_cpu" {
  type        = number
  description = "ECS task CPU units"
}

variable "ecs_memory" {
  type        = number
  description = "ECS task memory"
}

variable "alb_target_group_arn" {
  type        = string
  description = "ALB target group ARN to attach ECS service"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID of the ALB (used to restrict inbound to ECS tasks only from ALB)"
}

variable "app_environment" {
  type        = map(string)
  description = "Environment variables passed to container"
}
