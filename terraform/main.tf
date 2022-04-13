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

data "aws_availability_zones" "available" {}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

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

# for test application, if necessary
module "ecr_api_server" {
  source          = "./api-server"
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  front_alb_cidr  = var.front_alb_cidr
  tags = merge(
    var.additional_tags,
    {
      group = var.group
      env   = var.environment
    }
  )

  app_name             = "${var.group}-${var.app}-${var.environment}"
  app_ecs_cluster_name = "${var.group}-${var.app}-ecs"
  app_ecr_repo_name    = "${var.group}/${var.app}"
  app_environment = {
    PORT = var.app_container_port
    ENV  = var.environment
  }
  app_container_port          = var.app_container_port
  app_container_cpu           = var.app_container_cpu
  app_container_memory        = var.app_container_memory
  app_container_desired_count = var.app_container_desired_count

  firelens_repo_name = "${var.group}/firelens"
  firelens_tag       = "1.0"
}
