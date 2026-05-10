terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
  }

  # Terraform state backend:
  # Uses S3 for state storage + DynamoDB for state locking.
  # NOTE: backend "s3" configuration cannot accept variables.
  # Point directly at your already-bootstrapped bucket/table.
  backend "s3" {
    bucket         = "aws-devops-production-ready-infra-tfstate-669890779296"
    key            = "terraform/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "aws-devops-production-ready-infra-tflock"
  }
}

provider "aws" {
  region = var.aws_region
}
