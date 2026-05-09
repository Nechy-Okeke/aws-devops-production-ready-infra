variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "listener_port" {
  type        = number
  description = "ALB listener port"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name (for wiring)"
}

variable "ecs_container_name" {
  type        = string
  description = "ECS task family/container identifier (not strictly needed but kept for clarity)"
}

variable "container_port" {
  type        = number
  description = "Container port"
}
