# AI 對話紀錄

開始時間：2026-08-18

## 2026-08-18

使用者：重來！太醜了，重新開始記錄，從現在開始！

AI agent：已重新建立這份紀錄。接下來只保留作答過程中的重要提問、決定與提交內容。

## 2026-08-19

使用者：完成第二題 EKS 方案，依題圖保留 Ingress、App Service、Deployment、App PVC 與 MySQL StatefulSet 的關係，並以高可用為優先。

AI agent：建立跨 AZ VPC/EKS、private worker nodes、OIDC/IRSA、EBS/EFS CSI、AWS Load Balancer Controller、App RWX PVC、MySQL 每 Pod 獨立 EBS PVC、PDB、NetworkPolicy 與完整 README。

使用者：題圖中的 Ingress 位於 namespace；MySQL StatefulSet 管理 writer 與 reader 兩顆 Pod。

AI agent：調整文件圖示與說明，區分 Ingress 物件的 namespace 範圍、controller 管理、實際流量與儲存掛載關係；MySQL writer/reader 保持 logical role，不把 StatefulSet 誤當成流量路由。

使用者：開始做高可用，寫入端不要求資料庫 HA。

AI agent：強化 MySQL Pod 的 required node anti-affinity 與跨 AZ `DoNotSchedule` topology spread；同時保留說明：兩顆 MySQL Pod 的 baseline StatefulSet 不包含 replication、failover 或讀取端 HA。

驗證：Terraform fmt/init/validate 通過；Kubernetes manifests 經 strict schema validation，15 個 resources 全數有效；兩個 Service selector 均對應工作負載 labels。
