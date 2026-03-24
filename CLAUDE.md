# cn-stock-query 项目规范

## 仓库结构

这是一个发布到 ClawHub 的 openclaw skill，同时提供 Claude Code 原生格式，当前为双格式：

| 路径 | 格式 | 触发方式 |
|------|------|---------|
| `SKILL.md` + `skill.yaml` | OpenClaw | 自然语言关键词，`npx clawhub install` 安装 |
| `claude/SKILL.md` | Claude Code 原生 | `/cn-stock-query` slash command |

## 修改规范

**修改 skill 逻辑时，两个 SKILL.md 必须同步更新：**
- `SKILL.md`（根目录）— OpenClaw 格式
- `claude/SKILL.md` — Claude Code 原生格式

两者的 skill 内容应保持一致，不允许功能分叉。

## 版本与发布

- 版本号在 `skill.yaml` 和 `clawhub.json` 中同步维护
- **ClawHub 发布**：只在 openclaw skill（`skill.yaml`、根目录 `SKILL.md`、`scripts/`）有实质功能变化时才执行；`claude/` 目录的改动不需要触发 ClawHub 发布
