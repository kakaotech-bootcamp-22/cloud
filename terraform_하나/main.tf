terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

# 가용 영역 가져오기
data "aws_availability_zones" "available" {
  state = "available"
}

# 현재 AWS 계정 ID 가져오기
data "aws_caller_identity" "current" {}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "main-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# 프라이빗 서브넷 생성
resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# NAT 게이트웨이용 Elastic IP 생성
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "main-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# 프라이빗 라우트 테이블
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# 퍼블릭 라우트 테이블 연결
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 프라이빗 라우트 테이블 연결
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# EKS 클러스터 역할
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

########################## IAM 정책 연결 방식 변경 시작 ##########################
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}
########################## IAM 정책 연결 방식 변경 끝 ##########################

# EKS 노드 그룹 역할
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

########################## IAM 노드 정책 연결 방식 변경 시작 ##########################
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_role.name
}

# EKS 클러스터 생성
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  create_iam_role = false
  iam_role_arn    = aws_iam_role.eks_cluster_role.arn

  cluster_endpoint_public_access = true
  authentication_mode = "API"
  enable_cluster_creator_admin_permissions = true
  enable_irsa = true

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"
    iam_role_arn = aws_iam_role.eks_node_role.arn
  }

  eks_managed_node_groups = {
    ai = {
      name         = "ai-node-group"
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 2
      desired_size = 1

      tags = {
        "Name" = "ai-node"
        "Type" = "AI"
      }
    }

    backend = {
      name         = "backend-node-group"
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 2
      desired_size = 1

      tags = {
        "Name" = "backend-node"
        "Type" = "Backend"
      }
    }
  }

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  #  aws-ebs-csi-driver = {
  #    service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
  #  }
  }

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# EBS CSI Driver를 위한 IRSA 역할
module "ebs_csi_irsa_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.30.0"

  role_name = "${var.cluster_name}-ebs-csi-role"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  depends_on = [module.eks]
}

# EBS CSI Driver 애드온을 별도의 리소스로 생성
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name              = "aws-ebs-csi-driver"
  addon_version           = "v1.36.0-eksbuild.1"

  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [module.ebs_csi_irsa_role]
}

# EBS CSI Driver에 필요한 추가 정책
resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${var.cluster_name}-ebs-csi-policy"
  description = "Policy for EBS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
  role       = module.ebs_csi_irsa_role.iam_role_name

  depends_on = [module.ebs_csi_irsa_role]
}

########################## RDS 설정 시작 ##########################
# RDS 파라미터 그룹
resource "aws_db_parameter_group" "postgres" {
  family = "postgres16"
  name   = "${var.cluster_name}-postgres16"

  parameter {
    name  = "max_connections"
    value = "100"
    apply_method = "pending-reboot" 

  }
}

# RDS 모니터링을 위한 IAM 역할
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.cluster_name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS 보안 그룹 생성
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      module.eks.node_security_group_id
    ]
    description = "Allow Backend nodes to access RDS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# RDS 서브넷 그룹
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = {
    Name = "rds-subnet-group"
  }
}

# RDS 인스턴스
resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "16.3"
  instance_class        = "db.t4g.micro"
  identifier            = "backend2db"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = aws_db_parameter_group.postgres.name
  db_subnet_group_name  = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible   = false
  skip_final_snapshot   = true
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn
  
  performance_insights_enabled = true

  tags = {
    Name        = "backend2db"
    Environment = "development"
    Service     = "backend"
  }
}

# Kubernetes Secret for RDS credentials
resource "kubernetes_secret" "rds_credentials" {
  metadata {
    name      = "rds-credentials"
    namespace = "default"
  }

  data = {
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.rds.endpoint
    port     = "5432"
    database = var.db_name
  }

  depends_on = [
    module.eks
  ]
}
########################## RDS 설정 끝 ##########################

# ECR 리포지토리 생성
resource "aws_ecr_repository" "repositories" {
  count = length(var.ecr_repository_names)
  name  = var.ecr_repository_names[count.index]

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = var.ecr_repository_names[count.index]
  }
}