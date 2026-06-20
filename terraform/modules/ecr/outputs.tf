output "repository_url" {
  description = "ECR repository URL"
  value       = try(aws_ecr_repository.this[0].repository_url, null)
}
