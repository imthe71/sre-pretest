# 情境實戰題三：EC2 服務正常，但無法 SSH

## 問題判斷

EC2 上的服務仍正常，但 SSH 無法登入，且已排除網路與防火牆問題。這表示主機不一定故障，優先檢查 SSH daemon、登入帳號、SSH key、檔案權限與作業系統資源；不會一開始就直接 reboot，以免失去現場資訊。

## 排查順序

### 1. 先取得明確 SSH 錯誤

```bash
ssh -vvv -i key.pem user@host
```

| 錯誤現象 | 優先方向 |
| --- | --- |
| `Connection refused` | `sshd` 未啟動、設定錯誤，或未 listen 在預期 port。 |
| `Permission denied (publickey)` | SSH key、`authorized_keys`、帳號、家目錄權限或 PAM 問題。 |
| 連線後卡住或中斷 | CPU、Memory、Disk、sshd process、PAM 或系統資源異常。 |

### 2. 使用替代管理通道登入

優先順序如下：

1. **AWS Systems Manager Session Manager**：前提是已安裝 SSM Agent，且 Instance Role 具備 SSM 權限。
2. **EC2 Serial Console**：直接查看作業系統 console。
3. **EBS 救援**：前兩種方式都不可用時，先建立 root volume snapshot，再停止原 EC2，將 root EBS 掛到 Rescue EC2 修復，完成後再掛回原機。

EBS 救援會造成服務中斷，因此不是第一選擇；執行前需確認備援、維護窗口與 rollback 方式。

### 3. 登入後檢查 SSH 與系統狀態

```bash
systemctl status sshd
journalctl -u sshd --since "30 minutes ago"
ss -ltnp | grep ':22'
sshd -t

df -h
df -i
free -m
top
dmesg -T | tail -n 100
```

重點檢查：

- `sshd` 是否正常執行、是否有 listen 在預期 port。
- `/etc/ssh/sshd_config` 是否被修改，並以 `sshd -t` 驗證設定語法。
- root filesystem 或 inode 是否滿掉，導致無法寫 log、建立 session 或讀取設定。
- CPU、Memory、swap、process／file descriptor 是否耗盡。
- kernel log 是否出現 disk error、OOM 或其他系統錯誤。

### 4. 檢查帳號與 SSH key

```bash
id user
getent passwd user
ls -ld /home/user /home/user/.ssh
ls -l /home/user/.ssh/authorized_keys
```

確認：

- 使用的 username 是否正確，例如 AMI 常見的 `ec2-user`、`ubuntu`。
- 帳號沒有被 lock，且登入 shell 沒有被改成 `nologin`。
- `authorized_keys` 內容正確。
- 家目錄、`.ssh` 與 `authorized_keys` 的 owner、group、權限正確。
- PAM、`AllowUsers`、`DenyUsers`、`PermitRootLogin` 等 SSH 設定未阻擋登入。

## 可能原因與修復

| 原因 | 修復方式 |
| --- | --- |
| `sshd` 停止或設定錯誤 | 修正設定，執行 `sshd -t` 後 restart `sshd`。 |
| SSH key 或 `authorized_keys` 被覆蓋 | 以受控的 break-glass key 修復，並保留異動紀錄。 |
| 權限或 owner 錯誤 | 修正家目錄、`.ssh`、`authorized_keys` 權限與 owner。 |
| Disk 或 inode 滿 | 清理可安全移除的暫存檔／舊 log，並擴充 EBS。 |
| CPU、Memory、process、file descriptor 耗盡 | 找出異常程序或資源洩漏，修正後再恢復 SSH。 |
| PAM、帳號 lock 或登入 shell 異常 | 修正帳號、PAM 或 SSH 設定後測試登入。 |

## 復原與預防

修復後先以另一個測試連線確認 SSH 正常，再恢復原本使用者登入。若曾把執行個體移出服務，確認應用程式健康檢查、error rate 與 latency 正常後再加入流量。

平時應建立以下機制：

- 預先啟用 SSM Session Manager 與最小權限 Instance Role。
- 建立可稽核的 break-glass 存取流程，不只依賴單一 SSH key。
- 監控 Disk、inode、Memory、process、file descriptor 與 `sshd` 狀態。
- 將 SSH 設定、使用者與 key 管理納入 IaC／Configuration Management。
- 定期演練 SSM、Serial Console 與 EBS rescue 的復原流程。
