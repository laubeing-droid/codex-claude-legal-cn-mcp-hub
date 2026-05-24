# Codex-Claude-legal-cn-mcp-hub

> 中国法律 MCP 连接器中心 — 自托管 Server + 配置管理，全端生效

Codex Desktop / Claude Code / Claude Desktop 三端通用的中国法律 MCP 连接器中心。集配置管理、自托管 MCP Server、文档与 CI/CD 于一体。

## 连接器一览

| 连接器 | 接入方式 | 工具 | 凭证 | 推荐 |
|--------|---------|------|------|------|
| **元典智库 （chineselaw）** | Streamable HTTP MCP | 35+ 工具 | API Key （Bearer） | ⭐ 首选 |
| **元典智库 （chineselaw）** | npm stdio | 33 工具 | API Key （环境变量） | 备选 |
| **元典智库 （chineselaw）** | REST API 直调 | 36 接口 | API Key （X-API-Key） | 深度集成 |
| **北大法宝 （pkulaw）** | HTTP MCP | 10+ 服务 | Access Token | ⭐ 推荐 |
| **飞书 （LarkSuite）** | npm stdio | 文档/消息/日历 | App ID + Secret | 推荐 |
| **国家法规库 （flk-npc）** | Python 自托管（干净室实现） | 法规检索 | 免费无鉴权 | 可选 |
| **案例库 （rmfyalk）** | Python 自托管（干净室实现） | 案例检索 | Cookie Token | 可选 |

可配合 [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) 获取完整法律技能工作流，亦可单独安装给任意 MCP 客户端使用。

## 快速安装

```powershell
git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
cd Codex-Claude-legal-cn-mcp-hub
.\install.ps1
```

macOS/Linux：
```bash
git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
cd Codex-Claude-legal-cn-mcp-hub
chmod +x install.sh && ./install.sh
```

安装过程：检测本机 MCP 客户端 → 输入凭证 → 选择服务 → 自动写入所有客户端配置。

完成后重启客户端，运行 `.\verify.ps1` 验证。

## 仓库结构

```
├── install.ps1 / install.sh         # 安装入口
├── verify.ps1 / verify.sh           # 配置验证
├── update.ps1 / update.sh           # 自更新 + 诊断
├── uninstall.ps1 / uninstall.sh     # 卸载
├── detect.ps1 / detect.sh           # 环境检测（被以上脚本共用）
├── servers/
│   ├── flk-npc/                     # 国家法规库 Python MCP Server
│   └── rmfyalk/                     # 案例库 Python MCP Server
├── docs/
│   ├── connectors.md                # 连接器完整配置参考
│   ├── usage-guide.md               # 使用指南
│   ├── architecture.md              # 架构说明
│   ├── troubleshooting.md           # 故障排除
│   └── contributing.md              # 贡献指南
├── .github/workflows/
│   ├── npm-monitor.yml              # npm 包版本监控
├── QUICKSTART.md                    # 60 秒快速入门
├── CHANGELOG.md                     # 版本历史
└── 交接文档.md                      # 维护者手册
```

## 支持的环境

| 客户端 | 配置路径 | 格式 |
|--------|---------|------|
| **Codex Desktop** | `~/.codex/config.toml` | TOML |
| **Claude Code**（终端） | `~/.claude/settings.json` | JSON |
| **Claude Desktop**（Win） | `%APPDATA%/Claude/claude_desktop_config.json` | JSON |
| **Claude Desktop**（Mac） | `~/Library/Application Support/Claude/claude_desktop_config.json` | JSON |

## 配套项目

| 仓库 | 说明 |
|------|------|
| [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) | 上游主仓库：中国法律技能 + MCP 集成（依赖本仓库） |
| [PRC-US-Legal-Semantic-Alignment-Framework](https://github.com/laubeing-droid/PRC-US-Legal-Semantic-Alignment-Framework) | 中美法律语义对齐框架 |

## 许可证

MIT。上游依赖：
- [@pkulaw/mcp-cli](https://www.npmjs.com/package/@pkulaw/mcp-cli)（MIT，北大法宝官方）
