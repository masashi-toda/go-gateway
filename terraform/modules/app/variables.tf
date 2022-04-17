###############################
# Global
###############################

variable "tags" {
  default = {}
}

variable "environments" {
  default = {}
}

variable "vpc_id" {}

###############################
# ECS
###############################

variable "container_name" {}

###############################
# ECS Task
###############################

variable "container_port" {
  type    = number
  default = 8080
}

variable "container_cpu" {
  type    = number
  default = 256 # 0.25 vCPU
}

variable "container_memory" {
  type    = number
  default = 512 # 0.5 GB
}

###############################
# ECS Service
###############################

variable "container_desired_count" {
  type    = number
  default = 1
}

variable "subnets" {
  type = list(string)
}

variable "security_group_id" {}

variable "lb_target_group_arn" {}

###############################
# ECR
###############################

variable "repository_url" {}

variable "firelens_repository_url" {}

variable "firelens_tag" {}
