# Makefile for go-gateway
.DEFAULT_GOAL := help

# Load env file
ENV ?= dev
env ?= ./envs/$(ENV).env
include $(env)
export $(shell sed 's/=.*//' $(env))

# -----------------------------------------------------------------
#    ENV VARIABLE
# -----------------------------------------------------------------
GROUP      ?= learning
APP        ?= go-gateway

AWS_ACCOUNT_ID ?=# default empty
AWS_PROFILE    ?= go-gateway
AWS_REGION     ?= ap-northeast-1

TF_DYNAMODB_TABLE ?= $(GROUP)-$(APP)-$(ENV)-terraform-state-lock
TF_S3_BUCKET      ?= terraform-$(GROUP)-$(APP)-$(ENV)
TF_KEY            ?= terraform.tfstate/$(GROUP)-$(APP)-$(ENV)

# Terraform settings
TFM_BK_VARS   = -var 'aws_profile=$(AWS_PROFILE)' \
                -var 'aws_region=$(AWS_REGION)' \
                -var 's3_bucket=$(TF_S3_BUCKET)' \
                -var 'dynamodb_table=$(TF_DYNAMODB_TABLE)'

TFM_BK_CONFIG = -backend-config='region=$(AWS_REGION)' \
                -backend-config='bucket=$(TF_S3_BUCKET)' \
                -backend-config='key=$(TF_KEY)' \
                -backend-config='dynamodb_table=$(TF_DYNAMODB_TABLE)' \
                -backend-config='encrypt=true'

TFM_VARS      = -var 'aws_profile=$(AWS_PROFILE)' \
                -var 'aws_region=$(AWS_REGION)' \
                -var 'group=$(GROUP)' \
                -var 'app=$(APP)' \
                -var 'environment=$(ENV)'

# -----------------------------------------------------------------
#    Main targets
# -----------------------------------------------------------------

.PHONY: env
env: ## Print useful environment variables to stdout
	@echo AWS_ACCOUNT_ID = $(AWS_ACCOUNT_ID)
	@echo AWS_PROFILE = $(AWS_PROFILE)
	@echo AWS_REGION = $(AWS_REGION)
	@echo TFM_VARS = $(TFM_VARS)

.PHONY: terraform-setup
terraform-setup: ## Setup terraform backend configuration
	@cd backend && terraform init $(TFM_BK_VARS) && terraform apply $(TFM_BK_VARS) && cd ..

.PHONY: terraform-init
terraform-init: ## Init terraform
	@terraform init $(TFM_VARS) $(TFM_BK_CONFIG)

.PHONY: terraform-init-upgrade
terraform-init-upgrade: ## Init terraform (with upgrade)
	@terraform init $(TFM_VARS) $(TFM_BK_CONFIG) -upgrade

.PHONY: terraform-init-reconfigure
terraform-init-reconfigure: ## Init terraform (with reconfigure)
	@terraform init $(TFM_VARS) $(TFM_BK_CONFIG) -reconfigure

.PHONY: terraform-plan
terraform-plan: ## Plan terraform
	@terraform plan $(TFM_VARS)

.PHONY: terraform-apply
terraform-apply: ## Apply terraform
	@terraform apply $(TFM_VARS)

.PHONY: terraform-destroy
terraform-destroy: ## Destroy terraform
	@terraform destroy $(TFM_VARS)

.PHONY: help
help: env
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
