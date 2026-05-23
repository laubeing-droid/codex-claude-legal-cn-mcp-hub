#!/usr/bin/env bash
# verify.sh — Codex 中国法律 MCP 连接器验证脚本 (macOS/Linux)
set -euo pipefail

CONFIG_PATH="${HOME}/.codex/config.toml"

echo "=== Codex 中国法律 MCP 连接器 验证 ==="
echo ""

if [ ! -f "$CONFIG_PATH" ]; then
    echo "[!!] config.toml 不存在，请先运行 install.sh"
    exit 1
fi
echo "[OK] config.toml: ${CONFIG_PATH}"
echo ""

# 发现所有 MCP 服务
sections=$(grep -oP '(?<=\[mcp_servers\.)[^\]]+' "$CONFIG_PATH" 2>/dev/null | sort -u || true)
ALL_OK=true

if [ -z "$sections" ]; then
    echo "  [!!] 未找到任何 MCP 连接器配置"
    ALL_OK=false
fi

echo "MCP 连接器配置状态 ($(echo "$sections" | wc -l | tr -d ' ') 个):"
echo ""
for section in $sections; do
    if grep -qPz "\[mcp_servers\.${section}\][\s\S]*?enabled\s*=\s*true" "$CONFIG_PATH" 2>/dev/null; then
        echo "  [OK] ${section} (已启用)"
    elif grep -q "\[mcp_servers\.${section}\]" "$CONFIG_PATH" 2>/dev/null; then
        echo "  [!]  ${section} (已配置但未启用)"
        ALL_OK=false
    else
        echo "  [!!] ${section} (未配置)"
        ALL_OK=false
    fi

    # 检查占位符
    if [ "$section" = "chineselaw" ]; then
        if grep -q "CHINESELAW_API_KEY = \"YOUR_API_KEY\"" "$CONFIG_PATH" 2>/dev/null; then
            echo "         [!] API Key 仍为占位符"
            ALL_OK=false
        fi
    elif echo "$section" | grep -q "^pkulaw"; then
        if grep -q "Bearer YOUR_ACCESS_TOKEN" "$CONFIG_PATH" 2>/dev/null; then
            echo "         [!] Token 仍为占位符"
            ALL_OK=false
        fi
    fi
done

echo ""
echo "npm 包版本:"
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
    fi
done

echo ""
if command -v pkulaw-mcp &>/dev/null; then
    echo "[OK] @pkulaw/mcp-cli 已安装"
else
    echo "[!] @pkulaw/mcp-cli 未安装（可选调试工具）"
fi

echo ""
if [ "$ALL_OK" = true ]; then
    echo "✓ 验证通过。所有 MCP 连接器配置正常。"
else
    echo "⚠ 存在以下问题:"
    echo "  - 部分连接器未启用，检查 config.toml"
    echo "  - 凭证仍为占位符，替换为真实值"
    echo "  运行 update.sh 获取详细诊断。"
fi
