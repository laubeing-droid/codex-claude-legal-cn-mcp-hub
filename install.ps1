<#
.SYNOPSIS
  安装 Codex 中国法律 MCP 连接器
.DESCRIPTION
  写入 chineselaw（元典智库）/ 北大法宝 MCP 配置到 ~/.codex/config.toml。
  支持交互式输入凭证、选择服务、检测前置依赖。
  仅添加不存在的条目，不删除或覆盖已有配置。
#>

$ErrorActionPreference = 'Stop'
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

Write-Host '=== 安装 Codex 中国法律 MCP 连接器 ===' -ForegroundColor Green
Write-Host ''

# ─── 辅助函数 ──────────────────────────────────────────

function Add-McpServerToConfig {
    param([string]$Section, [string]$TomlBlock)
    if (-not (Test-Path $ConfigPath)) {
        New-Item -ItemType File -Force $ConfigPath | Out-Null
    }
    $content = Get-Content $ConfigPath -Encoding UTF8 -Raw
    if ($content -match "(?ms)^\[mcp_servers\.\Q$Section\E\]") {
        Write-Host "  [跳过] $Section (已存在)" -ForegroundColor DarkYellow
        return $false
    }
    Add-Content -Path $ConfigPath -Value "`n$TomlBlock" -Encoding UTF8
    Write-Host "  [添加] $Section" -ForegroundColor Green
    return $true
}

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# ─── 前置检查 ──────────────────────────────────────────

Write-Host '前置检查...' -ForegroundColor Yellow

$nodeOk = $true
if (-not (Test-Command 'node')) {
    Write-Host '  [!!] Node.js 未安装！chineselaw 需要 Node.js >= 18' -ForegroundColor Red
    Write-Host '       下载: https://nodejs.org (LTS 版本)' -ForegroundColor Cyan
    $nodeOk = $false
} else {
    $nodeVer = & node --version
    Write-Host "  [OK] Node.js $nodeVer" -ForegroundColor Green
}

$codexDir = Split-Path -Parent $ConfigPath
if (-not (Test-Path $codexDir)) {
    $null = New-Item -ItemType Directory -Force $codexDir
    Write-Host "  [OK] 创建 $codexDir" -ForegroundColor Green
}

Write-Host ''

# ─── chineselaw ────────────────────────────────────────

if ($nodeOk) {
    Write-Host '>> chineselaw（元典智库）— 推荐，33 个工具' -ForegroundColor Cyan
    Write-Host '   注册: https://open.chineselaw.com → API 管理 → 创建 API Key' -ForegroundColor DarkGray
    $useChineselaw = Read-Host '是否安装 chineselaw？(Y/n)'
    if ($useChineselaw -ne 'n' -and $useChineselaw -ne 'N') {
        $apiKey = Read-Host '  请输入 CHINESELAW_API_KEY（留空=使用占位符）'
        if ([string]::IsNullOrEmpty($apiKey)) {
            $apiKey = 'YOUR_API_KEY'
            Write-Host '  使用占位符，稍后手动替换' -ForegroundColor DarkYellow
        }
        $chineselawBlock = @"
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "$apiKey"
"@
        Add-McpServerToConfig -Section 'chineselaw' -TomlBlock $chineselawBlock
    } else {
        Write-Host '  跳过 chineselaw' -ForegroundColor DarkGray
    }
} else {
    Write-Host '>> 跳过 chineselaw（缺少 Node.js）' -ForegroundColor DarkGray
}

Write-Host ''

# ─── 北大法宝（官方中文名称来自 pkulaw-mcp-cli manifest） ───

Write-Host '>> 北大法宝 MCP 协议 — 10 个 HTTP 服务' -ForegroundColor Cyan
Write-Host '   注册: https://mcp.pkulaw.com → 开发者控制台 → 获取 Access Token' -ForegroundColor DarkGray
$usePkulaw = Read-Host '是否安装北大法宝？(Y/n)'
if ($usePkulaw -ne 'n' -and $usePkulaw -ne 'N') {
    $token = Read-Host '  请输入 Access Token（留空=使用占位符）'
    if ([string]::IsNullOrEmpty($token)) {
        $token = 'YOUR_ACCESS_TOKEN'
        Write-Host '  使用占位符，稍后手动替换' -ForegroundColor DarkYellow
    }

    $allPkulawServices = @(
        @{ name = 'pkulaw-law-search';             url = 'https://apim-gateway.pkulaw.com/mcp-law-search-service';         display = '检索法律法规-语义';      desc = '基于语义理解的法律法规检索与相关文章查找' }
        @{ name = 'pkulaw-law-keyword';             url = 'https://apim-gateway.pkulaw.com/mcp-law';                       display = '检索法律法规-关键词';    desc = '法规标题或正文关键词精确匹配检索' }
        @{ name = 'pkulaw-case-semantic-search';    url = 'https://apim-gateway.pkulaw.com/mcp-case-search-service';       display = '检索司法案例-语义';      desc = '用自然语言描述查找相关判例' }
        @{ name = 'pkulaw-case-keyword';            url = 'https://apim-gateway.pkulaw.com/mcp-case';                      display = '检索司法案例-关键词';    desc = '案例标题或正文关键词检索' }
        @{ name = 'pkulaw-law-item-keyword';        url = 'https://apim-gateway.pkulaw.com/mcp-fatiao';                    display = '精准查找法条-关键词';    desc = '通过法规名称与条号精确查询法条内容' }
        @{ name = 'pkulaw-law-recognition';         url = 'https://apim-gateway.pkulaw.com/law_recognition';               display = '法条识别与溯源';          desc = '从文本中识别法规名称与条款，返回来源链接' }
        @{ name = 'pkulaw-case-number-recognition'; url = 'https://apim-gateway.pkulaw.com/case_number_recognition';      display = '案号识别与溯源';          desc = '识别案号、标准化验证及与案例库溯源' }
        @{ name = 'pkulaw-citation-validator';      url = 'https://apim-gateway.pkulaw.com/pku_citation_validator';       display = '修正生成幻觉-法条';      desc = '分析引用并返回权威条文，修正模型引注幻觉' }
        @{ name = 'pkulaw-doc-link';                url = 'https://apim-gateway.pkulaw.com/add-doc-link';                  display = '法宝超链';                desc = '为文本智能添加法规超链接指向北大法宝文档' }
        @{ name = 'pkulaw-semantic-nlsql';          url = 'https://apim-gateway.pkulaw.com/YOUR_NL_SQL_SERVICE_ID';       display = '法宝语义检索（NL-SQL）'; desc = '自然语言在多库中语义检索（需额外购买配置）' }
    )

    Write-Host '  选择要安装的服务（多选，用逗号分隔，如 1,3,5）:' -ForegroundColor Yellow
    for ($i = 0; $i -lt $allPkulawServices.Count; $i++) {
        $svc = $allPkulawServices[$i]
        Write-Host "    [$($i+1)] $($svc.display) — $($svc.desc)" -ForegroundColor DarkGray
    }
    Write-Host "    [a] 全部安装" -ForegroundColor DarkGray
    $selection = Read-Host '  请输入'
    $selectedIndices = @()
    if ($selection -eq 'a' -or $selection -eq 'A' -or [string]::IsNullOrWhiteSpace($selection)) {
        $selectedIndices = 0..($allPkulawServices.Count - 1)
    } else {
        $selection -split ',' | ForEach-Object {
            $num = $_.Trim() -as [int]
            if ($num -ge 1 -and $num -le $allPkulawServices.Count) {
                $selectedIndices += $num - 1
            }
        }
    }
    foreach ($idx in $selectedIndices) {
        $svc = $allPkulawServices[$idx]
        $serviceUrl = $svc.url
        $pkulawBlock = @"
[mcp_servers.$($svc.name)]
url = "$serviceUrl"
http_headers = { Authorization = "Bearer $token" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
"@
        Add-McpServerToConfig -Section $svc.name -TomlBlock $pkulawBlock
    }
} else {
    Write-Host '  跳过北大法宝' -ForegroundColor DarkGray
}

# ─── 安装完成 ─────────────────────────────────────────

Write-Host ''
Write-Host '安装完成！重启 Codex Desktop 使配置生效。' -ForegroundColor Green

$config = Get-Content $ConfigPath -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
if ($config -notmatch '\[mcp_servers\.') {
    Write-Host '[警告] 未安装任何 MCP 连接器。技能仍可用，但引用将标注 [需验证]。' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '===== 后续步骤 =====' -ForegroundColor Cyan
Write-Host '1. 重启 Codex Desktop' -ForegroundColor Cyan
Write-Host '2. 运行 verify.ps1 验证配置' -ForegroundColor Cyan
if ($nodeOk -and $useChineselaw -ne 'n') {
    Write-Host "3. 编辑 config.toml（如需替换凭证）:" -ForegroundColor Cyan
    Write-Host "   notepad `$env:USERPROFILE\.codex\config.toml" -ForegroundColor Cyan
} else {
    Write-Host "3. 替换凭证后重启: notepad `$env:USERPROFILE\.codex\config.toml" -ForegroundColor Cyan
}
Write-Host ''
Write-Host '详细指南: docs/connectors.md' -ForegroundColor Cyan
