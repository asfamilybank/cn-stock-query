#!/usr/bin/env bash
# 测试输入校验（对应 query_price.sh 行 16-18）

describe "输入校验"

QUERY_SCRIPT="$PROJECT_ROOT/scripts/query_price.sh"

# 复现校验逻辑
validate_code() {
  local code="$1"
  if [[ ${#code} -ne 6 ]]; then
    echo "[ERROR] 无效代码: ${code}（必须为6位数字）"
    return 1
  fi
  return 0
}

# 正常 6 位代码
output=$(validate_code "600519" 2>&1)
assert_exit_code $? 0 "600519 → 通过"

# 5 位 → 错误
output=$(validate_code "12345" 2>&1)
assert_exit_code $? 1 "12345（5位）→ 失败"
assert_contains "$output" "[ERROR]" "5位代码输出含 [ERROR]"
assert_contains "$output" "无效代码" "5位代码输出含 无效代码"

# 7 位 → 错误
output=$(validate_code "1234567" 2>&1)
assert_exit_code $? 1 "1234567（7位）→ 失败"

# 空输入 → 错误
output=$(validate_code "" 2>&1)
assert_exit_code $? 1 "空输入 → 失败"

# 字母输入 → 错误（长度不为6）
output=$(validate_code "abcd" 2>&1)
assert_exit_code $? 1 "字母输入 → 失败"

# 6 位含字母（长度=6 但通过，后续由 API 处理）
output=$(validate_code "abc123" 2>&1)
assert_exit_code $? 0 "6位含字母 → 长度校验通过（API 层处理）"

# 实际脚本调用测试
describe "query_price.sh 无效代码输出"

script_output=$("$QUERY_SCRIPT" 123 2>&1 || true)
assert_contains "$script_output" "[ERROR]" "query_price.sh 123 → 输出 [ERROR]"
assert_contains "$script_output" "无效代码" "query_price.sh 123 → 输出 无效代码"
