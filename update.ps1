<#
.SYNOPSIS
  通用更新脚本：自更新 + 全环境 MCP 配置检查 + Token 过期检测
.DESCRIPTION
  自动检测 Codex / Claude Code / Claude Desktop 环境，
  检查每个环境的 MCP 配置状态和凭证有效性。
#>

$ErrorActionPreference = 'Stop'
$MyDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

. "$MyDir\detect.ps1"

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host '=== 更新中国法律 MCP 连接器 ===' -ForegroundColor Green
Write-Host ''

# ─── [1/5] 自更新 ─────────────────────────────────────
Write-Host '[1/5] 自更新...' -ForegroundColor Yellow
Push-Location $MyDir
try {
    $gitResult = git pull 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($gitResult -match 'Already up to date|Already up-to-date') {
            Write-Host '  [OK] 已是最新' -ForegroundColor Green
        } elseif ($gitResult -match 'Updating') {
            Write-Host '  [OK] 已更新至最新版本' -ForegroundColor Green
        } else {
            Write-Host "  [OK] $($gitResult | Out-String)" -ForegroundColor Green
        }
    } else {
        Write-Host '  [!]  git pull 失败（非 git 目录或网络问题）' -ForegroundColor Yellow
    }
} finally { Pop-Location }

# ─── [2/5] npm 版本检查 ─────────────────────────────
Write-Host ''
Write-Host '[2/5] 检查 npm 包版本...' -ForegroundColor Yellow
function Check-NpmVersion {
    param($PackageName, $DisplayName)
    try {
        $info = Invoke-RestMethod -Uri "https://registry.npmjs.org/$PackageName/latest" -ErrorAction SilentlyContinue
        if (-not $info -or -not $info.version) { Write-Host "  [!]  $DisplayName (无法获取)" -ForegroundColor DarkGray; return }
        $latest = $info.version
        $local = '未安装'
        if (Test-Command 'npx') {
            $localOutput = & npx.cmd "$PackageName" --version 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -and $localOutput.Trim()) { $local = $localOutput.Trim() }
        }
        if ($local -eq '未安装') { Write-Host "  [!]  $DisplayName latest=$latest (本地未安装)" -ForegroundColor Yellow }
        elseif ($local -eq $latest) { Write-Host "  [OK] $DisplayName v$latest (已最新)" -ForegroundColor Green }
        else { Write-Host "  [!!] $DisplayName local=$local → latest=$latest (有新版本)" -ForegroundColor Yellow }
    } catch { Write-Host "  [!]  $DisplayName (无法检查)" -ForegroundColor DarkGray }
}

Check-NpmVersion '@pkulaw/mcp-cli' '@pkulaw/mcp-cli'

# ─── [3/5] 全环境 MCP 配置检查 ───────────────────────
Write-Host ''
Write-Host '[3/5] 检查各环境 MCP 配置状态...' -ForegroundColor Yellow
$envs = Get-EnvironmentInfo
$activeEnvs = $envs | Where-Object { $_.Installed }
if ($activeEnvs.Count -eq 0) {
    Write-Host '  [!!] 未检测到任何 MCP 客户端环境' -ForegroundColor Red
} else {
    foreach ($e in $activeEnvs) {
        Write-Host "  >>> $($e.Display)" -ForegroundColor Cyan
        Write-Host "      配置: $($e.ConfigPath)" -ForegroundColor DarkGray
        if (-not (Test-Path $e.ConfigPath)) {
            Write-Host "  [!!] 配置文件不存在" -ForegroundColor Red
            continue
        }
        if ($e.Format -eq 'toml') {
            $config = Get-Content $e.ConfigPath -Encoding UTF8 -Raw
            $sections = [regex]::Matches($config, '(?m)^\[mcp_servers\.([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
            foreach ($section in $sections) {
                $r = "(?ms)^\[mcp_servers\.\Q$section\E\]"
                if ($config -match "${r}.*?enabled\s*=\s*true") {
                    Write-Host "  [OK] $section (已启用)" -ForegroundColor Green
                } else {
                    Write-Host "  [!]  $section (已配置)" -ForegroundColor Yellow
                }
            }
        } else {
            try {
                $json = Get-Content $e.ConfigPath -Encoding UTF8 -Raw | ConvertFrom-Json
                if ($json.mcpServers) {
                    $json.mcpServers.PSObject.Properties | ForEach-Object {
                        Write-Host "  [OK] $($_.Name) (已配置)" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Host "  [!!] 配置文件格式错误" -ForegroundColor Red
            }
        }
    }
}

# ─── [4/5] 凭证检测 ───────────────────────────────────
Write-Host ''
Write-Host '[4/5] 检测凭证状态...' -ForegroundColor Yellow
$credIssues = $false

foreach ($e in $activeEnvs) {
    if (-not (Test-Path $e.ConfigPath)) { continue }
    $content = Get-Content $e.ConfigPath -Encoding UTF8 -Raw

    if ($e.Format -eq 'toml') {
        if ($content -match 'CHINESELAW_API_KEY\s*=\s*"YOUR_API_KEY"') {
            Write-Host "  [!!] $($e.Display): chineselaw API Key 仍为占位符" -ForegroundColor Red
            $credIssues = $true
        }
        if ($content -match 'Bearer YOUR_ACCESS_TOKEN') {
            Write-Host "  [!!] $($e.Display): 北大法宝 Token 仍为占位符" -ForegroundColor Red
            $credIssues = $true
        }
    } else {
        try {
            $json = $content | ConvertFrom-Json
            if ($json.mcpServers) {
                $json.mcpServers.PSObject.Properties | ForEach-Object {
                    $svc = $_.Value
                    if ($svc.env -and $svc.env.CHINESELAW_API_KEY -eq 'YOUR_API_KEY') {
                        Write-Host "  [!!] $($e.Display): chineselaw API Key 仍为占位符" -ForegroundColor Red
                        $credIssues = $true
                    }
                    if ($svc.headers -and $svc.headers.Authorization -match 'Bearer YOUR_ACCESS_TOKEN') {
                        Write-Host "  [!!] $($e.Display): 北大法宝 Token 仍为占位符" -ForegroundColor Red
                        $credIssues = $true
                    }
                }
            }
        } catch {}
    }
}

# 尝试通过 pkulaw-mcp-cli 验证 Token
if (Test-Command 'pkulaw-mcp') {
    Write-Host '  检测到 @pkulaw/mcp-cli，正在验证 Token 有效性...' -ForegroundColor DarkGray
    try {
        $job = Start-Job -ScriptBlock { param($p) & $p update 2>&1 | Out-String }
        $job | Wait-Job -Timeout 15 | Out-Null
        if ($job.State -eq 'Completed') {
            $output = Receive-Job $job
            if ($output -match 'update completed|success|OK|成功') {
                Write-Host '  [OK] Token 有效，服务可用' -ForegroundColor Green
            } else {
                Write-Host '  [!]  Token 可能已过期或无效' -ForegroundColor Yellow
                Write-Host '       请登录 https://mcp.pkulaw.com 重新生成' -ForegroundColor Cyan
            }
        } else { Stop-Job $job; Write-Host '  [!]  Token 验证超时，跳过' -ForegroundColor Yellow }
        Remove-Job $job -ErrorAction SilentlyContinue
    } catch { Write-Host '  [!]  Token 验证出错' -ForegroundColor Yellow }
}

if (-not $credIssues) { Write-Host '  凭证状态正常' -ForegroundColor Green }

# ─── [5/5] 汇总 ──────────────────────────────────────
Write-Host ''
Write-Host '[5/5] 汇总' -ForegroundColor Yellow
foreach ($e in $activeEnvs) {
    Write-Host "  $($e.Display): $($e.ConfigPath)" -ForegroundColor Cyan
}
Write-Host ''
Write-Host '更新完成。重启 MCP 客户端使新内容生效。' -ForegroundColor Green
