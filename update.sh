#!/usr/bin/env bash
# update.sh — 通用更新脚本：自更新 + 全环境 MCP 诊断 (macOS/Linux)
set -euo pipefail

MY_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${MY_DIR}/detect.sh"

echo "=== 更新中国法律 MCP 连接器 ==="
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
for pkg in "@pkulaw/mcp-cli"; do
    latest=$(curl -s "https://registry.npmjs.org/${pkg}/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version','unknown'))" 2>/dev/null || echo "unknown")
    local_ver=$(npx "${pkg}" --version 2>/dev/null || echo "未安装")
    if [ "$local_ver" = "未安装" ]; then
        echo "  [!]  ${pkg} latest=${latest} (未安装)"
    elif [ "$local_ver" = "$latest" ]; then
        echo "  [OK] ${pkg} v${latest} (已最新)"
    else
        echo "  [!!] ${pkg} local=${local_ver} → latest=${latest}"
    fi
done

# [3/5] 全环境 MCP 配置检查
echo ""
echo "[3/5] 检查各环境 MCP 配置状态..."
ENVS=$(detect_environments)
echo "$ENVS" | python3 -c "
import json, sys, os, re
envs = json.load(sys.stdin)
for e in envs:
    cp = e['config']
    display = e['display']
    print(f'  >>> {display}')
    print(f'      配置: {cp}')
    if not os.path.exists(cp):
        print(f'  [!!] 配置文件不存在')
        continue
    if e['format'] == 'toml':
        with open(cp, 'r', encoding='utf-8') as f:
            content = f.read()
        sections = re.findall(r'\\[mcp_servers\\.([^\\]]+)\\]', content)
        for s in sorted(set(sections)):
            print(f'  [OK] {s} (已配置)')
    else:
        try:
            with open(cp, 'r', encoding='utf-8') as f:
                cfg = json.load(f)
            for name in cfg.get('mcpServers', {}):
                print(f'  [OK] {name} (已配置)')
        except:
            print(f'  [!!] 配置文件格式错误')
"

# [4/5] 凭证检测
echo ""
echo "[4/5] 检测凭证状态..."
echo "$ENVS" | python3 -c "
import json, sys, os
envs = json.load(sys.stdin)
cred_issues = False
for e in envs:
    cp = e['config']
    if not os.path.exists(cp):
        continue
    with open(cp, 'r', encoding='utf-8') as f:
        content = f.read()
    if e['format'] == 'toml':
        if 'CHINESELAW_API_KEY = \"YOUR_API_KEY\"' in content:
            print(f'  [!!] {e[\"display\"]}: chineselaw API Key 仍为占位符')
            cred_issues = True
        if 'Bearer YOUR_ACCESS_TOKEN' in content:
            print(f'  [!!] {e[\"display\"]}: 北大法宝 Token 仍为占位符')
            cred_issues = True
    else:
        try:
            cfg = json.loads(content)
            for name, svc in cfg.get('mcpServers', {}).items():
                env_vars = svc.get('env', {})
                if env_vars.get('CHINESELAW_API_KEY') == 'YOUR_API_KEY':
                    print(f'  [!!] {e[\"display\"]}: chineselaw API Key 仍为占位符')
                    cred_issues = True
                auth = svc.get('headers', {}).get('Authorization', '')
                if 'Bearer YOUR_ACCESS_TOKEN' in auth:
                    print(f'  [!!] {e[\"display\"]}: 北大法宝 Token 仍为占位符')
                    cred_issues = True
        except:
            pass
if not cred_issues:
    print('  凭证状态正常')
"

# [5/5] 汇总
echo ""
echo "[5/5] 汇总"
echo "$ENVS" | python3 -c "
import json, sys
envs = json.load(sys.stdin)
for e in envs:
    print(f'  {e[\"display\"]}: {e[\"config\"]}')
"

echo ""
echo "更新完成。重启 MCP 客户端使新内容生效。"
