# 架构说明

## 定位

本仓库是**中国法律 MCP 连接器管理中心**。只做一件事：

> 向本机所有 MCP 客户端配置文件写入 / 验证 / 更新 / 移除中国法律检索连接器。

## 架构流

```
用户运行 ──── install.ps1
                │
                ▼
         detect.ps1 ──── 自动检测本机 MCP 客户端
                │
                ├── Codex Desktop   → ~/.codex/config.toml           （TOML）
                ├── Claude Code     → ~/.claude/settings.json        （JSON）
                └── Claude Desktop  → %APPDATA%/Claude/... 或 ~/Library/...（JSON）
                │
                ▼
         交互式选择连接器 + 输入凭证
                │
                ├── 元典 HTTP MCP  → 写入 url/http_headers（Bearer Token）
                ├── 元典 npm stdio → 写入 command/args/env
                ├── 北大法宝 MCP   → 写入 url/http_headers（Access Token）
                ├── 飞书 MCP       → 写入 command/args/env
                └── 自建 MCP       → 手动配置 servers/ 目录的服务
                │
                ▼
         自动适配 TOML/JSON 格式，写入所有检测到的客户端
                │
                ▼
         verify.ps1（验证） / update.ps1（更新诊断） / uninstall.ps1（卸载）
```

## 脚本分层

| 层 | 脚本 | 职责 |
| **入口** | `install.ps1/sh` | 全流程编排：检测 → 输入 → 选择 → 写入 |
| **检测** | `detect.ps1/sh` | 被所有脚本共用，返回本机已安装的 MCP 客户端列表及配置路径 |
| **验证** | `verify.ps1/sh` | 解析各客户端 MCP 段，检查 enabled/占位符/npm 版本 |
| **诊断** | `update.ps1/sh` | git pull 自更新 + npm 版本检查 + 全环境配置巡检 + Token 过期检测 |
| **卸载** | `uninstall.ps1/sh` | 从所有客户端配置移除 MCP 连接器段 |

## 依赖关系

```
本仓库（配置管理层）
  ├── 不依赖任何上游仓库（可独立使用）
  ├── 被 Claude-for-Legal-CN-to-Codex 委托调用（install/update）
  │
  ├── 元典智库（chineselaw-mcp）    → npm 包，Node.js >= 18
  ├── 北大法宝（@pkulaw/mcp-cli）   → npm 包，调试/诊断工具
  ├── 飞书（@larksuiteoapi/lark-mcp）→ npm 包
  ├── 国家法规库（servers/flk-npc/）→ Python 自托管，免费无鉴权
  └── 案例库（servers/rmfyalk/）    → Python 自托管，Cookie Token 鉴权
```




## 自建 MCP Server 架构

两个 Server 均为基于公开 API 文档的干净室实现：

```
servers/
│   ├── server.py          # MCP 协议主服务
│   ├── client.py          # 请求封装
│   ├── models.py          # 数据模型
│   ├── formatters.py      # 格式化输出
│   ├── export_laws.py     # 法规导出
│   ├── export_formatter.py# 导出格式化
│   ├── requirements.txt   # 依赖
│   ├── start.bat          # Windows 启动
│   └── references/        # API 参考文档
│
    ├── server.py          # MCP 协议主服务
    ├── client.py          # 请求封装
    ├── models.py          # 数据模型
    ├── formatters.py      # 格式化输出
    ├── export_cases.py    # 案例导出
    ├── export_formatter.py# 导出格式化
    ├── requirements.txt   # 依赖
    ├── start.bat          # Windows 启动
    └── references/        # API 参考文档
```

