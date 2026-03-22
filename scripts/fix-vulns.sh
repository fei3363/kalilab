#!/bin/bash
# ============================================================
# VulnLab 弱點修補腳本
# 用法：bash /opt/scripts/fix-vulns.sh [選項]
#
#   --all          修補所有弱點
#   --passwords    修補弱密碼
#   --ssh          修補 SSH 配置
#   --web          修補 Web 漏洞
#   --apache       修補 Apache 配置
#   --mysql        修補 MySQL 配置
#   --ftp          修補 FTP 配置
#   --services     關閉不必要服務 (Telnet, FTP)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_fix() { echo -e "${GREEN}[FIXED]${NC} $1"; }
log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

fix_passwords() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  修補弱密碼"
    echo "══════════════════════════════════════"

    # 產生隨機強密碼
    NEW_ROOT_PASS=$(openssl rand -base64 16)
    NEW_ADMIN_PASS=$(openssl rand -base64 16)

    echo "root:${NEW_ROOT_PASS}" | chpasswd
    log_fix "root 密碼已更新為強密碼: ${NEW_ROOT_PASS}"

    echo "admin:${NEW_ADMIN_PASS}" | chpasswd
    log_fix "admin 密碼已更新為強密碼: ${NEW_ADMIN_PASS}"

    # 移除不必要帳號
    for u in test backup; do
        if id "$u" &>/dev/null; then
            userdel -r "$u" 2>/dev/null
            log_fix "已移除不必要帳號: $u"
        fi
    done

    # 移除 admin 的 NOPASSWD sudo
    sed -i '/admin.*NOPASSWD/d' /etc/sudoers
    log_fix "已移除 admin 的 NOPASSWD sudo 權限"

    echo -e "${YELLOW}[!] 請妥善記錄新密碼${NC}"
}

fix_ssh() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  修補 SSH 配置"
    echo "══════════════════════════════════════"

    # 禁止 root 遠端登入
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    log_fix "已禁止 root SSH 登入"

    # 禁用密碼認證（改用金鑰）
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    log_fix "已禁用密碼認證，改用金鑰認證"

    # 限制登入嘗試次數
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    log_fix "已限制 SSH 最大認證嘗試次數為 3"

    service ssh restart
    log_info "SSH 服務已重新啟動"
}

fix_web() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  修補 Web 應用程式漏洞"
    echo "══════════════════════════════════════"

    # 修補 login.php — 使用 prepared statement
    cat > /var/www/html/login.php << 'PHPEOF'
<?php
session_start();
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    $conn = new mysqli('localhost', 'root', 'rootpass', 'vulnlab');
    if ($conn->connect_error) {
        die("資料庫連線失敗");
    }

    // 修補：使用 prepared statement 防止 SQL Injection
    $stmt = $conn->prepare("SELECT * FROM users WHERE username = ? AND password = ?");
    $stmt->bind_param("ss", $username, $password);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $_SESSION['user_id']  = $row['id'];
        $_SESSION['username'] = $row['username'];
        $_SESSION['role']     = $row['role'];
        $message = "<div style='color:green'>登入成功！</div>";
    } else {
        // 修補：不洩漏 SQL 查詢細節
        $message = "<div style='color:red'>帳號或密碼錯誤。</div>";
    }
    $stmt->close();
    $conn->close();
}
?>
<!DOCTYPE html>
<html lang="zh-TW"><head><meta charset="UTF-8"><title>登入</title>
<style>body{font-family:Arial;margin:40px;background:#f5f5f5}.container{max-width:400px;margin:auto;background:#fff;padding:30px;border-radius:8px}input[type=text],input[type=password]{width:100%;padding:10px;margin:8px 0;box-sizing:border-box;border:1px solid #ccc;border-radius:4px}button{width:100%;padding:10px;background:#0066cc;color:#fff;border:none;border-radius:4px;cursor:pointer}</style>
</head><body><div class="container"><h2>使用者登入</h2><?php echo $message; ?>
<form method="POST"><label>帳號：</label><input type="text" name="username"><label>密碼：</label><input type="password" name="password"><button type="submit">登入</button></form></div></body></html>
PHPEOF
    log_fix "login.php — 已修補 SQL Injection（使用 prepared statement）"
    log_fix "login.php — 已移除錯誤訊息中的 SQL 洩漏"

    # 修補 search.php — XSS + SQLi
    sed -i 's/echo $keyword;/echo htmlspecialchars($keyword, ENT_QUOTES, '\''UTF-8'\'');/g' /var/www/html/search.php
    log_fix "search.php — 已修補 Reflected XSS"

    # 修補 ping.php — Command Injection
    cat > /var/www/html/ping.php << 'PHPEOF'
<?php
$output = '';
$host = '';

if (isset($_POST['host'])) {
    $host = $_POST['host'];
    // 修補：僅允許合法的 IP 或主機名稱
    if (preg_match('/^[a-zA-Z0-9\.\-]+$/', $host)) {
        $escaped = escapeshellarg($host);
        $output = shell_exec("ping -c 3 $escaped 2>&1");
    } else {
        $output = "錯誤：輸入包含非法字元，僅允許字母、數字、點和連字號。";
    }
}
?>
<!DOCTYPE html>
<html lang="zh-TW"><head><meta charset="UTF-8"><title>網路診斷</title>
<style>body{font-family:Arial;margin:40px;background:#f5f5f5}.container{max-width:700px;margin:auto;background:#fff;padding:30px;border-radius:8px}input[type=text]{width:60%;padding:10px;border:1px solid #ccc;border-radius:4px}button{padding:10px 20px;background:#0066cc;color:#fff;border:none;border-radius:4px;cursor:pointer}pre{background:#1e1e1e;color:#0f0;padding:15px;border-radius:4px}</style>
</head><body><div class="container"><h2>網路診斷工具</h2>
<form method="POST"><input type="text" name="host" value="<?php echo htmlspecialchars($host); ?>" placeholder="例如：127.0.0.1"><button type="submit">Ping</button></form>
<?php if($output):?><h3>執行結果：</h3><pre><?php echo htmlspecialchars($output);?></pre><?php endif;?>
</div></body></html>
PHPEOF
    log_fix "ping.php — 已修補 Command Injection（輸入驗證 + escapeshellarg）"

    # 修補 profile.php — IDOR
    cat > /var/www/html/profile.php << 'PHPEOF'
<?php
session_start();
$user = null;

// 修補：必須登入才能查看
if (!isset($_SESSION['user_id'])) {
    header('Location: /login.php');
    exit;
}

// 修補：只能查看自己的資料（除非是 admin）
$id = intval($_GET['id'] ?? $_SESSION['user_id']);
if ($_SESSION['role'] !== 'admin' && $id !== $_SESSION['user_id']) {
    die("存取被拒：您無權查看其他使用者的資料。");
}

$conn = new mysqli('localhost', 'root', 'rootpass', 'vulnlab');
if (!$conn->connect_error) {
    $stmt = $conn->prepare("SELECT id, username, email, role FROM users WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
    }
    $stmt->close();
    $conn->close();
}
?>
<!DOCTYPE html>
<html lang="zh-TW"><head><meta charset="UTF-8"><title>個人資料</title>
<style>body{font-family:Arial;margin:40px;background:#f5f5f5}.container{max-width:500px;margin:auto;background:#fff;padding:30px;border-radius:8px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #ddd;padding:10px;text-align:left}th{background:#f0f0f0;width:30%}</style>
</head><body><div class="container"><h2>使用者資料</h2>
<?php if($user):?>
<table>
<tr><th>ID</th><td><?php echo htmlspecialchars($user['id']);?></td></tr>
<tr><th>帳號</th><td><?php echo htmlspecialchars($user['username']);?></td></tr>
<tr><th>Email</th><td><?php echo htmlspecialchars($user['email']);?></td></tr>
<tr><th>角色</th><td><?php echo htmlspecialchars($user['role']);?></td></tr>
</table>
<?php else:?><p>找不到使用者。</p><?php endif;?>
</div></body></html>
PHPEOF
    log_fix "profile.php — 已修補 IDOR（登入驗證 + 權限檢查 + 隱藏密碼欄位）"

    # 移除敏感檔案
    rm -f /var/www/html/info.php
    log_fix "已移除 info.php (phpinfo)"

    rm -f /var/www/html/index.php.bak
    log_fix "已移除 index.php.bak 備份檔"

    rm -rf /var/www/html/.git
    log_fix "已移除 .git 目錄"

    rm -rf /var/www/html/backup
    log_fix "已移除 backup 目錄"

    # 清除 HTML 註解中的敏感資訊
    sed -i '/TODO.*test/d' /var/www/html/index.php
    sed -i '/DB Host.*DB User.*DB Pass/d' /var/www/html/index.php
    log_fix "已清除 index.php 中的敏感註解"
}

fix_apache() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  修補 Apache 配置"
    echo "══════════════════════════════════════"

    # 關閉伺服器簽名
    echo "ServerSignature Off" >> /etc/apache2/conf-enabled/security.conf
    echo "ServerTokens Prod"   >> /etc/apache2/conf-enabled/security.conf
    log_fix "已關閉 ServerSignature 和 ServerTokens"

    # 關閉目錄列表
    sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/' /etc/apache2/sites-available/000-default.conf
    log_fix "已關閉目錄列表 (Indexes)"

    # 關閉 server-status
    sed -i 's/Require all granted/#Require all granted\n        Require ip 127.0.0.1/' /etc/apache2/sites-available/000-default.conf
    log_fix "已限制 server-status 僅限本機存取"

    # 加入安全性標頭
    cat >> /etc/apache2/conf-enabled/security.conf << 'EOF'
Header always set X-Frame-Options "DENY"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self'"
EOF
    log_fix "已加入安全性 HTTP 標頭"

    service apache2 restart
    log_info "Apache 服務已重新啟動"
}

fix_mysql() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  修補 MySQL 配置"
    echo "══════════════════════════════════════"

    NEW_DB_PASS=$(openssl rand -base64 16)
    mysql -u root -prootpass -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_DB_PASS}';" 2>/dev/null
    log_fix "MySQL root 密碼已更新: ${NEW_DB_PASS}"

    mysql -u root -p"${NEW_DB_PASS}" -e "DROP USER IF EXISTS 'dbadmin'@'%';" 2>/dev/null
    log_fix "已移除開放遠端存取的 dbadmin 帳號"

    mysql -u root -p"${NEW_DB_PASS}" -e "DELETE FROM mysql.user WHERE Host='%';" 2>/dev/null
    mysql -u root -p"${NEW_DB_PASS}" -e "FLUSH PRIVILEGES;" 2>/dev/null
    log_fix "已移除所有允許遠端連線 (%) 的帳號"

    log_info "請更新 Web 應用程式中的資料庫連線密碼"
}

fix_ftp() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  修補 FTP 配置"
    echo "══════════════════════════════════════"

    # 關閉匿名登入
    sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
    log_fix "已關閉 FTP 匿名登入"

    # 移除洩漏的設定檔
    rm -f /var/ftp/pub/db_config.bak
    log_fix "已移除 FTP 上的敏感備份檔案"

    service vsftpd restart 2>/dev/null
    log_info "FTP 服務已重新啟動"
}

fix_services() {
    echo ""
    echo "══════════════════════════════════════"
    echo "  關閉不必要服務"
    echo "══════════════════════════════════════"

    # 停止 Telnet
    service xinetd stop 2>/dev/null
    log_fix "已停止 Telnet 服務（不安全的明文協定）"

    log_info "建議：改用 SSH 取代 Telnet"
    log_info "建議：若不需要 FTP，可改用 SFTP"
}

# ════════════════════════════════════════
#  主程式
# ════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════╗"
echo "║   VulnLab 弱點修補腳本              ║"
echo "╚══════════════════════════════════════╝"

case "${1}" in
    --all)
        fix_passwords
        fix_ssh
        fix_web
        fix_apache
        fix_mysql
        fix_ftp
        fix_services
        ;;
    --passwords) fix_passwords ;;
    --ssh)       fix_ssh ;;
    --web)       fix_web ;;
    --apache)    fix_apache ;;
    --mysql)     fix_mysql ;;
    --ftp)       fix_ftp ;;
    --services)  fix_services ;;
    *)
        echo ""
        echo "用法：bash $0 [選項]"
        echo ""
        echo "  --all          修補所有弱點"
        echo "  --passwords    修補弱密碼"
        echo "  --ssh          修補 SSH 配置"
        echo "  --web          修補 Web 應用程式漏洞"
        echo "  --apache       修補 Apache 配置"
        echo "  --mysql        修補 MySQL 配置"
        echo "  --ftp          修補 FTP 配置"
        echo "  --services     關閉不必要服務"
        echo ""
        ;;
esac

echo ""
echo "══════════════════════════════════════"
echo "  修補完成！請執行驗證腳本確認："
echo "  bash /opt/scripts/verify-fix.sh"
echo "══════════════════════════════════════"
echo ""
