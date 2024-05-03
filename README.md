# narwhal-delivery-zarf-package-eks-addons

This repository is used to create zarf packages of multiple add-ons for EKS.

The main intention is to be used with our terraform module [terraform-aws-eks](https://github.com/defenseunicorns/terraform-aws-eks). These Zarf packages will consume resources staged in AWS automatically or with Zarf you can override the values using a values.yaml file, providing your own values with a VALUES_OVERRIDES Zarf variable for each package.

# Example of how to use the Zarf package with arbitrary overrides using zarf dev

The example below will template the output with arbitrary overrides akin to a `helm template` command.

```bash
# make junk dir
DEMO=$(mktemp -d)

# adding extra labels with helm chart values overrides
cat << EOF > $DEMO/cluster-autoscaler-values-overrides-demo.yaml
podLabels:
  extraLabel: "whatever"
awsRegion: "us-gov-west-1"
EOF

# go to cluster-autoscaler package dir
pushd packages/cluster-autoscaler

# template helm charts with zarf dev and zarf variables
# all output
zarf dev find-images --deploy-set VALUES_OVERRIDES=$DEMO/cluster-autoscaler-values-overrides-demo.yaml --why "kind"

# input var file changes
zarf dev find-images --deploy-set VALUES_OVERRIDES=$DEMO/cluster-autoscaler-values-overrides-demo.yaml --why "kind" | grep -A 10 -B 10 "us-gov-west-1\|whatever" 

# cleanup
popd
rm -rf $DEMO
unset DEMO
```
