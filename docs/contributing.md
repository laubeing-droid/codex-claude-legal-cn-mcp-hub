# 贡献指南

## 开发原则

1. **双平台同步** — 所有逻辑修改必须在 PowerShell（`.ps1`）和 Bash（`.sh`）中保持对等
2. **新增不覆盖** — 安装脚本采用追加策略，已有配置段跳过写入
3. **文档即产品** — 修改功能后必须同步更新相关文档

## 目录约定

| 路径 | 说明 |
|------|------|
| `install.ps1/sh` | 安装入口（全流程编排） |
| `detect.ps1/sh`  | 环境检测模块（被其他脚本共用） |
| `verify.ps1/sh`  | 配置验证 |
| `update.ps1/sh`  | 自更新 + 诊断 |
| `uninstall.ps1/sh`| 卸载 |
| `servers/*/`      | Python MCP Server 实现 |
| `docs/*.md`       | 文档 |
| `.github/workflows/*.yml` | 自动化流水线 |

## 添加新连接器

1. 在 `install.ps1/sh` 的配置生成函数中新增对应的 TOML/JSON 段模板
2. 添加凭证输入步骤
3. 在 `verify.ps1/sh` 新增检测逻辑
4. 更新 `docs/connectors.md` 添加连接器说明
5. 更新交接文档

## 代码风格

- PowerShell：使用 `Write-Host` 输出，`PascalCase` 函数命名
- Bash：使用 `echo` 输出，`snake_case` 函数命名
- Python：遵循 PEP 8，`snake_case` 命名
- Markdown：中文文档使用中文标点，代码块标注语言

## 提交规范

提交信息格式：`type: 描述`

| type | 场景 |
|------|------|
| `feat` | 新连接器、新功能 |
| `fix`  | 配置生成 bug、路径错误 |
| `docs` | 文档修改 |
| `chore`| 工具链、CI、维护 |