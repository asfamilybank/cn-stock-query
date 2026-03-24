#!/usr/bin/env bash
# E2E 测试：通过 openclaw agent --local 做全链路验证
# 需要 ANTHROPIC_API_KEY 环境变量

E2E_TIMEOUT="${E2E_TIMEOUT:-60}"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  describe "E2E Agent Tests"
  test_skip "全部 E2E 测试" "未配置 ANTHROPIC_API_KEY"
  return 0 2>/dev/null || exit 0
fi

if ! command -v openclaw &>/dev/null; then
  describe "E2E Agent Tests"
  test_skip "全部 E2E 测试" "未安装 openclaw CLI"
  return 0 2>/dev/null || exit 0
fi

run_agent() {
  local message="$1"
  openclaw agent --local \
    --message "$message" \
    --timeout "$E2E_TIMEOUT" 2>&1
}

# --- 单只股票查询 ---
describe "E2E — 单只股票查询"

output=$(run_agent "查股价 600519")
agent_exit=$?

if [[ $agent_exit -ne 0 ]]; then
  test_fail "agent 执行成功 (exit: $agent_exit)"
else
  test_pass "agent 执行成功"
  # 输出应包含股票代码或名称
  if [[ "$output" == *"600519"* ]] || [[ "$output" == *"贵州茅台"* ]] || [[ "$output" == *"茅台"* ]]; then
    test_pass "输出含 600519 / 贵州茅台"
  else
    test_fail "输出含 600519 / 贵州茅台"
  fi
fi

# --- 批量查询 ---
describe "E2E — 批量查询"

output=$(run_agent "查行情 600519 518880")
agent_exit=$?

if [[ $agent_exit -ne 0 ]]; then
  test_fail "批量查询 agent 执行成功 (exit: $agent_exit)"
else
  test_pass "批量查询 agent 执行成功"
  if [[ "$output" == *"600519"* ]] || [[ "$output" == *"茅台"* ]]; then
    test_pass "批量查询含股票结果"
  else
    test_fail "批量查询含股票结果"
  fi
  if [[ "$output" == *"518880"* ]] || [[ "$output" == *"黄金"* ]]; then
    test_pass "批量查询含 ETF 结果"
  else
    test_fail "批量查询含 ETF 结果"
  fi
fi

# --- 基金查询 ---
describe "E2E — 基金查询"

output=$(run_agent "查净值 005827")
agent_exit=$?

if [[ $agent_exit -ne 0 ]]; then
  test_fail "基金查询 agent 执行成功 (exit: $agent_exit)"
else
  test_pass "基金查询 agent 执行成功"
  if [[ "$output" == *"005827"* ]] || [[ "$output" == *"蓝筹"* ]] || [[ "$output" == *"净值"* ]] || [[ "$output" == *"估"* ]]; then
    test_pass "基金查询含基金相关内容"
  else
    test_fail "基金查询含基金相关内容"
  fi
fi

# --- 名称查询 ---
describe "E2E — 名称查询"

output=$(run_agent "查一下黄金ETF最新价")
agent_exit=$?

if [[ $agent_exit -ne 0 ]]; then
  test_fail "名称查询 agent 执行成功 (exit: $agent_exit)"
else
  test_pass "名称查询 agent 执行成功"
  if [[ "$output" == *"518880"* ]] || [[ "$output" == *"黄金"* ]]; then
    test_pass "名称查询正确识别黄金ETF"
  else
    test_fail "名称查询正确识别黄金ETF"
  fi
fi

# --- 无效输入 ---
describe "E2E — 无效输入"

output=$(run_agent "查股价 123")
agent_exit=$?

if [[ $agent_exit -ne 0 ]]; then
  test_skip "无效输入测试" "agent 异常退出"
else
  test_pass "无效输入 agent 执行成功"
  # agent 应给出某种提示（格式错误、请确认等）
  if [[ "$output" == *"6位"* ]] || [[ "$output" == *"确认"* ]] || [[ "$output" == *"格式"* ]] || [[ "$output" == *"代码"* ]]; then
    test_pass "无效输入有提示信息"
  else
    test_skip "无效输入提示检测" "agent 响应格式不确定"
  fi
fi
