# Makefile for go-gateway

.DEFAULT_GOAL := help

# Load env file
ENV ?= local
env ?= .env.$(ENV)
include $(env)
export $(shell sed 's/=.*//' $(env))

# -----------------------------------------------------------------
#    ENV VARIABLE
# -----------------------------------------------------------------
VERSION    := $(shell git describe --tags --abbrev=0 2> /dev/null || echo 0)
REVISION   := $(shell git rev-parse --short HEAD 2> /dev/null || echo 0)

DESTDIR    := ./bin
CMDDIR     := ./cmd
SOURCEDIR  := .
SOURCES    := $(shell find . -type f -name '*.go' | grep -v vendor)
LDFLAGS    := -ldflags="-s -w -X 'main.version=$(VERSION)' -X 'main.revision=$(REVISION)' -X 'git.rarejob.com/rarejob-platform/rjpf-common/logger.ServiceName=event-search' -extldflags '-static'"
NOVENDOR   := $(shell go list $(SOURCEDIR)/... | grep -v vendor)
TOOLBINDIR := ./tools/bin
BUILD_OPTS := -v $(LDFLAGS)

# Tools version
GOLANGCI_LINT_VERSION  := 1.45.0

# ECR settings
GROUP            := go-gateway
APP_NAME         := api-server
ENVIRONMENT      := dev
ECS_CLUSTER_NAME := $(GROUP)-ecr
ECR_NAME         := $(GROUP)/$(APP_NAME)
APP_VERSION      := 1.0.0

# Terraform settings
TFM_VARS = -var 'profile=$(AWS_PROFILE)' \
           -var 'region=$(AWS_REGION)' \
           -var 'group=$(GROUP)' \
           -var 'app=$(APP_NAME)' \
           -var 'environment=$(ENVIRONMENT)' \
           -var 'app_ecs_cluster_name=$(ECS_CLUSTER_NAME)' \
           -var 'app_ecr_name=$(ECR_NAME)'

# -----------------------------------------------------------------
#    Main targets
# -----------------------------------------------------------------

.PHONY: env
env: ## Print useful environment variables to stdout
	@echo PREFIX = $(PREFIX)
	@echo VERSION = $(VERSION)
	@echo REVISION = $(REVISION)
	@echo ECS_CLUSTER_NAME = $(ECS_CLUSTER_NAME)
	@echo ECR_NAME = $(ECR_NAME)

.PHONY: build ## Build golang binary files
build: $(SOURCES)
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(BUILD_OPTS) -o $(DESTDIR)/app ./cmd/server/main.go

.PHONY: clean
clean: ## Remove temporary files
	@rm -rf cover.*
	@rm -rf bin/*
	@go clean --cache --testcache

.PHONY: fmt
fmt: ## Format all packages
	@go fmt $(NOVENDOR)

.PHONY: lint
lint: ## Code check
	@$(TOOLBINDIR)/golangci-lint run -v ./...

.PHONY: test
test: ## Run all the tests
	@go test -race -cover $(SOURCEDIR)/...

.PHONY: cover
cover: ## Run unit test and out coverage file for local environment
	@go test -race -timeout 10m -coverprofile=cover.out -covermode=atomic $(SOURCEDIR)/...
	@go tool cover -html=cover.out -o cover.html

.PHONY: mod-download
mod-download: ## Download go module packages
	@go mod download

.PHONY: mod-tidy
mod-tidy: ## Remove unnecessary go module packages
	@go mod tidy
	@go mod verify

.PHONY: help
help: env
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# -----------------------------------------------------------------
#    Terraform targets
# -----------------------------------------------------------------

.PHONY: terraform-init
terraform-init: ## Init terraform
	@cd terraform && terraform init $(TFM_VARS) && cd ..

.PHONY: terraform-plan
terraform-plan: ## Plan terraform
	@cd terraform && terraform plan $(TFM_VARS) && cd ..

.PHONY: terraform-apply
terraform-apply: ## Apply terraform
	@cd terraform && terraform apply $(TFM_VARS) && cd ..

.PHONY: terraform-destroy
terraform-destroy: ## Destroy terraform
	@cd terraform && terraform destroy $(TFM_VARS) && cd ..

# -----------------------------------------------------------------
#    AWS ECR targets
# -----------------------------------------------------------------
ifneq ($(shell which aws),)
ACCOUNT_ID    = $(shell aws sts get-caller-identity --profile $(AWS_PROFILE) | jq -r '.Account')
DOCKER_REPO   = $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
CMD_REPOLOGIN := "aws ecr get-login-password --profile $(AWS_PROFILE) --region $(AWS_REGION)"
CMD_REPOLOGIN += " | docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(APP_NAME)"
endif

.PHONY: ecr-push-api-server
ecr-push-api-server: build-nc publish ## Push ecr repository (api-server image)

build-nc: ## Build the container without caching
	docker build --no-cache -t $(ECR_NAME) .

publish: repo-login publish-latest

repo-login: ## Auto login to AWS-ECR unsing aws-cli
	@echo $(CMD_REPOLOGIN)
	@eval $(CMD_REPOLOGIN)

publish-latest: ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	@docker tag $(ECR_NAME) $(DOCKER_REPO)/$(ECR_NAME):latest
	@docker push $(DOCKER_REPO)/$(ECR_NAME):latest

# -----------------------------------------------------------------
#    Setup targets
# -----------------------------------------------------------------

.PHONY: setup
setup: ## Setup dev tools
ifeq ($(shell $(TOOLBINDIR)/golangci-lint --version | grep $(GOLANGCI_LINT_VERSION) 2> /dev/null),)
	rm -f $(TOOLBINDIR)/golangci-lint
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(TOOLBINDIR) v$(GOLANGCI_LINT_VERSION)
endif
