# AWS Node Termination Handler Zarf Package

This directory contains the Zarf package for the eks-addons AWS Node Termination Handler Helm chart. It is designed to be used with pre-staged configurations in AWS by defenseunicorns aws flavor terraform modules, but can also be used without executing those specific zarf component steps.

## Overview

The AWS Node Termination Handler provides a way to gracefully handle EC2 instance shutdown within a Kubernetes cluster. It ensures that the Kubernetes control plane responds appropriately to events that can cause your EC2 instance to become unavailable, such as EC2 maintenance events, Spot Instance interruption, and EC2 instance rebalance recommendations.

## Package Contents

This package includes:

- `zarf.yaml`: The main configuration file for the Zarf package.
- `zarf-config.yaml`: Additional configuration for the Zarf package.
- `values/values.yaml`: The Helm chart values file for the AWS Node Termination Handler Helm chart. These are default values that can be configured at package create time and deploy time.
- `values/overrides.yaml`: Additional values to override the Helm chart values file. These settings are configurable and can be changed at deploy time. These settings are last in the helm chart values file and will override any settings set previously in other values files. To include these settings use the `deploy-values-override.yaml` file which templates into the `values/overrides.yaml` file.

## How to Use

To use this package, follow these steps:

1. Create the zarf package using the `zarf package create` command
2. Deploy the zarf package using the `zarf package deploy` command and the specified zarf package and any additional configuration files suchas the `deploy-values-override.yaml` file or using a `zarf-config.yaml` file.

## Contributing

We welcome contributions to this package. Please see the main project's CONTRIBUTING.md for guidelines.

## License

This package is licensed under the same license as the main project. See the LICENSE file for more information.
