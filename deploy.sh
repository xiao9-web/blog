#!/bin/bash
set -e

#===========================================
# Halo 博客一键部署脚本
# 服务器上执行: bash deploy.sh
#===========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo "========================================"
echo "  Halo 博客一键部署"
echo "========================================"

#------------------------------
# 1. 安装 Docker
#------------------------------
if ! command -v docker &> /dev/null; then
    warn "未检测到 Docker，正在安装..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    log "Docker 安装完成"
else
    log "Docker 已安装: $(docker --version)"
fi

#------------------------------
# 2. 克隆项目
#------------------------------
PROJECT_DIR="/root/workspace/halo"

if [ -d "$PROJECT_DIR" ]; then
    warn "$PROJECT_DIR 已存在，执行 git pull 更新"
    cd "$PROJECT_DIR"
    git pull
else
    log "克隆项目..."
    mkdir -p /root/workspace
    git clone https://github.com/xiao9-web/blog.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

#------------------------------
# 3. 配置 .env
#------------------------------
if [ ! -f ".env" ]; then
    cp .env.example .env
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "你的服务器IP")
    RANDOM_PW=$(openssl rand -base64 12 2>/dev/null || head -c 12 /dev/urandom | base64)

    sed -i "s|http://你的服务器IP:8090/|http://${PUBLIC_IP}:8090/|" .env
    sed -i "s/你的密码/${RANDOM_PW}/" .env
    sed -i "s/你的数据库密码/${RANDOM_PW}/" .env

    log ".env 已生成 (IP: ${PUBLIC_IP})"
else
    log ".env 已存在，跳过"
fi

#------------------------------
# 4. 开放防火墙端口
#------------------------------
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --add-port=8090/tcp --permanent 2>/dev/null && firewall-cmd --reload 2>/dev/null
    log "防火墙端口 8090 已开放"
elif command -v ufw &> /dev/null; then
    ufw allow 8090/tcp 2>/dev/null
    log "UFW 端口 8090 已开放"
fi

#------------------------------
# 5. 启动服务
#------------------------------
log "拉取镜像并启动..."
docker compose up -d

log "等待 Halo 启动..."
for i in $(seq 1 30); do
    if docker compose logs halo 2>/dev/null | grep -q "started successfully"; then
        break
    fi
    sleep 2
done

#------------------------------
# 6. 完成
#------------------------------
source .env 2>/dev/null || true
echo ""
echo "========================================"
echo -e "  ${GREEN}部署完成！${NC}"
echo "========================================"
echo ""
echo "  访问地址:  ${HALO_EXTERNAL_URL:-http://${PUBLIC_IP}:8090}"
echo "  后台管理:  ${HALO_EXTERNAL_URL:-http://${PUBLIC_IP}:8090}/console"
echo "  用户名:    admin"
echo "  密码:      ${HALO_ADMIN_PASSWORD:-见 .env 文件}"
echo ""
echo "  ⚠️  请确保阿里云安全组已开放 8090 端口！"
echo "========================================"
