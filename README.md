# Codex 中国法律 MCP 连接器

中国法律检索 MCP 连接器配置工具。支持三种方式连接权威法律数据源：

| 连接器 | 方式 | 工具数 | 推荐 |
|--------|------|--------|------|
| **chineselaw（元典智库）** | MCP 协议 stdio | 33 | ⭐ 首选 |
| **北大法宝 MCP 协议** | MCP 协议 HTTP | 10 服务 | 推荐 |
| **北大法宝 CLI 命令行** | CLI 工具 | — | 调试/验证 |

本仓库独立管理 MCP 配置，可与 [codex-legal-cn-skills](https://github.com/laubeing-droid/codex-legal-cn-skills) 配合使用，
也可单独安装（即使不使用法律技能，也能让 Codex 具备中国法律检索能力）。

---

## 快速安装

### Windows (PowerShell)

```powershell
git clone https://github.com/laubeing-droid/codex-legal-mcp-connectors.git
cd codex-legal-mcp-connectors
.\install.ps1
```

### macOS / Linux (Bash)

```bash
git clone https://github.com/laubeing-droid/codex-legal-mcp-connectors.git
cd codex-legal-mcp-connectors
chmod +x install.sh && ./install.sh
```

安装脚本会：
- 检测 Node.js（chineselaw 前置依赖）
- 交互式输入 API Key / Access Token（也可留空后续手动配置）
- 选择要安装的北大法宝服务（支持多选）

重启 Codex Desktop，运行 `.\verify.ps1`（或 `./verify.sh`）验证配置。

---

## 文件说明

| 文件 | 说明 | Windows | macOS/Linux |
|------|------|---------|-------------|
| install.ps1 / install.sh | 安装 MCP 连接器（交互式） | ✅ | ✅ |
| verify.ps1 / verify.sh | 验证 MCP 配置状态 | ✅ | ✅ |
| update.ps1 / update.sh | 自更新 + 版本检查 + Token 过期检测 | ✅ | ✅ |
| docs/connectors.md | 完整配置指南（含工具列表） | — | — |
| .github/workflows/npm-monitor.yml | npm 包版本监控（每周一） | — | — |

---

## 已知问题与处理

详见 [交接文档](https://github.com/laubeing-droid/codex-legal-mcp-connectors/blob/main/docs/connectors.md#常见问题)。

- **Token 占位符**：install 时如未输入凭证，会写入 `YOUR_API_KEY` / `YOUR_ACCESS_TOKEN`，运行 `update.ps1` 可检测并提示替换
- **Token 过期**：运行 `update.ps1` 可通过 `@pkulaw/mcp-cli` 验证 Token 有效性
- **多平台**：Windows PowerShell + macOS/Linux Bash 全部支持
- **Node.js 依赖**：install 脚本自动检测，未安装时跳过 chineselaw

---

## 依赖关系

```
chineselaw-mcp (MCP stdio)         ← 基于 zooges/chineselaw-mcp (MIT)
@pkulaw/mcp-cli (CLI 调试工具)      ← 北大法宝官方 (MIT)
北大法宝 MCP 协议 (HTTP 10 服务)     ← 北大法宝官方
```

npm 包版本由 GitHub Actions 每周自动监控。

---

## 许可证

MIT。上游依赖：
- chineselaw-mcp（MIT，作者 zooges）
- @pkulaw/mcp-cli（MIT，北大法宝官方）
