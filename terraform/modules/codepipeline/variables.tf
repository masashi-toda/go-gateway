###############################
# Global
###############################

variable "name_prefix" {}

variable "tags" {
  default = {}
}

variable "environments" {
  default = {}
}

###############################
# CodeCommit
###############################

variable "git_repository_name" {}

###############################
# CodeBuild
###############################

variable "container_name" {}

variable "container_port" {}

variable "task_definition_arn" {}

variable "repository_name" {}

###############################
# CodeDeploy
###############################

variable "ecs_cluster_name" {}

variable "ecs_service_name" {}

variable "lb_listener_arn" {}
variable "lb_target_group_1" {}
variable "lb_target_group_2" {}
