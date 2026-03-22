-- VulnLab Database Dump
-- 漏洞：備份檔暴露在 Web 可存取目錄

CREATE DATABASE IF NOT EXISTS vulnlab;
USE vulnlab;

INSERT INTO users (username, password, email, role) VALUES
('admin', 'admin123', 'admin@vulnlab.corp', 'admin'),
('operator', 'oper@t0r', 'ops@vulnlab.corp', 'operator');

-- 內部 API Key（不應暴露）
-- API_KEY=sk-vuln-4f8a2b3c9d1e5f6a7b8c9d0e
-- AWS_SECRET=AKIAIOSFODNN7EXAMPLE
