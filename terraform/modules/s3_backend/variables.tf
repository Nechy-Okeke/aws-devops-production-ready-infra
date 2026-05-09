variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "state_bucket_name" {
  type        = string
  description = "Deterministic S3 bucket name to store Terraform state."
}

variable "lock_table_name" {
  type        = string
  description = "Deterministic DynamoDB table name used for Terraform state locking."
}
