# 更新日志

## v3.0.0 （2026-05-24）

### 变更
- 仓库重命名：`Codex-Claude-legal-CN-mcp-connectors` → `Codex-Claude-legal-cn-mcp-hub`
- 全仓文档重写，结构优化
- 引入国家法规库和案例库两个 Python MCP 服务器
- 新增 `servers/flk-npc/` 和 `servers/rmfyalk/` 自托管 MCP Server

### 新增
- GitHub Actions：上游同步
- 北大法宝 HTTP MCP 完整 10 服务支持
- 飞书 LarkSuite MCP 配置支持
- `.gitignore` + 交接文档完善

### 移除
- 过时的 `detect.ps1.bak`

## v2.0.0 （2026-05-23）

### 变更
- 从主仓库提取为独立 MCP 连接器仓库
- 双平台脚本（PowerShell + Bash）对齐
- 支持 Codex Desktop / Claude Code / Claude Desktop 三端

### 新增
- 元典智库 HTTP MCP（分 3 个 Server + 1 个全能力入口）
- 元典智库 npm stdio 备选方案
- 元典智库 REST API 36 端点直调
- 北大法宝 HTTP MCP 多服务选择
- `@pkulaw/mcp-cli` 诊断/调试工具支持
- `detect.ps1/sh` 环境检测模块
- 文档体系：README / QUICKSTART / connectors / architecture / usage-guide / troubleshooting / contributing
- GitHub Actions：`npm-monitor.yml` 包版本监控

## v1.0.0 （2026-05-22）

### 初始版本
- Codex Desktop / Claude Code 双端配置
- 基础 install.ps1
