# narwhal-delivery-zarf-package-eks-addons
Handles zarf packaging of multiple add-ons for EKS

## Getting Started

### Required Environment Variables

- REGISTRY1_USERNAME
- REGISTRY1_PASSWORD
- GITHUB_TOKEN

### Building Packages

To create the cluster-autoscaler zarf package
``` shell
make zarf-build-cluster-autoscaler
```

To create the metrics-server zarf package
``` shell
make zarf-build-metrics-server
```

To create the aws-node-termination-handler zarf package
``` shell
make zarf-build-aws-node-termination-handler
```

To create all the packages in this repo
``` shell
make zarf-build-all
```

### Publishing Packages

To publish the cluster-autoscaler zarf package
``` shell
make zarf-publish-cluster-autoscaler
```

To publish the metrics-server zarf package
``` shell
make zarf-publish-metrics-server
```

To publish the aws-node-termination-handler zarf package
``` shell
make zarf-publish-aws-node-termination-handler
```

To publish all the packages in this repo

``` shell
make zarf-publish-all
```