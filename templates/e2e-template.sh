#!/usr/bin/env bash
# <项目名> <阶段> E2E 验收脚本模板
# 用法：bash scripts/e2e_pSTAGE.sh
# 说明：自含环境（依赖服务 + 服务端 + 前端）+ 断言 + RESULT 汇总 + trap cleanup
# 占位符约定：STAGE=本脚本独占的阶段命名空间代号；以大写字母包夹的为占位符，替换后使用
set -euo pipefail

# ===== 环境准备 =====
STAGE="pSTAGE"                                   # TODO: 替换为本脚本独占的阶段代号
BASE_URL="http://127.0.0.1:8080"                 # TODO: 后端地址
FRONTEND_URL="http://127.0.0.1:5173"             # TODO: 前端地址
TMP="/tmp/${STAGE}-$$"
mkdir -p "$TMP"
declare -i PASS=0 FAIL=0
trap 'rm -rf "$TMP"' EXIT

say()  { echo -e "\033[1;36m== $*\033[0m"; }
ok()   { PASS+=1; echo -e "  \033[1;32m✓ PASS\033[0m  $*"; }
bad()  { FAIL+=1; echo -e "  \033[1;31m✗ FAIL\033[0m  $*"; }

# ===== 工具函数（断言三问：因什么失败？删功能必变红？目标失败？） =====
assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  if [ "$expected" = "$actual" ]; then ok "$msg (=$actual)"; else bad "$msg (期望 $expected 实得 $actual)"; fi
}
assert_contains() {
  local needle="$1" haystack="$2" msg="$3"
  if echo "$haystack" | grep -qF "$needle"; then ok "$msg"; else bad "$msg (缺 '$needle')"; fi
}
# 就绪断言：等待服务可用（防后端未起导致假失败）
wait_for() {
  local url="$1" n=0
  until curl -sf "$url" >/dev/null 2>&1; do
    n=$((n+1)); [ "$n" -ge 30 ] && { bad "服务未就绪 $url"; return 1; }; sleep 1
  done
  ok "服务就绪 $url"
}
# 注意：grep 无匹配 + pipefail 会 errexit 静默中止——所有管道统一 || true + 空值守卫

# ===== 阶段特有断言（按验收清单 A1–An 转录） =====
say "A1 <场景>"
resp=$(curl -s -X POST "$BASE_URL/..." -H 'Content-Type: application/json' -d '{...}')
assert_contains '"ok":true' "$resp" "A1 <断言描述>"

# ===== 链零回归（内嵌既有阶段 E2E 重跑） =====
say "链零回归"
for prev in pPREV1 pPREV2; do                 # TODO: 上一阶段脚本名列表
  bash "scripts/e2e_${prev}.sh" || { bad "链回归 ${prev}"; exit 1; }
done
ok "链回归 n/n 全绿"

# ===== 汇总 =====
echo
echo "RESULT(${STAGE}): PASS=${PASS} FAIL=${FAIL}"
[ "$FAIL" -eq 0 ]