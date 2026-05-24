#!/usr/bin/env bash
# install.sh — 通用安装脚本：支持 Codex Desktop / Claude Code / Claude Desktop (macOS/Linux)
set -euo pipefail

MY_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${MY_DIR}/detect.sh"

has_command() {
    command -v "$1" >/dev/null 2>&1
}

echo "=== 安装中国法律 MCP 连接器 ==="
echo ""

# [1/5] 环境检测
echo "[1/5] 检测本机 MCP 客户端环境..."
ENVS=$(detect_environments)
echo "$ENVS" | python3 -c "
import json,sys
envs=json.load(sys.stdin)
for e in envs:
    print(f'  [OK] {e[\"display\"]}')
    print(f'        配置: {e[\"config\"]} ({e[\"format\"]})')
" 2>/dev/null || echo "  [OK] Codex Desktop"

# [2/5] 前置检查
echo ""
echo "[2/5] 前置检查..."
NODE_OK=true
if ! has_command node; then
    echo "  [!!] Node.js 未安装！chineselaw 需要 Node.js >= 18"
    echo "       下载: https://nodejs.org (LTS 版本)"
    NODE_OK=false
else
    NODE_VER=$(node --version)
    echo "  [OK] Node.js ${NODE_VER}"
fi

echo ""

# [3/5] chineselaw
echo "[3/5] chineselaw（元典智库）— 推荐，33 个工具"
echo "   注册: https://open.chineselaw.com → API 管理 → 创建 API Key"

INSTALL_CHINESELAW=false
API_KEY="YOUR_API_KEY"
if [ "$NODE_OK" = true ]; then
    read -r -p "是否安装 chineselaw？(Y/n): " use_chineselaw
    if [ "$use_chineselaw" != "n" ] && [ "$use_chineselaw" != "N" ]; then
        INSTALL_CHINESELAW=true
        read -r -p "  请输入 CHINESELAW_API_KEY (留空=使用占位符): " input_key
        if [ -n "$input_key" ]; then
            API_KEY="$input_key"
        else
            echo "  使用占位符，稍后手动替换"
        fi
    fi
fi

if [ "$INSTALL_CHINESELAW" = true ]; then
    echo "$ENVS" | python3 -c "
import json, subprocess, sys, os

envs = json.load(sys.stdin)
api_key = '${API_KEY}'
config_paths = set()

for e in envs:
    config_path = e['config']
    if config_path in config_paths:
        continue
    config_paths.add(config_path)
    fmt = e['format']
    display = e['display']

    if fmt == 'toml':
        toml_block = f'''
[mcp_servers.chineselaw]
command = \"npx\"
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = \"{api_key}\"
'''
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, 'a+', encoding='utf-8') as f:
            f.seek(0)
            content = f.read()
            if '[mcp_servers.chineselaw]' not in content:
                f.write('\n' + toml_block)
                print(f'  [添加] {display} -> chineselaw')
            else:
                print(f'  [跳过] {display} -> chineselaw (已存在)')
    else:
        server_config = {
            'command': 'npx',
            
            'env': {'CHINESELAW_API_KEY': api_key}
        }
        result = subprocess.run(['python3', '-c', f'''
import json, os
cp = \"\"\"{config_path}\"\"\"
sid = \"chineselaw\"
sc = json.loads(\"\"\"{json.dumps(server_config)}\"\"\")
if os.path.exists(cp):
    with open(cp, 'r', encoding='utf-8') as f:
        try: cfg = json.load(f)
        except: cfg = {{}}
else:
    cfg = {{}}
    os.makedirs(os.path.dirname(cp), exist_ok=True)
if 'mcpServers' not in cfg: cfg['mcpServers'] = {{}}
if 'env' not in cfg: cfg['env'] = {{}}
if sid in cfg['mcpServers']:
    exit(1)
cfg['mcpServers'][sid] = sc
with open(cp, 'w', encoding='utf-8') as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
exit(0)
'''], capture_output=True)
        if result.returncode == 0:
            print(f'  [添加] {display} -> chineselaw')
        else:
            print(f'  [跳过] {display} -> chineselaw (已存在)')
" 2>&1
else
    [ "$NODE_OK" = false ] && echo "  跳过 chineselaw（缺少 Node.js）" || echo "  跳过 chineselaw"
fi

echo ""

# [4/5] 北大法宝
echo "[4/5] 北大法宝 MCP 协议 — 10 个 HTTP 服务"
echo "   注册: https://mcp.pkulaw.com → 开发者控制台 → 获取 Access Token"
read -r -p "是否安装北大法宝？(Y/n): " use_pkulaw

if [ "$use_pkulaw" != "n" ] && [ "$use_pkulaw" != "N" ]; then
    TOKEN="YOUR_ACCESS_TOKEN"
    read -r -p "  请输入 Access Token (留空=使用占位符): " input_token
    [ -n "$input_token" ] && TOKEN="$input_token" || echo "  使用占位符，稍后手动替换"

    echo "  选择要安装的服务（多选，用逗号分隔，如 1,3,5；回车=全部）:"
    echo "    [1]  检索法律法规-语义 — 基于语义理解的法律法规检索与相关文章查找"
    echo "    [2]  检索法律法规-关键词 — 法规标题或正文关键词精确匹配检索"
    echo "    [3]  检索司法案例-语义 — 用自然语言描述查找相关判例"
    echo "    [4]  检索司法案例-关键词 — 案例标题或正文关键词检索"
    echo "    [5]  精准查找法条-关键词 — 通过法规名称与条号精确查询法条内容"
    echo "    [6]  法条识别与溯源 — 从文本中识别法规名称与条款，返回来源链接"
    echo "    [7]  案号识别与溯源 — 识别案号、标准化验证及与案例库溯源"
    echo "    [8]  修正生成幻觉-法条 — 分析引用并返回权威条文，修正模型引注幻觉"
    echo "    [9]  法宝超链 — 为文本智能添加法规超链接指向北大法宝文档"
    echo "    [10] 法宝语义检索（NL-SQL） — 自然语言在多库中语义检索（需额外购买配置）"
    echo "    [a]  全部安装"
    read -r -p "  请输入: " selection

    # PKU services array
    SERVICES=(
        "pkulaw-law-search|https://apim-gateway.pkulaw.com/mcp-law-search-service"
        "pkulaw-law-keyword|https://apim-gateway.pkulaw.com/mcp-law"
        "pkulaw-case-semantic-search|https://apim-gateway.pkulaw.com/mcp-case-search-service"
        "pkulaw-case-keyword|https://apim-gateway.pkulaw.com/mcp-case"
        "pkulaw-law-item-keyword|https://apim-gateway.pkulaw.com/mcp-fatiao"
        "pkulaw-law-recognition|https://apim-gateway.pkulaw.com/law_recognition"
        "pkulaw-case-number-recognition|https://apim-gateway.pkulaw.com/case_number_recognition"
        "pkulaw-citation-validator|https://apim-gateway.pkulaw.com/pku_citation_validator"
        "pkulaw-doc-link|https://apim-gateway.pkulaw.com/add-doc-link"
        "pkulaw-semantic-nlsql|https://apim-gateway.pkulaw.com/YOUR_NL_SQL_SERVICE_ID"
    )

    is_selected() {
        local n="$1"
        [ -z "$selection" ] || [ "$selection" = "a" ] || [ "$selection" = "A" ] && return 0
        echo "$selection" | tr ',' '\n' | while read -r item; do
            [ "$(echo "$item" | tr -d ' ')" = "$n" ] && return 0
        done
        return 1
    }

    for i in "${!SERVICES[@]}"; do
        idx=$((i + 1))
        is_selected "$idx" || continue

        IFS='|' read -r svc_name svc_url <<< "${SERVICES[$i]}"

        # 写入所有环境
        echo "$ENVS" | python3 -c "
import json, sys, os

envs = json.load(sys.stdin)
svc_name = '${svc_name}'
svc_url = '${svc_url}'
token = '${TOKEN}'
config_paths = set()

for e in envs:
    cp = e['config']
    if cp in config_paths:
        continue
    config_paths.add(cp)
    display = e['display']

    if e['format'] == 'toml':
        toml_block = f'''
[mcp_servers.{svc_name}]
url = \"{svc_url}\"
http_headers = {{ Authorization = \"Bearer {token}\" }}
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
'''
        os.makedirs(os.path.dirname(cp), exist_ok=True)
        with open(cp, 'a+', encoding='utf-8') as f:
            f.seek(0)
            content = f.read()
            if f'[mcp_servers.{svc_name}]' not in content:
                f.write('\n' + toml_block)
                print(f'  [添加] {display} -> {svc_name}')
    else:
        server_config = {
            'url': svc_url,
            'headers': {'Authorization': f'Bearer {token}'}
        }
        cfg = {{}}
        if os.path.exists(cp):
            with open(cp, 'r', encoding='utf-8') as f:
                try: cfg = json.load(f)
                except: cfg = {{}}
        else:
            os.makedirs(os.path.dirname(cp), exist_ok=True)
        if 'mcpServers' not in cfg: cfg['mcpServers'] = {{}}
        if 'env' not in cfg: cfg['env'] = {{}}
        if svc_name not in cfg['mcpServers']:
            cfg['mcpServers'][svc_name] = server_config
            with open(cp, 'w', encoding='utf-8') as f:
                json.dump(cfg, f, ensure_ascii=False, indent=2)
            print(f'  [添加] {display} -> {svc_name}')
" 2>&1
    done
else
    echo "  跳过北大法宝"
fi

echo ""
echo "安装完成！重启 MCP 客户端使配置生效。"
echo ""
echo "===== 后续步骤 ====="
echo "1. 重启对应的 MCP 客户端"
echo "2. 运行 ./verify.sh 验证配置"
echo "3. (如需替换凭证) 修改上述配置文件中的占位符"
echo ""
echo "详细指南: docs/connectors.md"
