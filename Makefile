include .env

.DEFAULT_GOAL := help

# Optionally add the "-it" flag for docker run commands if the env var "CI" is not set (meaning we are on a local machine and not in github actions)
# TTY_ARG :=
# ifndef CI
# 	TTY_ARG := -it
# endif

BUILD_HARNESS_RUN := TF_VARS=$$(env | grep '^TF_VAR_' | awk -F= '{printf "-e %s ", $$1}'); \
	docker run --rm \
	--platform=linux/amd64 \
	--cap-add=NET_ADMIN \
	--cap-add=NET_RAW \
	-v "${PWD}:/app" \
	-v "${PWD}/.cache/pre-commit:/root/.cache/pre-commit" \
	-v "${PWD}/.cache/tmp:/tmp" \
	-v "${PWD}/.cache/go:/root/go" \
	-v "${PWD}/.cache/go-build:/root/.cache/go-build" \
	-v "${PWD}/.cache/.terraform.d/plugin-cache:/root/.terraform.d/plugin-cache" \
	-v "${PWD}/.cache/.zarf-cache:/root/.zarf-cache" \
	-v "${HOME}/.uds-cache:/root/.uds-cache" \
	--workdir "/app" \
	-e TF_LOG_PATH \
	-e TF_LOG \
	-e GOPATH=/root/go \
	-e GOCACHE=/root/.cache/go-build \
	-e TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true \
	-e TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache \
	-e AWS_REGION \
	-e AWS_DEFAULT_REGION \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e AWS_SESSION_TOKEN \
	-e AWS_SECURITY_TOKEN \
	-e AWS_SESSION_EXPIRATION \
	$${TF_VARS} \
	${BUILD_HARNESS_REPO}:${BUILD_HARNESS_VERSION}

REGION := $(shell $(BUILD_HARNESS_RUN) bash -c 'cd test/iac && terraform output -raw region')
SERVER_ID := $(shell $(BUILD_HARNESS_RUN) bash -c 'cd test/iac && terraform output -raw server_id')

SSM_SESSION_ARGS := \
	aws ssm start-session \
		--region $(REGION) \
		--target $(SERVER_ID) \
		--document-name AWS-StartInteractiveCommand

ZARF := zarf -l debug --no-progress --no-log-file

# The repo clone url
REPO := $(shell git remote get-url origin)
# The current branch name
BRANCH := $(shell git symbolic-ref --short HEAD)
# The "primary" directory
PRIMARY_DIR := $(shell basename $$(pwd))

.PHONY: arbitrary-container-command
arbitrary-container-command: ## Run an arbitrary command in a container. Example: make arbitrary-container-command COMMAND="ls -lahrt"
	${BUILD_HARNESS_RUN} \
		bash -c '$(COMMAND)'

.PHONY: _check-env-vars
_check-env-vars:
	echo $(PRIMARY_DIR)
	echo $(SSM_SESSION_ARGS)
	echo $(REGION)

# Silent mode by default. Run `make VERBOSE=1` to turn off silent mode.
ifndef VERBOSE
.SILENT:
endif

# Idiomatic way to force a target to always run, by having it depend on this dummy target
FORCE:

.PHONY: help
help: ## Show available user-facing targets
	grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ":"

.PHONY: help-dev
help-dev: ## Show available dev-facing targets
	grep -E '^_[a-zA-Z0-9_-]+:.*?#_# .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)#_#\(.*\)/\1:\3/p' \
	| column -t -s ":"

.PHONY: help-internal
help-internal: ## Show available internal targets
	grep -E '^\+[a-zA-Z0-9_-]+:.*?#\+# .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)#\+#\(.*\)/\1:\3/p' \
	| column -t -s ":"

.PHONY: _create-folders
_create-folders:
	mkdir -p .cache/docker
	mkdir -p .cache/pre-commit
	mkdir -p .cache/tmp
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
	${BUILD_HARNESS_RUN} \
	bash -c 'git config --global --add safe.directory /app \
		&& pre-commit run -a --show-diff-on-failure $(HOOK)'

.PHONY: pre-commit-all
pre-commit-all: ## Run all pre-commit hooks. Returns nonzero exit code if any hooks fail. Uses Docker for maximum compatibility
	$(MAKE) _runhooks HOOK="" SKIP=""

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
	${BUILD_HARNESS_RUN} \
		bash -c 'zarf tools registry login registry1.dso.mil -u ${REGISTRY1_USERNAME} -p ${REGISTRY1_PASSWORD} \
			&& cd packages/$(PACKAGE_NAME) \
			&& zarf package create --retries 10 --confirm'

.PHONY: zarf-build-all
zarf-build-all: ## Build all Zarf Packages
	$(MAKE) zarf-build-aws-node-termination-handler
	$(MAKE) zarf-build-cluster-autoscaler
	$(MAKE) zarf-build-metrics-server

.PHONY: zarf-build-cluster-autoscaler
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
	${BUILD_HARNESS_RUN} \
		bash -c 'zarf tools registry login ghcr.io -u dummy -p ${GITHUB_TOKEN} \
			&& cd $(PACKAGE_NAME) \
			&& zarf package publish zarf-package-${PACKAGE_NAME}-*.tar.zst oci://ghcr.io/defenseunicorns/narwhal-delivery-zarf-package-eks-addons'

.PHONY: zarf-publish-all
zarf-publish-all: ## Build all Zarf Packages
	$(MAKE) zarf-publish-aws-node-termination-handler
	$(MAKE) zarf-publish-cluster-autoscaler
	$(MAKE) zarf-publish-metrics-server

.PHONY: zarf-publish-cluster-autoscaler
zarf-publish-cluster-autoscaler:
	$(MAKE) publish-zarf-package PACKAGE_NAME="cluster-autoscaler"

.PHONY: zarf-publish-metrics-server
zarf-publish-metrics-server:
	$(MAKE) publish-zarf-package PACKAGE_NAME="metrics-server"

.PHONY: zarf-publish-aws-node-termination-handler
zarf-publish-aws-node-termination-handler:
	$(MAKE) publish-zarf-package PACKAGE_NAME="aws-node-termination-handler"

.PHONY: zarf-build-and-publish-all
zarf-build-and-publish-all: ## Build and Publish all Zarf Packages
	$(MAKE) zarf-build-all
	$(MAKE) zarf-publish-all

.PHONY: _test-infra-up
_test-infra-up: #_# Use Terraform to bring up the test server and prepare it for use
	$(MAKE) _test-terraform-apply _test-wait-for-zarf _test-install-dod-ca _test-clone _test-update-etc-hosts

.PHONY: _test-platform-up
_test-platform-up: #_# On the test server, set up the k8s cluster and UDS platform
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			cd ~/$(PRIMARY_DIR) \
			&& git pull \
			&& sudo make install-uds-cli VERBOSE=1 \
			&& sudo make zarf-init \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

.PHONY: _test-terraform-apply
_test-terraform-apply: #_# Use Terraform to apply the test server changes
	${BUILD_HARNESS_RUN} \
		bash -c 'cd test/iac && terraform init && terraform apply --auto-approve'

.PHONY: _test-uds-deploy-bundle
_test-uds-deploy-bundle: #_# On the test server, deploy the UDS package
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			cd ~/$(PRIMARY_DIR) \
			&& git pull \
			&& chmod +x ~/$(PRIMARY_DIR)/test/deploy-uds-package.sh \
			&& sudo ~/$(PRIMARY_DIR)/test/deploy-uds-package.sh \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

.PHONY: _test-all
_test-all: #_# Run the whole test end-to-end. Uses Docker. Requires access to AWS account. Costs real money. Handles cleanup by itself assuming it is able to run all the way through.
	$(MAKE) _test-infra-up _test-platform-up _test-uds-deploy-bundle
	echo "Test complete. Cleaning up..."
	# $(MAKE) _test-infra-down

.PHONY: _test-wait-for-zarf
_test-wait-for-zarf: #_# Wait for Zarf to be installed in the test server
	START_TIME=$$(date +%s); \
	echo $(REGION); \
	echo $(SERVER_ID); \
	while true; do \
		if aws ssm start-session \
				--region $(REGION) \
				--target $(SERVER_ID) \
				--document-name AWS-StartInteractiveCommand \
				--parameters command='["whoami"]'; then \
			break; \
		fi; \
		CURRENT_TIME=$$(date +%s); \
		ELAPSED_TIME=$$((CURRENT_TIME - START_TIME)); \
		if [[ $$ELAPSED_TIME -ge 300 ]]; then \
			echo "Timed out waiting for instance to be available"; \
			exit 1; \
		fi; \
		echo "Instance is not available yet. Retrying in 10 seconds"; \
		sleep 10; \
	done; \
		$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			START_TIME=$$(date +%s); \
			while true; do \
				if $(ZARF) version; then \
					echo \"EXITCODE: 0\"; \
					exit 0; \
				fi; \
				CURRENT_TIME=$$(date +%s); \
				ELAPSED_TIME=$$((CURRENT_TIME - START_TIME)); \
				if [[ $$ELAPSED_TIME -ge 300 ]]; then \
					echo \"Timed out waiting for Zarf to be installed\"; \
					echo \"EXITCODE: 1\"; \
					exit 1; \
				fi; \
				echo \" Zarf is not installed yet. Retrying in 10 seconds\"; \
				sleep 10; \
			done; \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

.PHONY: _test-install-dod-ca
_test-install-dod-ca: #_# Install the DOD CA in the test server
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			sudo yum install -y -q git \
			&& cd ~ \
			&& wget https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip \
			&& unzip -o unclass-certificates_pkcs7_DoD.zip \
			&& cd certificates_pkcs7_*_dod/ \
			&& sudo cp -f ./dod_pke_chain.pem /etc/pki/ca-trust/source/anchors/ \
			&& sudo update-ca-trust \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

.PHONY: _test-clone
_test-clone: #_# Clone the repo in the test instance so we can use it
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			sudo rm -rf ~/$(PRIMARY_DIR) \
			&& git clone -b $(BRANCH) $(REPO) ~/$(PRIMARY_DIR) \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

.PHONY: _test-update-etc-hosts
_test-update-etc-hosts: #_# Update /etc/hosts on the test instance
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			cd ~/$(PRIMARY_DIR)/test \
			&& chmod +x ./update-local-etc-hosts.sh \
			&& sudo ./update-local-etc-hosts.sh \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

.PHONY: zarf-init
zarf-init: ## Run 'zarf init' on the local machine. Will create a K3s cluster since the "k3s" component is selected.
ifneq ($(shell id -u), 0)
	$(error "This target must be run as root")
endif
	$(ZARF) init \
		--components=k3s,git-server \
		--set K3S_ARGS="--disable traefik,servicelb,metrics-server" \
		--confirm

.PHONY: install-uds-cli
install-uds-cli: ## Install the uds-cli on the bastion host
	ARCH=$$(uname -m | sed 's/x86_64/amd64/'); \
		sudo curl -L $(UDS_CLI_REPO)/releases/download/v$(UDS_CLI_VERSION)/uds-cli_v$(UDS_CLI_VERSION)_Linux_$${ARCH} -o /usr/bin/uds \
		&& sudo chmod +x /usr/bin/uds \
		&& which uds \
		&& echo "uds version: $$(uds version) $${ARCH}"


.PHONY: ssm-install-uds-cli
ssm-install-uds-cli: ## Install the uds-cli on the bastion host
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			ARCH=$$(uname -m | sed 's/x86_64/amd64/'); \
			sudo curl -L $(UDS_CLI_REPO)/releases/download/v$(UDS_CLI_VERSION)/uds-cli_v$(UDS_CLI_VERSION)_Linux_$${ARCH} -o /usr/local/bin/uds \
			&& sudo chmod +x /usr/local/bin/uds \
			&& which uds \
			&& echo \"uds version: $$(uds version)\" \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"


###############################################################
###### interactive ############################################
###############################################################

.PHONY: connect-to-bastion-host-interactivly
connect-to-bastion-host-interactive: ## Connect to the bastion host interactively
	aws ssm start-session \
		--region $(REGION) \
		--target $(SERVER_ID)

###############################################################
###### Cleanup ################################################
###############################################################

.PHONY: _test-platform-down
_test-platform-down: #_# On the test server, tear down the UDS platform and k8s cluster
	$(SSM_SESSION_ARGS) \
		--parameters command='[" \
			sudo zarf destroy --confirm --remove-components \
			&& echo \"EXITCODE: 0\" \
		"]' | tee /dev/tty | grep -q "EXITCODE: 0"

# Runs destroy again if the first one fails to complete.
.PHONY: _test-infra-down
_test-infra-down: #_# Use Terraform to bring down the test server
	${BUILD_HARNESS_RUN} \
		bash -c 'cd test/iac && terraform init && terraform destroy --auto-approve || terraform destroy -auto-approve'
