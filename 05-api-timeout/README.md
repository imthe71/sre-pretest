# 情境實戰題二：單台 API Server 經常逾時

## 問題判斷

API Server Cluster 中只有其中一台的 response latency 偏高，而且有時正常、有時經常 timeout。這種情況先視為單機、部署內容，或該機到下游服務的連線路徑異常；不會一開始就判定是整個 API 或資料庫故障。

## 處理方式

### 1. 先保護使用者流量

先從 ALB／Load Balancer 確認每個 target 的 latency、5xx 與 request 數，確認是否真的只有這台異常，以及是全部 API 都慢，還是特定 endpoint 慢。

確認異常後，先把該機從 Load Balancer 摘除或降低權重，避免持續影響使用者。不直接重開機，因為 CPU、記憶體、連線、磁碟 I/O 與 log 等現場資料可能會消失。

```text
Load Balancer
  ├─ 正常 API Server：繼續接流量
  └─ 異常 API Server：先摘流量，保留現場排查
```

### 2. 檢查主機狀態

```bash
top
free -m
df -h
iostat -xz 1 5
ss -s
dmesg -T | tail -n 100
```

主要檢查：

- CPU 是否在 timeout 時偶發滿載。
- Memory 是否不足、頻繁 GC、使用 swap 或發生 OOM。
- Disk I/O wait 是否高，或磁碟空間是否快滿。
- TCP connection、TIME_WAIT、SYN retransmit、file descriptor 或 conntrack 是否異常。
- Kernel、NIC 或系統層級是否有 error。

### 3. 查 Application Log 與 APM

依 timeout 發生時間、request ID 或 trace ID 追查，確認請求真正卡在哪裡：

- 特定 API 處理本身太久。
- DB、Redis 或第三方 API timeout。
- connection pool 耗盡。
- DNS lookup 偶發變慢。
- retry 太多，造成請求堆積。
- thread pool 或 file descriptor 用完。

### 4. 檢查網路與連線

IP 衝突可能造成時好時壞，但通常會讓整台主機的連線都不穩，不是第一優先。若主機與 application log 都沒有線索，再檢查：

```bash
ip addr
ip neigh
ip route
ip -s link
ss -s
```

包含 ARP、路由、NIC error、packet drop、TCP retransmit、DNS、NAT／conntrack，以及此台是否有不同的 Security Group、網路設定或 sidecar。

### 5. 和正常機比對

最後一定要用正常機作對照：

- 部署版本、image、套件版本。
- 環境變數、feature flag、connection pool 設定。
- 最近是否剛部署或調整設定。
- 流量、endpoint 分布與下游依賴 latency。
- DNS、網路、sidecar 或主機設定差異。

## 修復與後續

修正後先在隔離狀態觀察 latency、error rate 與 timeout 是否恢復，再重新加入 Load Balancer。若短時間查不出原因但異常持續，會先保留 log 與監控資料，再汰換該台機器，避免單點持續影響服務。

後續補上 per-target latency、connection pool、TCP retransmit、Disk I/O 與下游 dependency latency 的告警，讓下一次能更快判斷問題是在主機、應用程式或網路。
