<#
.SYNOPSIS
  检测Codex/Claude Code/Claude Desktop环境并返回配置路径
.DESCRIPTION
  自动检测本机安装了哪些MCP客户端环境及各自的配置路径/格式。
  返回对象包含每个环境的配置信息。
  提供各连接器的配置模板函数。
#>

function Get-EnvironmentInfo {
    $envs = @()

    # ---- Codex Desktop ----
    $codexConfig = "$env:USERPROFILE\.codex\config.toml"
    $codexInstalled = Test-Path "$env:USERPROFILE\.codex"
    $envs += @{
        Name       = 'codex'
        Display    = 'Codex Desktop'
        ConfigPath = $codexConfig
        Format     = 'toml'
        Installed  = $codexInstalled
        McpSection = 'mcp_servers'
    }

    # ---- Claude Code (terminal) ----
    $claudeCodeConfig = "$env:USERPROFILE\.claude\settings.json"
    $claudeCodeInstalled = Test-Path $claudeCodeConfig
    $envs += @{
        Name       = 'claude-code'
        Display    = 'Claude Code'
        ConfigPath = $claudeCodeConfig
        Format     = 'json'
        Installed  = $claudeCodeInstalled
        McpSection = 'mcpServers'
    }

    # ---- Claude Desktop ----
    $claudeDesktopConfig = "$env:LOCALAPPDATA\Claude\claude_desktop_config.json"
    if (-not (Test-Path $claudeDesktopConfig)) {
        $claudeDesktopConfig = "$env:APPDATA\Claude\claude_desktop_config.json"
    }
    $claudeDesktopInstalled = Test-Path $claudeDesktopConfig
    $envs += @{
        Name       = 'claude-desktop'
        Display    = 'Claude Desktop'
        ConfigPath = $claudeDesktopConfig
        Format     = 'json'
        Installed  = $claudeDesktopInstalled
        McpSection = 'mcpServers'
    }

    return $envs
}

function Write-McpToCodex {
    param([string]$ConfigPath, [string]$Section, [string]$TomlBlock)
    if (-not (Test-Path (Split-Path -Parent $ConfigPath))) {
        $null = New-Item -ItemType Directory -Force (Split-Path -Parent $ConfigPath)
    }
    if (-not (Test-Path $ConfigPath)) {
        $null = New-Item -ItemType File -Force $ConfigPath
    }
    $content = Get-Content $ConfigPath -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($content -match "(?ms)^\[mcp_servers\.\Q$Section\E\]") {
        return $false
    }
    Add-Content -Path $ConfigPath -Value "`n$TomlBlock" -Encoding UTF8
    return $true
}

function Write-McpToClaude {
    param([string]$ConfigPath, [string]$ServerId, [hashtable]$ServerConfig)
    $dir = Split-Path -Parent $ConfigPath
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Force $dir }

    $json = @{}
    if (Test-Path $ConfigPath) {
        try { $json = Get-Content $ConfigPath -Encoding UTF8 -Raw | ConvertFrom-Json }
        catch { $json = @{} }
    }
    $config = @{}
    $json.PSObject.Properties | ForEach-Object { $config[$_.Name] = $_.Value }

    if (-not $config.ContainsKey('mcpServers')) {
        $config['mcpServers'] = @{}
    }
    if (-not $config.ContainsKey('env')) {
        $config['env'] = @{}
    }

    if ($config['mcpServers'].ContainsKey($ServerId)) {
        return $false
    }

    $config['mcpServers'][$ServerId] = $ServerConfig
    $jsonStr = $config | ConvertTo-Json -Depth 10
    Set-Content -Path $ConfigPath -Value $jsonStr -Encoding UTF8
    return $true
}

# ─── 元典 (chineselaw) 配置模板 ────────────────────

# 方式 A: Streamable HTTP（元典官方，推荐）
function Get-YuandianHttpConfig {
    param([string]$ApiKey)
    return @(
        @{ name='yuandian-law';      url='https://open.chineselaw.com/mcp/law/stream';     display='元典-法律法规';   desc='5 个法律工具' }
        @{ name='yuandian-case';     url='https://open.chineselaw.com/mcp/case/stream';    display='元典-案例文书';   desc='4 个案例工具' }
        @{ name='yuandian-company';  url='https://open.chineselaw.com/mcp/company/stream'; display='元典-企业信息';   desc='26 个企业工具' }
    )
}

function Get-YuandianHttpToml {
    param([string]$Name, [string]$Url, [string]$ApiKey)
    return @"
[mcp_servers.$Name]
type = "http"
url = "$Url"
http_headers = { Authorization = "Bearer $ApiKey", Accept = "application/json, text/event-stream" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
"@
}

function Get-YuandianHttpJson {
    param([string]$Name, [string]$Url, [string]$ApiKey)
    return @{
        url     = $Url
        headers = @{
            Authorization = "Bearer $ApiKey"
            Accept        = "application/json, text/event-stream"
        }
    }
}


function Get-YuandianStdConfig {
    param([string]$ApiKey)
    return @{
        command = 'npx'
        
        env     = @{ CHINESELAW_API_KEY = $ApiKey }
    }
}

# ─── 飞书 (larksuite) 配置模板 ─────────────────────

function Get-FeishuConfig {
    param([string]$AppId, [string]$AppSecret)
    return @{
        command = 'npx'
        args    = @('-y', '@larksuiteoapi/lark-mcp')
        env     = @{
            LARK_APP_ID     = $AppId
            LARK_APP_SECRET = $AppSecret
        }
    }
}

function Get-FeishuToml {
    param([string]$AppId, [string]$AppSecret)
    return @"
[mcp_servers.feishu]
command = "npx"
args = ["-y", "@larksuiteoapi/lark-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.feishu.env]
LARK_APP_ID = "$AppId"
LARK_APP_SECRET = "$AppSecret"
"@
}

# ─── 北大法宝 (pkulaw) 配置模板 ────────────────────

function Get-PkulawHttpConfig {
    param([string]$Url, [string]$Token)
    return @{
        url     = $Url
        headers = @{ Authorization = "Bearer $Token" }
    }
}


# ─── 自建 Python MCP 配置模板 ─────────────────────

function Get-SelfHostedRmfyalkConfig {
    param([string]$Token, [string]$ExeDir)
    if ([string]::IsNullOrEmpty($ExeDir)) { $ExeDir = (Get-ItemProperty -Path "HKLM:\Software\Python\PythonCore\3*" -Name InstallPath -ErrorAction SilentlyContinue).InstallPath }
    return @{
        command = if ($ExeDir) { "$ExeDir\python.exe" } else { 'python' }
        args    = @("$PSScriptRoot\servers\rmfyalk\scripts\server.py")
        env     = @{ RMFYALK_TOKEN = $Token }
    }
}

function Get-SelfHostedRmfyalkToml {
    param([string]$Token)
    $scriptPath = "servers/rmfyalk/scripts/server.py".Replace('\', '/')
    $repoRoot = $PSScriptRoot.Replace('\', '/')
    return @"
[mcp_servers.rmfyalk]
command = "python"
args = ["$repoRoot/$scriptPath"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.rmfyalk.env]
RMFYALK_TOKEN = "$Token"
"@
}

function Get-SelfHostedFlkNpcConfig {
    param([string]$ExeDir)
    if ([string]::IsNullOrEmpty($ExeDir)) { $ExeDir = (Get-ItemProperty -Path "HKLM:\Software\Python\PythonCore\3*" -Name InstallPath -ErrorAction SilentlyContinue).InstallPath }
    return @{
        command = if ($ExeDir) { "$ExeDir\python.exe" } else { 'python' }
        args    = @("$PSScriptRoot\servers\flk-npc\scripts\server.py")
    }
}

function Get-SelfHostedFlkNpcToml {
    $scriptPath = "servers/flk-npc/scripts/server.py".Replace('\', '/')
    $repoRoot = $PSScriptRoot.Replace('\', '/')
    return @"
[mcp_servers.flk-npc]
command = "python"
args = ["$repoRoot/$scriptPath"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
"@
}

  # Export-ModuleMember -Function Get-EnvironmentInfo  # commented: script mode only, Write-McpToCodex, Write-McpToClaude,
    Get-YuandianHttpConfig, Get-YuandianHttpToml, Get-YuandianHttpJson, Get-YuandianStdConfig,
    Get-FeishuConfig, Get-FeishuToml,
    Get-PkulawHttpConfig,
    Get-SelfHostedRmfyalkConfig, Get-SelfHostedRmfyalkToml,
    Get-SelfHostedFlkNpcConfig, Get-SelfHostedFlkNpcToml


