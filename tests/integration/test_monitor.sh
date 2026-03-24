#!/usr/bin/env bash
# 测试 monitor.sh 运行

MONITOR_SCRIPT="$PROJECT_ROOT/scripts/monitor.sh"

describe "monitor.sh 接口监控"

if skip_if_no_network "monitor.sh 需网络"; then
  return 0 2>/dev/null || exit 0
fi

output=$("$MONITOR_SCRIPT" 2>&1)
exit_code=$?

# monitor.sh 使用 set -uo pipefail 但不 set -e，总应退出 0
assert_exit_code "$exit_code" 0 "monitor.sh exit code 0"
assert_contains "$output" "数据源可用性监控" "输出含标题"
assert_contains "$output" "股票/ETF（新浪财经）" "输出含新浪部分"
assert_contains "$output" "场外基金（天天基金）" "输出含天天基金部分"
assert_contains "$output" "备用接口（东方财富）" "输出含东方财富部分"

# 至少应有一些 [OK] 结果
ok_count=$(echo "$output" | grep -c '\[OK\]' || true)
assert_gt "$ok_count" "0" "至少有 1 个 [OK] 结果（实际: ${ok_count}）"

# 汇总行
assert_contains "$output" "结果:" "输出含结果汇总行"
# 提取汇总行做 regex 断言（assert_regex 不支持多行）
# monitor.sh 输出两种格式："全部通过 (N/N)" 或 "N/N 通过"
summary_line=$(echo "$output" | grep -E '(通过|全部通过)' | tail -1)
assert_regex "$summary_line" '[0-9]+/[0-9]+' "汇总含 N/N 计数"
