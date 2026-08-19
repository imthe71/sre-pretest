output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "region" {
  description = "AWS region used by the cluster."
  value       = var.aws_region
}

output "configure_kubectl" {
  description = "Command to add this cluster to the local kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "app_efs_file_system_id" {
  description = "EFS file system ID used by the RWX app StorageClass."
  value       = aws_efs_file_system.app.id
}

output "manifest_values" {
  description = "Values to copy into k8s/values.env before rendering manifests. Secrets are intentionally omitted."
  value = {
    APP_REPLICAS       = var.app_replicas
    MYSQL_REPLICAS     = var.mysql_replicas
    APP_IMAGE          = var.app_image
    APP_CONTAINER_PORT = var.app_container_port
    MYSQL_IMAGE        = var.mysql_image
    DOMAIN_NAME        = var.domain_name
    APP_PVC_SIZE       = var.app_pvc_size
    MYSQL_PVC_SIZE     = var.mysql_pvc_size
    EFS_FILE_SYSTEM_ID = aws_efs_file_system.app.id
    AWS_REGION         = var.aws_region
  }
}
