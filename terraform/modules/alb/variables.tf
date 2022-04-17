###############################
# Global
###############################

variable "name_prefix" {}

variable "tags" {
  default = {}
}

variable "vpc_id" {}

###############################
# ALB
###############################

variable "subnets" {
  type = list(string)
}

variable "internal" {
  type = bool
}

###############################
# Target Group
###############################

variable "target_port" {
  type = number
}

variable "health_check_path" {
  default = "/health"
}

###############################
# Security Group
###############################

variable "ingress_cidr_blocks" {
  default = ["0.0.0.0/0"]
}
