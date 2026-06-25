# Halo 博客部署

一键部署 Halo 博客到服务器。

## 快速部署

```bash
git clone https://github.com/xiao9-web/blog.git /root/workspace/halo
cd /root/workspace/halo
bash deploy.sh
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `docker-compose.yml` | Halo + PostgreSQL 容器编排 |
| `deploy.sh` | 一键部署脚本（安装 Docker、clone 项目、启动服务） |
| `.env.example` | 环境变量模板 |

## 默认信息

- 端口：`8090`
- 控制台：`/console`
- 账号：`admin`

## 部署前检查

- 阿里云安全组已放行 `8090` 端口
- `.env` 包含密码，不要提交到 git
