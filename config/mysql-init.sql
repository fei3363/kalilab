-- VulnLab 資料庫初始化
-- 包含弱密碼帳號與測試資料

CREATE DATABASE IF NOT EXISTS vulnlab;
USE vulnlab;

-- 使用者表（密碼以明文儲存 — 漏洞）
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入弱密碼帳號
INSERT INTO users (username, password, email, role) VALUES
('admin',    'admin123',    'admin@vulnlab.corp',    'admin'),
('manager',  'manager',     'mgr@vulnlab.corp',      'admin'),
('user1',    'password',    'user1@vulnlab.corp',     'user'),
('user2',    '123456',      'user2@vulnlab.corp',     'user'),
('test',     'test',        'test@vulnlab.corp',      'user'),
('backup',   'backup2024',  'backup@vulnlab.corp',    'operator'),
('api_user', 'api_key_123', 'api@vulnlab.corp',       'service');

-- 產品表（供搜尋功能使用）
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    secret_note TEXT
);

INSERT INTO products (name, description, price, secret_note) VALUES
('Web 防火牆',     '企業級 WAF 解決方案',      50000.00, '供應商後台：admin/Waf@dmin'),
('弱點掃描器',     '自動化弱點掃描工具',        35000.00, '授權金鑰：SCAN-2024-XXXX'),
('日誌分析平台',   'SIEM 日誌收集與分析',       80000.00, 'Elastic 密碼：elastic123'),
('端點防護',       'EDR 端點偵測與回應方案',    45000.00, NULL),
('身份驗證模組',   '多因素驗證 MFA 模組',       20000.00, 'TOTP 種子：BASE32SECRET');

-- 密碼表（模擬儲存在資料庫中的敏感資訊）
CREATE TABLE IF NOT EXISTS credentials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(50),
    username VARCHAR(50),
    password VARCHAR(100),
    notes TEXT
);

INSERT INTO credentials (service_name, username, password, notes) VALUES
('AWS Console',   'vulnlab-admin', 'AwsP@ss2024!',   'Production account'),
('GitHub',        'vulnlab-dev',   'gh_token_fake',   'CI/CD token'),
('Slack Webhook', 'bot',           'xoxb-fake-token', 'Alert channel');

-- 建立遠端存取帳號（漏洞：% 允許任何 IP 連線）
CREATE USER IF NOT EXISTS 'dbadmin'@'%' IDENTIFIED BY 'dbadmin';
GRANT ALL PRIVILEGES ON vulnlab.* TO 'dbadmin'@'%';
FLUSH PRIVILEGES;
