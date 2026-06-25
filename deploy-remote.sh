#!/bin/bash
# 从本地 Mac SSH 到阿里云 ECS 一键部署 Halo
set -e

SERVER="root@47.116.137.192"
PW="Zhong2017"

echo ">>> 连接服务器并部署 Halo..."

expect -c "
set timeout 120
spawn ssh -o StrictHostKeyChecking=no $SERVER \"bash -s\"
expect \"password:\" { send \"$PW\r\" }
sleep 2

send \"cd /root/workspace/halo && git pull origin main 2>&1\r\"
expect \"#\"

send \"docker compose down 2>&1 && rm -rf halo2 halo-db && echo '旧数据已清'\r\"
expect \"#\"

send \"if [ ! -f .env ]; then PWDX=\\\$(openssl rand -base64 12); cat > .env << ENVEOF\nHALO_EXTERNAL_URL=http://47.116.137.192:8090/\nHALO_ADMIN_PASSWORD=\\\${PWDX}\nHALO_DB_PASSWORD=\\\${PWDX}\nENVEOF\n echo \\\"新密码: \\\${PWDX}\\\"; else echo '使用已有 .env'; fi\r\"
expect \"#\"

send \"docker compose pull halo 2>&1\r\"
expect \"#\"

send \"docker compose up -d 2>&1\r\"
expect \"#\"

send \"echo '等待启动...' && for i in \\\$(seq 1 10); do curl -s -o /dev/null http://localhost:8090/console && echo '就绪!' && break; sleep 3; done\r\"
expect \"#\"

send \"echo ============ && docker ps --filter name=halo --format 'table {{.Names}}\t{{.Status}}' && echo ============ && grep ADMIN_PASSWORD .env && echo ============ && echo '后台: http://47.116.137.192:8090/console'\r\"
expect \"#\"
"
