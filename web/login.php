<?php
session_start();

$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    // 漏洞：SQL Injection — 直接拼接使用者輸入
    mysqli_report(MYSQLI_REPORT_OFF);
    $conn = @new mysqli('127.0.0.1', 'root', 'rootpass', 'vulnlab');

    if ($conn->connect_error) {
        die("資料庫連線失敗: " . $conn->connect_error);
    }

    // 危險！未使用 prepared statement
    $sql = "SELECT * FROM users WHERE username = '$username' AND password = '$password'";
    $result = $conn->query($sql);

    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $_SESSION['user_id']  = $row['id'];
        $_SESSION['username'] = $row['username'];
        $_SESSION['role']     = $row['role'];
        // 登入成功後跳轉到管理後台
        header('Location: /admin/');
        exit;
    } else {
        // 漏洞：錯誤訊息洩漏 SQL 細節
        $message = "<div style='color:red'>登入失敗。查詢：" . htmlspecialchars($sql) . "</div>";
    }
    $conn->close();
}
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>登入 — VulnLab</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 400px; margin: auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        input[type=text], input[type=password] { width: 100%; padding: 10px; margin: 8px 0; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px; }
        button { width: 100%; padding: 10px; background: #0066cc; color: #fff; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
        button:hover { background: #0055aa; }
        a { color: #0066cc; }
    </style>
</head>
<body>
<div class="container">
    <h2>使用者登入</h2>
    <?php echo $message; ?>
    <form method="POST" action="">
        <label>帳號：</label>
        <input type="text" name="username" placeholder="請輸入帳號">
        <label>密碼：</label>
        <input type="password" name="password" placeholder="請輸入密碼">
        <button type="submit">登入</button>
    </form>
    <p style="margin-top:15px"><a href="/">← 回首頁</a></p>
</div>
</body>
</html>
