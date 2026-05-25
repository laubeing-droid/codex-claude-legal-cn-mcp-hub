<!--
version: 3.0.2
module: mcp-hub
status: active
-->

# Codex-Claude-legal-cn-mcp-hub

> 中国法律 MCP 连接器中心 — 自托管 Server + 配置管理，全端生效

Codex Desktop / Claude Code / Claude Desktop 三端通用的中国法律 MCP 连接器中心，集自托管 MCP Server 与配置管理于一体。

## 连接器一览

| 连接器 | 接入方式 | 工具 | 凭证 |
|--------|---------|------|------|
| **元典智库** | Streamable HTTP MCP | 35+ 工具 | API Key |
| **北大法宝** | HTTP MCP | 10+ 服务 | Access Token |
| **飞书** | npm stdio | 文档/消息/日历 | App ID + Secret |
| **国家法规库** | Python 自托管（干净室实现） | 法规检索 | 免费无鉴权 |
| **案例库** | Python 自托管（干净室实现） | 案例检索 | Cookie Token |

可配合 [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) 获取完整法律技能工作流，亦可单独安装。

## 快速开始

**Windows:**

```powershell
git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
cd Codex-Claude-legal-cn-mcp-hub
.\install.ps1
```

**macOS / Linux:**
```bash
git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
cd Codex-Claude-legal-cn-mcp-hub
bash install.sh
```


完成后重启 MCP 客户端，运行 验证脚本 (bash verify.sh 或 .\verify.ps1)。

## 仓库结构

```
├── install.ps1 / install.sh         # 安装入口
├── verify.ps1 / verify.sh           # 配置验证
├── update.ps1 / update.sh           # 自更新 + 诊断
├── uninstall.ps1 / uninstall.sh     # 卸载
├── detect.ps1 / detect.sh           # 环境检测（被以上共用）
├── servers/
│   ├── flk-npc/                     # 国家法规库 Python MCP Server
│   └── rmfyalk/                     # 案例库 Python MCP Server
├── docs/                            # 文档
├── .github/workflows/               # CI/CD
├── QUICKSTART.md
├── CHANGELOG.md
└── 交接文档.md
```

## 支持的环境

| 客户端 | 配置路径 | 格式 |
|--------|---------|------|
| **Codex Desktop** | `~/.codex/config.toml` | TOML |
| **Claude Code** | `~/.claude/settings.json` | JSON |
| **Claude Desktop**（Win） | `%APPDATA%/Claude/claude_desktop_config.json` | JSON |
| **Claude Desktop**（Mac） | `~/Library/Application Support/Claude/claude_desktop_config.json` | JSON |

## 配套项目

> **法律数据库**: 本项目配合 [codex-claude-legal-cn-core-codices](https://github.com/laubeing-droid/codex-claude-legal-cn-core-codices) 使用（162部中国法律全文JSON）。
> 
> ```bash
> git submodule add https://github.com/laubeing-droid/codex-claude-legal-cn-core-codices.git legal-cn-data
> ```
> 即可在本地离线检索全部法条，无需API。

## 配套项目

| 仓库 | 说明 |
|------|------|
| [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) | 上游主仓库：中国法律技能 + MCP 集成 |
| [Codex-Legal-CN-Judgment-Predictor](https://github.com/laubeing-droid/Codex-Legal-CN-Judgment-Predictor) | AI 裁判预测框架 |
| [PRC-US-Legal-Semantic-Alignment-Framework](https://github.com/laubeing-droid/PRC-US-Legal-Semantic-Alignment-Framework) | 中美法律语义对齐框架 |

## 许可证

MIT。
