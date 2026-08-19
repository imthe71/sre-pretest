# 製作紀錄：第二題 EKS 架構

## 需求整理

- 以 Terraform 建立跨 AZ 的 AWS EKS 基礎設施，worker nodes 位於 private subnets。
- Kubernetes 僅使用 `asiayo` namespace；流量固定為 Client → Ingress → App Service → App Pods。
- App 多副本共享儲存採 `ReadWriteMany`；MySQL StatefulSet 的每顆 Pod 使用獨立 EBS PVC。
- 題圖的 writer / reader 是 MySQL 的邏輯角色，不把 Deployment 或 StatefulSet 誤畫成流量轉送元件。
- 不執行 Terraform apply 或任何 AWS 實際建立操作。

## 設計決策

1. VPC 使用至少兩個 AZ、public/private subnets、每 AZ NAT gateway；EKS managed node group 只部署於 private subnets。
2. EBS CSI、EFS CSI、AWS Load Balancer Controller 全部採 OIDC/IRSA，並由 Terraform 宣告。
3. App 以 EFS RWX PVC 支援多個 replicas；App Deployment 有 probes、resources、security context、PDB 與跨 AZ topology spread。
4. MySQL StatefulSet 維持兩顆 Pod，各自使用 EBS gp3 RWO PVC；pod anti-affinity 與 zone topology spread 要求跨 node、跨 AZ 排程。
5. MySQL StatefulSet 只提供 identity 與 storage，不把它誤稱為完整 MySQL HA。正式 DB HA 仍需要 replication、primary promotion、router 與 backup/PITR。

## 驗證紀錄

- `terraform fmt -check`：通過。
- `terraform init -backend=false`：成功。
- `terraform validate`：通過。
- manifests 渲染完成，無未替換 placeholder。
- Kubeconform strict schema validation：15 resources 有效、0 invalid。
- Service selector：`app` 對應 Deployment/app；`mysql-headless` 對應 StatefulSet/mysql。

## 未執行項目

未執行 `terraform plan`、`terraform apply`、`kubectl apply` 或任何 AWS 資源建立。部署命令與正式環境驗證步驟已寫入 README。
