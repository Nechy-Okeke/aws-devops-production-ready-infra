# Root module wiring

module "s3_backend" {
  source = "./modules/s3_backend"

  project_name      = var.project_name
  state_bucket_name = var.state_bucket_name
  lock_table_name   = var.lock_table_name
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

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  listener_port      = var.alb_listener_port

  # Link ALB to ECS service via target group attachment
  ecs_service_name = module.ecs.ecs_service_name
  ecs_container_name = module.ecs.ecs_container_name
  container_port = var.container_port
}
