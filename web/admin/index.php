<?php
/**
 * 漏洞：管理後台無存取控制
 * 沒有驗證使用者是否為管理員即可存取
 */
session_start();

// 登出處理
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    session_destroy();
    header('Location: /login.php');
    exit;
}

// 漏洞：只檢查 session 是否存在，沒有檢查角色
// 甚至可以不登入直接存取
$is_admin = isset($_SESSION['username']);

$users = [];
$db_error = '';
mysqli_report(MYSQLI_REPORT_OFF);
$conn = @new mysqli('127.0.0.1', 'root', 'rootpass', 'vulnlab');
if ($conn->connect_error) {
    $db_error = $conn->connect_error;
} else {
    $result = $conn->query("SELECT id, username, email, role, password FROM users ORDER BY id ASC");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $users[] = $row;
        }
    }
    $conn->close();
}
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>管理後台 — VulnLab</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; background: #1e1e2e; color: #cdd6f4; }
        .topbar { background: #181825; padding: 12px 30px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #313244; }
        .topbar h1 { margin: 0; font-size: 20px; color: #f38ba8; }
        .topbar .user-info { display: flex; align-items: center; gap: 15px; }
        .topbar .user-info span { color: #a6adc8; }
        .btn { padding: 6px 14px; border-radius: 4px; text-decoration: none; font-size: 13px; }
        .btn-logout { background: #f38ba8; color: #1e1e2e; }
        .btn-logout:hover { background: #eba0ac; }
        .container { max-width: 960px; margin: 30px auto; padding: 0 20px; }
        .stats { display: flex; gap: 16px; margin-bottom: 30px; }
        .stat-box { flex: 1; background: #313244; padding: 20px; border-radius: 8px; text-align: center; }
        .stat-box .num { font-size: 32px; font-weight: bold; color: #f38ba8; }
        .stat-box .label { color: #a6adc8; margin-top: 4px; font-size: 13px; }
        .card { background: #313244; border-radius: 8px; padding: 20px; margin-bottom: 24px; }
        .card h2 { margin-top: 0; color: #cba6f7; font-size: 16px; border-bottom: 1px solid #45475a; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #45475a; font-size: 14px; }
        th { color: #a6adc8; font-weight: 600; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }
        td { color: #cdd6f4; }
        tr:hover td { background: #45475a; }
        .role-admin { color: #f38ba8; font-weight: bold; }
        .role-user { color: #a6e3a1; }
        .role-other { color: #fab387; }
        pre { background: #181825; padding: 15px; border-radius: 6px; font-size: 13px; line-height: 1.6; overflow-x: auto; color: #a6e3a1; margin: 0; }
        .nav-bottom { margin-top: 20px; text-align: center; }
        .nav-bottom a { color: #89b4fa; text-decoration: none; }
        .nav-bottom a:hover { text-decoration: underline; }
        .db-error { background: #45475a; color: #f38ba8; padding: 12px; border-radius: 6px; }
    </style>
</head>
<body>

<div class="topbar">
    <h1>VulnLab 管理後台</h1>
    <div class="user-info">
        <span>歡迎，<?php echo htmlspecialchars($_SESSION['username'] ?? '訪客'); ?></span>
        <a href="/admin/?action=logout" class="btn btn-logout">登出</a>
    </div>
</div>

<div class="container">
    <?php if ($db_error): ?>
        <div class="db-error">資料庫連線失敗：<?php echo htmlspecialchars($db_error); ?></div>
    <?php endif; ?>

    <div class="stats">
        <div class="stat-box">
            <div class="num"><?php echo count($users); ?></div>
            <div class="label">使用者</div>
        </div>
        <div class="stat-box">
            <div class="num">5</div>
            <div class="label">服務運行中</div>
        </div>
        <div class="stat-box">
            <div class="num">3</div>
            <div class="label">待處理告警</div>
        </div>
    </div>

    <div class="card">
        <h2>使用者列表</h2>
        <?php if (count($users) > 0): ?>
        <table>
            <thead>
                <tr><th>ID</th><th>帳號</th><th>Email</th><th>角色</th><th>密碼（明文）</th></tr>
            </thead>
            <tbody>
            <?php foreach ($users as $u): ?>
                <?php
                    $role_class = 'role-other';
                    if ($u['role'] === 'admin') $role_class = 'role-admin';
                    elseif ($u['role'] === 'user') $role_class = 'role-user';
                ?>
                <tr>
                    <td><?php echo htmlspecialchars($u['id']); ?></td>
                    <td><?php echo htmlspecialchars($u['username']); ?></td>
                    <td><?php echo htmlspecialchars($u['email']); ?></td>
                    <td class="<?php echo $role_class; ?>"><?php echo htmlspecialchars($u['role']); ?></td>
                    <td><?php echo htmlspecialchars($u['password']); ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        <?php else: ?>
            <p style="color:#a6adc8">無使用者資料。</p>
        <?php endif; ?>
    </div>

    <div class="card">
        <h2>系統資訊</h2>
        <pre>
伺服器：<?php echo php_uname(); ?>

PHP 版本：<?php echo phpversion(); ?>

資料庫主機：127.0.0.1
資料庫帳號：root
資料庫密碼：rootpass</pre>
    </div>

    <div class="nav-bottom">
        <a href="/">← 回首頁</a>
    </div>
</div>

</body>
</html>
