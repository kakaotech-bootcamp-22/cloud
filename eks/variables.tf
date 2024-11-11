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