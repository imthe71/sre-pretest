resource "aws_security_group" "efs" {
  name        = "${local.name}-efs"
  description = "Allow NFS from EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from EKS managed node group"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_efs_file_system" "app" {
  creation_token = "${local.name}-app"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-app"
  })
}

resource "aws_efs_mount_target" "app" {
  for_each = toset(module.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.app.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
