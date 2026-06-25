# Halo 个人博客

基于 [Halo](https://github.com/halo-dev/halo) v2.25.2 的个人博客项目，支持一键部署到阿里云 ECS。

## 项目结构

```text
blog/
├── halo/                      # Halo 2.25.2 源码（可定制）
│   ├── api/                   # 公共 API 模块
│   ├── application/           # Spring Boot 主应用
│   ├── ui/                    # Vue 3 前端
│   ├── platform/              # BOM 依赖管理
│   ├── Dockerfile             # Halo 官方 Dockerfile
│   └── build.gradle           # Gradle 构建配置
├── Dockerfile                 # 从源码构建 Halo 镜像
├── docker-compose.yml         # 部署配置（官方镜像，快速）
├── docker-compose.build.yml   # 部署配置（从源码构建）
├── deploy.sh                  # 一键部署脚本
├── .env.example               # 环境变量模板
└── .gitignore
```

## 快速部署（服务器上）

```bash
# 一行命令部署（官方镜像，最快）
curl -sL https://raw.githubusercontent.com/xiao9-web/blog/main/deploy.sh | bash
```

或者：

```bash
git clone https://github.com/xiao9-web/blog.git /opt/halo
cd /opt/halo
bash deploy.sh
```

## 定制源码后部署

```bash
# 1. 修改 halo/ 源码
# 2. 从源码构建部署
bash deploy.sh --build
```

## 默认信息

- 端口：`8090`
- 博客：`http://<IP>:8090`
- 控制台：`http://<IP>:8090/console`
- 账号：`admin`
- 密码：首次部署自动生成

## 部署前检查

- 阿里云安全组已放行 `8090` 端口
- `.env` 包含密码，不要提交到 git
