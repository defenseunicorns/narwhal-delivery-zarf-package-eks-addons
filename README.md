# narwhal-delivery-zarf-package-eks-addons
Handles zarf packaging of multiple add-ons for EKS
```
cd cluster-autoscaler
zarf package create .
zarf package create . --flavor eks
```

## Getting Started
To create the cluster-autoscaler package for just a generic helm chart

``` shell
cd cluster-autoscaler
zarf package create .
```

To create the cluster-autoscaler package for EKS

``` shell
cd cluster-autoscaler
zarf package create . --flavor eks
```