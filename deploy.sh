#!/bin/bash
set -e

# ============================================
#  Halo 博客一键部署（服务器上执行）
#  用法: bash deploy.sh
# ============================================

REPO="https://github.com/xiao9-web/blog.git"
DIR="/opt/halo"
GREEN='\033[0;32m'
NC='\033[0m'

echo "========================================"
echo "  Halo 博客部署"
echo "========================================"

# 1. 安装 Docker（如果没有）
if ! command -v docker &>/dev/null; then
    echo "[!] 安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker && systemctl enable docker
    echo "[OK] Docker 安装完成"
else
    echo "[OK] Docker $(docker --version | awk '{print $3}' | tr -d ',')"
fi

# 2. 克隆或更新项目
if [ -d "$DIR/.git" ]; then
    echo "[!] 项目已存在，更新..."
    cd "$DIR"
    git pull origin main
else
    echo "[!] 克隆项目..."
    git clone "$REPO" "$DIR"
    cd "$DIR"
fi

# 3. 停旧容器，清数据
docker compose down 2>/dev/null || true
rm -rf halo2 halo-db
echo "[OK] 旧数据已清理"

# 4. 生成 .env
if [ ! -f .env ]; then
    PW=$(openssl rand -base64 12 2>/dev/null || date +%s | sha256sum | base64 | head -c 16)
    cat > .env << EOF
HALO_EXTERNAL_URL=http://47.116.137.192:8090/
HALO_ADMIN_PASSWORD=${PW}
HALO_DB_PASSWORD=${PW}
EOF
    echo "[OK] .env 已生成"
else
    echo "[OK] 使用已有 .env"
fi

# 5. 拉镜像 + 启动
echo "[!] 拉取 Halo 镜像..."
docker compose pull halo
echo "[!] 启动容器..."
docker compose up -d

# 6. 等待就绪
echo -n "[!] 等待 Halo 启动"
for i in $(seq 1 30); do
    if curl -s -o /dev/null http://localhost:8090/console 2>/dev/null; then
        echo " 就绪!"
        break
    fi
    echo -n "."
    sleep 2
done

# 7. 输出结果
PASS=$(grep ADMIN_PASSWORD .env | cut -d= -f2)
echo ""
echo "========================================"
echo -e "  ${GREEN}部署完成！${NC}"
echo "========================================"
echo "  博客: http://47.116.137.192:8090"
echo "  后台: http://47.116.137.192:8090/console"
echo "  账号: admin"
echo "  密码: ${PASS}"
echo "========================================"
echo "  ⚠️ 确保阿里云安全组已放行 8090 端口"
echo "========================================"
