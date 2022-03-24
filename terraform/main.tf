terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

data "aws_availability_zones" "available" {
}

locals {
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs            = data.aws_availability_zones.available.names
  public_subnets = var.aws_subnet_public

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
  source               = "./api-server"
  group                = var.group
  app                  = var.app
  environment          = var.environment
  owner                = var.owner
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnets
  aws_subnet_public    = var.aws_subnet_public
  app_ecs_cluster_name = var.app_ecs_cluster_name
  app_ecr_name         = var.app_ecr_name
}
