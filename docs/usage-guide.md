<!--
version: 3.0.2
module: docs
status: active
-->

# 使用指南

## 安装

```powershell
git clone https://github.com/laubeing-droid/legal-cn-mcp-hub.git
cd legal-cn-mcp-hub
.\install.ps1
```

macOS/Linux：
```bash
git clone https://github.com/laubeing-droid/legal-cn-mcp-hub.git
cd legal-cn-mcp-hub
chmod +x install.sh && ./install.sh
```

安装过程：
1. 环境检测（Codex / Claude Code / Claude Desktop）
2. 元典 API Key（选填）
3. 北大法宝 Token（选填）
4. 服务选择（多选 / 全选 / 跳过）
5. 自动写入所有客户端

## 验证

```powershell
.\verify.ps1
```

输出各客户端配置状态、连接器启用情况、Token 占位符检测。

## 更新

```powershell
.\update.ps1
```

自动 git pull → npm 版本检查 → 配置巡检 → Token 检测。

## 卸载

```powershell
.\uninstall.ps1
```

从所有客户端移除连接器段。

## 自建 Server 启动

```bash
cd servers/flk-npc     # 或 servers/rmfyalk
pip install -r requirements.txt
python scripts/server.py
```

## 配合主仓库

本仓库独立可用。配合 [legal-cn-main](https://github.com/laubeing-droid/legal-cn-main) 时，其 install.ps1 会自动调用本仓库。