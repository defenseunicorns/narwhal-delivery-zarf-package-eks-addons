#!/usr/bin/env bash

# enable common error handling options
set -o pipefail

# 1. Bring up the infra, the platform, deploy the uds bundle
# 2. Tear down
FAILURE=0

make _test-infra-up _test-platform-up _test-uds-deploy-bundle || FAILURE=1
