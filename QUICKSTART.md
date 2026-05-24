# 快速入门

60 秒完成中国法律 MCP 连接器安装。

## 前置条件

- **Git**（克隆仓库）
- **Node.js >= 18**（仅元典智库需要）

## 安装

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

按提示操作：
- **元典 API Key**：取 https://open.chineselaw.com → API 管理 → 创建
- **北大法宝 Access Token**：取 https://mcp.pkulaw.com → 开发者控制台
- **服务选择**：`a` 全选，`1,3,5` 多选，留空跳过
- **凭证可不输入**，后续通过 `update.ps1` 更新

## 验证

```powershell
.\verify.ps1
```

显示各客户端配置状态、连接器是否启用、Token 占位符检测、npm 包版本。

## 更新诊断

```powershell
.\update.ps1
```

自动 git pull、检查 npm 新版、检测各客户端配置状态、Token 过期检测。

## 卸载

```powershell
.\uninstall.ps1
```

从所有客户端配置中移除法律连接器段。

## 下一步

- [连接器完整参考](docs/connectors.md)
- [使用指南](docs/usage-guide.md)
- [故障排除](docs/troubleshooting.md)