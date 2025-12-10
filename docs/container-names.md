# WeKnora 容器名称说明文档

本文档说明 WeKnora 项目中所有 Docker 容器名称及其对应的服务功能。

## 生产环境容器 (docker-compose.yml)

### 核心服务

| 容器名称 | 服务说明 | 端口 | 说明 |
|---------|---------|------|------|
| `WeKnora-frontend` | 前端 Web UI 服务 | 80 | Vue.js 构建的前端界面，提供用户交互界面 |
| `WeKnora-app` | 后端 API 服务 | 8080 | Go 语言编写的后端服务，提供 RESTful API 接口 |
| `WeKnora-docreader` | 文档解析服务 | 50051 | gRPC 服务，负责解析 PDF、Word、图片等文档格式 |
| `WeKnora-postgres` | PostgreSQL 数据库 | 5432 | 主数据库，使用 ParadeDB 扩展支持向量检索 |
| `WeKnora-redis` | Redis 缓存服务 | 6379 | 用于缓存和会话管理 |

### 可选服务（通过 Profile 启用）

| 容器名称 | 服务说明 | 端口 | Profile | 说明 |
|---------|---------|------|---------|------|
| `WeKnora-minio` | MinIO 对象存储 | 9000, 9001 | `minio`, `full` | 用于存储上传的文档文件 |
| `WeKnora-jaeger` | Jaeger 链路追踪 | 16686, 4317, 4318 等 | `jaeger`, `full` | 用于分布式追踪和性能监控 |
| `WeKnora-neo4j` | Neo4j 图数据库 | 7474, 7687 | `neo4j`, `full` | 用于知识图谱功能（GraphRAG） |

## 开发环境容器 (docker-compose.dev.yml)

开发环境容器名称后缀为 `-dev`，用于本地开发时只启动基础设施服务，前端和后端在本地运行。

| 容器名称 | 对应生产环境 | 服务说明 | 端口 | 说明 |
|---------|------------|---------|------|------|
| `WeKnora-postgres-dev` | `WeKnora-postgres` | PostgreSQL 数据库 | 5432 | 开发环境数据库 |
| `WeKnora-redis-dev` | `WeKnora-redis` | Redis 缓存服务 | 6379 | 开发环境缓存 |
| `WeKnora-minio-dev` | `WeKnora-minio` | MinIO 对象存储 | 9000, 9001 | 开发环境文件存储 |
| `WeKnora-neo4j-dev` | `WeKnora-neo4j` | Neo4j 图数据库 | 7474, 7687 | 开发环境知识图谱 |
| `WeKnora-docreader-dev` | `WeKnora-docreader` | 文档解析服务 | 50051 | 开发环境文档解析 |
| `WeKnora-jaeger-dev` | `WeKnora-jaeger` | Jaeger 链路追踪 | 16686, 4317, 4318 等 | 开发环境链路追踪 |

## 服务依赖关系

```
WeKnora-frontend
  └─> WeKnora-app (健康检查通过后启动)

WeKnora-app
  ├─> WeKnora-postgres (健康检查通过后启动)
  ├─> WeKnora-redis (启动后即可使用)
  └─> WeKnora-docreader (健康检查通过后启动)
```

## 常用操作命令

### 查看所有容器状态
```bash
docker compose ps
```

### 查看特定容器日志
```bash
# 查看后端服务日志
docker compose logs app

# 查看前端服务日志
docker compose logs frontend

# 查看数据库日志
docker compose logs postgres
```

### 重启特定容器
```bash
# 重启后端服务
docker compose restart app

# 重启前端服务
docker compose restart frontend
```

### 停止特定容器
```bash
# 停止前端服务
docker compose stop frontend

# 停止后端服务
docker compose stop app
```

## 网络说明

- **生产环境网络**: `WeKnora-network`
- **开发环境网络**: `WeKnora-network-dev`

容器之间通过服务名称进行通信（如 `app` 通过 `postgres:5432` 访问数据库）。

## 数据卷说明

### 生产环境数据卷
- `postgres-data`: PostgreSQL 数据库数据
- `data-files`: 应用文件存储
- `jaeger_data`: Jaeger 追踪数据
- `minio_data`: MinIO 对象存储数据
- `neo4j-data`: Neo4j 图数据库数据

### 开发环境数据卷
- `postgres-data-dev`: 开发环境 PostgreSQL 数据
- `redis_data_dev`: 开发环境 Redis 数据
- `minio_data_dev`: 开发环境 MinIO 数据
- `neo4j-data-dev`: 开发环境 Neo4j 数据
- `jaeger_data_dev`: 开发环境 Jaeger 数据

## 注意事项

1. **容器命名规范**: 所有容器名称以 `WeKnora-` 开头，便于识别和管理
2. **开发环境**: 开发环境容器名称后缀为 `-dev`，避免与生产环境冲突
3. **端口映射**: 生产环境端口映射到宿主机，开发环境通常也映射以便调试
4. **健康检查**: `app`、`docreader`、`postgres` 等关键服务配置了健康检查，确保依赖服务就绪后再启动

