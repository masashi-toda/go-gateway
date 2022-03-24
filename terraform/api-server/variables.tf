variable "group" {}
variable "app" {}
variable "environment" {}

variable "owner" {}

variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "app_ecs_cluster_name" {}
variable "app_ecr_name" {}

variable "aws_subnet_public" {
  type = list(string)
}
