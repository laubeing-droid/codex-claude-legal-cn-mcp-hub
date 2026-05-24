# MCP 连接器配置参考

本仓库支持 4 类连接器接入方式。以下是每类的完整配置说明。

---

## 一、元典智库（chineselaw）

| 项目 | 内容 |
|------|------|
| 官网 | https://open.chineselaw.com |
| 注册 | https://open.chineselaw.com → API 管理 → 创建 API Key |
| 文档 | https://open.chineselaw.com/llms-full.txt（AI 可读） |
| API 目录 | https://apiplatform.legalmind.cn/api/apis?pageSize=200 |
| 价格 | 新人送 200 万 token，后续按量计费 |

### 方式 A：Streamable HTTP MCP（⭐ 首选）

元典提供 4 个 HTTP MCP 入口：

| Server | 分类 | 端点 | 工具数 |
|--------|------|------|--------|
| `yuandian-law` | 法律法规 | `https://open.chineselaw.com/mcp/law/stream` | 5 |
| `yuandian-case` | 案例文书 | `https://open.chineselaw.com/mcp/case/stream` | 4 |
| `yuandian-company` | 企业信息 | `https://open.chineselaw.com/mcp/company/stream` | 26 |
| `yuandian-open-platform` | 全能力兼容 | `https://open.chineselaw.com/mcp` | 全部 |

**优势**：无需安装 npm 包，直连即用。按分类隔离，可单独启用。

#### TOML 配置（Codex Desktop）
```toml
[mcp_servers.yuandian-law]
type = "http"
url = "https://open.chineselaw.com/mcp/law/stream"
http_headers = { Authorization = "Bearer YOUR_API_KEY", Accept = "application/json, text/event-stream" }
enabled = true

[mcp_servers.yuandian-case]
type = "http"
url = "https://open.chineselaw.com/mcp/case/stream"
http_headers = { Authorization = "Bearer YOUR_API_KEY", Accept = "application/json, text/event-stream" }
enabled = true

[mcp_servers.yuandian-company]
type = "http"
url = "https://open.chineselaw.com/mcp/company/stream"
http_headers = { Authorization = "Bearer YOUR_API_KEY", Accept = "application/json, text/event-stream" }
enabled = true
```

#### JSON 配置（Claude Code / Claude Desktop）
```json
{
  "mcpServers": {
    "yuandian-law": {
      "type": "http",
      "url": "https://open.chineselaw.com/mcp/law/stream",
      "httpHeaders": {
        "Authorization": "Bearer YOUR_API_KEY",
        "Accept": "application/json, text/event-stream"
      }
    },
    "yuandian-case": {
      "type": "http",
      "url": "https://open.chineselaw.com/mcp/case/stream",
      "httpHeaders": {
        "Authorization": "Bearer YOUR_API_KEY",
        "Accept": "application/json, text/event-stream"
      }
    },
    "yuandian-company": {
      "type": "http",
      "url": "https://open.chineselaw.com/mcp/company/stream",
      "httpHeaders": {
        "Authorization": "Bearer YOUR_API_KEY",
        "Accept": "application/json, text/event-stream"
      }
    }
  }
}
```

### 方式 B：npm stdio（备选）

当 HTTP MCP 不可用时，使用 npm 包 `chineselaw-mcp`。

```toml
[mcp_servers.chineselaw]
command = "npx"
args = ["chineselaw-mcp"]
env = { CHINESELAW_API_KEY = "YOUR_API_KEY" }
enabled = true
```

```json
{
  "mcpServers": {
    "chineselaw": {
      "command": "npx",
      "args": ["chineselaw-mcp"],
      "env": { "CHINESELAW_API_KEY": "YOUR_API_KEY" }
    }
  }
}
```

### 方式 C：REST API 直调

直接通过 HTTP 请求调用元典 36 个接口，适合自定义集成。

| 项 | 值 |
|---|-----|
| 基础 URL | `https://open.chineselaw.com` |
| 鉴权 | `X-API-Key: YOUR_API_KEY` |
| 完整 API 列表 | https://open.chineselaw.com/api-square |

---

## 二、北大法宝（pkulaw）

| 项目 | 内容 |
|------|------|
| 官网 | https://mcp.pkulaw.com |
| 注册 | https://mcp.pkulaw.com → 注册 → 控制台 → 获取 Access Token |
| 文档 | https://mcp.pkulaw.com/docs |
| 控制台 | https://mcp.pkulaw.com/console/apps |
| 价格 | 200万 token/月（免费），超出后¥0.8/万 token |

### 支持的 10 个 MCP 服务

| # | 段名 | 服务名 | HTTP 端点 |
|---|------|--------|----------|
| 1 | `pkulaw-law-search` | 法规检索 | `/mcp/law-search` |
| 2 | `pkulaw-case-search` | 案例检索 | `/mcp/case-search` |
| 3 | `pkulaw-lawyer-search` | 律师查询 | `/mcp/lawyer-search` |
| 4 | `pkulaw-firm-search` | 律所查询 | `/mcp/firm-search` |
| 5 | `pkulaw-legal-consult` | 法意问答 | `/mcp/legal-consult` |
| 6 | `pkulaw-law-compare` | 法规对比 | `/mcp/law-compare` |
| 7 | `pkulaw-bill-search` | 法案检索 | `/mcp/bill-search` |
| 8 | `pkulaw-foreign-law` | 域外法规 | `/mcp/foreign-law` |
| 9 | `pkulaw-investigation` | 审裁调研 | `/mcp/investigation` |
| 10 | `pkulaw-standard-contract` | 合同模板 | `/mcp/standard-contract` |

#### TOML 配置示例
```toml
[mcp_servers.pkulaw-law-search]
type = "http"
url = "https://apim-gateway.pkulaw.com/mcp/law-search"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }
enabled = true
```

#### JSON 配置示例
```json
{
  "mcpServers": {
    "pkulaw-law-search": {
      "type": "http",
      "url": "https://apim-gateway.pkulaw.com/mcp/law-search",
      "httpHeaders": {
        "Authorization": "Bearer YOUR_ACCESS_TOKEN"
      }
    }
  }
}
```

### CLI 调试工具

```bash
npm install -g @pkulaw/mcp-cli
pkulaw-mcp init --authorization "Bearer YOUR_TOKEN"
pkulaw-mcp tools      # 查看可用工具
pkulaw-mcp update     # 验证凭证 + 刷新
pkulaw-mcp doctor     # 诊断配置
```

---

## 三、飞书（LarkSuite MCP）

| 项目 | 内容 |
|------|------|
| 包名 | `@larksuiteoapi/lark-mcp` |
| 文档 | https://github.com/larksuite/cli |
| 凭证 | App ID + App Secret |

```toml
[mcp_servers.larksuite]
command = "npx"
args = ["-y", "@larksuiteoapi/lark-mcp"]
env = {
  LARK_APP_ID = "YOUR_APP_ID",
  LARK_APP_SECRET = "YOUR_APP_SECRET"
}
enabled = true
```

支持文档管理、消息发送、日历操作等飞书开放平台能力。

---

## 四、自建 MCP Server

本仓库内置两个 Python 实现的 MCP 服务器（干净室实现），部署后可作为标准 MCP 连接器使用。

### 4.1 国家法规库（flk-npc）

| 项目 | 内容 |
|------|------|
| 目录 | `servers/flk-npc/` |
| 数据源 | 国家法律法规数据库（flk.npc.gov.cn） |
| 鉴权 | **免费，无需鉴权** |
| 端口 | `localhost:18062` |
| 实现 | 单文件 `scripts/server.py` |

**启动：**
```bash
cd servers/flk-npc
pip install -r requirements.txt
python scripts/server.py
```

**配置：**
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
| 数据源 | 人民法院案例库（rmfyalk.court.gov.cn） |
| 鉴权 | Cookie Token（需从浏览器获取） |
| 端口 | `localhost:18061` |
| 实现 | 单文件 `scripts/server.py` |

**启动：**
```bash
cd servers/rmfyalk
pip install -r requirements.txt
python scripts/server.py
```

**配置：**
```toml
[mcp_servers.rmfyalk]
type = "http"
url = "http://localhost:18061/mcp"
http_headers = { Cookie = "YOUR_COOKIE_TOKEN" }
enabled = true
```

详情见各 server 目录下的 `README.md`。
