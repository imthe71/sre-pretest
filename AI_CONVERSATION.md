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

使用者：進行第三題，找出分數排名第二名學生所在班級。

AI agent：以 `score` 和 `class` 的 `name` 欄位 join，依分數由大到小排序，再使用 `LIMIT 1 OFFSET 1` 取第二筆；以題目資料驗證結果為 A。另補充 `DENSE_RANK()` 處理同分需求的寫法。

使用者：開始整理情境實戰題一。題目是假設活動網站上線後，訪客可能成長至平常 100 倍以上；先假設 CDN 已存在，聚焦 WAF、EKS、資料庫與快取的處理方式。

AI agent：確認流量路徑為：靜態內容由 CloudFront 快取；動態 API 由 ALB 分流至 EKS App Pods；可快取查詢先讀 Redis，miss 後經 Reader Endpoint 讀 Read Replicas；下單、扣名額、付款進 RDS Proxy 與單一 Writer；寄信、通知、分析改為 SQS 非同步處理。

使用者：EKS App Pods 應先提高預設值，並先分析監控資料決定 Pod 與 Node 的基礎容量。

AI agent：以單 Pod 穩定 RPS、p95/p99、錯誤率、CPU、記憶體、資料庫與 Redis 指標作為容量依據；活動前預擴 App `minReplicas` 與 Node Group `min/desired`，保留 1.3～1.5 倍餘裕與 N+1 Node 容量。

使用者：確認資料庫的處理方式。

AI agent：Writer 以垂直擴容處理必要交易；Read Replicas 以水平擴充處理讀取；Multi-AZ 用於可用性而不是增加寫入效能。Redis、RDS Proxy、WAF 與 SQS 用來避免資料庫直接承受 100 倍請求。

使用者：確認誰負責分流。

AI agent：CloudFront 負責邊緣快取；ALB 是動態 API 的主要 L7 分流器；Kubernetes Service 提供 Pod endpoints；Reader Endpoint 分散新的讀取連線；SQS 將非同步工作分給 Consumer Pods。HPA 與 Node Group 負責擴容，不是流量分流器。

使用者：檢查 GitHub 後發現第一題遺漏。

AI agent：補上 `01-word-frequency/`。以 Python 讀取 `words.txt`，將內容轉為不分大小寫的單字、排除標點符號後統計次數。若最高次數同分，保留全部同分單字並以字母排序輸出；題目範例驗證輸出為 `4 twinkle`。

使用者：進行情境實戰題二。API Server Cluster 中只有一台 response latency 偏高，且有時正常、有時 timeout。

AI agent：先確認 per-target latency、5xx、request 與 endpoint 範圍，並將異常機從 Load Balancer 摘流量但保留現場。依序檢查主機 CPU、Memory、Disk I/O、TCP connection、kernel log，再以 request ID／trace ID 檢查 application log、下游 dependency、connection pool、DNS 與 retry；最後對照正常機的版本、設定、流量與網路差異。IP 衝突列為網路排查的一項，但需先以 ARP、NIC error、packet drop 與 retransmit 等證據確認。

使用者：進行情境實戰題三。EC2 上的服務正常，但無法透過 SSH 登入，且已確認不是網路或防火牆問題。

AI agent：先用 `ssh -vvv` 判斷是 connection refused、public key 拒絕或連線卡住；不直接重開機。優先以 SSM Session Manager、EC2 Serial Console 取得主機存取，最後才採用建立 snapshot 後的 EBS rescue。登入後檢查 sshd、設定語法、Disk／inode、CPU／Memory、kernel log、帳號、SSH key 與權限；修復後以測試連線驗證，再恢復服務流量。平時應建立 SSM、break-glass、監控與復原演練。

使用者：進行情境實戰題四。既有 ELK／EFK Cluster 已存在，新服務需要讓 RD 在 Kibana 查 log。

AI agent：確認先盤點既有 collector、欄位規範、index／data stream、retention 與 Kibana Data View，再和 RD 對照新服務 log 格式與實際除錯需求。新服務符合 JSON、時間、level、service、environment、request／trace ID、stack trace 與敏感資料遮罩規範後，沿用原本 Fluent Bit／Fluentd／Filebeat 收集與路由方式整合。只有 retention、權限、mapping 或 log volume 有特殊需求時，才建立獨立 index／data stream；最後以測試 log 與 RD 查詢驗證。
