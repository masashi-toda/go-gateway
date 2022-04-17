variable "aws_profile" {}

variable "aws_region" {}

###################################
## Global Variables
###################################

variable "group" {}

variable "app" {}

variable "env" {}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

###################################
## VPC Variables
###################################

variable "vpc_az_names" {
  type = list(string)
}

variable "vpc_cidr" {}

variable "vpc_public_subnets" {
  type = list(string)
}

variable "vpc_private_subnets" {
  type = list(string)
}

###################################
## ALB Variables
###################################

variable "alb_ingress_cidr_blocks" {
  type = list(string)
}

###################################
## AWS ECS Container Variables
###################################

variable "container_port" {}

variable "container_cpu" {
  type = number
}

variable "container_memory" {
  type = number
}

variable "container_desired_count" {
  type = number
}

###################################
## CodePipeline Variables
###################################

variable "git_repository_name" {}

###################################
## Local Variables
###################################

locals {
  base_name = "${var.group}-${var.app}-${var.env}"
  tags = merge(
    var.additional_tags,
    {
      group = var.group
      env   = var.env
    }
  )
}
