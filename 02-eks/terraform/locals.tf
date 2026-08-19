locals {
  name = "${var.project_name}-${var.environment}"

  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnets = [
    for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, index)
  ]

  private_subnets = [
    for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, index + var.az_count)
  ]

  common_tags = merge(var.tags, {
    "kubernetes.io/cluster/${local.name}" = "shared"
  })
}
