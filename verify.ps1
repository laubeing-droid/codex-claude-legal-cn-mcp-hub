<#
.SYNOPSIS
  通用验证脚本：检查 Codex / Claude Code / Claude Desktop 的 MCP 配置
.DESCRIPTION
  自动检测所有 MCP 客户端环境，检查每个配置中的 MCP 连接器状态。
#>

$ErrorActionPreference = 'Stop'
$MyDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$MyDir\detect.ps1"

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host '=== 中国法律 MCP 连接器 验证 ===' -ForegroundColor Cyan
Write-Host ''

$envs = Get-EnvironmentInfo
$activeEnvs = $envs | Where-Object { $_.Installed }
if ($activeEnvs.Count -eq 0) {
    Write-Host '[!!] 未检测到任何 MCP 客户端环境。请先运行 install.ps1' -ForegroundColor Red
    exit 1
}

$allOk = $true

foreach ($e in $activeEnvs) {
    Write-Host ">>> $($e.Display)" -ForegroundColor Yellow
    Write-Host "    配置: $($e.ConfigPath)" -ForegroundColor DarkGray

    if (-not (Test-Path $e.ConfigPath)) {
        Write-Host "  [!!] 配置文件不存在" -ForegroundColor Red
        $allOk = $false
        Write-Host ''
        continue
    }

    if ($e.Format -eq 'toml') {
        # ---- Codex TOML 格式 ----
        $config = Get-Content $e.ConfigPath -Encoding UTF8 -Raw
        $sections = [regex]::Matches($config, '(?m)^\[mcp_servers\.([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
        if ($sections.Count -eq 0) {
            Write-Host "  [!!] 未找到任何 [mcp_servers] 配置" -ForegroundColor Red
            $allOk = $false
        }
        foreach ($section in $sections) {
            $sectionRegex = "(?ms)^\[mcp_servers\.\Q$section\E\]"
            if ($config -match "${sectionRegex}.*?enabled\s*=\s*true") {
                Write-Host "  [OK] $section (已启用)" -ForegroundColor Green
            } else {
                Write-Host "  [!]  $section (已配置)" -ForegroundColor Yellow
                $allOk = $false
            }
            # 检查占位符
            $sectionContent = ""
            if ($config -match "(?ms)\[mcp_servers\.\Q$section\E\](.*?)(?=\[mcp_servers\.|$)") {
                $sectionContent = $Matches[1]
            }
            if ($section -eq 'chineselaw') {
                if ($config -match 'CHINESELAW_API_KEY\s*=\s*"YOUR_API_KEY"') {
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
    } else {
        # ---- Claude JSON 格式 ----
        try {
            $json = Get-Content $e.ConfigPath -Encoding UTF8 -Raw | ConvertFrom-Json
            if (-not $json.mcpServers -or @($json.mcpServers.PSObject.Properties).Count -eq 0) {
                Write-Host "  [!!] 未找到任何 mcpServers 配置" -ForegroundColor Red
                $allOk = $false
            } else {
                $json.mcpServers.PSObject.Properties | ForEach-Object {
                    $name = $_.Name
                    $svc = $_.Value
                    if ($svc.command -or $svc.url) {
                        Write-Host "  [OK] $name (已配置)" -ForegroundColor Green
                        # 检查占位符
                        if ($svc.env -and $svc.env.CHINESELAW_API_KEY -eq 'YOUR_API_KEY') {
                            Write-Host "         [!] API Key 仍为占位符" -ForegroundColor Red
                            $allOk = $false
                        }
                        if ($svc.headers -and $svc.headers.Authorization -match 'Bearer YOUR_ACCESS_TOKEN') {
                            Write-Host "         [!] Token 仍为占位符" -ForegroundColor Red
                            $allOk = $false
                        }
                    } else {
                        Write-Host "  [!]  $name (配置不完整)" -ForegroundColor Yellow
                        $allOk = $false
                    }
                }
            }
        } catch {
            Write-Host "  [!!] 配置文件损坏或格式错误" -ForegroundColor Red
            $allOk = $false
        }
    }
    Write-Host ''
}

# ─── npm 版本检查 ─────────────────────────────────────
Write-Host 'npm 包版本:' -ForegroundColor Yellow
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
        if ($local -eq '未安装') { Write-Host "  [!]  $DisplayName latest=$latest (未安装)" -ForegroundColor Yellow }
        elseif ($local -eq $latest) { Write-Host "  [OK] $DisplayName v$latest (已最新)" -ForegroundColor Green }
        else { Write-Host "  [!!] $DisplayName local=$local → latest=$latest" -ForegroundColor Yellow }
    } catch { Write-Host "  [!]  $DisplayName (无法检查)" -ForegroundColor DarkGray }
}

Check-NpmVersion '@pkulaw/mcp-cli' '@pkulaw/mcp-cli'

Write-Host ''
if (Test-Command 'pkulaw-mcp') {
    Write-Host '[OK] @pkulaw/mcp-cli 已安装' -ForegroundColor Green
} else {
    Write-Host '[!] @pkulaw/mcp-cli 未安装（可选调试工具）' -ForegroundColor DarkGray
    Write-Host '  安装: npm install -g @pkulaw/mcp-cli' -ForegroundColor DarkGray
}

Write-Host ''
if ($allOk) { Write-Host '✓ 验证通过。所有配置正常。' -ForegroundColor Green }
else { Write-Host '⚠ 存在上述问题，请参考 docs/connectors.md 修复。' -ForegroundColor Yellow }
