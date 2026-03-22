#!/bin/bash
# ============================================================
# VulnLab 弱點驗證腳本
# 檢查各項弱點是否已被成功修補
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS++)); }
check_fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL++)); }
check_warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((WARN++)); }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   VulnLab 弱點驗證報告              ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ──────────────────────────────────────
echo "【1】弱密碼檢查"
echo "────────────────────────────────────"

# 檢查 root 是否使用弱密碼
if echo 'root' | su -c "echo ok" root 2>/dev/null | grep -q "ok"; then
    check_fail "root 仍使用弱密碼 'root'"
else
    check_pass "root 密碼已變更"
fi

# 檢查不必要帳號
for u in test backup; do
    if id "$u" &>/dev/null; then
        check_fail "不必要帳號 '$u' 仍然存在"
    else
        check_pass "帳號 '$u' 已移除"
    fi
done

# 檢查 NOPASSWD sudo
if grep -q "NOPASSWD" /etc/sudoers 2>/dev/null; then
    check_fail "sudoers 中仍有 NOPASSWD 設定"
else
    check_pass "sudoers 已移除 NOPASSWD"
fi

echo ""

# ──────────────────────────────────────
echo "【2】SSH 配置檢查"
echo "────────────────────────────────────"

if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    check_pass "SSH 已禁止 root 登入"
else
    check_fail "SSH 仍允許 root 登入"
fi

if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    check_pass "SSH 已禁用密碼認證"
else
    check_fail "SSH 仍允許密碼認證"
fi

if grep -q "MaxAuthTries" /etc/ssh/sshd_config; then
    check_pass "SSH 已設定登入嘗試限制"
else
    check_warn "SSH 未設定 MaxAuthTries"
fi

echo ""

# ──────────────────────────────────────
echo "【3】Web 敏感路徑檢查"
echo "────────────────────────────────────"

if [ -f /var/www/html/info.php ]; then
    check_fail "info.php (phpinfo) 仍然存在"
else
    check_pass "info.php 已移除"
fi

if [ -f /var/www/html/index.php.bak ]; then
    check_fail "index.php.bak 備份檔仍然存在"
else
    check_pass "index.php.bak 已移除"
fi

if [ -d /var/www/html/.git ]; then
    check_fail ".git 目錄仍然存在"
else
    check_pass ".git 目錄已移除"
fi

if [ -d /var/www/html/backup ]; then
    check_fail "backup 目錄仍然存在"
else
    check_pass "backup 目錄已移除"
fi

echo ""

# ──────────────────────────────────────
echo "【4】Web 應用程式漏洞檢查"
echo "────────────────────────────────────"

# 檢查 SQL Injection
if grep -q "prepare" /var/www/html/login.php 2>/dev/null; then
    check_pass "login.php 使用 prepared statement"
else
    check_fail "login.php 未使用 prepared statement（SQL Injection 風險）"
fi

# 檢查 Command Injection
if grep -q "escapeshellarg\|preg_match" /var/www/html/ping.php 2>/dev/null; then
    check_pass "ping.php 已加入輸入驗證"
else
    check_fail "ping.php 未驗證輸入（Command Injection 風險）"
fi

# 檢查 IDOR
if grep -q "session\|SESSION" /var/www/html/profile.php 2>/dev/null && \
   grep -q "role\|permission\|auth" /var/www/html/profile.php 2>/dev/null; then
    check_pass "profile.php 已加入存取控制"
else
    check_fail "profile.php 缺少存取控制（IDOR 風險）"
fi

# 檢查 XSS
if grep -q 'echo $keyword;' /var/www/html/search.php 2>/dev/null; then
    check_fail "search.php 存在 Reflected XSS"
else
    check_pass "search.php XSS 已修補"
fi

# 檢查 HTML 註解中的敏感資訊
if grep -q "DB Pass\|test123" /var/www/html/index.php 2>/dev/null; then
    check_fail "index.php 中仍有敏感註解"
else
    check_pass "index.php 敏感註解已清除"
fi

echo ""

# ──────────────────────────────────────
echo "【5】Apache 配置檢查"
echo "────────────────────────────────────"

if grep -q "ServerSignature Off" /etc/apache2/conf-enabled/security.conf 2>/dev/null; then
    check_pass "ServerSignature 已關閉"
else
    check_fail "ServerSignature 仍然開啟（版本資訊洩漏）"
fi

if grep -q "X-Frame-Options" /etc/apache2/conf-enabled/security.conf 2>/dev/null; then
    check_pass "安全性 HTTP 標頭已設定"
else
    check_fail "缺少安全性 HTTP 標頭"
fi

if grep -q "\-Indexes" /etc/apache2/sites-available/000-default.conf 2>/dev/null; then
    check_pass "目錄列表已關閉"
else
    check_fail "目錄列表仍然開啟"
fi

echo ""

# ──────────────────────────────────────
echo "【6】服務檢查"
echo "────────────────────────────────────"

if service xinetd status 2>/dev/null | grep -q "running"; then
    check_fail "Telnet (xinetd) 服務仍在運行"
else
    check_pass "Telnet 服務已停止"
fi

if grep -q "anonymous_enable=NO" /etc/vsftpd.conf 2>/dev/null; then
    check_pass "FTP 匿名登入已關閉"
else
    check_fail "FTP 仍允許匿名登入"
fi

if [ -f /var/ftp/pub/db_config.bak ]; then
    check_fail "FTP 上的敏感備份檔案仍然存在"
else
    check_pass "FTP 敏感檔案已清除"
fi

echo ""

# ──────────────────────────────────────
echo "══════════════════════════════════════"
echo "  驗證結果摘要"
echo "══════════════════════════════════════"
echo ""
echo -e "  ${GREEN}通過：${PASS} 項${NC}"
echo -e "  ${RED}失敗：${FAIL} 項${NC}"
echo -e "  ${YELLOW}警告：${WARN} 項${NC}"
echo ""

TOTAL=$((PASS + FAIL + WARN))
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}★ 所有弱點已成功修補！${NC}"
else
    SCORE=$(( (PASS * 100) / TOTAL ))
    echo -e "  修補進度：${SCORE}%（仍有 ${FAIL} 項弱點待修補）"
fi

echo ""
echo "══════════════════════════════════════"
echo ""
