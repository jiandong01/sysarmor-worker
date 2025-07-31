# SysArmor Vector ETL

基于 Vector 的简化 ETL 管道系统，专为 SysArmor 安全事件处理设计。从文件读取数据，使用 VRL 脚本处理，输出到控制台。

## 项目概述

SysArmor Vector 是一个简洁的 ETL 处理系统，提供：

- **文件数据源**: 从 JSONL 文件读取安全事件数据
- **VRL 脚本处理**: 使用 Vector Remap Language 进行数据转换和安全分析
- **控制台输出**: 处理结果直接输出到控制台，便于调试和查看
- **容器化部署**: Docker Compose 一键部署
- **简洁的管理工具**: Makefile 提供完整的管理命令

## 架构设计

```
数据文件 → Vector ETL → 控制台输出
   ↓         ↓           ↓
JSONL    VRL脚本处理   JSON格式
文件     安全分析      控制台显示
```

## 快速开始

### 1. 环境准备

```bash
# 确保 Docker 和 Docker Compose 已安装
docker --version
docker compose version
```

### 2. 启动服务

```bash
# 查看帮助
make help

# 启动 Vector 服务
make start

# 查看处理结果
make logs
```

### 3. 验证部署

```bash
# 查看服务状态
make status

# 验证配置
make validate

# 健康检查
make health
```

## 数据处理流程

### 1. 输入数据格式

示例数据文件 `data/sample-events.jsonl`：

```json
{"raw_data":"{\"event\":{\"evt.num\":\"1\",\"evt.type\":\"open\",\"fd.name\":\"/etc/passwd\",\"proc.name\":\"cat\",\"proc.pid\":\"1234\",\"evt.time\":\"2025-01-01T10:00:00Z\"}}","collector_id":"test-agent","hostname":"server01"}
```

### 2. VRL 脚本处理

`scripts/process_events.vrl` 脚本执行以下处理：

- **数据解析**: 解析嵌套的 JSON 数据
- **字段提取**: 提取事件类型、进程名、文件路径等关键信息
- **安全分析**: 检测可疑进程、路径、网络连接
- **风险评分**: 计算 0-1 的风险评分
- **结果汇总**: 生成分析摘要

### 3. 输出格式

处理后的数据包含：

```json
{
  "event_type": "open",
  "process_name": "cat",
  "process_pid": 1234,
  "fd_name": "/etc/passwd",
  "risk_level": "info",
  "risk_score": 0.0,
  "security_flags": [],
  "analysis_summary": {
    "event_type": "open",
    "process": "cat",
    "risk_level": "info",
    "risk_score": 0.0,
    "flags_count": 0,
    "timestamp": "2025-07-31T04:21:39.123456Z"
  }
}
```

## 管理命令

### 基础命令

```bash
# 启动服务
make start

# 停止服务
make stop

# 重启服务
make restart

# 查看日志（实时）
make logs

# 查看状态
make status

# 清理容器
make clean

# 完全重置
make reset
```

### 测试和调试

```bash
# 验证配置
make validate

# 运行测试
make test

# 健康检查
make health

# 一次性运行（不启动服务）
make run-once
```

### 数据查看

```bash
# 显示示例数据
make show-data

# 显示 VRL 脚本
make show-script
```

## 配置说明

### 管道配置 (pipelines/default.toml)

```toml
# 数据源：文件输入
[sources.file_input]
type = "file"
include = ["/data/sample-events.jsonl"]
read_from = "beginning"

# 数据转换：VRL 脚本处理
[transforms.process_events]
type = "remap"
inputs = ["file_input"]
file = "/etc/vector/scripts/process_events.vrl"

# 输出：控制台
[sinks.console_output]
type = "console"
inputs = ["process_events"]
encoding.codec = "json"
```

### VRL 脚本功能

VRL 脚本 `scripts/process_events.vrl` 提供以下安全分析功能：

#### 可疑进程检测
- `nc`, `netcat`: 网络工具
- `wget`, `curl`: 下载工具

#### 可疑路径检测
- `/tmp/`, `/var/tmp/`: 临时目录

#### 网络连接分析
- 解析网络连接格式 `source->destination`
- 提取源地址和目标地址

#### 风险评分
- 高风险 (≥0.8): 多个可疑指标
- 中风险 (≥0.5): 部分可疑指标
- 低风险 (≥0.2): 少量可疑指标
- 信息级 (<0.2): 正常活动

## 使用示例

### 基础使用

```bash
# 1. 启动服务
make start

# 2. 查看处理结果
make logs

# 3. 停止服务
make stop
```

### 一次性处理

```bash
# 运行一次性处理（不启动持久服务）
make run-once
```

### 自定义数据

```bash
# 1. 编辑数据文件
vim data/sample-events.jsonl

# 2. 重启服务查看新结果
make restart
make logs
```

### 自定义处理逻辑

```bash
# 1. 编辑 VRL 脚本
vim scripts/process_events.vrl

# 2. 验证配置
make validate

# 3. 重启服务
make restart
```

## 监控和调试

### 查看处理状态

```bash
# 查看服务状态
make status

# 查看实时日志
make logs

# 健康检查
make health
```

### 调试配置

```bash
# 验证配置语法
make validate

# 查看数据内容
make show-data

# 查看脚本内容
make show-script
```

### Vector API

Vector 提供 Web API 和 Playground：

- **API 端点**: http://localhost:8686
- **Playground**: http://localhost:8686/playground

## 项目结构

```
sysarmor-vector/
├── README.md                    # 项目文档
├── Makefile                     # 管理命令
├── docker-compose.yml           # Docker 部署配置
├── .env                         # 环境配置
├── .gitignore                   # Git 忽略文件
├── pipelines/
│   └── default.toml             # 默认管道配置
├── scripts/
│   └── process_events.vrl       # VRL 处理脚本
├── data/
│   └── sample-events.jsonl      # 示例数据
└── tests/
    └── test.sh                  # 测试脚本
```

## 扩展开发

### 添加新的安全规则

编辑 `scripts/process_events.vrl`，添加新的检测逻辑：

```vrl
# 检查新的可疑进程
if contains(.process_name, "suspicious_tool") {
    .security_flags = push(.security_flags, "new_suspicious_tool")
    .risk_score = .risk_score + 0.4
}
```

### 修改输出格式

编辑 `pipelines/default.toml`，更改输出目标：

```toml
# 输出到文件
[sinks.file_output]
type = "file"
inputs = ["process_events"]
path = "/tmp/processed_events.jsonl"
encoding.codec = "json"
```

### 添加新数据源

```toml
# 添加新的文件源
[sources.additional_input]
type = "file"
include = ["/data/additional-events.jsonl"]
read_from = "beginning"
```

## 故障排除

### 常见问题

1. **Vector 启动失败**
   ```bash
   # 检查配置语法
   make validate
   
   # 查看详细日志
   make logs
   ```

2. **数据文件读取失败**
   ```bash
   # 检查文件是否存在
   ls -la data/sample-events.jsonl
   
   # 检查文件格式
   make show-data
   ```

3. **VRL 脚本错误**
   ```bash
   # 验证配置
   make validate
   
   # 查看脚本内容
   make show-script
   ```

## 版本信息

- **Vector**: 0.34.0
- **Docker Compose**: 3.8
- **数据源**: File (JSONL)
- **处理**: VRL (Vector Remap Language)
- **输出**: Console (JSON)

## 许可证

MIT License

---

## 更新日志

### v1.0.0 (2025-07-31)
- 🎉 简化版本发布
- ✨ 文件到控制台的简单管道
- ✨ VRL 脚本安全分析
- ✨ Docker Compose 部署
- 📚 完整的文档和管理工具
