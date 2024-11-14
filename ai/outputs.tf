output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks_cluster.cluster_certificate_authority_data
}

output "cluster_name" {
  value = module.eks_cluster.cluster_id
}