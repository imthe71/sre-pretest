module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    default = {
      name           = "${local.name}-workers"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_group_min_size
      desired_size = var.node_group_desired_size
      max_size     = var.node_group_max_size

      subnet_ids = module.vpc.private_subnets
      labels = {
        workload = "general"
      }
    }
  }

  tags = local.common_tags
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
