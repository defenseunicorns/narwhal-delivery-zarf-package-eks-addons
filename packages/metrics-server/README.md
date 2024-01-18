# Metrics Server Zarf Package

This directory contains the Zarf package for the eks-addons Metrics Server Helm chart.

## Overview

The Metrics Server is a scalable, efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.

## Package Contents

This package includes:

- `zarf.yaml`: The main configuration file for the Zarf package.
- `zarf-config.yaml`: Additional configuration for the Zarf package.
- `values/values.yaml`: The Helm chart values file for the Metrics Server Helm chart. These are default values that can be configured at package create time and deploy time.
- `values/values-override.yaml`: Additional values to override the Helm chart values file. These settings are configurable and can be changed at deploy time. These settings are last in the helm chart values file and will override any settings set previously in other values files.

## How to Use

To use this package, follow these steps:

1. Create the zarf package using the `zarf package create` command
2. Deploy the zarf package using the `zarf package deploy` command and the specified zarf package and any additional configuration files suchas the `deploy-values-override.yaml` file or using a `zarf-config.yaml` file.

## Contributing

We welcome contributions to this package. Please see the main project's CONTRIBUTING.md for guidelines.

## License

This package is licensed under the same license as the main project. See the LICENSE file for more information.