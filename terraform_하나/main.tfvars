region               = "ap-northeast-2"

cluster_name         = "ktb-22-eks-cluster"

cluster_version      = "1.30"

ecr_repository_names = ["ai-server", "backend-server"]

# RDS 데이터베이스 설정
db_name     = "backend2db"
db_username = "postgres"
db_password = "postgres00"