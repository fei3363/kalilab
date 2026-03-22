#!/bin/bash
# VulnLab 啟動腳本 — 啟動所有服務

echo "=========================================="
echo "  VulnLab — 資安練習靶機"
echo "  ⚠  僅供教育與授權測試使用"
echo "=========================================="

# 啟動 MySQL
echo "[*] 啟動 MySQL..."
mysqld_safe --bind-address=0.0.0.0 &

# 等待 MySQL 完全啟動（最多 30 秒）
echo "[*] 等待 MySQL 就緒..."
for i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        echo "[+] MySQL 已就緒 (${i}s)"
        break
    fi
    sleep 1
done

# 初始化資料庫
if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
    echo "[*] 初始化資料庫..."
    # 設定 root 密碼（首次可能無密碼，之後有密碼）
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpass'; FLUSH PRIVILEGES;" 2>/dev/null \
    || mysql -u root -prootpass -e "SELECT 1" 2>/dev/null
    # 匯入初始資料
    mysql -u root -prootpass < /docker-entrypoint-initdb.d/init.sql 2>/dev/null
    echo "[+] 資料庫初始化完成（$(mysql -u root -prootpass -N -e 'SELECT COUNT(*) FROM vulnlab.users' 2>/dev/null) 位使用者）"
fi

# 啟動 SSH
echo "[*] 啟動 SSH (Port 22)..."
service ssh start

# 啟動 Apache
echo "[*] 啟動 Apache (Port 80)..."
service apache2 start

# 啟動 FTP
echo "[*] 啟動 vsftpd (Port 21)..."
service vsftpd start

# 啟動 Telnet (via xinetd)
echo "[*] 啟動 Telnet (Port 23)..."
service xinetd start

echo ""
echo "=========================================="
echo "  所有服務已啟動"
echo "=========================================="
echo ""
echo "  服務列表："
echo "  ─────────────────────────────────"
echo "  [SSH]    Port 22  — root:root / admin:admin"
echo "  [FTP]    Port 21  — anonymous / admin:admin"
echo "  [HTTP]   Port 80  — Web 管理介面"
echo "  [Telnet] Port 23  — admin:admin"
echo "  [MySQL]  Port 3306 — root:rootpass"
echo "  ─────────────────────────────────"
echo ""
echo "  敏感路徑："
echo "    http://<IP>/admin/        管理後台"
echo "    http://<IP>/info.php      PHP 資訊"
echo "    http://<IP>/backup/       備份檔案"
echo "    http://<IP>/.git/         Git 儲存庫"
echo "    http://<IP>/robots.txt    路徑洩漏"
echo "    http://<IP>/server-status Apache 狀態"
echo ""
echo "  漏洞頁面："
echo "    /login.php    — SQL Injection"
echo "    /search.php   — XSS + SQLi"
echo "    /profile.php  — IDOR"
echo "    /ping.php     — Command Injection"
echo ""
echo "  修補腳本：/opt/scripts/fix-vulns.sh"
echo "  驗證腳本：/opt/scripts/verify-fix.sh"
echo ""

# 保持容器運行
tail -f /var/log/apache2/access.log /var/log/apache2/error.log
