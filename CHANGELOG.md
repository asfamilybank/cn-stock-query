# Changelog

## [1.0.2] - 2026-03-18

### Fixed
- SKILL.md frontmatter 添加 `metadata.openclaw.requires.bins` 声明运行时依赖（curl, iconv, bc）
- SKILL.md frontmatter 添加 `tools: [shell]` 声明使用的工具类型
- skill.yaml 添加 `repository` 字段指向源码仓库
- clawhub.json 添加 `repository` 字段
- 解决 ClawHub 安全扫描标记的"未声明二进制依赖"和"缺少源码仓库 URL"问题

## [1.0.1] - 2026-03-18

### Fixed
- 替换示例中的个人持仓数据为通用虚构数据

## [1.0.0] - 2026-03-18

### Added
- 沪深股票/ETF 实时行情查询（新浪财经数据源）
- 场外基金估值/净值查询（天天基金数据源）
- 智能代码识别：自动判断沪市/深市/场外基金
- 市场前缀防碰撞校验（沪深同号不同标的的安全处理）
- 批量查询支持
- 涨跌 emoji 标识（🔴 上涨 🟢 下跌 ⚪ 平盘）
- QDII 基金净值延迟自动标注
- 持仓市值计算与浮盈/亏展示
- GBK→UTF-8 自动编码转换
- query_price.sh 命令行批量查询脚本
- monitor.sh 接口可用性监控脚本
- 东方财富净值 API 作为备用数据源
