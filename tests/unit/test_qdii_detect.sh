#!/usr/bin/env bash
# 测试 QDII 关键词检测（对应 query_price.sh 行 123）

describe "QDII 关键词检测"

# 与 query_price.sh 完全相同的 grep 模式
is_qdii() {
  echo "$1" | grep -qiE "QDII|纳斯达克|标普|海外|美国|全球"
}

# 应匹配
is_qdii "易方达优质精选混合(QDII)" && assert_eq "0" "0" "含 QDII → 匹配" || assert_eq "1" "0" "含 QDII → 匹配"
is_qdii "华安纳斯达克100ETF联接C" && assert_eq "0" "0" "含 纳斯达克 → 匹配" || assert_eq "1" "0" "含 纳斯达克 → 匹配"
is_qdii "博时标普500ETF联接A" && assert_eq "0" "0" "含 标普 → 匹配" || assert_eq "1" "0" "含 标普 → 匹配"
is_qdii "广发海外多元配置" && assert_eq "0" "0" "含 海外 → 匹配" || assert_eq "1" "0" "含 海外 → 匹配"
is_qdii "国泰美国房地产" && assert_eq "0" "0" "含 美国 → 匹配" || assert_eq "1" "0" "含 美国 → 匹配"
is_qdii "南方全球精选配置" && assert_eq "0" "0" "含 全球 → 匹配" || assert_eq "1" "0" "含 全球 → 匹配"

# 不应匹配
is_qdii "易方达蓝筹精选混合" && result=0 || result=1
assert_eq "$result" "1" "普通基金 → 不匹配"

is_qdii "招商中证白酒指数" && result=0 || result=1
assert_eq "$result" "1" "白酒指数 → 不匹配"

is_qdii "华夏沪深300ETF联接" && result=0 || result=1
assert_eq "$result" "1" "沪深300联接 → 不匹配"

# fixture 验证
describe "QDII 检测 — fixture 数据"

qdii_name=$(grep -o '"name":"[^"]*"' "$FIXTURES_DIR/fund_qdii.txt" | cut -d'"' -f4)
is_qdii "$qdii_name" && result=0 || result=1
assert_eq "$result" "0" "fund_qdii.txt 中的基金名称应匹配 QDII"

normal_name=$(grep -o '"name":"[^"]*"' "$FIXTURES_DIR/fund_normal.txt" | cut -d'"' -f4)
is_qdii "$normal_name" && result=0 || result=1
assert_eq "$result" "1" "fund_normal.txt 中的基金名称不应匹配 QDII"
