#!/usr/bin/env bash
# 测试新浪响应字段提取（对应 query_price.sh 行 57-70）

describe "新浪响应字段提取"

# 从 fixture 读取数据
fixture=$(cat "$FIXTURES_DIR/sina_stock.txt")

# 提取引号内的数据部分
data=$(echo "$fixture" | cut -d'"' -f2)

# 提取 full_code
full_code=$(echo "$fixture" | grep -o 'str_[a-z]*[0-9]*' | sed 's/str_//')
assert_eq "$full_code" "sh600519" "提取代码: sh600519"

# 字段提取（与 query_price.sh 相同的 cut 管道）
name=$(echo "$data" | cut -d',' -f1)
assert_eq "$name" "贵州茅台" "字段[0] 名称: 贵州茅台"

today_open=$(echo "$data" | cut -d',' -f2)
assert_not_empty "$today_open" "字段[1] 今开: 非空"
assert_regex "$today_open" '^[0-9]+\.[0-9]+$' "字段[1] 今开: 数字格式"

yesterday_close=$(echo "$data" | cut -d',' -f3)
assert_not_empty "$yesterday_close" "字段[2] 昨收: 非空"

latest=$(echo "$data" | cut -d',' -f4)
assert_not_empty "$latest" "字段[3] 最新价: 非空"
assert_regex "$latest" '^[0-9]+\.[0-9]+$' "字段[3] 最新价: 数字格式"

high=$(echo "$data" | cut -d',' -f5)
assert_not_empty "$high" "字段[4] 最高: 非空"

low=$(echo "$data" | cut -d',' -f6)
assert_not_empty "$low" "字段[5] 最低: 非空"

volume=$(echo "$data" | cut -d',' -f9)
assert_not_empty "$volume" "字段[8] 成交量: 非空"
assert_regex "$volume" '^[0-9]+$' "字段[8] 成交量: 整数格式"

date_field=$(echo "$data" | cut -d',' -f31)
assert_regex "$date_field" '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "字段[30] 日期: YYYY-MM-DD 格式"

time_field=$(echo "$data" | cut -d',' -f32)
assert_regex "$time_field" '^[0-9]{2}:[0-9]{2}:[0-9]{2}$' "字段[31] 时间: HH:MM:SS 格式"

# 批量响应：每行一个标的
describe "批量响应解析"

batch_fixture=$(cat "$FIXTURES_DIR/sina_batch.txt")
line_count=$(echo "$batch_fixture" | grep -c 'var hq_str')
assert_eq "$line_count" "3" "批量响应包含 3 行"

# 验证每行都能提取出名称
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  line_data=$(echo "$line" | cut -d'"' -f2)
  line_name=$(echo "$line_data" | cut -d',' -f1)
  assert_not_empty "$line_name" "批量行 名称非空: $line_name"
done <<< "$batch_fixture"

# 空响应识别
describe "空响应识别"

empty_fixture=$(cat "$FIXTURES_DIR/sina_empty.txt")
empty_data=$(echo "$empty_fixture" | cut -d'"' -f2)
assert_empty "$empty_data" "空响应 data 为空字符串"
assert_contains "$empty_fixture" '=""' "空响应包含 =\"\" 标记"
