# narwhal-delivery-zarf-package-eks-addons
Handles zarf packaging of multiple add-ons for EKS

## Getting Started
To create the cluster-autoscaler zarf package

``` shell
cd cluster-autoscaler
zarf package create .
```

To create the metrics-server zarf package

``` shell
cd metrics-server
zarf package create .
```

To create the aws-node-termination-handler zarf package

``` shell
cd aws-node-termination-handler
zarf package create .
```