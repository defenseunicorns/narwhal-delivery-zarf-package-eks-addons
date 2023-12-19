include .env

.DEFAULT_GOAL := help

# Optionally add the "-it" flag for docker run commands if the env var "CI" is not set (meaning we are on a local machine and not in github actions)
TTY_ARG :=
ifndef CI
	TTY_ARG := -it
endif

# DRY is good.
ALL_THE_DOCKER_ARGS := $(TTY_ARG) --rm \
	--cap-add=NET_ADMIN \
	--cap-add=NET_RAW \
	-v "${PWD}:/app" \
	-v "${PWD}/.cache/tmp:/tmp" \
	-v "${PWD}/.cache/go:/root/go" \
	-v "${PWD}/.cache/go-build:/root/.cache/go-build" \
	-v "${PWD}/.cache/.terraform.d/plugin-cache:/root/.terraform.d/plugin-cache" \
	-v "${PWD}/.cache/.zarf-cache:/root/.zarf-cache" \
	--workdir "/app" \
	-e TF_LOG_PATH \
	-e TF_LOG \
	-e GOPATH=/root/go \
	-e GOCACHE=/root/.cache/go-build \
	-e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true \
	-e TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache \
	-e "SKIP=$(SKIP)" \
	-e "PRE_COMMIT_HOME=/app/.cache/pre-commit" \
	-e AWS_REGION \
	-e AWS_DEFAULT_REGION \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e AWS_SESSION_TOKEN \
	-e AWS_SECURITY_TOKEN \
	-e AWS_SESSION_EXPIRATION \
	${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION}

# Silent mode by default. Run `make VERBOSE=1` to turn off silent mode.
ifndef VERBOSE
.SILENT:
endif

# Idiomatic way to force a target to always run, by having it depend on this dummy target
FORCE:

.PHONY: help
help: ## Show a list of all targets
	grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ":"

.PHONY: _create-folders
_create-folders:
	mkdir -p .cache/docker
	mkdir -p .cache/pre-commit
	mkdir -p .cache/go
	mkdir -p .cache/go-build
	mkdir -p .cache/tmp
	mkdir -p .cache/.terraform.d/plugin-cache
	mkdir -p .cache/.zarf-cache

.PHONY: docker-save-build-harness
docker-save-build-harness: _create-folders ## Pulls the build harness docker image and saves it to a tarball
	docker pull ${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION}
	docker save -o .cache/docker/build-harness.tar ${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION}

.PHONY: docker-load-build-harness
docker-load-build-harness: ## Loads the saved build harness docker image
	docker load -i .cache/docker/build-harness.tar

.PHONY: _runhooks
_runhooks: _create-folders
	docker run ${ALL_THE_DOCKER_ARGS} \
	bash -c 'git config --global --add safe.directory /app \
		&& pre-commit run -a --show-diff-on-failure $(HOOK)'

.PHONY: pre-commit-all
pre-commit-all: ## Run all pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP=""

.PHONY: pre-commit-terraform
pre-commit-terraform: ## Run the terraform pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP="check-added-large-files,check-merge-conflict,detect-aws-credentials,detect-private-key,end-of-file-fixer,fix-byte-order-marker,trailing-whitespace,check-yaml,fix-smartquotes,go-fmt,golangci-lint,renovate-config-validator"

.PHONY: pre-commit-golang
pre-commit-golang: ## Run the golang pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP="check-added-large-files,check-merge-conflict,detect-aws-credentials,detect-private-key,end-of-file-fixer,fix-byte-order-marker,trailing-whitespace,check-yaml,fix-smartquotes,terraform_fmt,terraform_docs,terraform_checkov,terraform_tflint,renovate-config-validator"

.PHONY: pre-commit-renovate
pre-commit-renovate: ## Run the renovate pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="renovate-config-validator" SKIP=""

.PHONY: pre-commit-common
pre-commit-common: ## Run the common pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP="go-fmt,golangci-lint,terraform_fmt,terraform_docs,terraform_checkov,terraform_tflint,renovate-config-validator"

.PHONY: fix-cache-permissions
fix-cache-permissions: ## Fixes the permissions on the pre-commit cache
	docker run $(TTY_ARG) --rm -v "${PWD}:/app" --workdir "/app" -e "PRE_COMMIT_HOME=/app/.cache/pre-commit" ${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION} chmod -R a+rx .cache

.PHONY: autoformat
autoformat: ## Update files with automatic formatting tools. Uses Docker for maximum compatibility.
	$(MAKE) _runhooks HOOK="" SKIP="check-added-large-files,check-merge-conflict,detect-aws-credentials,detect-private-key,check-yaml,golangci-lint,terraform_checkov,terraform_tflint,renovate-config-validator"

.PHONY: build-zarf-package
build-zarf-package: ## Build the Zarf Package
ifndef REGISTRY1_USERNAME
	$(error environment variable REGISTRY1_USERNAME is not set)
endif
ifndef REGISTRY1_PASSWORD
	$(error environment variable REGISTRY1_PASSWORD is not set)
endif
	docker run ${ALL_THE_DOCKER_ARGS} \
		bash -c 'zarf tools registry login registry1.dso.mil -u ${REGISTRY1_USERNAME} -p ${REGISTRY1_PASSWORD} \
			&& cd $(PACKAGE_NAME) \
			&& zarf package create --confirm'

.PHONY: build-all
build-all: ## Build all Zarf Packages
	$(MAKE) zarf-build-aws-node-termination-handler
	$(MAKE) zarf-build-cluster-autoscaler
	$(MAKE) zarf-build-metrics-server
	
zarf-build-cluster-autoscaler:
	$(MAKE) build-zarf-package PACKAGE_NAME="cluster-autoscaler"

.PHONY: zarf-build-metrics-server
zarf-build-metrics-server:
	$(MAKE) build-zarf-package PACKAGE_NAME="metrics-server"

.PHONY: zarf-build-aws-node-termination-handler
zarf-build-aws-node-termination-handler:
	$(MAKE) build-zarf-package PACKAGE_NAME="aws-node-termination-handler"


.PHONY: publish-zarf-package
publish-zarf-package: ## Publish the Zarf Package
ifndef GITHUB_TOKEN
	$(error environment variable GITHUB_TOKEN is not set)
endif
	docker run ${ALL_THE_DOCKER_ARGS} \
		bash -c 'zarf tools registry login ghcr.io -u dummy -p ${GITHUB_TOKEN} \
			&& zarf package publish zarf-package-*.tar.zst oci://ghcr.io/defenseunicorns/narwhal-delivery-zarf-package-eks-addons'