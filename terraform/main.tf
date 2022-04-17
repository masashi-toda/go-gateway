terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.71.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

###############################
# VPC Module
###############################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.base_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.vpc_az_names
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
  }

  public_subnet_tags = {
  }

  private_subnet_tags = {
  }
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

###############################
# NLB Module
###############################

module "nlb" {
  source = "./modules/nlb"

  name_prefix = local.base_name
  tags        = local.tags

  // nlb variables
  subnets  = module.vpc.public_subnets
  internal = false

  // target group variables
  vpc_id            = module.vpc.vpc_id
  target_alb_arn    = module.alb.arn
  health_check_path = "/health"

  depends_on = [
    module.alb
  ]
}

###############################
# ALB Module
###############################

module "alb" {
  source = "./modules/alb"

  name_prefix = local.base_name
  tags        = local.tags

  // alb variables
  subnets  = module.vpc.private_subnets
  internal = true

  // target group variables
  vpc_id            = module.vpc.vpc_id
  target_port       = var.container_port
  health_check_path = "/health"

  // security group
  ingress_cidr_blocks = var.alb_ingress_cidr_blocks
}

###############################
# ECR Module
###############################

module "ecr" {
  source = "./modules/ecr"

  repository_name          = "${var.group}/${var.app}-${var.env}"
  firelens_repository_name = "${var.group}/firelens-${var.env}"
  firelens_tag             = "1.0"
}

###############################
# Application Module
###############################

module "app" {
  source = "./modules/app"

  vpc_id       = module.vpc.vpc_id
  tags         = local.tags
  environments = { ENV = var.env }

  // ecs task
  container_name          = local.base_name
  container_port          = var.container_port
  container_cpu           = var.container_cpu
  container_memory        = var.container_memory
  container_desired_count = var.container_desired_count

  // ecs service
  subnets             = module.vpc.private_subnets
  security_group_id   = module.alb.security_group_id
  lb_target_group_arn = module.alb.target_group_arn.blue

  // ecr
  repository_url          = module.ecr.repository_url
  firelens_repository_url = module.ecr.firelens_repository_url
  firelens_tag            = "1.0"

  depends_on = [
    module.alb,
    module.ecr
  ]
}

###############################
# CodePipeline Module
###############################

module "codepipeline" {
  source = "./modules/codepipeline"

  name_prefix  = local.base_name
  tags         = local.tags
  environments = { ENV = var.env }

  // codecommit
  git_repository_name = var.git_repository_name

  // codebuild
  container_name      = module.app.container_name
  container_port      = module.app.container_port
  task_definition_arn = module.app.task_definition_arn
  repository_name     = module.ecr.repository_name

  // codepipeline
  ecs_cluster_name  = module.app.cluster_name
  ecs_service_name  = module.app.service_name
  lb_listener_arn   = module.alb.listener_arn
  lb_target_group_1 = module.alb.target_group_name.blue
  lb_target_group_2 = module.alb.target_group_name.green

  depends_on = [
    module.alb,
    module.ecr,
    module.app,
  ]
}
