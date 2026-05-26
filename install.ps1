<#
.SYNOPSIS
  legal-cn-mcp-hub 安装脚本
.DESCRIPTION
  检测 MCP 客户端环境 → 自托管服务 → 元典智库 → 北大法宝 → 飞书。
  - 直接运行:     完整交互流程
  - -Quick 参数:  仅自托管服务（供 main/judgment-predictor 作为依赖调用）
#>
param([switch]$Quick)

$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── 加载共享库 + 连接器 ────────────────────────────
. "$PSScriptRoot\detect.ps1"
. "$PSScriptRoot\connectors\self-hosted.ps1"
. "$PSScriptRoot\connectors\yuandian.ps1"
. "$PSScriptRoot\connectors\pkulaw.ps1"
. "$PSScriptRoot\connectors\feishu.ps1"

# ─── [0] 环境校验 ─────────────────────────────────
Write-Host "[0] 环境一致性校验..." -ForegroundColor Yellow
$envCheckScript = Join-Path $PSScriptRoot "env-check.ps1"
if (Test-Path $envCheckScript) {
    & $envCheckScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  环境校验未通过。请修复上述阻断项后重新安装。" -ForegroundColor Red
        Write-Host "  修复后运行: .\env-check.ps1" -ForegroundColor DarkGray
        Write-Host "========================================" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [OK] 环境校验通过" -ForegroundColor Green
} else {
    Write-Host "  [!] env-check.ps1 未找到，跳过环境校验" -ForegroundColor DarkYellow
}
Write-Host ""
Write-Host "=== legal-cn-mcp-hub 安装 ===" -ForegroundColor Green
if ($Quick) { Write-Host "  模式: Quick（仅自托管）" -ForegroundColor DarkYellow }
Write-Host ""

# ─── [1/6] 环境检测 ─────────────────────────────────
Write-Host "[1/6] 检测 MCP 客户端环境..." -ForegroundColor Yellow
$envs = Get-EnvironmentInfo
$activeEnvs = $envs | Where-Object { $_.Installed }
if ($activeEnvs.Count -eq 0) {
    Write-Host "  未检测到已安装的 MCP 客户端，将至少为 Codex Desktop 创建配置。" -ForegroundColor DarkGray
    $activeEnvs = @(@{
        Name = 'codex'; Display = 'Codex Desktop'
        ConfigPath = "$env:USERPROFILE\.codex\config.toml"
        Format = 'toml'; Installed = $true; McpSection = 'mcp_servers'
    })
}
foreach ($e in $activeEnvs) {
    Write-Host "  [OK] $($e.Display) — $($e.ConfigPath)" -ForegroundColor Green
}

# ─── [2/6] Node.js 检查 ─────────────────────────────
Write-Host ""
Write-Host "[2/6] 前置检查..." -ForegroundColor Yellow
$nodeOk = Get-Command node -ErrorAction SilentlyContinue
if ($nodeOk) {
    $nodeVer = & node --version
    Write-Host "  [OK] Node.js $nodeVer" -ForegroundColor Green
} else {
    Write-Host "  [!] Node.js 未安装（飞书需要）。下载: https://nodejs.org" -ForegroundColor DarkYellow
}

Write-Host ""

# ─── [3/6] 自托管服务（始终安装）─────────────────────
Install-SelfHosted -ActiveEnvs $activeEnvs

# ─── Quick 模式到此为止 ─────────────────────────────
if ($Quick) {
    Write-Host "========================================" -ForegroundColor DarkYellow
    Write-Host "  Quick 模式完成 — 仅部署了自托管服务。" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  MCP 在线服务未配置（元典/北大法宝/飞书）" -ForegroundColor Red
    Write-Host "  运行完整安装以启用在线服务:" -ForegroundColor Cyan
    Write-Host "    cd legal-cn-mcp-hub" -ForegroundColor White
    Write-Host "    .\install.ps1" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor DarkYellow
    return
}

# ─── [4/6] 元典智库 ─────────────────────────────────
Write-Host "[4/6]" -ForegroundColor Yellow
Install-Yuandian -ActiveEnvs $activeEnvs

# ─── [5/6] 北大法宝 ─────────────────────────────────
Write-Host "[5/6]" -ForegroundColor Yellow
Install-Pkulaw -ActiveEnvs $activeEnvs

# ─── [6/6] 飞书 ─────────────────────────────────────
Write-Host "[6/6]" -ForegroundColor Yellow
Install-Feishu -ActiveEnvs $activeEnvs

# ─── 完成 ───────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  已配置的 MCP 客户端:" -ForegroundColor Cyan
foreach ($e in $activeEnvs) {
    Write-Host "    - $($e.Display): $($e.ConfigPath)" -ForegroundColor White
}
Write-Host ""
Write-Host "  后续步骤:" -ForegroundColor Cyan
Write-Host "    1. 重启 MCP 客户端" -ForegroundColor White
Write-Host "    2. 运行 verify.ps1 验证" -ForegroundColor White
Write-Host "    3. 补充凭证: 直接运行 .\install.ps1（已配置的会跳过）" -ForegroundColor White
Write-Host ""
Write-Host "  注册入口:" -ForegroundColor Cyan
Write-Host "    元典:  https://open.chineselaw.com" -ForegroundColor DarkGray
Write-Host "    法宝:  https://mcp.pkulaw.com" -ForegroundColor DarkGray
Write-Host "    飞书:  https://open.feishu.cn/app" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Green
