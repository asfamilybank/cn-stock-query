#!/usr/bin/env bash
# 测试基金 JSONP 响应解析（对应 query_price.sh 行 104-108）

describe "基金 JSONP 解析 — 正常响应"

fixture=$(cat "$FIXTURES_DIR/fund_normal.txt")

# 与 query_price.sh 完全相同的提取管道
name=$(echo "$fixture" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
assert_eq "$name" "易方达蓝筹精选混合" "name 字段提取"

fundcode=$(echo "$fixture" | grep -o '"fundcode":"[^"]*"' | cut -d'"' -f4)
assert_eq "$fundcode" "005827" "fundcode 字段提取"

dwjz=$(echo "$fixture" | grep -o '"dwjz":"[^"]*"' | cut -d'"' -f4)
assert_not_empty "$dwjz" "dwjz（单位净值）非空"
assert_regex "$dwjz" '^[0-9]+\.[0-9]+$' "dwjz 为数字格式"

gsz=$(echo "$fixture" | grep -o '"gsz":"[^"]*"' | cut -d'"' -f4)
assert_not_empty "$gsz" "gsz（估算净值）非空"
assert_regex "$gsz" '^[0-9]+\.[0-9]+$' "gsz 为数字格式"

gszzl=$(echo "$fixture" | grep -o '"gszzl":"[^"]*"' | cut -d'"' -f4)
assert_not_empty "$gszzl" "gszzl（估算涨跌幅）非空"

gztime=$(echo "$fixture" | grep -o '"gztime":"[^"]*"' | cut -d'"' -f4)
assert_regex "$gztime" '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$' "gztime 时间格式"

jzrq=$(echo "$fixture" | grep -o '"jzrq":"[^"]*"' | cut -d'"' -f4)
assert_regex "$jzrq" '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "jzrq 日期格式"

# QDII 基金
describe "基金 JSONP 解析 — QDII 基金"

qdii_fixture=$(cat "$FIXTURES_DIR/fund_qdii.txt")
qdii_name=$(echo "$qdii_fixture" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
assert_contains "$qdii_name" "QDII" "QDII 基金名称含 QDII 关键词"

# 空响应
describe "基金 JSONP 解析 — 空响应"

empty_fixture=$(cat "$FIXTURES_DIR/fund_empty.txt")
assert_eq "$empty_fixture" "jsonpgz();" "空响应为 jsonpgz();"

empty_name=$(echo "$empty_fixture" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
assert_empty "$empty_name" "空响应无 name 字段"
