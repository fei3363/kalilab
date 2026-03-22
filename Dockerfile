FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ──────────────────────────────────────────────
# 1. 安裝服務：SSH, Apache, PHP, MySQL, FTP, Telnet
#    提供多種可掃描的攻擊面
# ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    openssh-server \
    apache2 \
    libapache2-mod-php \
    php php-mysql php-cli php-curl \
    mysql-server \
    vsftpd \
    telnetd xinetd \
    curl wget net-tools iputils-ping vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────
# 2. 弱密碼 / 預設密碼帳號
# ──────────────────────────────────────────────
# root 密碼：root (極弱)
RUN echo 'root:root' | chpasswd

# 一般使用者弱密碼
RUN useradd -m -s /bin/bash admin   && echo 'admin:admin'       | chpasswd
RUN useradd -m -s /bin/bash user    && echo 'user:password'     | chpasswd
RUN useradd -m -s /bin/bash test    && echo 'test:test123'      | chpasswd
RUN usermod -m -d /home/backup -s /bin/bash backup && echo 'backup:backup' | chpasswd

# admin 有 sudo 權限（模擬權限過大的帳號）
RUN usermod -aG sudo admin
RUN echo 'admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# ──────────────────────────────────────────────
# 3. SSH 配置 — 允許 root 登入 + 密碼認證
# ──────────────────────────────────────────────
RUN mkdir -p /run/sshd
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/'       /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ──────────────────────────────────────────────
# 4. FTP 配置 — 允許匿名登入 + 本地帳號
# ──────────────────────────────────────────────
COPY config/vsftpd.conf /etc/vsftpd.conf
RUN mkdir -p /var/ftp/pub && \
    echo "FTP 匿名區域 — 內部備份伺服器" > /var/ftp/pub/welcome.txt && \
    echo "db_backup_user=dbadmin"          > /var/ftp/pub/db_config.bak && \
    echo "db_backup_pass=P@ssw0rd123"     >> /var/ftp/pub/db_config.bak

# ──────────────────────────────────────────────
# 5. Telnet 配置（不安全的明文協定）
# ──────────────────────────────────────────────
COPY config/telnet.xinetd /etc/xinetd.d/telnet

# ──────────────────────────────────────────────
# 6. Apache 配置 — 啟用目錄列表 + Server 資訊洩漏
# ──────────────────────────────────────────────
RUN a2enmod rewrite headers status
COPY config/apache-vuln.conf /etc/apache2/sites-available/000-default.conf

# 移除 Apache 預設首頁，讓 index.php 優先
RUN rm -f /var/www/html/index.html

# 讓 www-data 可以存取 MySQL socket
RUN usermod -aG mysql www-data

# ──────────────────────────────────────────────
# 7. Web 應用程式 — 含漏洞的網站
# ──────────────────────────────────────────────
COPY web/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html

# 模擬 .git 洩漏
RUN mkdir -p /var/www/html/.git && \
    echo "ref: refs/heads/main" > /var/www/html/.git/HEAD && \
    echo "[user]\n  name = dev\n  email = dev@internal.corp" > /var/www/html/.git/config

# 模擬備份檔暴露
RUN cp /var/www/html/index.php /var/www/html/index.php.bak
RUN echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# ──────────────────────────────────────────────
# 8. MySQL 初始化 — 弱密碼 + 範例資料庫
# ──────────────────────────────────────────────
COPY config/mysql-init.sql /docker-entrypoint-initdb.d/init.sql

# ──────────────────────────────────────────────
# 9. 修補與驗證腳本
# ──────────────────────────────────────────────
COPY scripts/fix-vulns.sh   /opt/scripts/fix-vulns.sh
COPY scripts/verify-fix.sh  /opt/scripts/verify-fix.sh
RUN chmod +x /opt/scripts/*.sh

# ──────────────────────────────────────────────
# 10. 啟動腳本
# ──────────────────────────────────────────────
COPY scripts/startup.sh /startup.sh
RUN chmod +x /startup.sh

# 暴露所有服務埠
EXPOSE 21 22 23 80 3306

CMD ["/startup.sh"]
