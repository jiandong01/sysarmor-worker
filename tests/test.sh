#!/bin/bash

# SysArmor Vector ETL 测试脚本
# 简化版测试，验证基本功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 测试计数器
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_info "运行测试: $test_name"
    
    if eval "$test_command"; then
        log_success "✅ $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "❌ $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    run_test "Docker 可用性" "docker --version > /dev/null 2>&1"
    run_test "Docker Compose 可用性" "docker compose version > /dev/null 2>&1"
    run_test "curl 可用性" "command -v curl > /dev/null 2>&1"
}

# 验证配置文件
validate_configs() {
    log_info "验证管道配置文件..."
    
    for config in pipelines/*.toml; do
        if [ -f "$config" ]; then
            config_name=$(basename "$config" .toml)
            run_test "配置验证: $config_name" "make validate $config_name > /dev/null 2>&1"
        fi
    done
}

# 测试基础功能
test_basic_functionality() {
    log_info "测试基础功能..."
    
    # 创建测试数据
    run_test "创建测试数据" "make create-sample-data > /dev/null 2>&1"
    
    # 验证测试数据
    if [ -f "data/sample-events.jsonl" ]; then
        run_test "验证测试数据" "[ -s data/sample-events.jsonl ]"
    fi
    
    # 测试管道列表
    run_test "列出管道配置" "make list-pipelines > /dev/null 2>&1"
}

# 测试容器启动（可选）
test_container_startup() {
    log_info "测试容器启动（快速测试）..."
    
    # 快速启动测试（30秒超时）
    if timeout 30 make start default > /dev/null 2>&1; then
        run_test "容器启动测试" "true"
        
        # 等待服务启动
        sleep 5
        
        # 健康检查
        if curl -s http://localhost:8686/health > /dev/null 2>&1; then
            run_test "健康检查" "true"
        else
            run_test "健康检查" "false"
        fi
        
        # 清理
        make stop > /dev/null 2>&1
    else
        run_test "容器启动测试" "false"
    fi
}

# 显示测试结果
show_results() {
    echo
    echo "=================================="
    echo "         测试结果汇总"
    echo "=================================="
    echo "总测试数: $TESTS_TOTAL"
    echo "通过: $TESTS_PASSED"
    echo "失败: $TESTS_FAILED"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "🎉 所有测试通过！"
        return 0
    else
        log_error "❌ 有 $TESTS_FAILED 个测试失败"
        return 1
    fi
}

# 主函数
main() {
    echo "🧪 SysArmor Vector ETL 测试"
    echo "=========================="
    echo
    
    check_dependencies
    validate_configs
    test_basic_functionality
    
    # 可选的容器测试（如果用户想要）
    if [ "$1" = "--full" ]; then
        test_container_startup
    else
        log_info "跳过容器启动测试（使用 --full 参数启用完整测试）"
    fi
    
    show_results
}

# 运行主函数
main "$@"
