variable "cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS 클러스터 인증서"
  type        = string
}

variable "cluster_token" {
  description = "EKS 클러스터 토큰"
  type        = string
}

variable "ai_image" {
  description = "AI 서버 Docker 이미지"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 버킷 이름"
  type        = string
}