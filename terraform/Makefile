# Makefile for go-gateway
.DEFAULT_GOAL := help

# Load env file
ENV     ?= dev
envfile ?= ./tfvars/$(ENV).tfvars
include $(envfile)
#export $(shell sed 's/=.*//' $(envfile))

# -----------------------------------------------------------------
#    ENV VARIABLE
# -----------------------------------------------------------------
tf_bk_dynamo_table := "$(group)-$(app)-terraform-state-lock"
tf_bk_s3_bucket    := "terraform-$(group)-$(app)"
tf_bk_key          := "terraform.tfstate/$(group)-$(app)-$(ENV)"

# Terraform settings
tf_bk_vars   = -var aws_profile=$(aws_profile) \
               -var aws_region=$(aws_region) \
               -var s3_bucket=$(tf_bk_s3_bucket) \
               -var dynamodb_table=$(tf_bk_dynamo_table)

tf_bk_config = -backend=true \
               -backend-config="region=$(aws_region)" \
               -backend-config="bucket=$(tf_bk_s3_bucket)" \
               -backend-config="dynamodb_table=$(tf_bk_dynamo_table)" \
               -backend-config="key=$(tf_bk_key)" \
               -backend-config="encrypt=true"

tf_opts = -var-file=$(envfile) -var="env=$(ENV)"

# -----------------------------------------------------------------
#    Main targets
# -----------------------------------------------------------------

.PHONY: env
env: ## Print useful environment variables to stdout
	@echo aws_profile  = $(aws_profile)
	@echo aws_region   = $(aws_region)
	@echo tf_bk_vars   = $(tf_bk_vars)
	@echo tf_bk_config = $(tf_bk_config)
	@echo tf_opts      = $(tf_opts)

.PHONY: clean
clean: ## Clean terraform temporary files
	@rm -rf .terraform
	@rm -rf */.terraform

.PHONY: terraform-setup
terraform-setup: clean ## Setup terraform backend configuration
	@cd backend && terraform init $(tf_bk_vars) && terraform apply $(tf_bk_vars) && cd ..

.PHONY: terraform-init
terraform-init: ## Init terraform (with reconfigure)
	@terraform init $(tf_opts) $(tf_bk_config) -reconfigure

.PHONY: terraform-init-upgrade
terraform-init-upgrade: ## Init terraform (with upgrade)
	@terraform init $(tf_opts) $(tf_bk_config) -upgrade

.PHONY: terraform-plan
terraform-plan: terraform-init ## Plan terraform
	@terraform plan $(tf_opts)

.PHONY: terraform-apply
terraform-apply: terraform-init ## Apply terraform
	@terraform apply $(tf_opts)

.PHONY: terraform-destroy
terraform-destroy: terraform-init ## Destroy terraform
	@terraform destroy $(tf_opts)

.PHONY: help
help: env
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
