provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Project = var.project_name
      Managed = "terraform"
    })
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
