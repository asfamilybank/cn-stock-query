#!/usr/bin/env bash
# fmt.sh — stock-query 格式化输出工具
# 用法:
#   bash scripts/sq.sh get AAPL 00700 | bash scripts/fmt.sh
#   bash scripts/sq.sh get AAPL 00700 | bash scripts/fmt.sh --format detail
#   bash scripts/sq.sh hist 600519    | bash scripts/fmt.sh
#   bash scripts/sq.sh get AAPL      | bash scripts/fmt.sh --format json
#
# --format / -f:
#   table   标准行情表格（默认）
#   detail  详细宽表格（含成交量/换手率/PE/52W等）
#   json    格式化 JSON（pretty-print）
#
# 输入自动识别：JSON 数组 → sq get 行情；含 klines 字段的对象 → sq hist 历史K线

set -uo pipefail

FORMAT="table"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --format|-f) FORMAT="${2:-table}"; shift 2 ;;
    json|table|detail) FORMAT="$1"; shift ;;
    *) printf 'Usage: sq.sh get <codes> | fmt.sh [--format json|table|detail]\n' >&2; exit 1 ;;
  esac
done

if ! command -v python3 &>/dev/null; then
  printf 'Error: python3 is required\n' >&2; exit 1
fi

INPUT=$(cat)
[[ -z "$INPUT" ]] && exit 0

_PY=$(mktemp /tmp/sqfmt_XXXXXX.py)
trap 'rm -f "$_PY"' EXIT INT TERM

cat > "$_PY" << 'PYEOF'
import json
import sys
import unicodedata

FMT = sys.argv[1] if len(sys.argv) > 1 else 'table'
text = sys.stdin.read()

# parse_float=str preserves original decimal representation (e.g. "511.000" stays "511.000")
data = json.loads(text, parse_float=str)

# ── Display utilities ──────────────────────────────────────────────────────────

def dw(s):
    """Display width: CJK/full-width chars count as 2."""
    w = 0
    for c in str(s):
        w += 2 if unicodedata.east_asian_width(c) in ('W', 'F') else 1
    return w

def pad(s, width):
    s = str(s)
    return s + ' ' * max(0, width - dw(s))

def make_table(headers, rows):
    widths = [dw(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            if i < len(widths):
                widths[i] = max(widths[i], dw(str(cell)))
    def render(cells):
        return '| ' + ' | '.join(pad(str(c), w) for c, w in zip(cells, widths)) + ' |'
    def sep():
        return '|' + '|'.join('-' * (w + 2) for w in widths) + '|'
    lines = [render(headers), sep()]
    for row in rows:
        lines.append(render(row))
    return '\n'.join(lines)

# ── Field formatters ───────────────────────────────────────────────────────────

def f_price(v):
    return '—' if v is None else str(v)

def f_pct(change_pct, direction, market, itype=None, is_estimate=None):
    if change_pct is None:
        return '—'
    pct_f = float(change_pct)
    if market in ('A股', '港股'):
        emoji = '🔴' if pct_f > 0 else ('🟢' if pct_f < 0 else '⚪')
    else:
        emoji = '🟩' if pct_f > 0 else ('🟥' if pct_f < 0 else '⚪')
    sign = '+' if pct_f >= 0 else ''
    r = f'{emoji} {sign}{pct_f:.2f}%'
    if itype == 'fund' and is_estimate is not None:
        r += '（估）' if is_estimate else '（净值）'
    return r

def f_change(v):
    if v is None:
        return '—'
    v_f = float(v)
    return ('+' if v_f >= 0 else '') + str(v)

def f_volume(v, market):
    if v is None:
        return '—'
    v_i = int(float(str(v)))
    if market in ('A股', '港股'):
        return f'{v_i / 10000:.1f}万手'
    return str(v_i)

def f_amount(v):
    """amount 单位：万元（A股有效）"""
    if v is None:
        return '—'
    v_f = float(str(v))
    if v_f >= 10000:
        return f'{v_f / 10000:.2f}亿'
    return f'{v_f:,.0f}万'

def f_turnover(v):
    return '—' if v is None else f'{float(str(v)):.2f}%'

def f_datetime(v):
    if v is None:
        return '—'
    # YYYY-MM-DD HH:MM:SS → YYYY-MM-DD HH:MM
    return v[:16] if len(v) == 19 else v

# ── JSON mode ─────────────────────────────────────────────────────────────────

if FMT == 'json':
    print(json.dumps(json.loads(text), ensure_ascii=False, indent=2))
    sys.exit(0)

# ── Detect input type ─────────────────────────────────────────────────────────

is_hist = isinstance(data, dict) and 'klines' in data

# ── Hist (sq hist) ────────────────────────────────────────────────────────────

if is_hist:
    if data.get('error'):
        print(f'⚠ {data.get("code", "")}: {data["error"]}')
        sys.exit(0)

    code    = data.get('code', '')
    name    = data.get('name') or code
    market  = data.get('market', '')
    period  = data.get('period', 'day')
    fq      = data.get('fq', 'pre')
    klines  = data.get('klines', [])

    period_label = {'day': '日K', 'week': '周K', 'month': '月K'}.get(period, period)
    fq_label     = {'pre': '前复权', 'post': '后复权', 'none': '不复权'}.get(fq, fq)

    print(f'{name}（{code}）{period_label} · {fq_label} · 共{len(klines)}条\n')

    if not klines:
        print('（无数据）')
        sys.exit(0)

    headers = ['日期', '收盘', '涨跌幅', '开盘', '最高', '最低', '成交量']
    rows = []
    for k in reversed(klines):
        cp  = k.get('change_pct')
        cp_f = float(cp) if cp is not None else None
        dir_ = ('up' if cp_f > 0 else ('down' if cp_f < 0 else 'flat')) if cp_f is not None else 'flat'
        rows.append([
            k.get('date') or '—',
            f_price(k.get('close')),
            f_pct(cp, dir_, market),
            f_price(k.get('open')),
            f_price(k.get('high')),
            f_price(k.get('low')),
            f_volume(k.get('volume'), market),
        ])
    print(make_table(headers, rows))

    # Area stats (use original order: klines[0] = oldest, klines[-1] = newest)
    if len(klines) >= 2:
        first_close = float(str(klines[0]['close']))
        last_close  = float(str(klines[-1]['close']))
        range_pct   = (last_close - first_close) / first_close * 100
        sign        = '+' if range_pct >= 0 else ''

        closes = [(float(str(k['close'])), k['date']) for k in klines]
        max_c, max_d = max(closes, key=lambda x: x[0])
        min_c, min_d = min(closes, key=lambda x: x[0])

        print(f'\n📊 区间统计：{klines[0]["date"]} ~ {klines[-1]["date"]}'
              f' · 涨跌幅 {sign}{range_pct:.2f}%'
              f' · 最高 {max_c}（{max_d[5:]}）'
              f' · 最低 {min_c}（{min_d[5:]}）')
    sys.exit(0)

# ── Get (sq get) ──────────────────────────────────────────────────────────────

items  = data if isinstance(data, list) else [data]
valid  = [item for item in items if not item.get('error')]
errors = [item for item in items if item.get('error')]

if FMT == 'table':
    headers = ['代码', '名称', '市场', '最新价', '昨收', '涨跌幅', '最高', '最低', '币种', '更新时间']
    rows = []
    for item in valid:
        market = item.get('market') or '—'
        rows.append([
            item.get('code') or '—',
            item.get('name') or '—',
            market,
            f_price(item.get('price')),
            f_price(item.get('prev_close')),
            f_pct(item.get('change_pct'), item.get('direction', 'flat'), market,
                  item.get('type'), item.get('is_estimate')),
            f_price(item.get('high')),
            f_price(item.get('low')),
            item.get('currency') or '—',
            f_datetime(item.get('datetime')),
        ])
    if rows:
        print(make_table(headers, rows))

elif FMT == 'detail':
    headers = ['代码', '名称', '市场', '最新价', '昨收', '今开', '涨跌幅', '涨跌额',
               '最高', '最低', '成交量', '成交额', '换手率', '市盈率PE',
               '52W最高', '52W最低', '币种', '更新时间']
    rows = []
    for item in valid:
        market = item.get('market') or '—'
        rows.append([
            item.get('code') or '—',
            item.get('name') or '—',
            market,
            f_price(item.get('price')),
            f_price(item.get('prev_close')),
            f_price(item.get('open')),
            f_pct(item.get('change_pct'), item.get('direction', 'flat'), market,
                  item.get('type'), item.get('is_estimate')),
            f_change(item.get('change')),
            f_price(item.get('high')),
            f_price(item.get('low')),
            f_volume(item.get('volume'), market),
            f_amount(item.get('amount')),
            f_turnover(item.get('turnover')),
            f_price(item.get('pe')),
            f_price(item.get('week52_high')),
            f_price(item.get('week52_low')),
            item.get('currency') or '—',
            f_datetime(item.get('datetime')),
        ])
    if rows:
        print(make_table(headers, rows))

# Annotations
qdii_items = [item for item in valid if item.get('is_qdii')]
if qdii_items:
    codes = ', '.join(item['code'] for item in qdii_items)
    print(f'\n⏳ QDII基金，净值公布有 T+2~T+7 延迟：{codes}')

# Errors
for item in errors:
    print(f'\n⚠ {item["code"]}: {item["error"]}')
PYEOF

printf '%s' "$INPUT" | python3 "$_PY" "$FORMAT"
