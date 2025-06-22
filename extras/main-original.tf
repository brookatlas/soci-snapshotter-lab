module "vpc" {
  count = var.create == true ? 1 : 0
  source = "terraform-aws-modules/vpc/aws"
  version = "v5.21.0"

  name = "${var.vpc_name}${var.suffix}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.16.0/20", "10.0.32.0/20", "10.0.48.0/20"]
  public_subnets  = ["10.0.112.0/20", "10.0.128.0/20", "10.0.144.0/20"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module eks {
  count = var.create == true ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "v20.37.0"

  cluster_name    = "${var.cluster_name}${var.suffix}"
  cluster_version = var.cluster_version

  bootstrap_self_managed_addons = true
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                 = {}
  }
  

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc[count.index].vpc_id
  subnet_ids               = module.vpc[count.index].private_subnets

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [
        "c6a.xlarge", 
        "c5a.xlarge", 
        "c5.xlarge", 
        "c7a.xlarge", 
        "c5ad.xlarge", 
        "t3a.xlarge", 
        "t3.xlarge"
      ]
      min_size     = 2
      max_size     = 3
      desired_size = 2
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}