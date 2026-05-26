# legal-cn-mcp-hub

> 中国法律 MCP 连接器中心 · Codex Desktop / Claude Code / WorkBuddy / Trae 四平台通用

自托管 + 在线服务，多客户端配置管理。

## 连接器

| 连接器 | 接入方式 | 说明 |
|:-----|:-----|:-----|
| **国家法规库** | Python 自托管 | 法规检索，免费无鉴权 |
| **案例库** | Python 自托管 | 案例检索，免费无鉴权 |
| **元典智库** | Streamable HTTP MCP | API Key 鉴权 |
| **北大法宝** | HTTP MCP | Access Token 鉴权 |
| **飞书** | npm stdio | App ID + Secret 鉴权 |

## 平台支持

| 平台 | 配置格式 | 配置路径 |
|:-----|:-----|:-----|
| **Codex Desktop** | TOML | `~/.codex/config.toml` |
| **Claude Code** | JSON | `~/.claude/settings.json` |
| **WorkBuddy** | JSON | `~/.workbuddy/config.json` |
| **Trae** | JSON | `~/.trae/mcp.json` |

## 快速开始

```powershell
git clone https://github.com/laubeing-droid/legal-cn-mcp-hub.git
cd legal-cn-mcp-hub
.\install.ps1          # 完整安装
.\install.ps1 -Quick   # 仅自托管服务
```

## 开发准则

参见 [AGENTS.md](AGENTS.md)
