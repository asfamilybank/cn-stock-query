#!/usr/bin/env bash
# 测试涨跌额/涨跌幅计算（对应 query_price.sh 行 72-84）

describe "涨跌幅计算"

# 复现 query_price.sh 的计算逻辑
calc_change() {
  local latest="$1" yesterday_close="$2"
  local change change_pct emoji sign

  if [[ "$yesterday_close" == "0.000" ]]; then
    echo "skip"
    return
  fi

  change=$(echo "scale=4; $latest - $yesterday_close" | bc)
  change_pct=$(echo "scale=4; ($latest - $yesterday_close) / $yesterday_close * 100" | bc | xargs printf "%.2f")

  if (( $(echo "$change > 0" | bc -l) )); then
    emoji="🔴"; sign="+"
  elif (( $(echo "$change < 0" | bc -l) )); then
    emoji="🟢"; sign=""
  else
    emoji="⚪"; sign=""
  fi

  echo "${emoji} ${sign}${change_pct}%"
}

# 上涨
result=$(calc_change "4.310" "4.250")
assert_contains "$result" "🔴" "上涨 → 红色圆点"
assert_contains "$result" "+" "上涨 → + 前缀"
assert_contains "$result" "1.41%" "4.310 vs 4.250 → +1.41%"

# 下跌
result=$(calc_change "10.606" "10.637")
assert_contains "$result" "🟢" "下跌 → 绿色圆点"
assert_contains "$result" "-" "下跌 → - 前缀"

# 平盘
result=$(calc_change "4.250" "4.250")
assert_contains "$result" "⚪" "平盘 → 白色圆点"
assert_contains "$result" "0.00%" "平盘 → 0.00%"

# 昨收为 0 → skip
result=$(calc_change "4.250" "0.000")
assert_eq "$result" "skip" "昨收为 0.000 → 跳过计算"

# 小幅波动精度
result=$(calc_change "1.001" "1.000")
assert_contains "$result" "🔴" "小幅上涨 0.1% → 红色"
assert_contains "$result" "0.10%" "1.001 vs 1.000 → 0.10%"

# 较大跌幅
result=$(calc_change "9.000" "10.000")
assert_contains "$result" "🟢" "10% 下跌 → 绿色"
assert_contains "$result" "-10.00%" "9.000 vs 10.000 → -10.00%"
