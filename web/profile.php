<?php
/**
 * 漏洞：IDOR (Insecure Direct Object Reference)
 * 任何人都可以透過修改 ?id= 參數查看其他使用者的資料
 * 沒有驗證登入狀態或權限
 */
session_start();

$user = null;

if (isset($_GET['id'])) {
    $id = $_GET['id'];

    mysqli_report(MYSQLI_REPORT_OFF);
    $conn = @new mysqli('127.0.0.1', 'root', 'rootpass', 'vulnlab');
    if (!$conn->connect_error) {
        // 漏洞：未驗證目前使用者是否有權查看此 ID
        // 也存在 SQL Injection
        $sql = "SELECT * FROM users WHERE id = $id";
        $result = $conn->query($sql);
        if ($result && $result->num_rows > 0) {
            $user = $result->fetch_assoc();
        }
        $conn->close();
    }
}
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>個人資料 — VulnLab</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 500px; margin: auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #f0f0f0; width: 30%; }
        a { color: #0066cc; }
        .hint { color: #999; font-size: 12px; }
    </style>
</head>
<body>
<div class="container">
    <h2>使用者資料</h2>

    <?php if ($user): ?>
    <table>
        <tr><th>ID</th><td><?php echo htmlspecialchars($user['id']); ?></td></tr>
        <tr><th>帳號</th><td><?php echo htmlspecialchars($user['username']); ?></td></tr>
        <tr><th>Email</th><td><?php echo htmlspecialchars($user['email']); ?></td></tr>
        <tr><th>角色</th><td><?php echo htmlspecialchars($user['role']); ?></td></tr>
        <!-- 漏洞：密碼直接顯示 -->
        <tr><th>密碼</th><td><?php echo htmlspecialchars($user['password']); ?></td></tr>
    </table>
    <p class="hint">提示：試試修改網址中的 id 參數 ?id=2, ?id=3 ...</p>
    <?php else: ?>
        <p>找不到使用者。請提供 ?id=1 參數。</p>
    <?php endif; ?>

    <p style="margin-top:15px"><a href="/">← 回首頁</a></p>
</div>
</body>
</html>
