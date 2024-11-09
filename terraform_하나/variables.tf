variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.21"
}

variable "ecr_repository_names" {
  description = "ECR 리포지토리 이름 목록"
  type        = list(string)
}

variable "db_name" {
  description = "RDS 데이터베이스 이름"
  type        = string
  default     = "backend-db"
}

variable "db_username" {
  description = "RDS 데이터베이스 사용자 이름"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "RDS 데이터베이스 비밀번호"
  type        = string
  default     = "postgres00"
}
