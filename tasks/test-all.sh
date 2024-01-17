#!/usr/bin/env bash

# enable common error handling options
set -o pipefail

# 1. Bring up the infra, the platform, and the mission app
# 2. wait 30 sec
# 3. Run the test
# 4. Tear down
FAILURE=0
make _test-infra-up _test-platform-up _test-mission-app-up || FAILURE=1
[[ $FAILURE -eq 0 ]] && echo "waiting for a few seconds for the app to come up" && sleep 60
[[ $FAILURE -eq 0 ]] && make _test-mission-app-test || FAILURE=1
make _test-infra-down || FAILURE=1
exit $FAILURE
