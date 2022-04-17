###############################
# Global
###############################

variable name_prefix {}

variable tags {
  default = {}
}

variable "vpc_id" {}

###############################
# NLB
###############################

variable "subnets" {
  type    = list(string)
}

variable "internal" {
  type = bool
}

###############################
# Target Group
###############################

variable "target_alb_arn" {
  type = string
}

variable "health_check_path" {
  default = "/health"
}
