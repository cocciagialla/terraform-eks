# Terraform AWS EKS Module

This Terraform module creates and manages an Amazon EKS (Elastic Kubernetes Service) cluster along with its associated resources.

## Description

This module is a wrapper around the [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) module with additional configurations and customizations. It sets up an EKS cluster with managed node groups, cluster addons, and IAM roles for service accounts.

## Features

- Creates an EKS cluster in your VPC
- Configures EKS managed node groups
- Sets up cluster addons (CoreDNS, kube-proxy, VPC CNI, EBS CSI Driver)
- Configures IAM roles for service accounts (IRSA)
- Manages AWS auth for cluster access
- Configures node-to-node communication

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 3.72 |
| kubernetes | >= 2.10 |
| helm | >= 2.4.1 |
| kubectl | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.72 |
| kubernetes | >= 2.10 |

## Resources

This module creates the following resources:

- EKS Cluster
- EKS Managed Node Groups
- IAM Roles for Service Accounts
- Kubernetes Service Account for EBS CSI Driver
- AWS Auth ConfigMap

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | `""` | yes |
| project_name | Name of the project | `string` | `""` | yes |
| environment | Environment of the cluster (e.g., dev, staging, prod) | `string` | `""` | yes |
| cluster_version | Kubernetes version of the cluster | `string` | `""` | yes |
| cluster_repo | Git repo used to create the cluster | `string` | `""` | yes |
| cluster_repo_ver | Git repo version used to create the cluster | `string` | `""` | yes |
| vpc_id | VPC ID where the cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the cluster and worker nodes | `list(string)` | `[]` | yes |
| self_managed_node_groups | Self-Managed node groups definition | `any` | `{}` | no |
| eks_managed_node_groups | EKS-Managed node groups definition | `any` | `{}` | yes |
| aws_auth_users | AWS users to authorize to access the Cluster | `list(object)` | n/a | yes |
| cluster_addons_version | The version for each addon of the cluster | `object` | n/a | yes |

### cluster_addons_version Object Structure

```hcl
cluster_addons_version = {
  coredns             = "v1.11.3-eksbuild.1"
  kube-proxy          = "v1.29.7-eksbuild.9"
  vpc-cni             = "v1.18.5-eksbuild.1"
  aws-ebs-csi-driver  = "v1.36.0-eksbuild.1"
}
```

### aws_auth_users List Structure

```hcl
aws_auth_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/username"
    username = "username"
    groups   = ["system:masters"]
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_endpoint | The endpoint of the cluster API server |
| oidc_provider | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| oidc_provider_arn | The OpenID Connect identity provider ARN |
| eks_cluster_version | The Kubernetes version for the cluster |
| eks_cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |

## Example Usage

```hcl
module "eks" {
  source = "path/to/terraform-eks"

  cluster_name    = "my-cluster"
  project_name    = "my-project"
  environment     = "prod"
  cluster_version = "1.31"
  cluster_repo    = "terraform-aws-modules/eks/aws"
  cluster_repo_ver = "20.36.0"
  
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  
  eks_managed_node_groups = {
    mg_apps = {
      name           = "mg_apps_prod"
      instance_types = ["r5.large"]
      min_size       = 1
      max_size       = 8
      desired_size   = 1
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 60
          }
        }
      }
      ebs_optimized     = true
      enable_monitoring = true
    }
  }
  
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::123456789012:user/admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  
  cluster_addons_version = {
    coredns             = "v1.11.3-eksbuild.1"
    kube-proxy          = "v1.29.7-eksbuild.9"
    vpc-cni             = "v1.18.5-eksbuild.1"
    aws-ebs-csi-driver  = "v1.36.0-eksbuild.1"
  }
}
```

## Terragrunt Example

```hcl
dependency "vpc" {
  config_path = "../vpc"
}

dependency "vpc_subnets" {
  config_path = "../vpc_subnets"
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc_subnets.outputs.subnet_ids
  
  eks_managed_node_groups = {
    mg_apps = {
      name           = "mg_apps_prod"
      instance_types = ["r5.large"]
      min_size       = 1
      max_size       = 8
      desired_size   = 1
      subnet_ids     = dependency.vpc.outputs.public_subnets
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 60
          }
        }
      }
      ebs_optimized     = true
      enable_monitoring = true
    }
  }
  
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::123456789012:user/admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
}
```

## Notes

- When applying to an existing cluster, you may need to comment out the `depends_on` blocks in the data sources to avoid errors.
- The module enables prefix delegation for the VPC CNI addon to increase the number of available IP addresses.
- The module configures node-to-node communication through security group rules.
