# VulnLab — 資安練習靶機

> **警告：此環境僅供教育與授權滲透測試使用，請勿部署在公開網路上。**

## 快速啟動

```bash
# 建置並啟動
docker compose up -d --build

# 查看日誌
docker logs -f vulnlab
```

## 服務與連線方式

| 服務     | 容器埠 | 對映埠 | 帳號 / 密碼               |
|----------|--------|--------|---------------------------|
| SSH      | 22     | 2222   | `root:root` / `admin:admin` |
| FTP      | 21     | 2121   | anonymous / `admin:admin`  |
| Telnet   | 23     | 2323   | `admin:admin`              |
| HTTP     | 80     | 8080   | 瀏覽器開啟                  |
| MySQL    | 3306   | 33060  | `root:rootpass`            |

## 練習情境

### 1. 弱密碼 / 預設密碼風險
- SSH、FTP、Telnet 都有弱密碼帳號
- MySQL 使用預設密碼
- Web 管理後台預設帳號 `admin / admin123`
- **練習**：使用 Hydra 或 Medusa 進行暴力破解

```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://localhost:2222
```

### 2. 服務掃描與攻擊面盤點
- 開放 5 個服務埠 (21, 22, 23, 80, 3306)
- Telnet 明文傳輸
- FTP 允許匿名登入
- **練習**：使用 Nmap 掃描

```bash
nmap -sV -sC -p 2121,2222,2323,8080,33060 localhost
```

### 3. Web 管理介面 / 敏感路徑暴露
- `/admin/` — 無存取控制的管理後台
- `/info.php` — phpinfo() 資訊洩漏
- `/.git/` — Git 儲存庫洩漏
- `/backup/` — 資料庫備份檔暴露
- `/robots.txt` — 洩漏所有敏感路徑
- `/server-status` — Apache 狀態頁面
- **練習**：使用 dirb / gobuster 掃描

```bash
dirb http://localhost:8080
gobuster dir -u http://localhost:8080 -w /usr/share/wordlists/dirb/common.txt
```

### 4. Web 請求觀察與參數濫用
| 頁面 | 漏洞類型 | 測試方式 |
|------|---------|---------|
| `/login.php` | SQL Injection | `' OR 1=1 --` |
| `/search.php` | Reflected XSS + SQLi | `<script>alert(1)</script>` |
| `/profile.php?id=1` | IDOR | 修改 `id=2`, `id=3` |
| `/ping.php` | Command Injection | `127.0.0.1; cat /etc/passwd` |

```bash
# SQL Injection 測試
curl -X POST http://localhost:8080/login.php \
  -d "username=admin' OR 1=1 --&password=x"

# Command Injection 測試
curl -X POST http://localhost:8080/ping.php \
  -d "host=127.0.0.1;id"
```

### 5. 弱點驗證與修補後確認

```bash
# 進入容器
docker exec -it vulnlab bash

# 修補前先執行驗證（全部 FAIL）
bash /opt/scripts/verify-fix.sh

# 執行修補（可選擇全部或個別修補）
bash /opt/scripts/fix-vulns.sh --all
bash /opt/scripts/fix-vulns.sh --web       # 僅修補 Web
bash /opt/scripts/fix-vulns.sh --passwords # 僅修補密碼

# 修補後再次驗證（應全部 PASS）
bash /opt/scripts/verify-fix.sh
```

## 檔案結構

```
kalilab/
├── Dockerfile              # 靶機映像定義
├── docker-compose.yml      # 容器編排
├── config/
│   ├── apache-vuln.conf    # Apache 不安全配置
│   ├── vsftpd.conf         # FTP 不安全配置
│   ├── telnet.xinetd       # Telnet 配置
│   └── mysql-init.sql      # 資料庫初始化（含弱密碼）
├── web/
│   ├── index.php           # 首頁（含敏感註解）
│   ├── login.php           # SQL Injection
│   ├── search.php          # XSS + SQL Injection
│   ├── profile.php         # IDOR
│   ├── ping.php            # Command Injection
│   ├── robots.txt          # 路徑洩漏
│   ├── admin/index.php     # 無存取控制的管理後台
│   └── backup/db_dump.sql  # 暴露的資料庫備份
└── scripts/
    ├── startup.sh          # 服務啟動腳本
    ├── fix-vulns.sh        # 弱點修補腳本
    └── verify-fix.sh       # 修補驗證腳本
```

## 涵蓋的弱點清單

| # | 弱點                         | OWASP/CWE        |
|---|------------------------------|-------------------|
| 1 | SQL Injection                | A03 / CWE-89     |
| 2 | Command Injection            | A03 / CWE-78     |
| 3 | Reflected XSS                | A03 / CWE-79     |
| 4 | IDOR                         | A01 / CWE-639    |
| 5 | 弱密碼 / 預設密碼             | A07 / CWE-521    |
| 6 | 敏感資料暴露 (phpinfo, .git)  | A01 / CWE-200    |
| 7 | 管理後台無存取控制             | A01 / CWE-284    |
| 8 | 密碼明文儲存                  | A02 / CWE-256    |
| 9 | 目錄列表                      | A05 / CWE-548    |
|10 | 伺服器版本洩漏                | A05 / CWE-200    |
|11 | 不安全協定 (Telnet, FTP)      | A02 / CWE-319    |
|12 | 匿名 FTP 存取                | A01 / CWE-284    |
|13 | SSH root 登入                | A05 / CWE-250    |
|14 | 備份檔暴露                    | A05 / CWE-530    |
|15 | robots.txt 資訊洩漏           | A01 / CWE-200    |
