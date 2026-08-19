# 情境實戰題四：新服務整合既有 ELK／EFK

## 做法

既有 ELK／EFK 已經有一套 log 收集、欄位、index 與 Kibana 使用方式，因此不會先替新服務另開一套規格。會先盤點現況，再和 RD 對照新服務 log 是否符合既有規範；確認後沿用原本 Fluent Bit／Fluentd／Filebeat 的收集與路由流程整合。

```text
New Service
  → stdout / stderr
  → 既有 Fluent Bit / Fluentd / Filebeat
  → 既有 Elasticsearch index / data stream
  → 既有 Kibana Data View / Dashboard
```

## 1. 先確認既有規範

先確認目前使用的 collector、log parser、index／data stream 命名、index template、retention、Kibana Data View 與存取權限。也會確認既有服務是依 namespace、Pod label、container name，或 service 欄位做路由與查詢。

## 2. 和 RD 對照新服務 log

先和 RD 確認實際除錯情境，例如訂單失敗、付款失敗、第三方 API timeout，以及他們需要用哪些欄位追查問題。

新服務的 log 需要符合既有格式，通常至少包含：

```json
{
  "@timestamp": "2026-08-19T10:00:00Z",
  "level": "error",
  "service": "booking-api",
  "environment": "prod",
  "request_id": "req-123",
  "trace_id": "trace-456",
  "message": "payment gateway timeout",
  "error_code": "PAYMENT_TIMEOUT"
}
```

確認項目：

- 使用結構化 JSON，並輸出至 stdout／stderr。
- `@timestamp`、時區、`level` 命名與既有規範一致。
- `service`、`environment`、`request_id`、`trace_id` 可用來篩選與串接請求。
- 多行 stack trace 能被 collector 合併為同一筆 log。
- password、token、電話、Email 等敏感資料先遮罩，不送進 Elasticsearch。

若不符合規範，會先協助 RD 調整服務 log，再開始接入。

## 3. 沿用原本的收集與路由方式

新服務符合規範後，透過既有 Fluent Bit／Fluentd／Filebeat 設定，以 namespace、Pod label 或 service name 納入原本的 parser、metadata enrichment 與 output 路由。

Index 是否獨立建立，依現有規範決定：

- 原本所有 production 服務共用 index／data stream 時，只要帶上 `service` 與 `environment` 欄位，讓 Kibana 篩選即可。
- 只有 retention、權限、mapping 或 log volume 有特殊需求時，才建立獨立 index／data stream，並一併設定 index template 與 ILM policy。

## 4. Kibana 與驗證

在 Kibana 使用既有 Data View，或依既有命名方式補上新 Data View。確認 RD 可依時間、`service`、`level`、`request_id`、`trace_id` 與 error code 查詢。

最後在測試環境送出 info、error 與 stack trace log，確認：

1. collector 有收集到新服務 log。
2. JSON parser 與欄位型別正確。
3. 沒有敏感資料被寫入 Elasticsearch。
4. Kibana 可在合理時間內查到資料。
5. RD 能用 request ID／trace ID 找到完整的問題線索。

## 結論

重點是先沿用既有 ELK／EFK 標準，和 RD 對齊 log 格式與除錯需求，再用原本的收集方式整合。這樣可以避免 index、欄位與 retention 規則分散，也讓 RD 在 Kibana 能直接用既有方式查詢新服務。
