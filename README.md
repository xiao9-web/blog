# 个人博客部署文档

基于 [Halo](https://github.com/halo-dev/halo)（33k+ stars）搭建的个人博客，部署于阿里云 ECS。

> 用于记录读书感悟、读书笔记、技术文章等。

---

## 目录

- [环境要求](#环境要求)
- [第一步：服务器准备](#第一步服务器准备)
- [第二步：上传项目文件](#第二步上传项目文件)
- [第三步：配置阿里云安全组](#第三步配置阿里云安全组)
- [第四步：修改外部地址](#第四步修改外部地址)
- [第五步：启动服务](#第五步启动服务)
- [第六步：初始化博客](#第六步初始化博客)
- [第七步：安装主题](#第七步安装主题)
- [日常使用](#日常使用)
- [备份与恢复](#备份与恢复)
- [常见问题](#常见问题)
- [主题推荐](#主题推荐)

---

## 环境要求

| 项目 | 要求 |
|------|------|
| 服务器 | 阿里云 ECS（1核2G 即可） |
| 操作系统 | CentOS 7+ / Ubuntu 18.04+ / Debian 10+ |
| 软件 | Docker 20.10+ |

---

## 第一步：服务器准备

### 1.1 SSH 登录服务器

```bash
ssh root@<你的服务器公网IP>
```

### 1.2 安装 Docker

```bash
# 一键安装 Docker（适用于 CentOS / Ubuntu / Debian）
curl -fsSL https://get.docker.com | sh

# 启动 Docker 并设置开机自启
systemctl start docker
systemctl enable docker

# 验证安装
docker --version
```

> 如果服务器在国内，Docker 拉取镜像可能较慢，建议配置阿里云镜像加速器：
>
> ```bash
> mkdir -p /etc/docker
> tee /etc/docker/daemon.json <<-'EOF'
> {
>   "registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]
> }
> EOF
> systemctl daemon-reload
> systemctl restart docker
> ```

### 1.3 创建项目目录

```bash
mkdir -p /root/workspace/halo
```

---

## 第二步：上传项目文件

在**本地电脑**终端执行（不是在服务器上）：

```bash
# 进入项目目录
cd /Users/xiao9/workSpace/blog

# 上传 docker-compose.yml 到服务器
scp docker-compose.yml root@<你的服务器IP>:/root/workspace/halo/
```

---

## 第三步：配置阿里云安全组

**这步非常关键，漏掉会导致外部无法访问！**

1. 登录 [阿里云 ECS 控制台](https://ecs.console.aliyun.com/)
2. 左侧菜单 → **实例** → 点击你的 ECS 实例
3. 点击 **安全组** 标签页
4. 点击 **配置规则** → **入方向** → **手动添加**
5. 添加以下规则：

| 配置项 | 值 |
|--------|-----|
| 授权策略 | 允许 |
| 优先级 | 1 |
| 协议类型 | 自定义 TCP |
| 端口范围 | **8090** |
| 授权对象 | `0.0.0.0/0`（允许所有 IP 访问） |

> 生产环境建议把 `0.0.0.0/0` 改为你自己的 IP 地址。

---

## 第四步：修改外部地址

SSH 登录服务器，编辑 `docker-compose.yml`：

```bash
cd /root/workspace/halo
vi docker-compose.yml
```

找到以下两行，**修改为你的服务器公网 IP**（或域名）：

```yaml
- --halo.external-url=http://<你的服务器IP>:8090/
- --halo.security.initializer.superadminpassword=<改成你自己的密码>
```

| 参数 | 说明 | 示例 |
|------|------|------|
| `external-url` | 博客访问地址 | `http://8.8.8.8:8090/` |
| `superadminpassword` | 管理员密码 | 改成复杂密码 |

> 如果你有域名（如 `blog.example.com`），先到 DNS 控制台添加 A 记录指向服务器 IP，然后把 external-url 改为 `http://blog.example.com:8090/`。

---

## 第五步：启动服务

```bash
cd /root/workspace/halo

# 拉取镜像并启动（根据网速可能需要 1-3 分钟）
docker compose up -d

# 查看容器状态（两个都应该是 Up）
docker compose ps

# 查看 Halo 启动日志
docker compose logs halo
```

看到以下日志说明启动成功：

```
Halo has started successfully!
Access at: http://<IP>:8090/
```

> 如果启动失败，执行 `docker compose logs halodb` 检查数据库是否正常。

---

## 第六步：初始化博客

1. 浏览器打开：`http://<你的服务器IP>:8090`
2. 看到 Halo 初始化页面，填写：

| 配置项 | 填写内容 |
|--------|----------|
| 站点名称 | `读书札记`（可自定义） |
| 用户名 | `admin` |
| 密码 | 你在 docker-compose.yml 中设置的密码 |
| 邮箱 | 你的常用邮箱 |

3. 点击「初始化」→ 完成

4. 初始化后访问 `http://<IP>:8090/console` 进入后台管理。

---

## 第七步：安装主题

### 7.1 推荐主题

以下主题适合写读书笔记、阅读感悟，风格简洁且有品质感：

| 主题 | 风格 | 适用场景 |
|------|------|----------|
| **halo-theme-fuwari** | 极简现代、暗色模式、毛玻璃 | 读书笔记、个人随笔 |
| **theme-retypeset** | 纸质书排版美学、专注阅读 | 长篇读书笔记 |
| **halo-theme-stellar** | 商务科技、组件丰富 | 综合型博客 |
| **halo-theme-vapor** | 简约轻量、移植 Cali.so | 极简个人博客 |

### 7.2 安装方式

**方式一：后台一键安装（推荐）**

1. 登录 Halo 后台：`http://<IP>:8090/console`
2. 左侧菜单 → **外观** → **主题**
3. 点击 **安装** → 在主题商店搜索上面推荐的主题名
4. 点击安装 → 安装完成后点击 **启用**

**方式二：手动上传**

1. 去 [Halo 主题商店](https://www.halo.run/store/apps?type=THEME) 下载主题 zip
2. 后台 → 外观 → 主题 → 上传 → 选择 zip 文件
3. 点击启用

---

## 日常使用

### 写文章

1. 登录后台 → **文章** → **新建文章**
2. 选择编辑器（富文本 / Markdown）
3. 写好文章后设置分类、标签
4. 点击 **发布**

### 文章分类建议（读书笔记）

建议创建以下分类：

| 分类名称 | 别名 | 用途 |
|----------|------|------|
| 读书笔记 | reading-notes | 书籍的详细笔记 |
| 读书感悟 | reading-thoughts | 读后感、思考 |
| 书单推荐 | book-list | 推荐书单 |
| 阅读日志 | reading-log | 阅读进度记录 |

创建方式：后台 → **文章** → **分类** → **新建分类**

### 设置首页

1. 后台 → **外观** → **主题** → 点击已启用主题的 **设置**
2. 根据主题提供的选项调整首页布局、配色、导航等

---

## 备份与恢复

### 备份

```bash
# 备份整个 Halo 数据目录
cd /root/workspace/halo
tar -czf halo-backup-$(date +%Y%m%d).tar.gz halo2/ halo-db/

# 建议定期执行，可以用 crontab 自动备份
# 每天凌晨 3 点备份
echo '0 3 * * * cd /root/workspace/halo && tar -czf halo-backup-$(date +\%Y\%m\%d).tar.gz halo2/ halo-db/' | crontab -
```

### 恢复

```bash
cd /root/workspace/halo
docker compose down
tar -xzf halo-backup-20250101.tar.gz
docker compose up -d
```

---

## 常见问题

### Q: 外网访问不了？

1. 检查安全组是否开放了 8090 端口
2. 检查服务器防火墙：`systemctl status firewalld`，如果开启了就 `firewall-cmd --add-port=8090/tcp --permanent && firewall-cmd --reload`
3. 检查容器是否运行：`docker compose ps`

### Q: Docker 拉取镜像很慢？

配置阿里云镜像加速器（见第一步 1.2 节）。

### Q: 想用域名 + HTTPS 访问？

推荐使用 Nginx 反向代理 + Let's Encrypt 免费 SSL 证书。

```bash
# 安装 Nginx
yum install -y nginx  # CentOS
# 或
apt install -y nginx  # Ubuntu

# 反向代理配置示例 /etc/nginx/conf.d/blog.conf
# server {
#     listen 80;
#     server_name blog.example.com;
#     location / {
#         proxy_pass http://127.0.0.1:8090;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
# }
```

> HTTPS 配置可后续使用 `certbot` 工具自动获取证书。

### Q: 如何升级 Halo？

```bash
cd /root/workspace/halo
docker compose pull halo       # 拉取最新镜像
docker compose up -d           # 重新创建容器
```

---

## 主题推荐

### 🥇 首选：halo-theme-fuwari

- 移植自 Astro 静态博客模板 Fuwari
- 特点：极简设计、响应式、暗色模式、毛玻璃效果
- 适合读书笔记的优雅排版

### 🥈 备选：theme-retypeset

- 移植自 astro-theme-retypeset
- 特点：纸质书般的排版美学、极致阅读体验
- 写长篇读书笔记的最佳选择

### 🥉 进阶：halo-theme-stellar

- 移植自 Hexo Stellar
- 特点：动态数据组件、Widget 丰富、现代商务风
- 适合综合型博客，首页可玩性强

---

## 技术栈

| 组件 | 技术 |
|------|------|
| 博客系统 | Halo 2.20 |
| 后端 | Java 17 + Spring Boot |
| 数据库 | PostgreSQL 16 |
| 容器化 | Docker + Docker Compose |
| 服务器 | 阿里云 ECS |

---

## 参考链接

- [Halo 官方文档](https://docs.halo.run)
- [Halo GitHub](https://github.com/halo-dev/halo)
- [Halo 主题商店](https://www.halo.run/store/apps?type=THEME)
- [Awesome Halo 主题列表](https://github.com/halo-sigs/awesome-halo)
