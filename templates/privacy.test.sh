#!/usr/bin/env bash
# privacy.test.sh — 隐私防护行为测试（先写失败，再最小实现）
# 覆盖两处必须 fail-closed 的点：
#   T1  pre-commit.sh：缺 .privacy-patterns 必须阻断提交（不得 exit 0 放行）
#   T2  history-scan.sh：历史中曾入库的密钥文件必须被检出并阻断
#   T3  history-scan.sh：提交信息中的密钥模式必须被检出
#   T4  history-scan.sh：干净仓库必须通过（防止规则过宽导致误报阻断）
#
# 用法：bash templates/privacy.test.sh
# 说明：每个用例在独立临时 git 仓库里跑，用完自动清理；断言计数与 RESULT 汇总。
set -uo pipefail

PASS=0; FAIL=0
TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/privacy-test-XXXXXX")"
# 只给 mktemp 私有权限，避免测试期间临时仓库里的假密钥被同机其他用户读到
chmod 700 "$TMPROOT"
trap 'chmod -R 700 "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()  { PASS=$((PASS+1)); echo -e "  \033[1;32m✓ PASS\033[0m  $*"; }
bad() { FAIL=$((FAIL+1)); echo -e "  \033[1;31m✗ FAIL\033[0m  $*"; }
say() { echo -e "\033[1;36m== $*\033[0m"; }

# 断言退出码必须精确等于期望值。
# 刻意不用 "!= 0" 判阻断：脚本缺失时退出码 127 也会让 "!= 0" 通过，
# 那属于"恰好命中了别的失败原因"，是假绿（见 AGENTS.md §六 断言质量四问）。
assert_exit() {
  local want="$1" got="$2" msg="$3"
  if [ "$want" -eq "$got" ]; then
    ok "$msg"
  elif [ "$want" -eq 0 ]; then
    bad "$msg（期望放行退出 0，实际退出码 $got）"
  else
    bad "$msg（期望阻断退出 $want，实际退出码 $got —— 若为 127 说明脚本本身缺失，属假绿）"
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" msg="$3"
  printf '%s' "$haystack" | grep -qF "$needle" && ok "$msg" || bad "$msg（输出里没有 '$needle'）"
}

assert_not_contains() {
  local needle="$1" haystack="$2" msg="$3"
  printf '%s' "$haystack" | grep -qF "$needle" && bad "$msg（不该出现 '$needle'）" || ok "$msg"
}

# 建一个干净的测试仓库：<dir> 路径，用法 new_repo <dir>
new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email "test@<email>"
  git -C "$1" config user.name  "<tester>"
  git -C "$1" config commit.gpgsign false
}

# ===== T1：pre-commit 缺 .privacy-patterns 时必须阻断 =====
say "T1 隐私钩子缺模式文件时 fail-closed"
T1="$TMPROOT/t1"; new_repo "$T1"
mkdir -p "$T1/.githooks"
cp "$SRC_DIR/pre-commit.sh" "$T1/.githooks/pre-commit"
chmod +x "$T1/.githooks/pre-commit"
git -C "$T1" config core.hooksPath .githooks
printf 'secret-looking content\n' > "$T1/a.txt"
git -C "$T1" add a.txt
OUT1=$(git -C "$T1" commit -m "test" 2>&1); RC1=$?
assert_exit 1 "$RC1" "缺 .privacy-patterns 时提交被阻断"
assert_contains ".privacy-patterns" "$OUT1" "报错指明缺失的文件名"

# ===== T1b：模式文件存在但为空 —— 同样不得静默放行 =====
say "T1b 模式文件存在但为空时阻断"
T1B="$TMPROOT/t1b"; new_repo "$T1B"
mkdir -p "$T1B/.githooks"
cp "$SRC_DIR/pre-commit.sh" "$T1B/.githooks/pre-commit"
chmod +x "$T1B/.githooks/pre-commit"
git -C "$T1B" config core.hooksPath .githooks
: > "$T1B/.privacy-patterns"
printf 'content\n' > "$T1B/b.txt"
git -C "$T1B" add b.txt
OUT1B=$(git -C "$T1B" commit -m "test" 2>&1); RC1B=$?
assert_exit 1 "$RC1B" "空模式文件时提交被阻断"

# ===== T1c：模式齐备 + 内容干净 —— 必须放行 =====
say "T1c 配置完整且干净时放行（防止过度阻断）"
T1C="$TMPROOT/t1c"; new_repo "$T1C"
mkdir -p "$T1C/.githooks"
cp "$SRC_DIR/pre-commit.sh" "$T1C/.githooks/pre-commit"
chmod +x "$T1C/.githooks/pre-commit"
git -C "$T1C" config core.hooksPath .githooks
printf 'BEGIN FAKE KEY\nvalue\nEND FAKE KEY\n' > "$T1C/.privacy-patterns"
printf 'placeholder text <repo-root>\n' > "$T1C/c.txt"
git -C "$T1C" add c.txt .privacy-patterns
OUT1C=$(git -C "$T1C" commit -m "test" 2>&1); RC1C=$?
assert_exit 0 "$RC1C" "配置完整且内容干净时提交通过"

# ===== T2：历史中曾入库的密钥文件必须被检出 =====
say "T2 历史中曾入库的密钥文件被检出"
T2="$TMPROOT/t2"; new_repo "$T2"
printf -- '-----BEGIN FAKE PRIVATE KEY-----\nnot-a-real-key\n-----END FAKE PRIVATE KEY-----\n' > "$T2/secret.pem"
git -C "$T2" add secret.pem
git -C "$T2" commit -q -m "误提交密钥" >/dev/null 2>&1
git -C "$T2" rm -q --cached secret.pem >/dev/null 2>&1
rm -f "$T2/secret.pem"
OUT2=$(bash "$SRC_DIR/history-scan.sh" "$T2" 2>&1); RC2=$?
assert_exit 1 "$RC2" "历史含密钥文件时扫描阻断"
assert_contains "secret.pem" "$OUT2" "报出具体文件名"
assert_contains "密钥文件" "$OUT2" "说明命中的是密钥文件类"

# ===== T3：提交信息中的密钥模式必须被检出 =====
say "T3 提交信息中的密钥模式被检出"
T3="$TMPROOT/t3"; new_repo "$T3"
printf 'ok\n' > "$T3/d.txt"
git -C "$T3" add d.txt
git -C "$T3" commit -q -m '配置 AKIAZZZZZZZZZZZZZZZZ 为默认访问密钥' >/dev/null 2>&1
OUT3=$(bash "$SRC_DIR/history-scan.sh" "$T3" 2>&1); RC3=$?
assert_exit 1 "$RC3" "提交信息含访问密钥时扫描阻断"
assert_contains "提交信息" "$OUT3" "指出问题在提交信息里"

# ===== T4：干净仓库必须通过 =====
say "T4 干净仓库通过（规则不得过宽）"
T4="$TMPROOT/t4"; new_repo "$T4"
mkdir -p "$T4/docs"
# 模式文件必须存在且有效：本用例断言的是"规则不过宽导致误报阻断"，
# 若缺模式文件会先被 fail-closed 拦下 —— 那属于前置校验命中，不是本用例的目标失败。
printf 'BEGIN FAKE KEY\n' > "$T4/.privacy-patterns"
printf '# 说明\n占位符 <repo-root> <email>\n' > "$T4/docs/readme.md"
git -C "$T4" add .privacy-patterns docs/readme.md
git -C "$T4" commit -q -m 'docs: 补充说明' >/dev/null 2>&1
OUT4=$(bash "$SRC_DIR/history-scan.sh" "$T4" 2>&1); RC4=$?
assert_exit 0 "$RC4" "干净仓库扫描通过"
assert_not_contains "secret.pem" "$OUT4" "干净仓库不误报"

# ===== T5：非 git 目录给出明确报错（fail-closed，不静默） =====
say "T5 非 git 目录明确报错"
# 用法/环境错误用退出码 2，与"发现泄漏"的 1 区分开，避免把环境问题误读成泄漏
OUT5=$(bash "$SRC_DIR/history-scan.sh" "$TMPROOT/not-a-repo" 2>&1); RC5=$?
assert_exit 2 "$RC5" "非 git 目录以用法错误码退出（不与泄漏的 1 混淆）"
assert_contains "不是 git 仓库" "$OUT5" "提示目录不是 git 仓库"

echo
echo "RESULT(privacy): PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
