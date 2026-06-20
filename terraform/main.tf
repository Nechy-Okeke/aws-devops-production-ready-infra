terraform {
  backend "s3" {
    bucket         = "aws-devops-production-ready-infra-tfstate-669890779296"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-devops-production-ready-infra-tflock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
  }
}

# Root module wiring

locals {
  # AWS ALB/TG name limit is 32 chars. Keep a short deterministic prefix.
  name_prefix = substr(var.project_name, 0, 24)
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  container_port = var.container_port
  desired_count  = var.desired_count
  ecs_cpu         = var.ecs_cpu
  ecs_memory      = var.ecs_memory

  ecr_repository_url = module.ecr.repository_url
  ecr_image_tag      = var.ecr_image_tag

  alb_target_group_arn   = module.alb.target_group_arn
  alb_security_group_id   = module.alb.alb_security_group_id

  app_environment = var.app_environment
}

module "alb" {
  source = "./modules/alb"

  project_name = var.project_name
  name_prefix  = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  listener_port      = var.alb_listener_port

  # Link ALB to ECS service via target group attachment
  ecs_service_name = module.ecs.ecs_service_name
  ecs_container_name = module.ecs.ecs_container_name
  container_port = var.container_port
}
