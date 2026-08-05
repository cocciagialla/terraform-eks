#output "eks_cluster_id" {
#  description = "The ID of the cluster"
#  value       = module.eks.id
#}

output "eks_cluster_endpoint" {
  description = "The endpoint of the cluster API server"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "The OpenID Connect identity provider arn"
  value       = module.eks.oidc_provider_arn
}


output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}
