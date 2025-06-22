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

resource aws_vpc_endpoint ssm {
  count = var.create == true ? 1 : 0
  vpc_id            = module.vpc[count.index].vpc_id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc[count.index].private_subnets
  security_group_ids = [module.eks[count.index].cluster_primary_security_group_id]
  private_dns_enabled = true
}

resource aws_vpc_endpoint ssmmessages {
  count = var.create == true ? 1 : 0
  vpc_id = module.vpc[count.index].vpc_id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc[count.index].private_subnets
  security_group_ids = [module.eks[count.index].cluster_primary_security_group_id]
  private_dns_enabled = true
}

resource aws_vpc_endpoint ec2messages {
  count = var.create == true ? 1 : 0
  vpc_id = module.vpc[count.index].vpc_id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc[count.index].private_subnets
  security_group_ids = [module.eks[count.index].cluster_primary_security_group_id]
  private_dns_enabled = true
}

resource aws_vpc_endpoint kms {
  count = var.create == true ? 1 : 0
  vpc_id = module.vpc[count.index].vpc_id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc[count.index].private_subnets
  security_group_ids = [module.eks[count.index].cluster_primary_security_group_id]
  private_dns_enabled = true
}


resource aws_vpc_endpoint s3 {
  count = var.create == true ? 1 : 0
  vpc_id = module.vpc[count.index].vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = module.vpc[count.index].private_route_table_ids
  vpc_endpoint_type = "Gateway"
}

data aws_ssm_parameter eks_al2023_ami {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

resource aws_launch_template eks_al2023_soci_enabled {
  count = var.create == true ? 1 : 0
  name_prefix   = "eks-custom-al2023-"
  image_id      = data.aws_ssm_parameter.eks_al2023_ami.value

  user_data = base64encode(templatefile("${path.module}/extras/user_data.sh.tpl", {
    cluster_name = "${var.cluster_name}${var.suffix}",
    cluster_endpoint = module.eks[count.index].cluster_endpoint,
    cluster_ca = module.eks[count.index].cluster_certificate_authority_data,
    cluster_cidr = module.eks[count.index].cluster_service_cidr
    cluster_dns = "${replace(module.eks[count.index].cluster_service_cidr, ".0/16", "")}.10",
    ami_id = data.aws_ssm_parameter.eks_al2023_ami.value,
    capacity_type = local.capacity_type,
    launch_template_version = "1",
    launch_template_id = "lt-00b4e94e497c42926"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "soci"
    }
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
  cluster_security_group_additional_rules = {
    allowSSM = {
      cidr_blocks = [module.vpc[count.index].vpc_cidr_block]
      description = "Allow https traffic node to vpc(SSM)"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
    }
  }

  vpc_id                   = module.vpc[count.index].vpc_id
  subnet_ids               = module.vpc[count.index].private_subnets

  eks_managed_node_groups = {}

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

module "eks_managed_node_group" {
  count = var.create == true ? 1 : 0
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "v20.37.0"

  name = "soci"

  cluster_name    = module.eks[count.index].cluster_name

  subnet_ids = module.vpc[count.index].private_subnets

  cluster_service_ipv4_cidr = module.eks[count.index].cluster_service_cidr
  cluster_primary_security_group_id = module.eks[count.index].cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks[count.index].node_security_group_id]
  ami_type       = "CUSTOM"
  create_launch_template = false
  launch_template_id = aws_launch_template.eks_al2023_soci_enabled[count.index].id
  use_custom_launch_template = true
  instance_types = [
    "c6a.xlarge", 
    "c5a.xlarge", 
    "c5.xlarge", 
    "c7a.xlarge", 
    "c5ad.xlarge", 
    "t3a.xlarge", 
    "t3.xlarge"
  ]

  min_size     = 1
  max_size     = 3
  desired_size = 2

  capacity_type  = local.capacity_type


  tags = {
    Environment = "dev"
    Terraform   = "true"
    Name = "example"
  }
}


locals {
  capacity_type = "SPOT"
}