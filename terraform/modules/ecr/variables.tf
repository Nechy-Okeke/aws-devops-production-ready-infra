variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "force_delete_images" {
  type        = bool
  description = "When true, ECR repo can be destroyed even if images exist (useful for CI/CD re-runs)."
  default     = true
}
