output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.cluster.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = module.cluster.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  value = module.cluster.cluster_oidc_issuer_url
}
