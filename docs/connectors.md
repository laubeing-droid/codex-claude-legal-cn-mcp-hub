# MCP 连接器配置指南

本仓库为 Codex Desktop 配置中国法律 MCP 连接器。支持 Windows（PowerShell）和 macOS/Linux（Bash）。

安装后重启 Codex Desktop 即可使用。配置存储在 `~/.codex/config.toml` 的 `[mcp_servers]` 段。

---

## 一、连接器总览

| 连接器 | 类型 | 工具数 | 推荐 |
|--------|------|--------|------|
| **chineselaw（元典智库）** | stdio（npx） | 33 | ⭐ 首选 |
| **北大法宝 MCP 协议** | HTTP（10 服务） | 10+ | 推荐 |
| **北大法宝 CLI 命令行** | 调试工具 | — | 诊断/验证 |

chineselaw 和北大法宝**二选一即可**，不需要两个都配。

---

## 二、安装

### Windows（PowerShell）

```powershell
git clone https://github.com/laubeing-droid/codex-legal-mcp-connectors.git
cd codex-legal-mcp-connectors
.\install.ps1
```

### macOS / Linux（Bash）

```bash
git clone https://github.com/laubeing-droid/codex-legal-mcp-connectors.git
cd codex-legal-mcp-connectors
chmod +x install.sh && ./install.sh
```

安装脚本会：
1. **前置检查**：检测 Node.js（chineselaw 依赖）
2. **交互式配置**：提示输入 API Key / Access Token（可留空后续配置）
3. **服务选择**：北大法宝 10 个服务可选安装，支持多选（如 `1,3,5`）或全部
4. **智能追加**：不覆盖 config.toml 已有配置，仅添加新条目

---

## 三、chineselaw（元典智库）— 首选

基于 [chineselaw-mcp](https://www.npmjs.com/package/chineselaw-mcp)（MIT），将元典智库 API 封装为 MCP 工具。

### 前置条件
- **Node.js >= 18**。从 https://nodejs.org 下载 LTS 版本。安装脚本会自动检测。

### 注册获取 API Key
1. 打开 https://open.chineselaw.com → 注册
2. 个人中心 → API 管理 → 创建 API Key

### 手动配置

```powershell
notepad "$env:USERPROFILE\.codex\config.toml"
```

找到 `[mcp_servers.chineselaw.env]`，将 `CHINESELAW_API_KEY` 替换为真实 Key：

```toml
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "你的真实API Key"    # ← 替换
```

### 可用工具（33 个）

**法律法规（5）**：search_regulations, search_legal_articles, get_article_detail, get_regulation_detail, semantic_search_law

**案例文书（4）**：search_cases, search_authoritative_cases, get_case_detail, semantic_search_cases

**企业信息（24）**：企业检索、工商信息、商标专利、涉诉信息、失信被执行人、行政处罚等

---

## 四、北大法宝 MCP 协议

10 个独立 HTTP MCP 服务。官方中文名称及说明来自北大法宝 MCP 服务平台。

### 注册获取 Access Token
1. 打开 https://mcp.pkulaw.com → 注册/登录
2. 开发者控制台 → 我的应用 → 创建应用 → 获取 Access Token

### 手动配置

打开 config.toml，将所有 `pkulaw-*` 段中的 `YOUR_ACCESS_TOKEN` 替换为真实 Token：

```toml
[mcp_servers.pkulaw-law-search]
url = "https://apim-gateway.pkulaw.com/mcp-law-search-service"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }   # ← 替换
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
```

### 10 个服务详情

| # | 配置段名 | 官方中文名 | 用途说明 |
|---|---------|-----------|---------|
| 1 | pkulaw-law-search | **检索法律法规-语义** | 基于语义理解的法律法规检索与相关文章查找 |
| 2 | pkulaw-law-keyword | **检索法律法规-关键词** | 法规标题或正文关键词精确匹配检索 |
| 3 | pkulaw-case-semantic-search | **检索司法案例-语义** | 用自然语言描述查找相关判例 |
| 4 | pkulaw-case-keyword | **检索司法案例-关键词** | 案例标题或正文关键词检索 |
| 5 | pkulaw-law-item-keyword | **精准查找法条-关键词** | 通过法规名称与条号精确查询法条内容 |
| 6 | pkulaw-law-recognition | **法条识别与溯源** | 从文本中识别法规名称与条款，返回来源链接 |
| 7 | pkulaw-case-number-recognition | **案号识别与溯源** | 识别案号、标准化验证及与案例库溯源 |
| 8 | pkulaw-citation-validator | **修正生成幻觉-法条** | 分析引用并返回权威条文，修正引用幻觉 |
| 9 | pkulaw-doc-link | **法宝超链** | 为文本智能添加法规超链接指向北大法宝文档 |
| 10 | pkulaw-semantic-nlsql | **法宝语义检索（NL-SQL）** | 自然语言在多库中语义检索（需额外购买配置） |

---

## 五、使用 pkulaw-mcp-cli 验证配置

基于 [@pkulaw/mcp-cli](https://www.npmjs.com/package/@pkulaw/mcp-cli)（北大法宝官方，MIT），用于诊断 Token 有效性。

### 安装与初始化

```bash
npm install -g @pkulaw/mcp-cli
pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"
```

### 验证流程

```bash
pkulaw-mcp check           # 检查配置完整性
pkulaw-mcp update          # 拉取工具列表，确认 Token 有效
pkulaw-mcp tools           # 列出已订阅服务的可用工具
pkulaw-mcp doctor          # 别名，与 check 相同
```

### 调用示例

```bash
pkulaw-mcp law-keyword search_regulations --searchKey "民法典 合同无效"
pkulaw-mcp law-semantic semantic_search_law --searchKey "民间借贷利率"
pkulaw-mcp citation-validator validate_citation --citation "民法典第二条"
pkulaw-mcp case-keyword search_cases --searchKey "股权转让纠纷"
```

### 查看服务文档

```bash
pkulaw-mcp docs                                # 列出所有服务的文档链接
pkulaw-mcp docs law-keyword --open             # 用浏览器打开指定服务文档
```

---

## 六、脚本参考

| 脚本 | Windows | macOS/Linux | 功能 |
|------|---------|-------------|------|
| `install.ps1` / `install.sh` | ✅ | ✅ | 安装 MCP 连接器（交互式） |
| `verify.ps1` / `verify.sh` | ✅ | ✅ | 验证 MCP 配置状态 |
| `update.ps1` / `update.sh` | ✅ | ✅ | 自更新 + 版本检查 + Token 检测 |

### verify —— 验证配置状态

检查所有 `[mcp_servers.*]` 配置段：
- 是否已配置、是否启用
- Token / API Key 是否为占位符
- npm 包最新版本
- @pkulaw/mcp-cli 安装状态

```powershell
.\verify.ps1           # Windows
./verify.sh            # macOS/Linux
```

### update —— 更新与诊断

5 步全面诊断：
1. **自更新**：`git pull` 同步本仓库最新版本
2. **npm 版本检查**：检测 chineselaw-mcp / @pkulaw/mcp-cli 是否有新版本
3. **MCP 配置检查**：动态发现所有配置段，检查启用状态
4. **凭证检测**：检测占位符；如有 pkulaw-mcp-cli 则验证 Token 有效性
5. **调试工具检测**：检测 pkulaw-mcp CLI 并显示安装提示

```powershell
.\update.ps1           # Windows
./update.sh            # macOS/Linux
```

---

## 七、故障排除

### 连接器不生效？
1. 确认 config.toml 中 `enabled = true` 存在
2. 运行 `verify.ps1` 检查配置状态
3. 确认已重启 Codex Desktop
4. 运行 `update.ps1` 获取完整诊断

### chineselaw npx 错误？
- `node --version` 确认 >= 18
- 从 https://nodejs.org 下载 LTS 版本
- 运行 `update.ps1` 检查 npm 包版本

### Token 无效或过期？
- 运行 `update.ps1` 自动检测 Token 是否仍为占位符
- 安装 pkulaw-mcp-cli 后，update 脚本自动验证 Token 有效性
- 登录 https://mcp.pkulaw.com 重新生成 Token

### config.toml 损坏？
- 重新运行 `install.ps1`（只添加不覆盖已有配置）
- 或手动编辑 `~/.codex/config.toml`

### 无连接器也能用吗？
可以。技能仍可用，但法规引用将标注 `[需验证]`，
不保证法条和案例的现行有效性。

---

## 八、凭证安全

- Token 和 API Key 存储在 `~/.codex/config.toml` 中
- 安装时交互式输入，不保留在终端历史
- 如使用 `pkulaw-mcp-cli`，Token 存储在 `~/.pkulaw/mcp/config.json`
- 切勿将含 Token 的配置文件提交到 Git

---

## 九、相关链接

- 本仓库：https://github.com/laubeing-droid/codex-legal-mcp-connectors
- 主技能仓库：https://github.com/laubeing-droid/codex-legal-cn-skills
- chineselaw-mcp（npm）：https://www.npmjs.com/package/chineselaw-mcp
- @pkulaw/mcp-cli（npm）：https://www.npmjs.com/package/@pkulaw/mcp-cli
- 元典智库开放平台：https://open.chineselaw.com
- 北大法宝 MCP 平台：https://mcp.pkulaw.com
- 北大法宝 MCP 文档：https://mcp.pkulaw.com/docs
