variable "project_name" {
  type        = string
  description = "Project name prefix (may be longer than AWS 32-char limits; avoid using for strict name resources)"
}

variable "name_prefix" {
  type        = string
  description = "Short deterministic prefix (<= 24 chars recommended) for resources with strict name limits (ALB/TG/Security Group)."
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

variable "acm_certificate_domain_name" {
  type        = string
  description = "Placeholder domain name used to request an ACM certificate. Replace/validate with a real domain in production."
  default     = "example.com"
}

variable "acm_certificate_validation_method" {
  type        = string
  description = "ACM validation method."
  default     = "DNS"
}

variable "acm_route53_zone_id" {
  type        = string
  description = "Optional Route53 hosted zone ID to perform DNS validation for ACM. If not set, HTTPS listener/certificate will be omitted (HTTP redirect remains)."
  default     = ""
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, protects the ALB from deletion (may block CI/CD destroy). Set false for re-runnable CI/CD."
  default     = false
}
