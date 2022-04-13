# Makefile for go-gateway
.DEFAULT_GOAL := help

# -----------------------------------------------------------------
#    ENV VARIABLE
# -----------------------------------------------------------------
GROUP      ?= learning
APP        ?= go-gateway
VERSION    ?= $(shell git describe --tags --abbrev=0 2> /dev/null || echo 1.0.0-alpha)
REVISION   ?= $(CODEBUILD_RESOLVED_SOURCE_VERSION)# $(shell git rev-parse --short HEAD 2> /dev/null || echo 0)

DESTDIR    := ./bin
CMDDIR     := ./cmd
SOURCEDIR  := .
SOURCES    := $(shell find . -type f -name '*.go' | grep -v vendor)
LDFLAGS    := -ldflags="-s -w -X 'main.version=$(VERSION)' -X 'main.revision=$(REVISION)' -extldflags '-static'"
NOVENDOR   := $(shell go list $(SOURCEDIR)/... | grep -v vendor)
TOOLBINDIR := ./tools/bin
BUILD_OPTS := -v $(LDFLAGS)

# Tools version
GOLANGCI_LINT_VERSION  := 1.45.0

# ECR settings
AWS_ACCOUNT_ID ?=# default empty
AWS_PROFILE    ?= go-gateway
AWS_REGION     ?= ap-northeast-1
ECR_REPO_NAME  ?= $(GROUP)/$(APP)

ifdef AWS_ACCOUNT_ID
AWS_PROFILE =# set empty
else
AWS_ACCOUNT_ID = $(shell aws sts get-caller-identity --profile $(AWS_PROFILE) | jq -r '.Account')
endif

DOCKER_REPO   := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
CMD_REPOLOGIN := "aws ecr get-login-password"
ifdef AWS_PROFILE
CMD_REPOLOGIN += " --profile $(AWS_PROFILE)"
endif
ifdef AWS_REGION
CMD_REPOLOGIN += " --region $(AWS_REGION)"
endif
CMD_REPOLOGIN += " | docker login --username AWS --password-stdin $(DOCKER_REPO)/$(ECR_REPO_NAME)"

# -----------------------------------------------------------------
#    Main targets
# -----------------------------------------------------------------

.PHONY: env
env: ## Print useful environment variables to stdout
	@echo GROUP            = $(GROUP)
	@echo APP              = $(APP)
	@echo VERSION          = $(VERSION)
	@echo REVISION         = $(REVISION)
	@echo AWS_ACCOUNT_ID   = $(AWS_ACCOUNT_ID)
	@echo AWS_PROFILE      = $(AWS_PROFILE)
	@echo AWS_REGION       = $(AWS_REGION)
	@echo ECR_REPO_NAME    = $(ECR_REPO_NAME)
	@echo DOCKER_REPO      = $(DOCKER_REPO)

.PHONY: build ## Build golang binary files
build: $(SOURCES)
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(BUILD_OPTS) -o $(DESTDIR)/app ./cmd/adapter/main.go

.PHONY: build-local ## Build golang binary files
build-local: $(SOURCES)
	@CGO_ENABLED=0 go build $(BUILD_OPTS) -o $(DESTDIR)/app ./cmd/adapter/main.go

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

.PHONY: run-local-server
run-local-server: ## Run local server
	@go run cmd/adapter/main.go

.PHONY: help
help: env
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# -----------------------------------------------------------------
#    AWS ECR targets
# -----------------------------------------------------------------

.PHONY: ecr-push-api-server
ecr-push-api-server: ecr-login docker-build docker-push ## Push ecr repository (api-server image)

ecr-login: ## Auto login to AWS-ECR unsing aws-cli
	@echo $(CMD_REPOLOGIN)
	@eval $(CMD_REPOLOGIN)

docker-build: ## Build the container without caching
	docker build --no-cache -t $(ECR_REPO_NAME) .

docker-push: docker-push-latest docker-push-revision

docker-push-latest: ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	@docker tag $(ECR_REPO_NAME) $(DOCKER_REPO)/$(ECR_REPO_NAME):latest
	@docker push $(DOCKER_REPO)/$(ECR_REPO_NAME):latest

docker-push-revision: ## Publish the `revision` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	@docker tag $(ECR_REPO_NAME) $(DOCKER_REPO)/$(ECR_REPO_NAME):$(REVISION)
	@docker push $(DOCKER_REPO)/$(ECR_REPO_NAME):$(REVISION)

show-docker-image-uri: ## Show docker image uri
	@echo '{"ImageURI":"$(DOCKER_REPO)/$(ECR_REPO_NAME):$(REVISION)"}'

# -----------------------------------------------------------------
#    Setup targets
# -----------------------------------------------------------------

.PHONY: setup
setup: ## Setup dev tools
ifeq ($(shell $(TOOLBINDIR)/golangci-lint --version | grep $(GOLANGCI_LINT_VERSION) 2> /dev/null),)
	rm -f $(TOOLBINDIR)/golangci-lint
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(TOOLBINDIR) v$(GOLANGCI_LINT_VERSION)
endif
