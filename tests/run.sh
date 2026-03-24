#!/usr/bin/env bash
# 主测试运行器
# Usage:
#   ./tests/run.sh              # 按 .env.local 开关执行
#   ./tests/run.sh unit         # 仅 unit
#   ./tests/run.sh integration  # 仅 integration
#   ./tests/run.sh e2e          # 仅 e2e
#   ./tests/run.sh all          # 全部层级

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 加载 .env.local（存在则 source）
if [[ -f "$PROJECT_ROOT/.env.local" ]]; then
  set -a
  source "$PROJECT_ROOT/.env.local"
  set +a
fi

# 默认值
RUN_UNIT="${RUN_UNIT:-true}"
RUN_INTEGRATION="${RUN_INTEGRATION:-true}"
RUN_E2E="${RUN_E2E:-false}"

# CLI 参数覆盖
case "${1:-}" in
  unit)
    RUN_UNIT=true; RUN_INTEGRATION=false; RUN_E2E=false ;;
  integration)
    RUN_UNIT=false; RUN_INTEGRATION=true; RUN_E2E=false ;;
  e2e)
    RUN_UNIT=false; RUN_INTEGRATION=false; RUN_E2E=true ;;
  all)
    RUN_UNIT=true; RUN_INTEGRATION=true; RUN_E2E=true ;;
  "") ;; # 用 .env.local 的开关
  *)
    echo "Usage: $0 [unit|integration|e2e|all]"
    exit 1 ;;
esac

# 全局计数
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

run_layer() {
  local layer="$1" label="$2"
  local layer_dir="$SCRIPT_DIR/$layer"

  if [[ ! -d "$layer_dir" ]]; then
    echo "⚠  目录不存在: $layer_dir"
    return 0
  fi

  local test_files=("$layer_dir"/test_*.sh)
  if [[ ! -f "${test_files[0]:-}" ]]; then
    echo "⚠  $label: 无测试文件"
    return 0
  fi

  echo ""
  echo "╔════════════════════════════════════╗"
  printf "║  %-32s  ║\n" "$label"
  echo "╚════════════════════════════════════╝"

  local layer_fail=0
  for test_file in "${test_files[@]}"; do
    # 每个测试文件在子 shell 中运行，隔离计数器
    (
      source "$SCRIPT_DIR/helpers.sh"
      source "$test_file"
      summary
    )
    local exit_code=$?

    # 从子 shell 中无法直接传递计数，用 exit code 标记失败
    if [[ $exit_code -ne 0 ]]; then
      layer_fail=1
    fi
  done

  return $layer_fail
}

EXIT_CODE=0

if [[ "$RUN_UNIT" == "true" ]]; then
  run_layer "unit" "Unit Tests（纯本地）" || EXIT_CODE=1
fi

if [[ "$RUN_INTEGRATION" == "true" ]]; then
  run_layer "integration" "Integration Tests（真实 API）" || EXIT_CODE=1
fi

if [[ "$RUN_E2E" == "true" ]]; then
  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo ""
    echo "⚠  E2E tests 需要 ANTHROPIC_API_KEY，跳过"
    echo "   请在 .env.local 中配置 ANTHROPIC_API_KEY 并设置 RUN_E2E=true"
  else
    run_layer "e2e" "E2E Agent Tests（openclaw --local）" || EXIT_CODE=1
  fi
fi

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "🎉 所有测试通过"
else
  echo "💥 存在失败的测试"
fi

exit $EXIT_CODE
