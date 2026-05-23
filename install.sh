#!/usr/bin/env bash
# install.sh — Codex 中国法律 MCP 连接器安装脚本 (macOS/Linux)
set -euo pipefail

CONFIG_PATH="${HOME}/.codex/config.toml"
CODEC_DIR="$(dirname "${CONFIG_PATH}")"

echo "=== 安装 Codex 中国法律 MCP 连接器 ==="
echo ""

# ─── 辅助函数 ──────────────────────────────────────────

add_mcp_server() {
    local section="$1"
    local toml_block="$2"
    if [ ! -f "$CONFIG_PATH" ]; then
        mkdir -p "$(dirname "$CONFIG_PATH")"
        touch "$CONFIG_PATH"
    fi
    if grep -q "\[mcp_servers\.${section}\]" "$CONFIG_PATH" 2>/dev/null; then
        echo "  [跳过] ${section} (已存在)"
        return 1
    fi
    echo "" >> "$CONFIG_PATH"
    echo "$toml_block" >> "$CONFIG_PATH"
    echo "  [添加] ${section}"
    return 0
}

has_command() {
    command -v "$1" >/dev/null 2>&1
}

# ─── 前置检查 ──────────────────────────────────────────

echo "前置检查..."
NODE_OK=true
if ! has_command node; then
    echo "  [!!] Node.js 未安装！chineselaw 需要 Node.js >= 18"
    echo "       下载: https://nodejs.org (LTS 版本)"
    NODE_OK=false
else
    NODE_VER=$(node --version)
    echo "  [OK] Node.js ${NODE_VER}"
fi

mkdir -p "$CODEC_DIR"
echo ""

# ─── chineselaw ────────────────────────────────────────

if [ "$NODE_OK" = true ]; then
    echo ">> chineselaw（元典智库）— 推荐，33 个工具"
    echo "   注册: https://open.chineselaw.com → API 管理 → 创建 API Key"
    read -r -p "是否安装 chineselaw？(Y/n): " use_chineselaw
    if [ "$use_chineselaw" != "n" ] && [ "$use_chineselaw" != "N" ]; then
        read -r -p "  请输入 CHINESELAW_API_KEY (留空=使用占位符): " api_key
        if [ -z "$api_key" ]; then
            api_key="YOUR_API_KEY"
            echo "  使用占位符，稍后手动替换"
        fi
        add_mcp_server "chineselaw" "$(cat <<-EOF
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "${api_key}"
EOF
)"
    else
        echo "  跳过 chineselaw"
    fi
else
    echo ">> 跳过 chineselaw（缺少 Node.js）"
fi

echo ""

# ─── 北大法宝 ─────────────────────────────────────────

echo ">> 北大法宝 MCP 协议 — 10 个 HTTP 服务"
echo "   注册: https://mcp.pkulaw.com → 开发者控制台 → 获取 Access Token"
read -r -p "是否安装北大法宝？(Y/n): " use_pkulaw
if [ "$use_pkulaw" != "n" ] && [ "$use_pkulaw" != "N" ]; then
    read -r -p "  请输入 Access Token (留空=使用占位符): " token
    if [ -z "$token" ]; then
        token="YOUR_ACCESS_TOKEN"
        echo "  使用占位符，稍后手动替换"
    fi

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

    # 辅助函数：检查某个编号是否被选中
    is_selected() {
        local n="$1"
        if [ -z "$selection" ] || [ "$selection" = "a" ] || [ "$selection" = "A" ]; then
            return 0
        fi
        echo "$selection" | tr ',' '\n' | while read -r item; do
            item=$(echo "$item" | tr -d ' ')
            if [ "$item" = "$n" ]; then
                return 0
            fi
        done
        return 1
    }

    # 逐个添加选中的服务
    if is_selected "1"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-law-search]
url = "https://apim-gateway.pkulaw.com/mcp-law-search-service"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-law-search"
    fi

    if is_selected "2"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-law-keyword]
url = "https://apim-gateway.pkulaw.com/mcp-law"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-law-keyword"
    fi

    if is_selected "3"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-case-semantic-search]
url = "https://apim-gateway.pkulaw.com/mcp-case-search-service"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-case-semantic-search"
    fi

    if is_selected "4"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-case-keyword]
url = "https://apim-gateway.pkulaw.com/mcp-case"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-case-keyword"
    fi

    if is_selected "5"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-law-item-keyword]
url = "https://apim-gateway.pkulaw.com/mcp-fatiao"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-law-item-keyword"
    fi

    if is_selected "6"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-law-recognition]
url = "https://apim-gateway.pkulaw.com/law_recognition"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-law-recognition"
    fi

    if is_selected "7"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-case-number-recognition]
url = "https://apim-gateway.pkulaw.com/case_number_recognition"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-case-number-recognition"
    fi

    if is_selected "8"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-citation-validator]
url = "https://apim-gateway.pkulaw.com/pku_citation_validator"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-citation-validator"
    fi

    if is_selected "9"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-doc-link]
url = "https://apim-gateway.pkulaw.com/add-doc-link"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-doc-link"
    fi

    if is_selected "10"; then
    cat <<-EOF >> "$CONFIG_PATH"

[mcp_servers.pkulaw-semantic-nlsql]
url = "https://apim-gateway.pkulaw.com/YOUR_NL_SQL_SERVICE_ID"
http_headers = { Authorization = "Bearer ${token}" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
EOF
    echo "  [添加] pkulaw-semantic-nlsql"
    fi

else
    echo "  跳过北大法宝"
fi

echo ""
echo "安装完成！重启 Codex Desktop 使配置生效。"
echo ""
echo "===== 后续步骤 ====="
echo "1. 重启 Codex Desktop"
echo "2. 运行 ./verify.sh 验证配置"
echo "3. (如需替换凭证) 编辑 ${CONFIG_PATH}"
echo ""
echo "详细指南: docs/connectors.md"
