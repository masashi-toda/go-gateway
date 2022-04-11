variable "aws_profile" {
  default = "go-gateway"
}

variable "aws_region" {
  default = "ap-northeast-1"
}

###################################
## Terraform Backend State Variables
###################################

variable "dynamodb_table" {
}

variable "s3_bucket" {
}
