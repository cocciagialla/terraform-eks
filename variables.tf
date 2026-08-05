# tflint-ignore: terraform_unused_declarations
variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Env of the cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "K8S version of cluster"
  type        = string
  default     = ""
}

variable "cluster_repo" {
  description = "Git repo used to create the cluster"
  type        = string
  default     = ""
}

variable "cluster_repo_ver" {
  description = "Git repo version used to create the cluster"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC Id"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnets (private or public) Ids for the cluster and worker nodes"
  type        = list(string)
  default     = []
}

variable "self_managed_node_groups" {
  description = "Self-Managed node groups definition"
  type        = any
  default     = {}
}


variable "eks_managed_node_groups" {
  description = "EKS-Managed node groups definition"
  type        = any
  default     = {}
}

variable "aws_auth_users" {
  description = "AWS users to authorize to access the Cluster"
  type =list(object({
    userarn       = string
    username      = string
    groups  = list(string)
  }))
}

variable "cluster_addons_version" {
  description = "The version for each addon of the cluster"
  type =object({
    coredns             = string
    kube-proxy          = string
    vpc-cni             = string
    aws-ebs-csi-driver  = string
  })
}


