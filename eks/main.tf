# VPC 및 네트워크 설정
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.5.0"

  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets      = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
}

# EKS 클러스터 생성
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.0.0"

  cluster_name    = "eks-cluster"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    backend_nodes = {
      desired_capacity = 2
      max_size         = 3
      min_size         = 1

      instance_type = "t3.medium"
    },
    ai_nodes = {
      desired_capacity = 2
      max_size         = 3
      min_size         = 1

      instance_type = "t3.medium"
    }
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}