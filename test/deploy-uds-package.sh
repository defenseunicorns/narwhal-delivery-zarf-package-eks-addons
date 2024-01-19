#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source the .env file from the script's directory
source "$SCRIPT_DIR/../.env"

# stage uds configs for values overrides patterns
cat << 'EOF' > uds-config.yaml
variables:
  cluster-autoscaler:
    values_overrides: "cluster-autoscaler-values-overrides-demo.yaml"
  metrics-server:
    values_overrides: "metrics-server-values-overrides-demo.yaml"
  aws-node-termination-handler:
    values_overrides: "aws-node-termination-handler-values-overrides-demo.yaml"
EOF

# adding extra labels with helm is fun

cat << EOF > cluster-autoscaler-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
EOF

# https://github.com/kubernetes-sigs/metrics-server/blob/master/charts/metrics-server/templates/deployment.yaml#L24-L30
cat << EOF > metrics-server-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
EOF

# https://github.com/aws/aws-node-termination-handler/blob/main/config/helm/aws-node-termination-handler/templates/daemonset.linux.yaml#L19-L26
cat << EOF > aws-node-termination-handler-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
EOF


uds deploy "oci://${UDS_EKS_ADDONS_REPO}:${UDS_EKS_ADDONS_VERSION}-amd64" --confirm
