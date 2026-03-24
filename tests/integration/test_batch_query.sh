#!/usr/bin/env bash
# 测试 query_price.sh 批量查询

QUERY_SCRIPT="$PROJECT_ROOT/scripts/query_price.sh"

describe "query_price.sh 批量查询"

if skip_if_no_network "批量查询需网络"; then
  return 0 2>/dev/null || exit 0
fi

# 正常批量查询：一个沪市股票 + 一个 ETF
output=$("$QUERY_SCRIPT" 600519 518880 2>&1)
exit_code=$?

assert_exit_code "$exit_code" 0 "exit code 0"
assert_contains "$output" "股票/ETF 行情" "输出含 股票/ETF 行情 标题"
assert_contains "$output" "600519" "输出含 sh600519"
assert_contains "$output" "518880" "输出含 sh518880"

# 验证每行都有管道分隔的字段
result_lines=$(echo "$output" | grep '|' | wc -l | tr -d ' ')
assert_gt "$result_lines" "1" "输出含 >1 行管道分隔结果"

describe "query_price.sh 混合查询（股票 + 基金）"

# 混合查询：股票 + 场外基金
mixed_output=$("$QUERY_SCRIPT" 600519 005827 2>&1)
mixed_exit=$?

assert_exit_code "$mixed_exit" 0 "混合查询 exit code 0"
assert_contains "$mixed_output" "股票/ETF 行情" "混合查询含股票部分"
assert_contains "$mixed_output" "基金" "混合查询含基金部分"

describe "query_price.sh 无参数"

# 无参数应正常退出（无输出）
no_arg_output=$("$QUERY_SCRIPT" 2>&1)
no_arg_exit=$?
assert_exit_code "$no_arg_exit" 0 "无参数 exit code 0"
