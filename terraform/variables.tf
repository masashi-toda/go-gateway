variable "profile" {}
variable "region" {}

# The application's name
variable "app" {}
# The application's group name
variable "group" {}
# The environment that is being built
variable "environment" {}

variable "owner" {}

variable "aws_az" {
  type = list(string)
}

# The vpc name
variable "vpc_name" {}

# The vpc cidr
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# The public subnets, minimum of 2, that are a part of the VPC(s)
variable "aws_subnet_public" {
  type = list(string)
}

# The ecs cluster name
variable "app_ecs_cluster_name" {}
# The ecr repository name
variable "app_ecr_name" {}
