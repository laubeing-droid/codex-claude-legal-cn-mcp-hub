# 故障排除

## 连接器不工作

### 检查步骤

1. **重启 MCP 客户端** — Codex Desktop / Claude Code / Claude Desktop 安装配置后必须重启
2. **运行验证** — `.\verify.ps1` 检查配置是否写入正确
3. **检查配置文件** — 直接查看客户端配置文件确认段存在

### 配置未写入

```powershell
# 查看 Codex Desktop 配置
notepad "$env:USERPROFILE\.codex\config.toml"

# 查看 Claude Code 配置
notepad "$env:USERPROFILE\.claude\settings.json"
```

如果缺少连接器段，重新运行 `.\install.ps1`。

---

## 凭证问题

### 元典智库（chineselaw）
1. 打开 https://open.chineselaw.com → 注册 → API 管理 → 创建 API Key
2. 编辑配置文件，将 `YOUR_API_KEY` 替换为真实 Key
3. 或运行 `update.ps1` 检测占位符

### 北大法宝（pkulaw）
1. 打开 https://mcp.pkulaw.com → 注册 → 控制台 → 获取 Access Token
2. 编辑配置文件，将 `YOUR_ACCESS_TOKEN` 替换
3. Token 有时效性，过期需重新获取
4. 安装 `@pkulaw/mcp-cli` 可辅助验证：
   ```bash
   npm install -g @pkulaw/mcp-cli
   pkulaw-mcp init --authorization "Bearer YOUR_TOKEN"
   pkulaw-mcp update
   ```

---

## 多环境冲突

### 同时使用 Codex + Claude Code + Claude Desktop
安装脚本自动处理所有检测到的客户端。运行一次 `install.ps1` 即可。

### Claude Code JSON 格式错误
```powershell
.\verify.ps1
# 或用 Python 校验
python -c "import json; json.load(open(r'$env:USERPROFILE\.claude\settings.json'))"
```

---

## 网络问题

### git clone 失败
```powershell
# 使用代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
```

### npm 连接失败（国内用户）
```powershell
npm config set registry https://registry.npmmirror.com
```

---

## 更新问题

### git pull 冲突
```powershell
git stash && git pull && git stash pop
# 或直接重新克隆
cd .. && git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
```

---

## 自建 MCP Server 问题

### 端口冲突
默认端口 `18062`（法规库）/ `18061`（案例库）。如有冲突，修改 `server.py` 中的端口号。

### Python 依赖
```bash
cd servers/flk-npc  # 或 servers/rmfyalk
pip install -r requirements.txt
```

### 鉴权失败（案例库）
案例库需 Cookie Token（从浏览器登录人民法院案例库后从请求头中获取）。