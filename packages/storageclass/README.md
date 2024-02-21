# Storageclass zarf package

This package provides storageclass configurations for the EKS cluster provisioned by the <https://github.com/defenseunicorns/terraform-aws-eks> module specifically when the terraform is not interacting with the kubernetes API.

ebs-storageclass.yaml and efs-storageclass.yaml are the storageclass configurations for EBS and EFS respectively when using EKS marketplace addons that do not allow modification of the storageclass on deployment

ebs gp2 storageclass is created by default when installing the ebs-csi driver from the amazon marketplace
