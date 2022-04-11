variable "aws_profile" {
  default = "go-gateway"
}

variable "aws_region" {
  default = "ap-northeast-1"
}

# The application's group name
variable "group" {
  default = "go-gateway"
}

# The application's name
variable "app" {
  default = "api-server"
}

# The environment that is being built
variable "environment" {
  default = "dev"
}

# The vpc name
variable "vpc_name" {
  default = "go_gateway_vpc"
}

variable "aws_az" {
  type = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

# The vpc cidr
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# The public subnets, minimum of 2, that are a part of the VPC(s)
variable "aws_subnet_public" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "front_alb_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "additional_tags" {
  type    = map(string)
  default = {}
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
