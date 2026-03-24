#!/usr/bin/env bash
# 测试新浪财经 API 真实调用

TIMEOUT="${INTEGRATION_TIMEOUT:-10}"
TEST_SH="${TEST_STOCK_SH:-600519}"
TEST_SZ="${TEST_STOCK_SZ:-000001}"

describe "新浪财经 API — 沪市股票"

if skip_if_no_network "新浪 API 连通性"; then
  return 0 2>/dev/null || exit 0
fi

response=$(curl -s -m "$TIMEOUT" "https://hq.sinajs.cn/list=sh${TEST_SH}" \
  -H "Referer: https://finance.sina.com.cn" | iconv -f GBK -t UTF-8 2>/dev/null)

assert_not_empty "$response" "sh${TEST_SH} 响应非空"
assert_not_contains "$response" '=""' "sh${TEST_SH} 响应非空数据（不含 =\"\"）"
assert_contains "$response" "var hq_str" "响应包含 var hq_str 前缀"

# 验证字段数量
data=$(echo "$response" | cut -d'"' -f2)
field_count=$(echo "$data" | tr ',' '\n' | wc -l | tr -d ' ')
assert_gt "$field_count" "30" "字段数 > 30（实际: ${field_count}）"

# 名称为有效 UTF-8
name=$(echo "$data" | cut -d',' -f1)
assert_not_empty "$name" "名称字段非空: ${name}"

# 价格为有效数字
latest=$(echo "$data" | cut -d',' -f4)
assert_regex "$latest" '^[0-9]+\.[0-9]+$' "最新价为数字: ${latest}"

describe "新浪财经 API — 深市股票"

response_sz=$(curl -s -m "$TIMEOUT" "https://hq.sinajs.cn/list=sz${TEST_SZ}" \
  -H "Referer: https://finance.sina.com.cn" | iconv -f GBK -t UTF-8 2>/dev/null)

assert_not_empty "$response_sz" "sz${TEST_SZ} 响应非空"
assert_not_contains "$response_sz" '=""' "sz${TEST_SZ} 响应非空数据"

describe "新浪财经 API — 无效代码"

response_invalid=$(curl -s -m "$TIMEOUT" "https://hq.sinajs.cn/list=sz999999" \
  -H "Referer: https://finance.sina.com.cn" | iconv -f GBK -t UTF-8 2>/dev/null)

assert_contains "$response_invalid" '=""' "无效代码 sz999999 返回空数据"
