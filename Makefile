# SysArmor Vector ETL Makefile
# 简化版本 - 单一默认管道

.PHONY: help start stop restart logs status clean reset test validate

# 默认目标
help:
	@echo "SysArmor Vector ETL 管理工具"
	@echo "============================="
	@echo ""
	@echo "🚀 基础命令:"
	@echo "  start                    - 启动 Vector 服务"
	@echo "  stop                     - 停止 Vector 服务"
	@echo "  restart                  - 重启 Vector 服务"
	@echo "  logs                     - 查看 Vector 日志"
	@echo "  status                   - 查看服务状态"
	@echo "  clean                    - 清理容器"
	@echo "  reset                    - 完全重置"
	@echo ""
	@echo "🧪 测试和调试:"
	@echo "  test                     - 运行测试"
	@echo "  validate                 - 验证配置"
	@echo ""
	@echo "📊 监控命令:"
	@echo "  health                   - 健康检查"
	@echo ""
	@echo "📋 数据处理:"
	@echo "  - 从 data/sample-events.jsonl 读取数据"
	@echo "  - 使用 scripts/process_events.vrl 处理"
	@echo "  - 输出到控制台"

# 启动 Vector 服务
start:
	@echo "🚀 启动 SysArmor Vector ETL..."
	@echo "📋 使用默认管道配置"
	@docker compose up -d
	@echo "⏳ 等待 Vector 启动..."
	@sleep 10
	@echo "✅ Vector ETL 启动完成!"
	@echo "📊 Vector API: http://localhost:8686"
	@echo "🎮 Vector Playground: http://localhost:8686/playground"
	@$(MAKE) status

# 停止服务
stop:
	@echo "🛑 停止 SysArmor Vector ETL..."
	@docker compose stop
	@echo "✅ Vector ETL 已停止"

# 重启服务
restart:
	@echo "🔄 重启 SysArmor Vector ETL..."
	@$(MAKE) stop
	@sleep 3
	@$(MAKE) start

# 查看日志
logs:
	@echo "📋 查看 Vector 日志..."
	@docker compose logs -f vector

# 查看服务状态
status:
	@echo "🔍 检查 Vector 服务状态..."
	@echo "=== 容器状态 ==="
	@docker compose ps 2>/dev/null || echo "❌ Vector 未运行"
	@echo ""
	@echo "=== 健康检查 ==="
	@if curl -s http://localhost:8686/health >/dev/null 2>&1; then \
		echo "✅ Vector API: 健康运行 (http://localhost:8686)"; \
	else \
		echo "❌ Vector API: 异常或未启动 (http://localhost:8686)"; \
	fi
	@echo ""
	@echo "=== 数据文件检查 ==="
	@if [ -f "data/sample-events.jsonl" ]; then \
		echo "✅ 示例数据文件存在 ($(shell wc -l < data/sample-events.jsonl) 行)"; \
	else \
		echo "❌ 示例数据文件不存在"; \
	fi
	@echo ""
	@echo "=== VRL 脚本检查 ==="
	@if [ -f "scripts/process_events.vrl" ]; then \
		echo "✅ VRL 处理脚本存在"; \
	else \
		echo "❌ VRL 处理脚本不存在"; \
	fi

# 清理容器
clean:
	@echo "🧹 清理 Vector 容器..."
	@docker compose down
	@echo "✅ 容器清理完成"

# 完全重置
reset:
	@echo "💥 完全重置 Vector ETL (删除容器和数据卷)..."
	@docker compose down -v
	@echo "✅ 完全重置完成"

# 验证管道配置
validate:
	@echo "🔍 验证管道配置..."
	@docker run --rm -v $(PWD)/pipelines:/etc/vector/pipelines:ro \
		-v $(PWD)/scripts:/etc/vector/scripts:ro \
		timberio/vector:0.34.0-alpine \
		validate /etc/vector/pipelines/default.toml && \
	echo "✅ 配置验证通过"

# 健康检查
health:
	@echo "🏥 Vector 健康检查..."
	@curl -s http://localhost:8686/health | jq . 2>/dev/null || echo "❌ 无法连接到 Vector API"

# 运行测试
test:
	@echo "🧪 运行 Vector ETL 测试..."
	@if [ -f "tests/test.sh" ]; then \
		bash tests/test.sh; \
	else \
		echo "⚠️  测试脚本不存在"; \
		exit 1; \
	fi

# 查看处理结果（运行一次性处理）
run-once:
	@echo "🔄 运行一次性数据处理..."
	@docker run --rm \
		-v $(PWD)/pipelines:/etc/vector/pipelines:ro \
		-v $(PWD)/scripts:/etc/vector/scripts:ro \
		-v $(PWD)/data:/data:ro \
		timberio/vector:0.34.0-alpine \
		--config /etc/vector/pipelines/default.toml

# 显示示例数据
show-data:
	@echo "📄 示例数据内容:"
	@echo "=================="
	@if [ -f "data/sample-events.jsonl" ]; then \
		cat data/sample-events.jsonl | head -3 | jq .; \
	else \
		echo "❌ 示例数据文件不存在"; \
	fi

# 显示 VRL 脚本
show-script:
	@echo "📜 VRL 处理脚本:"
	@echo "================"
	@if [ -f "scripts/process_events.vrl" ]; then \
		head -20 scripts/process_events.vrl; \
		echo "..."; \
	else \
		echo "❌ VRL 脚本文件不存在"; \
	fi
