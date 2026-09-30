#!/usr/bin/env bash
# .githooks/pre-commit — 提交前隐私信息泄漏检查（模板）
# 检查 staged 内容中的绝对路径、本机 IP、用户名、邮箱等敏感信息
# 注意：钩子自身保持"零隐私字符串"——模式全部外置到 gitignored 的 .privacy-patterns
# 安装：git config core.hooksPath .githooks
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "🔍 检查隐私信息泄漏..."

# 获取 staged 文件列表（排除删除的文件）
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMRT)
[ -z "$STAGED_FILES" ] && exit 0

# 隐私模式从 gitignored 的 .privacy-patterns 读取（每行一个扩展正则）。
# fail-closed：模式文件缺失或为空一律阻断提交 —— 校验不通过就拒绝，不做"宽松通过"
# （对应 AGENTS.md §九 安全隐私红线的 fail-closed 原则）。
# 确需临时放行时走授权绕过流程（见文末提示），不得靠"删掉模式文件"绕过。
PATTERNS_FILE=".privacy-patterns"
if [ ! -f "$PATTERNS_FILE" ]; then
  echo -e "${RED}✗ 提交已阻止：未找到 $PATTERNS_FILE${NC}"
  echo "  该文件存放本单位的隐私扫描模式，属于不入库配置，必须本地存在。"
  echo "  处理方式："
  echo "    cp templates/privacy-patterns.example $PATTERNS_FILE"
  echo "    # 然后按本单位实际情况增删模式（该文件已被 .gitignore 忽略）"
  exit 1
fi
mapfile -t PRIVACY_PATTERNS < <(grep -vE '^\s*(#|$)' "$PATTERNS_FILE" || true)
if [ "${#PRIVACY_PATTERNS[@]}" -eq 0 ]; then
  echo -e "${RED}✗ 提交已阻止：$PATTERNS_FILE 没有任何有效模式${NC}"
  echo "  空模式等于没有防护，不能当作检查通过。请按本单位实际情况填写后重试。"
  exit 1
fi

# 跳过文件模式（二进制、锁定文件、测试文件、迁移文件）
SKIP_PATTERNS=(
  '^\.privacy-patterns$'            # 模式文件自身：它按定义装满了要查的模式，不该查自己
  '\.lock$' 'package-lock\.json$' 'yarn\.lock$' 'pnpm-lock\.yaml$'
  'migrations/' '\.git/'
  '\.png$' '\.jpg$' '\.jpeg$' '\.gif$' '\.ico$' '\.pdf$' '\.zip$'
  '\.tar\.gz$' '\.woff$' '\.woff2$' '\.ttf$' '\.eot$'
)

LEAK_FOUND=0

for file in $STAGED_FILES; do
  skip=false
  for pattern in "${SKIP_PATTERNS[@]}"; do
    if echo "$file" | grep -qE "$pattern"; then skip=true; break; fi
  done
  [ "$skip" = true ] && continue

  for pattern in "${PRIVACY_PATTERNS[@]:-}"; do
    [ -z "$pattern" ] && continue
    matches=$(git show ":$file" 2>/dev/null | grep -nE "$pattern" || true)
    if [ -n "$matches" ]; then
      echo -e "${RED}⚠️  隐私泄漏: $file${NC}"
      echo "$matches"
      LEAK_FOUND=1
    fi
  done
done

if [ "$LEAK_FOUND" -ne 0 ]; then
  echo -e "${RED}✗ 提交已阻止：存在隐私泄漏。${NC}"
  echo "  处理方式："
  echo "    (1) 真实敏感信息 -> 修复为占位符后再提交"
  echo "        占位符约定：<repo-root> / <tmp> / <credential-path> / <email> / <internal-host>"
  echo "    (2) 确有必要的文档示例 -> 人工复核后使用 --no-verify（并在提交信息中注明原因）"
  exit 1
fi

echo -e "${GREEN}✓ 隐私检查通过${NC}"