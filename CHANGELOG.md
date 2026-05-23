# 更新日志

## [1.1.0] - 2026-05-23

### 改进
- install.ps1: 交互式输入 API Key / Access Token，替代硬编码占位符
- install.ps1: 添加 Node.js 前置检测
- install.ps1: 支持选择要安装的北大法宝服务（多选）
- install.ps1: 添加 Read-Host 交互提示

### 新增
- update.ps1: 新脚本，包含自更新 + npm 版本检查 + 全部 MCP 配置状态检查 + Token 过期检测 + @pkulaw/mcp-cli 验证
- install.sh: 新增 macOS/Linux 支持（Bash）
- verify.sh: 新增 macOS/Linux 验证脚本
- update.sh: 新增 macOS/Linux 更新脚本

### 增强
- verify.ps1: 改为动态发现所有 [mcp_servers.*] 配置段，检查全部服务
- verify.ps1: 新增 Token / API Key 占位符检测
- verify.ps1: 新增 npm 包版本检查
- verify.ps1: 新增 @pkulaw/mcp-cli 检测
- README.md: 更新文件清单，新增多平台支持说明

## [1.0.0] - 2026-05-23

### 新增
- 初始版本：install.ps1, verify.ps1, README.md, docs/connectors.md, npm-monitor.yml
- 支持 chineselaw（元典智库）+ 北大法宝 MCP 协议 + @pkulaw/mcp-cli
