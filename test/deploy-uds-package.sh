#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source the .env file from the script's directory
source "$SCRIPT_DIR/../.env"

# stage uds config.yaml for values overrides patterns
cat << 'EOF' > uds-config.yaml
variables:
  cluster-autoscaler:
    values_overrides: "cluster-autoscaler-values-overrides-demo.yaml"
  metrics-server:
    values_overrides: "metrics-server-values-overrides-demo.yaml"
  aws-node-termination-handler:
    values_overrides: "aws-node-termination-handler-values-overrides-demo.yaml"
EOF

# staging values overrides per component
# adding extra labels with helm chart values overrides
cat << EOF > cluster-autoscaler-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
EOF

cat << EOF > metrics-server-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
EOF

cat << EOF > aws-node-termination-handler-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
EOF

# deploy the uds bundle of eks addons
uds deploy "oci://${UDS_EKS_ADDONS_REPO}:${UDS_EKS_ADDONS_VERSION}-amd64" --confirm
