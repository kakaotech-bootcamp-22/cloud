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

variable "backend_image" {
  description = "백엔드 서버 Docker 이미지"
  type        = string
}

variable "db_host" {
  description = "데이터베이스 호스트"
  type        = string
}

variable "db_port" {
  description = "데이터베이스 포트"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_user" {
  description = "데이터베이스 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
}