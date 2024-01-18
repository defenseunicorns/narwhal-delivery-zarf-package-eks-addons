#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source the .env file from the script's directory
source "$SCRIPT_DIR/../.env"

cat << 'EOF' > uds-config.yaml
variables:
  cluster-autoscaler:
    values_overrides: "cluster-autoscaler-values-overrides-demo.yaml"
  metrics-server:
    values_overrides: "metrics-server-values-overrides-demo.yaml"
EOF

cat << EOF > cluster-autoscaler-values-overrides-demo.yaml
extraEnv:
  whatever: "extraEnvVar"
EOF

cat << EOF > metrics-server-values-overrides-demo.yaml
extraEnv:
    whatever: "extraEnvVar"
EOF

uds deploy "oci://${UDS_EKS_ADDONS_REPO}:${UDS_EKS_ADDONS_VERSION}-amd64" --confirm
