terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Terraform state backend:
  # Uses S3 for state storage + DynamoDB for state locking.
  # NOTE: backend "s3" configuration cannot accept variables.
  # Populate bucket/table/region/key by editing this file (or using -backend-config at init time).
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
