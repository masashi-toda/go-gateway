variable "app_name" {}

variable "vpc_id" {}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "front_alb_cidr" {
  type    = list(string)
}

###################################
## AWS ECR Repository Variables
###################################

variable "app_ecs_cluster_name" {}

variable "app_ecr_repo_name" {}

variable "firelens_repo_name" {}

variable "firelens_tag" {
  default = "1.0"
}

###################################
## AWS ECS Container Variables
###################################

variable "app_container_port" {
  default = 8080
}

variable "app_container_cpu" {
  type    = number
  default = 256 # 0.25 vCPU
}

variable "app_container_memory" {
  type    = number
  default = 512 # 0.5 GB
}

variable "app_container_desired_count" {
  type    = number
  default = 1
}

###################################
## Application Variables
###################################

variable "app_environment" {
  type    = map(string)
  default = {}
}
