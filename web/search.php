<?php
/**
 * 漏洞：Reflected XSS + SQL Injection
 * 使用者輸入未經過濾直接輸出到頁面 & 拼入 SQL
 */
$results = [];
$keyword = '';

if (isset($_GET['q'])) {
    $keyword = $_GET['q'];

    mysqli_report(MYSQLI_REPORT_OFF);
    $conn = @new mysqli('127.0.0.1', 'root', 'rootpass', 'vulnlab');
    if (!$conn->connect_error) {
        // SQL Injection
        $sql = "SELECT * FROM products WHERE name LIKE '%$keyword%' OR description LIKE '%$keyword%'";
        $result = $conn->query($sql);
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $results[] = $row;
            }
        }
        $conn->close();
    }
}
?>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>搜尋 — VulnLab</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 700px; margin: auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        input[type=text] { width: 70%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; }
        button { padding: 10px 20px; background: #0066cc; color: #fff; border: none; border-radius: 4px; cursor: pointer; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #f0f0f0; }
        a { color: #0066cc; }
    </style>
</head>
<body>
<div class="container">
    <h2>產品搜尋</h2>
    <form method="GET">
        <input type="text" name="q" value="<?php echo $keyword; ?>" placeholder="輸入關鍵字...">
        <!-- ↑ 漏洞：XSS — $keyword 未經 htmlspecialchars 處理 -->
        <button type="submit">搜尋</button>
    </form>

    <?php if ($keyword): ?>
        <!-- 漏洞：Reflected XSS -->
        <p>搜尋結果：「<?php echo $keyword; ?>」</p>

        <?php if (count($results) > 0): ?>
        <table>
            <tr><th>ID</th><th>名稱</th><th>描述</th><th>價格</th></tr>
            <?php foreach ($results as $row): ?>
            <tr>
                <td><?php echo $row['id']; ?></td>
                <td><?php echo htmlspecialchars($row['name']); ?></td>
                <td><?php echo $row['description']; ?></td>
                <td><?php echo $row['price']; ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
        <?php else: ?>
            <p>找不到相關結果。</p>
        <?php endif; ?>
    <?php endif; ?>

    <p style="margin-top:15px"><a href="/">← 回首頁</a></p>
</div>
</body>
</html>
