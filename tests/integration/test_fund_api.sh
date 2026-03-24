#!/usr/bin/env bash
# 测试天天基金 API 真实调用

TIMEOUT="${INTEGRATION_TIMEOUT:-10}"
TEST_FC="${TEST_FUND:-110011}"

describe "天天基金 API — 正常基金"

if skip_if_no_network "天天基金 API 连通性"; then
  return 0 2>/dev/null || exit 0
fi

response=$(curl -s -m "$TIMEOUT" "http://fundgz.1234567.com.cn/js/${TEST_FC}.js")

assert_not_empty "$response" "基金 ${TEST_FC} 响应非空"

# 非空响应检查
if [[ "$response" == "jsonpgz();" ]] || [[ "$response" == "jsonpgz()" ]]; then
  test_fail "基金 ${TEST_FC} 返回空 jsonpgz()"
else
  test_pass "基金 ${TEST_FC} 返回有效数据"

  # 验证关键字段存在
  name=$(echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
  assert_not_empty "$name" "name 字段: ${name}"

  dwjz=$(echo "$response" | grep -o '"dwjz":"[^"]*"' | cut -d'"' -f4)
  assert_not_empty "$dwjz" "dwjz 字段: ${dwjz}"
  assert_regex "$dwjz" '^[0-9]+\.[0-9]+$' "dwjz 为数字格式"

  gsz=$(echo "$response" | grep -o '"gsz":"[^"]*"' | cut -d'"' -f4)
  assert_not_empty "$gsz" "gsz 字段: ${gsz}"

  gszzl=$(echo "$response" | grep -o '"gszzl":"[^"]*"' | cut -d'"' -f4)
  assert_not_empty "$gszzl" "gszzl 字段: ${gszzl}"

  gztime=$(echo "$response" | grep -o '"gztime":"[^"]*"' | cut -d'"' -f4)
  assert_not_empty "$gztime" "gztime 字段: ${gztime}"
fi

describe "天天基金 API — 无效基金代码"

response_bad=$(curl -s -m "$TIMEOUT" "http://fundgz.1234567.com.cn/js/999999.js")
# 无效代码可能返回空 jsonpgz() 或实际数据（API 行为不可控）
# 仅验证接口不崩溃，能返回响应
assert_not_empty "$response_bad" "无效代码 999999 接口有响应（不崩溃）"
