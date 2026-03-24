#!/usr/bin/env bash
# 测试市场前缀识别逻辑（对应 query_price.sh 行 21-37）

describe "市场前缀识别"

# 复现 query_price.sh 的市场判断逻辑
identify_market() {
  local code="$1"
  if [[ $code =~ ^6 ]]; then
    echo "sh:stock"
  elif [[ $code =~ ^[03] ]]; then
    echo "sz:stock_or_fund"
  elif [[ $code =~ ^5 ]]; then
    echo "sh:etf"
  elif [[ $code =~ ^1 ]]; then
    echo "sz:etf"
  else
    echo "fund"
  fi
}

# 沪市股票
assert_eq "$(identify_market 600519)" "sh:stock" "600519 → sh:stock（贵州茅台）"
assert_eq "$(identify_market 601991)" "sh:stock" "601991 → sh:stock（大唐发电）"
assert_eq "$(identify_market 688981)" "sh:stock" "688981 → sh:stock（科创板）"

# 深市股票 / 可能是基金
assert_eq "$(identify_market 000001)" "sz:stock_or_fund" "000001 → sz:stock_or_fund（平安银行）"
assert_eq "$(identify_market 300750)" "sz:stock_or_fund" "300750 → sz:stock_or_fund（创业板）"
assert_eq "$(identify_market 002594)" "sz:stock_or_fund" "002594 → sz:stock_or_fund（中小板）"

# 沪市 ETF
assert_eq "$(identify_market 510300)" "sh:etf" "510300 → sh:etf（沪深300ETF）"
assert_eq "$(identify_market 518880)" "sh:etf" "518880 → sh:etf（黄金ETF）"
assert_eq "$(identify_market 563230)" "sh:etf" "563230 → sh:etf（卫星ETF）"

# 深市 ETF
assert_eq "$(identify_market 159915)" "sz:etf" "159915 → sz:etf（创业板ETF）"
assert_eq "$(identify_market 159919)" "sz:etf" "159919 → sz:etf（沪深300ETF深市）"

# 场外基金（2/4/7/8/9 开头）
assert_eq "$(identify_market 210001)" "fund" "210001 → fund（2开头）"
assert_eq "$(identify_market 400001)" "fund" "400001 → fund（4开头）"
assert_eq "$(identify_market 710001)" "fund" "710001 → fund（7开头）"
assert_eq "$(identify_market 810001)" "fund" "810001 → fund（8开头）"
assert_eq "$(identify_market 960001)" "fund" "960001 → fund（9开头）"
