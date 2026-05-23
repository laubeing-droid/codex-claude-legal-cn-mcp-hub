<#
.SYNOPSIS
  验证 Codex 中国法律 MCP 连接器状态
.DESCRIPTION
  检查 config.toml 中所有 MCP 配置是否启用、凭证是否配置、
  检测 npm 包版本、检测 @pkulaw/mcp-cli。
#>

$ErrorActionPreference = 'Stop'
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

Write-Host '=== Codex 中国法律 MCP 连接器 验证 ===' -ForegroundColor Cyan
Write-Host ''

# ─── 辅助函数 ──────────────────────────────────────────

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# ─── 1. 检查 config.toml 存在性 ──────────────────────

if (-not (Test-Path $ConfigPath)) {
    Write-Host '[!!] config.toml 不存在，请先运行 install.ps1' -ForegroundColor Red
    exit 1
}
Write-Host "[OK] config.toml: $ConfigPath" -ForegroundColor Green
Write-Host ''

$config = Get-Content $ConfigPath -Encoding UTF8 -Raw

# ─── 2. 动态发现所有 MCP 服务 ────────────────────────

$sections = [regex]::Matches($config, '(?m)^\[mcp_servers\.([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$allOk = $true

Write-Host "MCP 连接器配置状态 (共 $($sections.Count) 个):" -ForegroundColor Yellow
Write-Host ''

if ($sections.Count -eq 0) {
    Write-Host '  [!!] 未找到任何 MCP 连接器配置' -ForegroundColor Red
    $allOk = $false
}

foreach ($section in $sections) {
    $displayName = $section
    $sectionRegex = "(?ms)^\[mcp_servers\.\Q$section\E\]"

    # 检查是否已配置
    if ($config -notmatch $sectionRegex) {
        Write-Host "  [!!] $displayName (未配置)" -ForegroundColor Red
        $allOk = $false
        continue
    }

    # 检查是否启用
    if ($config -match "${sectionRegex}.*?enabled\s*=\s*true") {
        Write-Host "  [OK] $displayName (已启用)" -ForegroundColor Green
    } else {
        Write-Host "  [!]  $displayName (已配置但未启用)" -ForegroundColor Yellow
        $allOk = $false
    }

    # 检查凭证是否仍为占位符
    $sectionContent = ""
    $remainder = ""
    if ($config -match "(?ms)\[mcp_servers\.\Q$section\E\](.*?)(?=\[mcp_servers\.|$)") {
        $sectionContent = $Matches[1]
    }
    if ($section -eq 'chineselaw') {
        # 检查 env 段
        if ($config -match "(?ms)\[mcp_servers\.chineselaw\.env\].*?CHINESELAW_API_KEY\s*=\s*""YOUR_API_KEY""") {
            Write-Host "         [!] API Key 仍为占位符" -ForegroundColor Red
            $allOk = $false
        }
    } elseif ($section -like 'pkulaw-*') {
        if ($sectionContent -match 'Bearer YOUR_ACCESS_TOKEN') {
            Write-Host "         [!] Token 仍为占位符" -ForegroundColor Red
            $allOk = $false
        }
    }
}

# ─── 3. npm 包版本检查 ───────────────────────────────

Write-Host ''
Write-Host 'npm 包版本:' -ForegroundColor Yellow

function Check-NpmVersion {
    param($PackageName, $DisplayName)
    try {
        $info = Invoke-RestMethod -Uri "https://registry.npmjs.org/$PackageName/latest" -ErrorAction SilentlyContinue
        if (-not $info -or -not $info.version) {
            Write-Host "  [!]  $DisplayName (无法获取)" -ForegroundColor DarkGray
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
        if ($local -eq '未安装') {
            Write-Host "  [!]  $DisplayName latest=$latest (未安装)" -ForegroundColor Yellow
        } elseif ($local -eq $latest) {
            Write-Host "  [OK] $DisplayName v$latest (已最新)" -ForegroundColor Green
        } else {
            Write-Host "  [!!] $DisplayName local=$local → latest=$latest" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [!]  $DisplayName (无法检查)" -ForegroundColor DarkGray
    }
}

Check-NpmVersion 'chineselaw-mcp' 'chineselaw-mcp'
Check-NpmVersion '@pkulaw/mcp-cli' '@pkulaw/mcp-cli'

# ─── 4. @pkulaw/mcp-cli 检测 ─────────────────────────

Write-Host ''
if (Test-Command 'pkulaw-mcp') {
    Write-Host '[OK] @pkulaw/mcp-cli 已安装' -ForegroundColor Green
    Write-Host '  运行 pkulaw-mcp update 验证 Token 有效性' -ForegroundColor DarkGray
} else {
    Write-Host '[!] @pkulaw/mcp-cli 未安装（可选调试工具）' -ForegroundColor DarkGray
    Write-Host '  安装: npm install -g @pkulaw/mcp-cli' -ForegroundColor DarkGray
    Write-Host '  初始化: pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"' -ForegroundColor DarkGray
}

# ─── 5. 验证汇总 ─────────────────────────────────────

Write-Host ''
if ($allOk) {
    Write-Host '✓ 验证通过。所有 MCP 连接器配置正常。' -ForegroundColor Green
} else {
    Write-Host '⚠ 存在以下问题:' -ForegroundColor Yellow
    if (-not (Test-Path $ConfigPath)) { Write-Host '  - config.toml 不存在，运行 install.ps1' -ForegroundColor Yellow }
    if ($config -notmatch 'enabled\s*=\s*true') { Write-Host '  - 部分连接器未启用，检查 config.toml' -ForegroundColor Yellow }
    if ($config -match 'YOUR_API_KEY|YOUR_ACCESS_TOKEN') { Write-Host '  - 凭证仍为占位符，替换为真实值' -ForegroundColor Yellow }
    Write-Host '  运行 update.ps1 获取详细诊断。' -ForegroundColor Yellow
}
