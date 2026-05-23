<#
.SYNOPSIS
  更新并验证 Codex 中国法律 MCP 连接器
.DESCRIPTION
  1. 自更新（git pull）
  2. 检查 npm 包版本（chineselaw-mcp / @pkulaw/mcp-cli）
  3. 检查 config.toml 中所有 MCP 配置状态
  4. 检测 Access Token 是否过期或仍为占位符
  5. 检测 @pkulaw/mcp-cli 并运行验证
  runbook: 输出帮助信息，列出常见问题与修复步骤
#>

$ErrorActionPreference = 'Stop'
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

Write-Host '=== 更新 Codex 中国法律 MCP 连接器 ===' -ForegroundColor Green
Write-Host ''

# ─── 辅助函数 ──────────────────────────────────────────

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# ─── [1/5] 自更新 ─────────────────────────────────────

Write-Host '[1/5] 自更新...' -ForegroundColor Yellow
$MyPath = $MyInvocation.MyCommand.Path
$MyDir = Split-Path -Parent $MyPath
Push-Location $MyDir
try {
    $gitResult = git pull 2>&1
    if ($LASTEXITCODE -eq 0) {
        $msg = ($gitResult | Out-String).Trim()
        if ($msg -match 'Already up to date|Already up-to-date') {
            Write-Host '  [OK] 已是最新' -ForegroundColor Green
        } elseif ($msg -match 'Updating') {
            Write-Host '  [OK] 已更新至最新版本' -ForegroundColor Green
        } else {
            Write-Host "  [OK] $msg" -ForegroundColor Green
        }
    } else {
        Write-Host '  [!]  git pull 失败（非 git 目录或网络问题）' -ForegroundColor Yellow
        Write-Host "      $($gitResult | Out-String)" -ForegroundColor DarkGray
    }
} finally {
    Pop-Location
}

# ─── [2/5] npm 包版本检查 ─────────────────────────────

Write-Host ''
Write-Host '[2/5] 检查 npm 包版本...' -ForegroundColor Yellow

function Check-NpmVersion {
    param($PackageName, $DisplayName)
    try {
        $info = Invoke-RestMethod -Uri "https://registry.npmjs.org/$PackageName/latest" -ErrorAction SilentlyContinue
        if (-not $info -or -not $info.version) {
            Write-Host "  [!]  $DisplayName (无法获取版本)" -ForegroundColor DarkGray
            return
        }
        $latest = $info.version
        $local = '未安装'
        if (Test-Command 'npx') {
            $localOutput = & npx.cmd "$PackageName" --version 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -and $localOutput.Trim()) {
                $local = $localOutput.Trim()
            }
        }
        if ($local -eq $latest) {
            Write-Host "  [OK] $DisplayName v$latest (已最新)" -ForegroundColor Green
        } elseif ($local -eq '未安装') {
            Write-Host "  [!]  $DisplayName latest=$latest (本地未安装)" -ForegroundColor Yellow
        } else {
            Write-Host "  [!!] $DisplayName local=$local → latest=$latest (有新版本)" -ForegroundColor Yellow
            Write-Host "       更新: npm install -g $PackageName" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  [!]  $DisplayName (无法检查版本)" -ForegroundColor DarkGray
    }
}

Check-NpmVersion 'chineselaw-mcp' 'chineselaw-mcp'
Check-NpmVersion '@pkulaw/mcp-cli' '@pkulaw/mcp-cli'

# ─── [3/5] MCP 配置状态检查 ───────────────────────────

Write-Host ''
Write-Host '[3/5] 检查 MCP 配置状态...' -ForegroundColor Yellow

if (-not (Test-Path $ConfigPath)) {
    Write-Host '  [!!] config.toml 不存在，请先运行 install.ps1' -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigPath -Encoding UTF8 -Raw

# 动态发现所有 [mcp_servers.*] 配置段
$sections = [regex]::Matches($config, '(?m)^\[mcp_servers\.([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
if ($sections.Count -eq 0) {
    Write-Host '  [!!] config.toml 中未找到任何 MCP 连接器配置' -ForegroundColor Red
    $allOk = $false
} else {
    $allOk = $true
    foreach ($section in $sections) {
        # 从 section 名称反查连接器类型
        $displayName = $section
        $isChineselaw = $section -eq 'chineselaw'
        $isPkulaw = $section -like 'pkulaw-*'

        # 检查 enabled
        $sectionRegex = "(?ms)^\[mcp_servers\.\Q$section\E\].*?"
        if ($config -match "${sectionRegex}enabled\s*=\s*true") {
            Write-Host "  [OK] $displayName (已启用)" -ForegroundColor Green
        } elseif ($config -match "(?ms)^\[mcp_servers\.\Q$section\E\]") {
            Write-Host "  [!]  $displayName (已配置但未启用)" -ForegroundColor Yellow
            $allOk = $false
        }
    }
}

if ($allOk) { Write-Host '  配置状态正常' -ForegroundColor Green }
else { Write-Host '  部分配置异常，建议重新运行 install.ps1' -ForegroundColor Yellow }

# ─── [4/5] Token / API Key 过期检测 ───────────────────

Write-Host ''
Write-Host '[4/5] 检测凭证状态...' -ForegroundColor Yellow
$credIssues = $false

# 检查 chineselaw API Key
if ($config -match '(?ms)\[mcp_servers\.chineselaw\.env\]') {
    if ($config -match 'CHINESELAW_API_KEY\s*=\s*"YOUR_API_KEY"') {
        Write-Host '  [!!] chineselaw: API Key 仍为占位符 YOUR_API_KEY' -ForegroundColor Red
        Write-Host '       注册: https://open.chineselaw.com' -ForegroundColor Cyan
        $credIssues = $true
    } else {
        Write-Host '  [OK] chineselaw: API Key 已配置' -ForegroundColor Green
    }
}

# 检查北大法宝 Token
$pkulawSections = $sections | Where-Object { $_ -like 'pkulaw-*' }
if ($pkulawSections.Count -gt 0) {
    if ($config -match 'Bearer YOUR_ACCESS_TOKEN') {
        Write-Host '  [!!] 北大法宝: Access Token 仍为占位符 YOUR_ACCESS_TOKEN' -ForegroundColor Red
        Write-Host '       注册: https://mcp.pkulaw.com → 开发者控制台' -ForegroundColor Cyan
        $credIssues = $true
    } else {
        Write-Host '  [OK] 北大法宝: Access Token 已配置' -ForegroundColor Green
        # 如果安装了 pkulaw-mcp-cli，尝试验证 Token 有效性
        if (Test-Command 'pkulaw-mcp') {
            Write-Host '  检测到 @pkulaw/mcp-cli，正在验证 Token 有效性...' -ForegroundColor DarkGray
            try {
                $timeoutSec = 15
                $job = Start-Job -ScriptBlock { param($p) & $p update 2>&1 | Out-String }
                $job | Wait-Job -Timeout $timeoutSec | Out-Null
                if ($job.State -eq 'Completed') {
                    $output = Receive-Job $job
                    if ($output -match 'update completed|success|OK|成功') {
                        Write-Host '  [OK] Token 有效，服务可用' -ForegroundColor Green
                    } else {
                        Write-Host '  [!]  Token 可能已过期或无效' -ForegroundColor Yellow
                        Write-Host '       请登录 https://mcp.pkulaw.com 重新生成 Token' -ForegroundColor Cyan
                    }
                } else {
                    Stop-Job $job
                    Write-Host '  [!]  Token 验证超时（${timeoutSec}s），跳过' -ForegroundColor Yellow
                }
                Remove-Job $job -ErrorAction SilentlyContinue
            } catch {
                Write-Host '  [!]  Token 验证出错，可能已过期' -ForegroundColor Yellow
                Write-Host '       请登录 https://mcp.pkulaw.com 重新生成 Token' -ForegroundColor Cyan
            }
        } else {
            Write-Host '  提示: 安装 @pkulaw/mcp-cli 可验证 Token 有效性' -ForegroundColor DarkGray
            Write-Host '       npm install -g @pkulaw/mcp-cli' -ForegroundColor DarkGray
            Write-Host '       pkulaw-mcp init --authorization "Bearer YOUR_TOKEN"' -ForegroundColor DarkGray
        }
    }
}

if (-not $credIssues) {
    Write-Host '  凭证状态正常' -ForegroundColor Green
}

# ─── [5/5] 北大法宝 CLI 状态检测 ─────────────────────

Write-Host ''
Write-Host '[5/5] 检测调试工具...' -ForegroundColor Yellow
if (Test-Command 'pkulaw-mcp') {
    Write-Host '  [OK] @pkulaw/mcp-cli 已安装' -ForegroundColor Green
} else {
    Write-Host '  [!]  @pkulaw/mcp-cli 未安装（可选调试工具）' -ForegroundColor DarkGray
    Write-Host '       安装: npm install -g @pkulaw/mcp-cli' -ForegroundColor DarkGray
    Write-Host '       初始化: pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"' -ForegroundColor DarkGray
}

# ─── 汇总 ──────────────────────────────────────────────

Write-Host ''
Write-Host '===== 汇总 =====' -ForegroundColor Cyan
$hasChineselaw = $sections -contains 'chineselaw'
$hasPkulaw = ($sections | Where-Object { $_ -like 'pkulaw-*' }).Count -gt 0
if ($hasChineselaw -or $hasPkulaw) {
    $connectorList = @()
    if ($hasChineselaw) { $connectorList += 'chineselaw' }
    if ($hasPkulaw) { $connectorList += '北大法宝' }
    Write-Host "  已配置: $($connectorList -join ', ')" -ForegroundColor Cyan
} else {
    Write-Host '  未配置任何连接器' -ForegroundColor Yellow
}
Write-Host "  配置路径: $ConfigPath" -ForegroundColor Cyan
Write-Host ''
Write-Host '更新完成。' -ForegroundColor Green
