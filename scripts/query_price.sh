#!/usr/bin/env bash
# 批量查询中国 A 股股票/ETF/场外基金价格
# 用法: ./query_price.sh 600519 510300 110011
# 所有新浪接口响应自动从 GBK 转 UTF-8

set -euo pipefail

SINA_API="https://hq.sinajs.cn/list="
FUND_API="http://fundgz.1234567.com.cn/js/"
TIMEOUT=5

stock_list=""
fund_codes=()

for code in "$@"; do
  if [[ ${#code} -ne 6 ]]; then
    echo "[ERROR] 无效代码: ${code}（必须为6位数字）"
    continue
  fi

  if [[ $code =~ ^6 ]]; then
    stock_list="${stock_list:+$stock_list,}sh${code}"
  elif [[ $code =~ ^[03] ]]; then
    result=$(curl -s -m $TIMEOUT "https://hq.sinajs.cn/list=sz${code}" \
      -H "Referer: https://finance.sina.com.cn" | iconv -f GBK -t UTF-8 2>/dev/null)
    if [[ "$result" == *'=""'* ]] || [[ -z "$result" ]]; then
      fund_codes+=("$code")
    else
      stock_list="${stock_list:+$stock_list,}sz${code}"
    fi
  elif [[ $code =~ ^5 ]]; then
    stock_list="${stock_list:+$stock_list,}sh${code}"
  elif [[ $code =~ ^1 ]]; then
    stock_list="${stock_list:+$stock_list,}sz${code}"
  else
    fund_codes+=("$code")
  fi
done

if [[ -n "$stock_list" ]]; then
  echo "=== 股票/ETF 行情 ==="
  response=$(curl -s -m $TIMEOUT "${SINA_API}${stock_list}" \
    -H "Referer: https://finance.sina.com.cn" | iconv -f GBK -t UTF-8 2>/dev/null)

  if [[ -z "$response" ]]; then
    echo "[ERROR] 新浪接口请求失败，正在重试..."
    sleep 1
    response=$(curl -s -m $TIMEOUT "${SINA_API}${stock_list}" \
      -H "Referer: https://finance.sina.com.cn" | iconv -f GBK -t UTF-8 2>/dev/null)
  fi

  if [[ -z "$response" ]]; then
    echo "[ERROR] 新浪接口不可用，请稍后重试"
  else
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      full_code=$(echo "$line" | grep -o 'str_[a-z]*[0-9]*' | sed 's/str_//')
      data=$(echo "$line" | cut -d'"' -f2)
      if [[ -z "$data" ]]; then
        echo "[WARN] ${full_code} 返回空数据"
        continue
      fi
      name=$(echo "$data" | cut -d',' -f1)
      yesterday_close=$(echo "$data" | cut -d',' -f3)
      latest=$(echo "$data" | cut -d',' -f4)
      high=$(echo "$data" | cut -d',' -f5)
      low=$(echo "$data" | cut -d',' -f6)
      volume=$(echo "$data" | cut -d',' -f9)
      date=$(echo "$data" | cut -d',' -f31)
      time=$(echo "$data" | cut -d',' -f32)

      if command -v bc &>/dev/null && [[ "$yesterday_close" != "0.000" ]]; then
        change=$(echo "scale=4; $latest - $yesterday_close" | bc)
        change_pct=$(echo "scale=4; ($latest - $yesterday_close) / $yesterday_close * 100" | bc | xargs printf "%.2f")
        if (( $(echo "$change > 0" | bc -l) )); then
          emoji="🔴"
          sign="+"
        elif (( $(echo "$change < 0" | bc -l) )); then
          emoji="🟢"
          sign=""
        else
          emoji="⚪"
          sign=""
        fi
        echo "${full_code} | ${name} | ${latest} | ${emoji} ${sign}${change_pct}% | ${date} ${time}"
      else
        echo "${full_code} | ${name} | ${latest} | ${date} ${time}"
      fi
    done <<< "$response"
  fi
  echo ""
fi

for fc in "${fund_codes[@]+"${fund_codes[@]}"}"; do
  [[ -z "$fc" ]] && continue
  echo "=== 基金 ${fc} ==="
  result=$(curl -s -m $TIMEOUT "${FUND_API}${fc}.js")

  if [[ "$result" == "jsonpgz()" ]] || [[ -z "$result" ]]; then
    echo "[ERROR] 未找到基金 ${fc}，请确认代码是否正确"
    continue
  fi

  name=$(echo "$result" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
  dwjz=$(echo "$result" | grep -o '"dwjz":"[^"]*"' | cut -d'"' -f4)
  gsz=$(echo "$result" | grep -o '"gsz":"[^"]*"' | cut -d'"' -f4)
  gszzl=$(echo "$result" | grep -o '"gszzl":"[^"]*"' | cut -d'"' -f4)
  gztime=$(echo "$result" | grep -o '"gztime":"[^"]*"' | cut -d'"' -f4)
  jzrq=$(echo "$result" | grep -o '"jzrq":"[^"]*"' | cut -d'"' -f4)

  if (( $(echo "$gszzl > 0" | bc -l 2>/dev/null || echo 0) )); then
    emoji="🔴"
    sign="+"
  elif (( $(echo "$gszzl < 0" | bc -l 2>/dev/null || echo 0) )); then
    emoji="🟢"
    sign=""
  else
    emoji="⚪"
    sign=""
  fi

  qdii_note=""
  if echo "$name" | grep -qiE "QDII|纳斯达克|标普|海外|美国|全球"; then
    qdii_note=" ⏳ QDII基金，净值有延迟"
  fi

  echo "fund_${fc} | ${name} | 净值${dwjz}(${jzrq}) | 估值${gsz} | ${emoji} ${sign}${gszzl}%（估）| ${gztime}${qdii_note}"
  echo ""
done
