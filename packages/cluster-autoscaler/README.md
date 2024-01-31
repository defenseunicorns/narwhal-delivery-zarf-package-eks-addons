# Cluster Autoscaler Zarf Package

This directory contains the Zarf package for the eks-addons Cluster Autoscaler Helm chart. It is designed to be used with pre-staged configurations in AWS by defenseunicorns aws flavor terraform modules, but can also be used without executing those specific zarf component steps.

## Overview

The Cluster Autoscaler is a Kubernetes component that automatically adjusts the size of a Kubernetes cluster so that all pods have a place to run and there are no unneeded nodes. It ensures that the Kubernetes control plane responds appropriately to workloads that can cause your cluster to become over or underutilized.

## Package Contents

This package includes:

- `zarf.yaml`: The main configuration file for the Zarf package.
- `zarf-config.yaml`: Additional configuration for the Zarf package.
- `values/values.yaml`: The Helm chart values file for the AWS Node Termination Handler Helm chart. These are default values that can be configured at package create time and deploy time.
- `values/overrides.yaml`: Additional values to override the Helm chart values file. These settings are configurable and can be changed at deploy time. These settings are last in the helm chart values file and will override any settings set previously in other values files. To include these settings use the `deploy-values-override.yaml` file which templates into the `values/overrides.yaml` file.

## How to Use

To use this package, follow these steps:

1. Create the zarf package using the `zarf package create` command
2. Deploy the zarf package using the `zarf package deploy` command and the specified zarf package and any additional configuration files such as the `deploy-values-override.yaml` file or using a `zarf-config.yaml` file.

## Contributing

We welcome contributions to this package. Please see the main project's CONTRIBUTING.md for guidelines.

## License

This package is licensed under the same license as the main project. See the LICENSE file for more information.
