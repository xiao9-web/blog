#!/bin/bash
set -e

# ============================================
#  Halo 博客一键部署（服务器上执行）
#  用法: bash deploy.sh            # 使用官方镜像（快速）
#        bash deploy.sh --build    # 从源码构建（定制后）
# ============================================

REPO="https://github.com/xiao9-web/blog.git"
DIR="/opt/halo"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MODE="official"
if [ "$1" = "--build" ] || [ "$1" = "-b" ]; then
    MODE="build"
fi

echo "========================================"
echo "  Halo 博客部署"
echo "  模式: $MODE"
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
    echo "[!] 克隆项目（含 Halo 源码）..."
    git clone "$REPO" "$DIR"
    cd "$DIR"
fi

# 3. 判断首次部署还是更新
if [ -f .env ]; then
    echo "[!] 更新模式（保留数据）"
    docker compose down 2>/dev/null || true
else
    echo "[!] 首次部署模式"
    docker compose down 2>/dev/null || true
    rm -rf halo2 halo-db
    PW=$(openssl rand -base64 12 2>/dev/null || date +%s | sha256sum | base64 | head -c 16)
    cat > .env << EOF
HALO_EXTERNAL_URL=http://47.116.137.192:8090/
HALO_ADMIN_PASSWORD=${PW}
HALO_DB_PASSWORD=${PW}
EOF
    echo "[OK] .env 已生成，密码: ${PW}"
fi

# 4. 构建或拉取镜像
if [ "$MODE" = "build" ]; then
    echo "[!] 从源码构建 Docker 镜像（可能需要几分钟）..."
    docker compose -f docker-compose.build.yml build
    COMPOSE_FILE="docker-compose.build.yml"
else
    echo "[!] 拉取最新官方镜像..."
    docker compose pull halo
    COMPOSE_FILE="docker-compose.yml"
fi

# 5. 启动
echo "[!] 启动容器..."
docker compose -f "$COMPOSE_FILE" up -d

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
echo "  模式: ${MODE}"
echo "========================================"
echo "  ⚠️ 确保阿里云安全组已放行 8090 端口"
echo "========================================"
