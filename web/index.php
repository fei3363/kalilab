<?php
session_start();
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>內部管理系統 — VulnLab Corp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        a { color: #0066cc; text-decoration: none; margin-right: 15px; }
        a:hover { text-decoration: underline; }
        .nav { background: #333; padding: 10px 20px; border-radius: 4px; margin-bottom: 20px; }
        .nav a { color: #fff; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 10px; border-radius: 4px; margin: 10px 0; }
    </style>
</head>
<body>
<div class="container">
    <h1>VulnLab Corp — 內部管理系統</h1>
    <div class="nav">
        <a href="/">首頁</a>
        <a href="/admin/">管理後台</a>
        <a href="/login.php">登入</a>
        <a href="/search.php">搜尋</a>
        <a href="/profile.php?id=1">個人資料</a>
        <a href="/ping.php">網路診斷</a>
        <a href="/info.php">系統資訊</a>
        <a href="/server-status">伺服器狀態</a>
    </div>
    <div class="warning">
        <strong>注意：</strong>此系統僅供內部使用，請勿將帳密分享給外部人員。
    </div>
    <h2>公告</h2>
    <ul>
        <li>2026-03-20：新版備份系統上線，備份檔暫存於 /backup/ 目錄</li>
        <li>2026-03-18：管理後台已更新，預設帳號 admin / admin123</li>
        <li>2026-03-15：系統維護完成</li>
    </ul>

    <!-- TODO: 移除測試帳號 test/test123 -->
    <!-- DB Host: localhost, DB User: root, DB Pass: rootpass -->
</div>
</body>
</html>
