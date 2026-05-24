# 使用指南

## 一、安装

### 前置条件

| 需求 | 说明 |
|------|------|
| Git | 克隆仓库 |
| Node.js >= 18 | 仅元典智库、飞书需要。北大法宝 MCP 不需要 |
| Python 3.8+ | 仅自建 MCP Server 需要 |

### 安装流程

```powershell
git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
cd Codex-Claude-legal-cn-mcp-hub
.\install.ps1
```

macOS/Linux：
```bash
git clone https://github.com/laubeing-droid/Codex-Claude-legal-cn-mcp-hub.git
cd Codex-Claude-legal-cn-mcp-hub
chmod +x install.sh && ./install.sh
```

安装脚本 5 步：

1. **环境检测** — 自动发现本机已安装的 MCP 客户端
2. **前置检查** — 检测 Node.js 是否可用
3. **元典 API Key** — 选填，留空写入占位符后续可补
4. **北大法宝 Token** — 选填，留空写入占位符后续可补
5. **服务选择** — 输入 `a` 全选，`1,3,5` 按序号多选，留空跳过
6. **写入配置** — 遍历所有检测到的客户端，自动适配 TOML/JSON

> 凭证不在安装时输入也没关系，后续通过 `update.ps1` 或手动编辑配置文件补充。

### 仅安装某个连接器

安装过程中在服务选择步骤留空即可跳过不想装的连接器。
如需精细控制，参考 [connectors.md](connectors.md) 手动写入配置段。

## 二、验证

```powershell
.\verify.ps1
```

输出范例：
```
=== 中国法律 MCP 连接器 验证 ===

[OK] Codex Desktop    → ~/.codex/config.toml
[OK] Claude Code      → ~/.claude/settings.json

>>> Codex Desktop
  [OK] yuandian-law （已启用）
  [OK] yuandian-case （已启用）
  [OK] yuandian-company （已启用）
  [!]  Token 仍为占位符

npm 包版本:
  [!]  @pkulaw/mcp-cli（未安装）
```

## 三、更新与诊断

```powershell
.\update.ps1
```

自动完成：
1. `git pull` 拉取本仓库最新版本
3. 遍历所有客户端环境检查 MCP 段状态
4. 检测 Token / API Key 是否仍为占位符
5. 如安装了 `@pkulaw/mcp-cli`，自动调用验证 Token 有效性

建议每月运行一次。

## 四、卸载

```powershell
.\uninstall.ps1
```

从所有 MCP 客户端配置文件中移除中国法律连接器段。

需重新安装时再次运行 `install.ps1` 即可。

## 五、配合上游仓库

本仓库是一个独立工具，无需配合任何其他仓库使用。

如果同时使用 [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex)（中国法律技能包），其 `install.ps1` 会自动克隆本仓库并调用安装：

```powershell
git clone https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex.git
cd Claude-for-Legal-CN-to-Codex
.\install.ps1
```