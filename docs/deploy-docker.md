在服务器使用 Docker 部署 WeKnora
================================

本文档说明如何在一台安装了 Docker 的服务器上打包、构建并运行整个 WeKnora 项目（前端、后端 `app`、文档解析 `docreader` 以及依赖服务）。

前置条件
--------
- 64 位 Linux 服务器（推荐 x86_64），root 或 sudo 权限  
- Docker 24+ 与 Docker Compose v2（`docker compose version` 可用）  
- 开放端口：80/8080/50051/5432/6379/9000/9001/7474/7687/16686（如启用对应组件）  
- 磁盘至少 15GB，可联网拉取镜像

项目组件与镜像
--------------
`docker-compose.yml` 定义的主要组件：
- `frontend`：UI，镜像名 `wechatopenai/weknora-ui:latest`
- `app`：Go 服务，镜像名 `wechatopenai/weknora-app:latest`
- `docreader`：Python 文档解析，镜像名 `wechatopenai/weknora-docreader:latest`
- 依赖：PostgreSQL(ParadeDB)、Redis、MinIO（有 profile）、Jaeger（有 profile）、Neo4j（有 profile）

拉取代码
--------
```bash
git clone https://<your-git>/WeKnora.git
cd WeKnora
```

准备环境变量
------------
在仓库根目录创建 `.env`，覆盖 `docker-compose.yml` 中的占位符。示例（请按需修改）：
```
# 端口
FRONTEND_PORT=80
APP_PORT=8080
DOCREADER_PORT=50051
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# 数据库与缓存
DB_USER=weknora
DB_PASSWORD=weknora_pass
DB_NAME=weknora
REDIS_PASSWORD=redis_pass
REDIS_DB=0

# 对象存储
MINIO_ACCESS_KEY_ID=minioadmin
MINIO_SECRET_ACCESS_KEY=minioadmin
MINIO_BUCKET_NAME=weknora

# 应用安全
JWT_SECRET=please_change_me
TENANT_AES_KEY=change_me_32_chars

# 可选：初始模型/外部服务
INIT_LLM_MODEL_NAME=qwen2.5
INIT_LLM_MODEL_BASE_URL=http://host.docker.internal:11434
INIT_LLM_MODEL_API_KEY=
INIT_EMBEDDING_MODEL_NAME=bge
INIT_EMBEDDING_MODEL_BASE_URL=
INIT_EMBEDDING_MODEL_API_KEY=
INIT_EMBEDDING_MODEL_DIMENSION=1024

# 如需 COS/Elastic/Neo4j/Jaeger 等，请同步设置对应变量
```
> 如果使用 MinIO，本地访问端点为 `http://<server>:9000`，控制台 `http://<server>:9001`。

可选配置
--------
- 应用配置文件位于 `config/config.yaml`，默认已适合容器运行，只需在需要时调整。例如本地文件存储目录可通过环境变量 `LOCAL_STORAGE_BASE_DIR` 指向宿主机路径（同时将该路径通过 volume 挂载到 `/data/files`）。
- ParadeDB 初始化脚本位于 `migrations/paradedb`，compose 已自动挂载到 postgres 容器的 init 目录。

构建镜像
--------
推荐直接在服务器构建：
```bash
docker compose -f docker-compose.yml build
```
如果在国内网络，可在构建时添加代理/镜像参数（示例）：
```bash
docker compose build --build-arg GOPROXY_ARG=https://goproxy.cn,direct --build-arg APK_MIRROR_ARG=mirrors.tencent.com
```

启动服务
--------
基础组件（前端、后端、docreader、Postgres、Redis）：
```bash
docker compose up -d
```
如需对象存储/观测/图数据库，可启用 profile（`minio`/`jaeger`/`neo4j`），或一次性拉起全栈：
```bash
docker compose --profile full up -d   # full 包含 minio、jaeger、neo4j
```

初始化数据库（首次部署必做）
--------------------------
等待 postgres 健康检查通过后，在 app 容器内执行迁移：
```bash
docker compose exec app ./scripts/migrate.sh up
```
如需要回滚或查看版本，脚本也支持 `down|version|force|goto` 等子命令。

验证与常用命令
--------------
- 查看容器状态：`docker compose ps`
- 查看日志：`docker compose logs -f app` / `frontend` / `docreader`
- 健康检查：`curl http://localhost:8080/health`
- 访问前端：浏览器打开 `http://<server_ip>:${FRONTEND_PORT}`

升级/重启/清理
--------------
- 更新代码 & 重新构建：`git pull && docker compose build`
- 平滑重启：`docker compose restart`
- 拉取预构建镜像（如已推送到私有仓库）：`docker compose pull`
- 停止：`docker compose down`
- 连数据一起清理：`docker compose down -v`（会删除数据库/对象存储数据，谨慎使用）

离线/跨机分发（可选）
-------------------
在一台联网机器上构建并导出镜像：
```bash
docker compose build
docker save wechatopenai/weknora-ui:latest wechatopenai/weknora-app:latest wechatopenai/weknora-docreader:latest paradedb/paradedb:v0.18.9-pg17 redis:7.0-alpine minio/minio:latest > weknora-images.tar
```
将 `weknora-images.tar` 拷贝到目标机后导入：
```bash
docker load -i weknora-images.tar
docker compose up -d
```

排查指引
--------
- 数据库无法连接：检查 `.env` 中 DB 用户/密码与 `docker compose exec postgres env | grep POSTGRES_` 是否一致。
- 前端白屏：`docker compose logs frontend` 查看 Nginx 反代是否能访问 `app`；确认 `APP_PORT` 未被占用。
- docreader 健康检查失败：确认服务器有足够内存（建议 >=4GB），并检查网络能下载模型文件；或提前下载并挂载到 `/root/.paddleocr`。

完成后即可在浏览器通过前端地址访问 WeKnora。根据业务需要调整 `.env` 与 `config/config.yaml`，重新 `docker compose up -d` 即可生效。

