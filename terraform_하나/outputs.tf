output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "rds_port" {
  value = aws_db_instance.rds.port
}

output "ecr_repository_urls" {
  value = [for repo in aws_ecr_repository.repositories : repo.repository_url]
}