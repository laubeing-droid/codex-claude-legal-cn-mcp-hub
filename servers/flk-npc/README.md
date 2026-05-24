# 国家法规库 MCP Server（flk-npc）

基于国家法律法规数据库（flk.npc.gov.cn）的 MCP 协议封装服务。

## 特点
- 免费，无需 API Key
- 支持法规全文检索与获取
- 自动格式化输出

## 启动

```bash
cd servers/flk-npc
pip install -r requirements.txt
python scripts/server.py
```

启动后监听 `localhost:18062`。

## MCP 配置

```toml
[mcp_servers.flk-npc]
type = "http"
url = "http://localhost:18062/mcp"
enabled = true
```

## 配置说明

参考 `.env.example` 创建 `.env` 文件。

## 依赖

- Python 3.8+
- 见 `requirements.txt`