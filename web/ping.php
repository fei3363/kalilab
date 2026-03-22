<?php
/**
 * 漏洞：OS Command Injection
 * 使用者輸入直接拼接到 shell 命令中
 */
$output = '';
$host = '';

if (isset($_POST['host'])) {
    $host = $_POST['host'];
    // 漏洞：未過濾使用者輸入，直接執行系統命令
    // 攻擊範例：127.0.0.1; cat /etc/passwd
    //           127.0.0.1 && whoami
    //           127.0.0.1 | id
    $output = shell_exec("ping -c 3 " . $host . " 2>&1");
}
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>網路診斷 — VulnLab</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 700px; margin: auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        input[type=text] { width: 60%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; }
        button { padding: 10px 20px; background: #0066cc; color: #fff; border: none; border-radius: 4px; cursor: pointer; }
        pre { background: #1e1e1e; color: #0f0; padding: 15px; border-radius: 4px; overflow-x: auto; }
        a { color: #0066cc; }
    </style>
</head>
<body>
<div class="container">
    <h2>網路診斷工具</h2>
    <p>輸入主機名稱或 IP 位址進行 Ping 測試：</p>
    <form method="POST">
        <input type="text" name="host" value="<?php echo htmlspecialchars($host); ?>" placeholder="例如：127.0.0.1">
        <button type="submit">Ping</button>
    </form>

    <?php if ($output): ?>
        <h3>執行結果：</h3>
        <pre><?php echo htmlspecialchars($output); ?></pre>
    <?php endif; ?>

    <p style="margin-top:15px"><a href="/">← 回首頁</a></p>
</div>
</body>
</html>
