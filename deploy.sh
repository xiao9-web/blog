#!/bin/bash
set -e
# Halo 博客一键部署脚本

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[XX]${NC} $1"; exit 1; }

echo "========================================"
echo "  Halo 博客部署"
echo "========================================"

# 1. Docker
if ! command -v docker &>/dev/null; then
    warn "安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker && systemctl enable docker
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<<'{"registry-mirrors":["https://registry.cn-hangzhou.aliyuncs.com"]}'
    systemctl daemon-reload && systemctl restart docker
    log "Docker OK"
else
    log "Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
fi

# 2. Clone (with fallback for blocked GitHub)
REPO="https://github.com/xiao9-web/blog.git"
DIR="/root/workspace/halo"

if [ -d "$DIR/.git" ]; then
    warn "$DIR 已存在，git pull"
    cd "$DIR" && git pull 2>/dev/null || true
else
    log "克隆项目..."
    mkdir -p /root/workspace
    if ! git clone -c http.version=HTTP/1.1 "$REPO" "$DIR" 2>/dev/null; then
        warn "HTTPS 失败，试 SSH..."
        git clone "git@github.com:xiao9-web/blog.git" "$DIR" 2>/dev/null || \
        err "GitHub 不可达，请先解决网络问题"
    fi
fi
cd "$DIR"

# 3. Config
if [ ! -f .env ]; then
    IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_IP")
    PW=$(openssl rand -base64 12 2>/dev/null || echo "changeme123")
    cat > .env << EOF
HALO_EXTERNAL_URL=http://${IP}:8090/
HALO_ADMIN_PASSWORD=${PW}
HALO_DB_PASSWORD=${PW}
EOF
    log ".env 已生成 (IP: $IP)"
fi

# 4. Firewall
command -v firewall-cmd &>/dev/null && { firewall-cmd --add-port=8090/tcp --permanent 2>/dev/null; firewall-cmd --reload 2>/dev/null; log "防火墙 8090 已开放"; }
command -v ufw &>/dev/null && { ufw allow 8090/tcp 2>/dev/null; log "UFW 8090 已开放"; }

# 5. Start
log "启动容器..."
docker compose up -d
log "等待 Halo 就绪..."
for i in $(seq 1 30); do
    docker compose logs halo 2>/dev/null | grep -q "started" && break
    sleep 2
done

# 6. Done
source .env 2>/dev/null
echo ""
echo "========================================"
echo -e "  ${GREEN}部署完成！${NC}"
echo "========================================"
echo "  地址: ${HALO_EXTERNAL_URL}"
echo "  后台: ${HALO_EXTERNAL_URL}console"
echo "  用户: admin"
echo "  密码: ${HALO_ADMIN_PASSWORD}"
echo "  ⚠️  确保阿里云安全组已开放 8090"
echo "========================================"
