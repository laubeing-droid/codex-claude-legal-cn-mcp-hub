<!--
version: 3.0.2
module: docs
status: active
-->

# MCP 连接器配置参考

## 一、元典智库

| 项目 | 内容 |
|------|------|
| 官网 | https://open.chineselaw.com |
| 注册 | → API 管理 → 创建 API Key |
| 文档 | https://open.chineselaw.com/llms-full.txt |

Streamable HTTP MCP，无需安装 npm 包。4 个入口：

| Server | 分类 | 端点 | 工具 |
|--------|------|------|------|
| yuandian-law | 法律法规 | `/mcp/law/stream` | 5 |
| yuandian-case | 案例文书 | `/mcp/case/stream` | 4 |
| yuandian-company | 企业信息 | `/mcp/company/stream` | 26 |
| yuandian-open-platform | 全能力 | `/mcp` | 全部 |

```toml
[mcp_servers.yuandian-law]
type = "http"
url = "https://open.chineselaw.com/mcp/law/stream"
http_headers = { Authorization = "Bearer YOUR_API_KEY" }
enabled = true
```

元典也提供 REST API 直调：`https://open.chineselaw.com/open/{routeKey}`，鉴权 `X-API-Key`。

## 二、北大法宝

| 项目 | 内容 |
|------|------|
| 官网 | https://mcp.pkulaw.com |
| 注册 | → 控制台 → 获取 Access Token |
| 文档 | https://mcp.pkulaw.com/docs |

多个 HTTP MCP 服务，共用 `https://apim-gateway.pkulaw.com` 基础 URL：

| # | 段名 | 服务名 |
|---|------|--------|
| 1 | pkulaw-law-search | 法规检索 |
| 2 | pkulaw-case-search | 案例检索 |
| 3 | pkulaw-lawyer-search | 律师查询 |
| 4 | pkulaw-firm-search | 律所查询 |
| 5 | pkulaw-legal-consult | 法意问答 |
| 6 | pkulaw-law-compare | 法规对比 |
| 7 | pkulaw-bill-search | 法案检索 |
| 8 | pkulaw-foreign-law | 域外法规 |
| 9 | pkulaw-investigation | 审裁调研 |
| 10 | pkulaw-standard-contract | 合同模板 |

```toml
[mcp_servers.pkulaw-law-search]
type = "http"
url = "https://apim-gateway.pkulaw.com/mcp-law-search-service/mcp"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }
enabled = true
```

CLI 调试：`npm install -g @pkulaw/mcp-cli` → `pkulaw-mcp doctor`

## 三、飞书

```toml
[mcp_servers.larksuite]
command = "npx"
args = ["-y", "@larksuiteoapi/lark-mcp"]
env = { LARK_APP_ID = "YOUR_APP_ID", LARK_APP_SECRET = "YOUR_APP_SECRET" }
enabled = true
```

## 四、自建 MCP Server

### 4.1 国家法规库（flk-npc）

| 项目 | 内容 |
|------|------|
| 目录 | `servers/flk-npc/` |
| 实现 | 干净室单文件 `scripts/server.py` |
| 鉴权 | 免费，无需鉴权 |
| 端口 | localhost:18062 |

```bash
cd servers/flk-npc
pip install -r requirements.txt
python scripts/server.py
```

```toml
[mcp_servers.flk-npc]
type = "http"
url = "http://localhost:18062/mcp"
enabled = true
```

### 4.2 案例库（rmfyalk）

| 项目 | 内容 |
|------|------|
| 目录 | `servers/rmfyalk/` |
| 实现 | 干净室单文件 `scripts/server.py` |
| 鉴权 | Cookie Token（浏览器获取） |
| 端口 | localhost:18061 |

```bash
cd servers/rmfyalk
pip install -r requirements.txt
python scripts/server.py
```

```toml
[mcp_servers.rmfyalk]
type = "http"
url = "http://localhost:18061/mcp"
http_headers = { Cookie = "YOUR_COOKIE_TOKEN" }
enabled = true
```