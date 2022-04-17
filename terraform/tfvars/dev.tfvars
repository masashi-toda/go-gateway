# environments for AWS
aws_profile = "go-gateway"
aws_region  = "ap-northeast-1"

# for Application
group = "learning"
app   = "go-gateway"

# for VPC
vpc_az_names        = ["ap-northeast-1a", "ap-northeast-1c"]
vpc_cidr            = "10.0.0.0/16"
vpc_public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
vpc_private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

# for ALB Security Group
alb_ingress_cidr_blocks = ["0.0.0.0/0"]

# for ECS Fargate
container_port          = 8080
container_cpu           = 256 # 0.25 vCPU
container_memory        = 512 # 0.5 GB
container_desired_count = 1

# for Github
git_repository_name = "learning-go-gateway-dev"
