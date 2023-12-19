# narwhal-delivery-zarf-package-eks-addons
Handles zarf packaging of multiple add-ons for EKS

## Getting Started
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