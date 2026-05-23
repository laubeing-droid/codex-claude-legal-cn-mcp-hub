#!/usr/bin/env bash
# update.sh — 更新并验证 Codex 中国法律 MCP 连接器 (macOS/Linux)
set -euo pipefail

CONFIG_PATH="${HOME}/.codex/config.toml"
MY_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 更新 Codex 中国法律 MCP 连接器 ==="
echo ""

# [1/5] 自更新
echo "[1/5] 自更新..."
cd "$MY_DIR"
if git pull 2>&1 | grep -q "Already up to date"; then
    echo "  [OK] 已是最新"
elif git pull 2>&1 | grep -q "Updating"; then
    echo "  [OK] 已更新至最新版本"
else
    echo "  [!]  git pull 失败（非 git 目录或网络问题）"
fi

# [2/5] npm 包版本检查
echo ""
echo "[2/5] 检查 npm 包版本..."
for pkg in "chineselaw-mcp" "@pkulaw/mcp-cli"; do
    latest=$(curl -s "https://registry.npmjs.org/${pkg}/latest" 2>/dev/null | grep -oP '"version"\s*:\s*"\K[^"]+' || echo "unknown")
    if command -v npx &>/dev/null; then
        local_ver=$(npx "${pkg}" --version 2>/dev/null || echo "未安装")
    else
        local_ver="未安装"
    fi
    if [ "$local_ver" = "未安装" ]; then
        echo "  [!]  ${pkg} latest=${latest} (未安装)"
    elif [ "$local_ver" = "$latest" ]; then
        echo "  [OK] ${pkg} v${latest} (已最新)"
    else
        echo "  [!!] ${pkg} local=${local_ver} → latest=${latest}"
        echo "       更新: npm install -g ${pkg}"
    fi
done

# [3/5] MCP 配置状态检查
echo ""
echo "[3/5] 检查 MCP 配置状态..."
if [ ! -f "$CONFIG_PATH" ]; then
    echo "  [!!] config.toml 不存在，请先运行 install.sh"
    exit 1
fi
sections=$(grep -oP '(?<=\[mcp_servers\.)[^\]]+' "$CONFIG_PATH" 2>/dev/null | sort -u || true)
if [ -z "$sections" ]; then
    echo "  [!!] 未找到任何 MCP 连接器配置"
else
    for section in $sections; do
        if grep -qPz "\[mcp_servers\.${section}\][\s\S]*?enabled\s*=\s*true" "$CONFIG_PATH" 2>/dev/null; then
            echo "  [OK] ${section} (已启用)"
        else
            echo "  [!]  ${section} (已配置但未启用)"
        fi
    done
fi

# [4/5] 凭证检测
echo ""
echo "[4/5] 检测凭证状态..."
CRED_ISSUES=false
if grep -q "CHINESELAW_API_KEY = \"YOUR_API_KEY\"" "$CONFIG_PATH" 2>/dev/null; then
    echo "  [!!] chineselaw: API Key 仍为占位符"
    echo "       注册: https://open.chineselaw.com"
    CRED_ISSUES=true
else
    echo "  [OK] chineselaw: API Key 已配置"
fi
if grep -q "Bearer YOUR_ACCESS_TOKEN" "$CONFIG_PATH" 2>/dev/null; then
    echo "  [!!] 北大法宝: Access Token 仍为占位符"
    echo "       注册: https://mcp.pkulaw.com → 开发者控制台"
    CRED_ISSUES=true
else
    echo "  [OK] 北大法宝: Access Token 已配置"
    if command -v pkulaw-mcp &>/dev/null; then
        echo "  正在验证 Token 有效性..."
        timeout 15 pkulaw-mcp update 2>/dev/null && echo "  [OK] Token 有效" || echo "  [!]  Token 可能已过期，请重新生成"
    fi
fi

# [5/5] 调试工具检测
echo ""
echo "[5/5] 检测调试工具..."
if command -v pkulaw-mcp &>/dev/null; then
    echo "  [OK] @pkulaw/mcp-cli 已安装"
else
    echo "  [!]  @pkulaw/mcp-cli 未安装（可选）"
fi

echo ""
echo "===== 汇总 ====="
echo "  配置路径: ${CONFIG_PATH}"
echo ""
echo "更新完成。"
