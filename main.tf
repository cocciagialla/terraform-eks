# commentato perchè, su un cluster già creato, all'apply torna:
# Error: Duplicate data "aws_eks_cluster_auth" configuration
# data "aws_eks_cluster_auth" "this" {
#  name = module.eks.eks_cluster_id
# }

data "aws_eks_cluster" "this" {
  name = var.cluster_name
  # Questo depends_on va commentato quando il cluster è già creato e da errori il plan
  # depends_on = [
  #   module.eks.eks_managed_node_groups,
  # ]
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
  # Questo depends_on va commentato quando il cluster è già creato e da errori il plan
  # depends_on = [
  #   module.eks.eks_managed_node_groups,
  # ]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  tags = {
    env         = var.environment
    repo        = var.cluster_repo
    repo_ver    = var.cluster_repo_ver
    project     = var.project_name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types = []

  cluster_addons = {
    coredns = {
      most_recent = false
      addon_version = var.cluster_addons_version.coredns #"v1.10.1-eksbuild.13"
    }
    kube-proxy = {
      most_recent = false
      addon_version = var.cluster_addons_version.kube-proxy #"v1.28.12-eksbuild.9"
    }
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = false # To ensure access to the latest settings provided
      addon_version  = var.cluster_addons_version.vpc-cni #"v1.18.3-eksbuild.3"
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
        enableNetworkPolicy = "true"
      })
    }
    aws-ebs-csi-driver = {
      most_recent = false
      addon_version = var.cluster_addons_version.aws-ebs-csi-driver #"v1.35.0-eksbuild.1"
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
#  control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    }
  }

  node_security_group_additional_rules = {
    node_to_node_all_ingress = {
      self = true
      description = "[CUSTOM] Node to node all ingress traffic"
      protocol = "all"
      from_port = 0
      to_port = 0
      type = "ingress"
    }
  }

  eks_managed_node_groups = var.eks_managed_node_groups

  # aws-auth configmap (removed from version 20+)
  #manage_aws_auth_configmap = true
  #aws_auth_users = var.aws_auth_users

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = local.tags
}

# this module is needed from version 20+ in place of settings directly inserted into module eks
module "aws_auth" {
  source = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.36.0"
  manage_aws_auth_configmap = true
  aws_auth_users = var.aws_auth_users
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

resource "kubernetes_service_account" "ebs_csi_driver" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.ebs_csi_irsa.iam_role_arn
    }
  }
}
