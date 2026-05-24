<#
.SYNOPSIS
  通用安装脚本：支持 Codex Desktop / Claude Code / Claude Desktop
.DESCRIPTION
  自动检测本机安装的所有 MCP 客户端环境，将中国法律 MCP 连接器
  写入每个环境的配置文件中（TOML 或 JSON 格式自动适配）。
  支持交互式输入凭证、选择服务、检测前置依赖。
  支持的连接器：
    - 元典智库（Streamable HTTP MCP）
    - 飞书（LarkSuite 官方 MCP）
    - 北大法宝（HTTP 服务 + npm CLI 调试工具）
#>

$ErrorActionPreference = 'Stop'
$MyDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── 加载检测模块 ──────────────────────────────────────
. "$MyDir\detect.ps1"

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host '=== 安装中国法律 MCP 连接器 ===' -ForegroundColor Green
Write-Host ''

# ─── 1. 环境检测 ──────────────────────────────────────
Write-Host '[1/8] 检测本机 MCP 客户端环境...' -ForegroundColor Yellow
$envs = Get-EnvironmentInfo
$activeEnvs = $envs | Where-Object { $_.Installed }
if ($activeEnvs.Count -eq 0) {
    Write-Host '  未检测到已安装的 MCP 客户端环境。' -ForegroundColor Yellow
    Write-Host '  将至少为 Codex Desktop 创建配置。' -ForegroundColor DarkGray
    $codexFallback = @{
        Name = 'codex'; Display = 'Codex Desktop'
        ConfigPath = "$env:USERPROFILE\.codex\config.toml"
        Format = 'toml'; Installed = $true; McpSection = 'mcp_servers'
    }
    $activeEnvs = @($codexFallback)
}
foreach ($e in $activeEnvs) {
    $icon = if ($e.Installed) { '[OK]' } else { '[!]' }
    Write-Host "  $icon $($e.Display)" -ForegroundColor $(if ($e.Installed) { 'Green' } else { 'DarkGray' })
    Write-Host "        配置: $($e.ConfigPath) ($($e.Format))" -ForegroundColor DarkGray
}

# ─── 2. 前置检查 ──────────────────────────────────────
Write-Host ''
Write-Host '[2/8] 前置检查...' -ForegroundColor Yellow
$nodeOk = $true
if (-not (Test-Command 'node')) {
    Write-Host '  [!!] Node.js 未安装！飞书 / pkulaw 需要 Node.js >= 18' -ForegroundColor Red
    Write-Host '       下载: https://nodejs.org (LTS 版本)' -ForegroundColor Cyan
    $nodeOk = $false
} else {
    $nodeVer = & node --version
    Write-Host "  [OK] Node.js $nodeVer" -ForegroundColor Green
}

Write-Host ''

# ─── 3. 元典智库（chineselaw）─────────────────────────
Write-Host '[3/8] 元典智库 — 中国法律检索（36 API + 33 MCP 工具）' -ForegroundColor Cyan
Write-Host '   注册: https://open.chineselaw.com → API 管理 → 创建 API Key' -ForegroundColor DarkGray
Write-Host '   官方文档: https://open.chineselaw.com/llms-full.txt' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  接入方式:' -ForegroundColor Yellow
Write-Host '    [1] Streamable HTTP MCP（官方推荐，3 个细分 Server）' -ForegroundColor Cyan
Write-Host '    [3] 跳过' -ForegroundColor DarkGray
$mode = Read-Host '  请选择 (默认 1)'
if ([string]::IsNullOrWhiteSpace($mode)) { $mode = '1' }

$installYuandian = $mode -ne '3'
$yuandianApiKey = 'YOUR_API_KEY'

if ($installYuandian) {
    $input = Read-Host '  请输入 API Key（留空=使用占位符）'
    if (-not [string]::IsNullOrEmpty($input)) { $yuandianApiKey = $input }
    else { Write-Host '  使用占位符，稍后手动替换' -ForegroundColor DarkYellow }

    if ($mode -eq '1') {
        # ── 方式 A: Streamable HTTP ──
        Write-Host '  安装元典 HTTP MCP（3 个 Server）...' -ForegroundColor DarkGray
        $servers = Get-YuandianHttpConfig -ApiKey $yuandianApiKey
        foreach ($svc in $servers) {
            foreach ($e in $activeEnvs) {
                if ($e.Format -eq 'toml') {
                    $tomlBlock = Get-YuandianHttpToml -Name $svc.name -Url $svc.url -ApiKey $yuandianApiKey
                    $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section $svc.name -TomlBlock $tomlBlock
                } else {
                    $svcConfig = Get-YuandianHttpJson -Name $svc.name -Url $svc.url -ApiKey $yuandianApiKey
                    $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId $svc.name -ServerConfig $svcConfig
                }
                if ($added) { Write-Host "  [添加] $($e.Display) -> $($svc.name) ($($svc.display))" -ForegroundColor Green }
                else { Write-Host "  [跳过] $($e.Display) -> $($svc.name)（已存在）" -ForegroundColor DarkYellow }
            }
        }
        # 同时保存 API Key 到环境变量（供 REST API 使用）
        [Environment]::SetEnvironmentVariable('YUANDIAN_API_KEY', $yuandianApiKey, 'User')
        Write-Host '  [完成] 环境变量 YUANDIAN_API_KEY 已保存（用于 REST API 直调）' -ForegroundColor DarkGray

        }
} else {
    Write-Host '  跳过元典智库' -ForegroundColor DarkGray
}

Write-Host ''

# ─── 4. 国家法律法规数据库 MCP ──────────────────────
Write-Host '[4/8] 国家法律法规数据库 MCP（免费，无需认证）' -ForegroundColor Cyan
Write-Host '   数据源: https://flk.npc.gov.cn（全国人大常委会办公厅主办）' -ForegroundColor DarkGray
Write-Host '   端口: localhost:18062，Python 自建 MCP Server' -ForegroundColor DarkGray
Write-Host '   工具: 法规搜索/详情/命中展示/高级检索/相关推荐/下载等 11 个' -ForegroundColor DarkGray

$installFlk = (Read-Host '是否安装国家法律法规数据库 MCP？(Y/n)') -ne 'n'

if ($installFlk) {
    $pyOk = Test-Command 'python'
    if (-not $pyOk) {
        Write-Host '  [!!] Python 未安装！请先安装 Python 3.x' -ForegroundColor Red
        Write-Host '       下载: https://www.python.org/downloads/' -ForegroundColor Cyan
    } else {
        Write-Host '  安装 Python 依赖...' -ForegroundColor DarkGray
        $pipDir = "$MyDir\servers\flk-npc"
        try {
            & pip install -r "$pipDir\requirements.txt" 2>&1 | Out-Null
            Write-Host '  [OK] 依赖安装完成' -ForegroundColor Green
        } catch {
            Write-Host '  [!] pip 安装失败：可手动运行 pip install -r servers/flk-npc/requirements.txt' -ForegroundColor Yellow
        }

        foreach ($e in $activeEnvs) {
            if ($e.Format -eq 'toml') {
                $tomlBlock = Get-SelfHostedFlkNpcToml
                $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section 'flk-npc' -TomlBlock $tomlBlock
            } else {
                $svcConfig = Get-SelfHostedFlkNpcConfig
                $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId 'flk-npc' -ServerConfig $svcConfig
            }
            Write-Host "  $($(if ($added) { '[添加]' } else { '[跳过]' })) $($e.Display) -> flk-npc（国家法律法规数据库）" -ForegroundColor $(if ($added) { 'Green' } else { 'DarkYellow' })
        }
        Write-Host '  [提示] 运行 servers/flk-npc/start.bat 启动服务，或直接 python servers/flk-npc/scripts/server.py' -ForegroundColor DarkGray
    }
} else {
    Write-Host '  跳过国家法律法规数据库 MCP' -ForegroundColor DarkGray
}

Write-Host ''

# ─── 5. 人民法院案例库 MCP ──────────────────────────
Write-Host '[5/8] 人民法院案例库 MCP（需登录 Token）' -ForegroundColor Cyan
Write-Host '   数据源: https://rmfyalk.court.gov.cn（最高人民法院主办）' -ForegroundColor DarkGray
Write-Host '   端口: localhost:18061，Python 自建 MCP Server' -ForegroundColor DarkGray
Write-Host '   工具: 案例搜索/详情/聚类统计/分类枚举/导出等 7 个' -ForegroundColor DarkGray
Write-Host '   Token: 登录 rmfyalk.court.gov.cn → F12 → Application → Cookies → faxin-cpws-al-token' -ForegroundColor DarkGray

$installRmfyalk = (Read-Host '是否安装人民法院案例库 MCP？(y/N)') -eq 'y'
$rmfyalkToken = ''

if ($installRmfyalk) {
    $pyOk = Test-Command 'python'
    if (-not $pyOk) {
        Write-Host '  [!!] Python 未安装！请先安装 Python 3.x' -ForegroundColor Red
    } else {
        Write-Host '  安装 Python 依赖...' -ForegroundColor DarkGray
        $pipDir = "$MyDir\servers\rmfyalk"
        try {
            & pip install -r "$pipDir\requirements.txt" 2>&1 | Out-Null
            Write-Host '  [OK] 依赖安装完成' -ForegroundColor Green
        } catch {
            Write-Host '  [!] pip 安装失败：可手动运行 pip install -r servers/rmfyalk/requirements.txt' -ForegroundColor Yellow
        }

        $input = Read-Host '  请输入 Cookie Token（留空=稍后通过 MCP 工具设置）'
        if (-not [string]::IsNullOrEmpty($input)) { $rmfyalkToken = $input }

        foreach ($e in $activeEnvs) {
            if ($e.Format -eq 'toml') {
                $tomlBlock = Get-SelfHostedRmfyalkToml -Token $rmfyalkToken
                $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section 'rmfyalk' -TomlBlock $tomlBlock
            } else {
                $svcConfig = Get-SelfHostedRmfyalkConfig -Token $rmfyalkToken
                $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId 'rmfyalk' -ServerConfig $svcConfig
            }
            Write-Host "  $($(if ($added) { '[添加]' } else { '[跳过]' })) $($e.Display) -> rmfyalk（人民法院案例库）" -ForegroundColor $(if ($added) { 'Green' } else { 'DarkYellow' })
        }
        Write-Host '  [提示] 运行 servers/rmfyalk/start.bat 启动服务' -ForegroundColor DarkGray
        Write-Host '  [提示] 启动后通过 rmfyalk_set_token 工具设置/更新 Token（4h 过期）' -ForegroundColor DarkGray
    }
} else {
    Write-Host '  跳过人民法院案例库 MCP' -ForegroundColor DarkGray
}

Write-Host ''

# ─── 4. 飞书（LarkSuite）────────────────────────────
Write-Host '[6/8] 飞书（LarkSuite MCP）— 文档/消息/日历/通讯录' -ForegroundColor Cyan
Write-Host '   前提: 在 https://open.feishu.cn/app 创建企业自建应用' -ForegroundColor DarkGray
Write-Host '        → 获取 App ID 和 App Secret' -ForegroundColor DarkGray
Write-Host '   包名: @larksuiteoapi/lark-mcp（飞书官方）' -ForegroundColor DarkGray

$installFeishu = (Read-Host '是否安装飞书 MCP？(y/N)') -eq 'y'
$appId = 'YOUR_APP_ID'
$appSecret = 'YOUR_APP_SECRET'

if ($installFeishu) {
    if (-not $nodeOk) {
        Write-Host '  [!!] 需要 Node.js，跳过飞书安装' -ForegroundColor Red
    } else {
        $input = Read-Host '  请输入 App ID（留空=使用占位符）'
        if (-not [string]::IsNullOrEmpty($input)) { $appId = $input }
        $input = Read-Host '  请输入 App Secret（留空=使用占位符）'
        if (-not [string]::IsNullOrEmpty($input)) { $appSecret = $input }

        foreach ($e in $activeEnvs) {
            if ($e.Format -eq 'toml') {
                $tomlBlock = Get-FeishuToml -AppId $appId -AppSecret $appSecret
                $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section 'feishu' -TomlBlock $tomlBlock
            } else {
                $svcConfig = Get-FeishuConfig -AppId $appId -AppSecret $appSecret
                $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId 'feishu' -ServerConfig $svcConfig
            }
            Write-Host "  $($(if ($added) { '[添加]' } else { '[跳过]' })) $($e.Display) -> feishu" -ForegroundColor $(if ($added) { 'Green' } else { 'DarkYellow' })
        }
    }
} else {
    Write-Host '  跳过飞书 MCP' -ForegroundColor DarkGray
}

Write-Host ''

# ─── 5. 北大法宝（pkulaw）───────────────────────────
Write-Host '[7/8] 北大法宝 MCP 协议 — 10 个 HTTP 服务' -ForegroundColor Cyan
Write-Host '   注册: https://mcp.pkulaw.com → 开发者控制台 → 获取 Access Token' -ForegroundColor DarkGray
Write-Host '   调试 CLI: npm install -g @pkulaw/mcp-cli（北大法宝官方 CLI）' -ForegroundColor DarkGray

$installPkulaw = (Read-Host '是否安装北大法宝？(Y/n)') -ne 'n'
$token = 'YOUR_ACCESS_TOKEN'
if ($installPkulaw) {
    $input = Read-Host '  请输入 Access Token（留空=使用占位符）'
    if (-not [string]::IsNullOrEmpty($input)) { $token = $input }
    else { Write-Host '  使用占位符，稍后手动替换' -ForegroundColor DarkYellow }

    $allPkulawServices = @(
        @{ name = 'pkulaw-law-search';             url = 'https://apim-gateway.pkulaw.com/mcp-law-search-service/mcp';    display = '检索法律法规-语义';      desc = '基于语义理解的法律法规检索与相关文章查找' }
        @{ name = 'pkulaw-law-keyword';             url = 'https://apim-gateway.pkulaw.com/mcp-law/mcp';                   display = '检索法律法规-关键词';    desc = '法规标题或正文关键词精确匹配检索' }
        @{ name = 'pkulaw-case-semantic-search';    url = 'https://apim-gateway.pkulaw.com/mcp-case-search-service/mcp';  display = '检索司法案例-语义';      desc = '用自然语言描述查找相关判例' }
        @{ name = 'pkulaw-case-keyword';            url = 'https://apim-gateway.pkulaw.com/mcp-case/mcp';                  display = '检索司法案例-关键词';    desc = '案例标题或正文关键词检索' }
        @{ name = 'pkulaw-law-item-keyword';        url = 'https://apim-gateway.pkulaw.com/mcp-fatiao/mcp';                display = '精准查找法条-关键词';    desc = '通过法规名称与条号精确查询法条内容' }
        @{ name = 'pkulaw-law-recognition';         url = 'https://apim-gateway.pkulaw.com/law_recognition/mcp';           display = '法条识别与溯源';          desc = '从文本中识别法规名称与条款，返回来源链接' }
        @{ name = 'pkulaw-case-number-recognition'; url = 'https://apim-gateway.pkulaw.com/case_number_recognition/mcp';  display = '案号识别与溯源';          desc = '识别案号、标准化验证及与案例库溯源' }
        @{ name = 'pkulaw-citation-validator';      url = 'https://apim-gateway.pkulaw.com/pku_citation_validator/mcp';   display = '修正生成幻觉-法条';      desc = '分析引用并返回权威条文，修正模型引注幻觉' }
        @{ name = 'pkulaw-doc-link';                url = 'https://apim-gateway.pkulaw.com/add-doc-link/mcp';              display = '法宝超链';                desc = '为文本智能添加法规超链接指向北大法宝文档' }
        @{ name = 'pkulaw-semantic-nlsql';          url = 'https://apim-gateway.pkulaw.com/assistant/mcp-pkulaw-search/mcp'; display = '法宝语义检索（NL-SQL）'; desc = '自然语言在多库中语义检索（需额外购买配置）' }
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
        foreach ($e in $activeEnvs) {
            if ($e.Format -eq 'toml') {
                $tomlBlock = @"
[mcp_servers.$($svc.name)]
url = "$($svc.url)"
http_headers = { Authorization = "Bearer $token" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
"@
                $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section $svc.name -TomlBlock $tomlBlock
            } else {
                $svcConfig = Get-PkulawHttpConfig -Url $svc.url -Token $token
                $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId $svc.name -ServerConfig $svcConfig
            }
            if ($added) {
                Write-Host "  [添加] $($e.Display) -> $($svc.name)" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host '  跳过北大法宝' -ForegroundColor DarkGray
}

# ─── 6. 完成 ─────────────────────────────────────────
Write-Host ''
Write-Host '[8/8] 安装完成！' -ForegroundColor Yellow
Write-Host ''
Write-Host '已配置的 MCP 客户端环境:' -ForegroundColor Cyan
foreach ($e in $activeEnvs) {
    Write-Host "  - $($e.Display): $($e.ConfigPath)" -ForegroundColor Cyan
}
Write-Host ''
Write-Host '===== 后续步骤 =====' -ForegroundColor Cyan
Write-Host '1. 重启对应的 MCP 客户端' -ForegroundColor Cyan
Write-Host '2. 运行 verify.ps1 验证配置' -ForegroundColor Cyan
Write-Host '3. (如需替换凭证) 修改上述配置文件中的占位符' -ForegroundColor Cyan
Write-Host ''
Write-Host '元典智库注册: https://open.chineselaw.com' -ForegroundColor Cyan
Write-Host '  REST API: https://open.chineselaw.com/open/{routeKey} (X-API-Key)' -ForegroundColor DarkGray
Write-Host '  HTTP MCP: https://open.chineselaw.com/mcp/{law,case,company}/stream (Bearer)' -ForegroundColor DarkGray
Write-Host '飞书开通:   https://open.feishu.cn/app' -ForegroundColor Cyan
Write-Host '  MCP 包:   @larksuiteoapi/lark-mcp' -ForegroundColor DarkGray
Write-Host '北大法宝注册: https://mcp.pkulaw.com' -ForegroundColor Cyan
Write-Host '  调试 CLI:  npm install -g @pkulaw/mcp-cli' -ForegroundColor DarkGray
Write-Host '详细指南:   docs/connectors.md' -ForegroundColor Cyan






