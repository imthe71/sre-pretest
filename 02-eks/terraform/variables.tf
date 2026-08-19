variable "aws_region" {
  description = "AWS region for all infrastructure."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Short project identifier used in AWS resource names."
  type        = string
  default     = "asiayo-pretest"
}

variable "environment" {
  description = "Environment suffix used in AWS resource names."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must provide enough /20 subnets for the selected AZ count."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones used by public and private subnets."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be between 2 and 3 for this pre-test baseline."
  }
}

variable "nat_gateway_mode" {
  description = "Use per_az for NAT gateway high availability, or single to reduce non-production cost."
  type        = string
  default     = "per_az"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be single or per_az."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint has public access. Restrict CIDRs further for production."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Managed node group instance types."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_capacity_type" {
  description = "EC2 capacity type for the managed node group."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_min_size" {
  description = "Managed node group minimum node count."
  type        = number
  default     = 2
}

variable "node_group_desired_size" {
  description = "Managed node group desired node count."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Managed node group maximum node count."
  type        = number
  default     = 4
}

variable "app_replicas" {
  description = "Desired number of application replicas rendered into Kubernetes manifests."
  type        = number
  default     = 2
}

variable "mysql_replicas" {
  description = "Desired number of baseline MySQL StatefulSet replicas rendered into Kubernetes manifests. This alone does not create database replication."
  type        = number
  default     = 2
}

variable "domain_name" {
  description = "DNS host rendered into the ALB Ingress manifest."
  type        = string
  default     = "app.example.com"
}

variable "app_image" {
  description = "Container image rendered into the application Deployment manifest. The image must implement /healthz and /readyz."
  type        = string
  default     = "YOUR_REGISTRY/YOUR_APP:TAG"
}

variable "mysql_image" {
  description = "MySQL image rendered into the baseline StatefulSet manifest."
  type        = string
  default     = "mysql:8.4"
}
variable "app_container_port" {
  description = "Application container and Service port."
  type        = number
  default     = 8080
}

variable "app_pvc_size" {
  description = "Requested EFS-backed shared application storage size."
  type        = string
  default     = "5Gi"
}

variable "mysql_pvc_size" {
  description = "Requested EBS-backed storage size per MySQL StatefulSet pod."
  type        = string
  default     = "20Gi"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Pinned AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "1.8.2"
}

variable "aws_load_balancer_controller_replicas" {
  description = "AWS Load Balancer Controller replicas."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional AWS tags."
  type        = map(string)
  default     = {}
}
