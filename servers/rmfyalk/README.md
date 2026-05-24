# 案例库 MCP Server（rmfyalk）

基于人民法院案例库（rmfyalk.court.gov.cn）的 MCP 协议封装服务。

## 特点
- 支持案例全文检索
- 支持案例详情获取与导出
- 格式化输出（Markdown / JSON）

## 启动

```bash
cd servers/rmfyalk
pip install -r requirements.txt
python scripts/server.py
```

启动后监听 `localhost:18061`。

## MCP 配置

```toml
[mcp_servers.rmfyalk]
type = "http"
url = "http://localhost:18061/mcp"
http_headers = { Cookie = "YOUR_COOKIE_TOKEN" }
enabled = true
```

## 获取 Cookie Token

1. 浏览器打开人民法院案例库并登录
2. 按 F12 打开开发者工具
3. 任意请求的 Request Headers 中复制 `Cookie` 值
4. 填入 `http_headers` 的 `Cookie` 字段

## 配置说明

参考 `.env.example` 创建 `.env` 文件。

## 依赖

- Python 3.8+
- 见 `requirements.txt`