# Portabase

一个自用的数据库备份与恢复平台。把 PostgreSQL / MySQL 的连接信息录入进来，就能手动或定时做备份、只保留最近若干份，需要时一键恢复。

> 本项目基于开源项目 [Portabase](https://github.com/Portabase/portabase)（Apache-2.0）二次开发：沿用其技术栈，按个人使用场景做了裁剪与重写，保留上游版权声明。

## 功能

- **账号**：邮箱 + 密码登录（管理员 / 普通用户）
- **数据库接入**：录入 PostgreSQL、MySQL 连接信息，支持「测试连接」后再保存
- **手动备份**：一键执行 `pg_dump -Fc` / `mysqldump --single-transaction`
- **定时备份**：每天 / 每周固定时间自动执行
- **备份列表**：时间、大小、耗时、状态，支持下载与删除
- **保留策略**：每个库只保留最近 N 份，超出的自动清理
- **一键恢复**：用 `pg_restore` / `mysql` 把指定备份导回目标库
- **操作日志**：记录执行的命令、退出码与耗时，便于排查失败原因

## 技术栈

| 层 | 选型 |
|---|---|
| 前端 | Next.js 16（App Router）、React 19、TypeScript、Tailwind CSS、shadcn/ui |
| 服务端 | Next.js Server Actions |
| 平台数据 | PostgreSQL、Drizzle ORM |
| 认证 | better-auth（邮箱密码） |
| 定时任务 | node-cron |
| 备份工具 | 容器内的 `pg_dump` / `pg_restore` / `mysqldump` |
| 部署 | Docker、docker compose |

## 目录结构

```
app/                        页面与接口
  (auth)/                   登录、注册
  (customer)/dashboard/     控制台：数据库、备份、设置
  api/health/               健康检查
src/
  db/                       数据库 schema、迁移、服务层
  features/                 业务模块（auth / database / backup / layout）
  lib/backup/               备份执行器、队列、恢复、调度
  lib/crypto.ts             数据库密码加解密
  utils/init/               启动初始化与定时任务注册
docker/                     Dockerfile 与入口脚本
```

## 快速开始

### 1. 拉取代码

```bash
git clone https://github.com/SANMU-684/portabase.git
cd portabase
```

### 2. 准备环境变量

```bash
cp .env.example .env
```

至少需要填这三项：`PROJECT_SECRET`（32 字节随机串）、`DATABASE_URL`（平台自身数据库）、`AUTH_DEFAULT_PASSWORD`（初始管理员密码）。

### 3. 一条命令启动

```bash
docker compose up -d
```

打开 http://localhost:8887 ，用 `.env` 里的 `AUTH_DEFAULT_USER` / `AUTH_DEFAULT_PASSWORD` 登录。首次启动会自动建表并创建默认管理员。

### 4. 本地开发

```bash
pnpm install
docker compose up -d db      # 只起数据库
pnpm db:generate             # 改了 schema 后生成迁移
pnpm db:migrate
pnpm dev                     # http://localhost:8887
```

## 环境变量

| 变量 | 说明 | 示例 |
|---|---|---|
| `PROJECT_NAME` | 站点名称 | `Portabase` |
| `PROJECT_URL` | 访问地址 | `http://localhost:8887` |
| `PROJECT_SECRET` | 密钥（密码加密用），生成后不要修改 | 64 位十六进制串 |
| `DATABASE_URL` | 平台自身使用的 PostgreSQL | `postgresql://user:pwd@db:5432/portabase` |
| `AUTH_DEFAULT_USER` | 初始管理员邮箱 | `admin@example.com` |
| `AUTH_DEFAULT_PASSWORD` | 初始管理员密码 | 强密码 |
| `BACKUP_DIR` | 备份文件存放目录 | `/data/private/backups` |
| `BACKUP_TIMEOUT_MS` | 单个备份超时时间 | `1800000`（30 分钟） |

## 备份是怎么跑起来的

1. 点击「立即备份」→ 写入一条备份记录，状态为「排队中」。
2. 备份队列串行取任务（同一个库不并发），把数据库密码解密后拼出命令。
3. 执行 `pg_dump -Fc` 或 `mysqldump`，文件落到 `BACKUP_DIR`，同时记录文件大小与耗时。
4. 执行完毕把记录更新为「成功 / 失败」；失败时保留退出码与错误输出。
5. 定时任务按保留策略清理超出份数的旧备份。

## 已知限制

- 目前只支持 PostgreSQL 与 MySQL，其余数据库（MongoDB、Redis、SQLite 等）尚未支持。
- 备份由应用进程直接执行，未做独立的 agent 与对象存储，不适合多机大规模场景。
- 恢复是「覆盖式」的，操作前请确认目标库可以接受被覆盖。

## 后续计划

- 备份失败自动重试一次，并在页面上标注
- 备份成功率与最近一次备份时间的小看板
- 支持 S3 / MinIO 作为异地存储

## License

本项目基于 [Portabase](https://github.com/Portabase/portabase) 二次开发，遵循 Apache-2.0 协议，保留上游版权声明，详见 [LICENSE](./LICENSE)。
