terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

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

variable "state_bucket_suffix" {
  type        = string
  description = "Optional extra suffix to make bucket name globally unique (recommended for multi-user accounts)."
  default     = "bootstrap"
}

locals {
  state_bucket_name = "${var.project_name}-tfstate-${var.state_bucket_suffix}"
  lock_table_name   = "${var.project_name}-tf-lock-${var.state_bucket_suffix}"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket_name
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_lock_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}
