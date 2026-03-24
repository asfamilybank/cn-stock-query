#!/usr/bin/env bash
# 测试东方财富备用 API

TIMEOUT="${INTEGRATION_TIMEOUT:-10}"

describe "东方财富净值 API"

if skip_if_no_network "东方财富 API 连通性"; then
  return 0 2>/dev/null || exit 0
fi

response=$(curl -s -m "$TIMEOUT" \
  "https://api.fund.eastmoney.com/f10/lsjz?fundCode=110011&pageIndex=1&pageSize=1" \
  -H "Referer: https://fund.eastmoney.com" 2>/dev/null)

assert_not_empty "$response" "东方财富 API 响应非空"

# 检查 JSON 结构
assert_contains "$response" "Data" "响应包含 Data 字段"
assert_contains "$response" "LSJZList" "响应包含 LSJZList 字段"

# 不应包含明显的错误标记
assert_not_contains "$response" '"ErrCode":1' "响应无错误码"
