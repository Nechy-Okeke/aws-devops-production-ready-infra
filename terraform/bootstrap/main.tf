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

# Bootstrap resources intentionally removed.
#
# Production-grade approach:
# - create the remote-state S3 bucket + DynamoDB lock table ONCE (manually or via a dedicated bootstrap run)
# - keep the main infrastructure project focused on real infrastructure modules
#
# This CI job now runs a no-op plan/apply (ensures pipeline steps still succeed without trying to recreate backend state).
