#!/usr/bin/env bash
# history-scan.sh — 仓库历史隐私体检（模板）
# 定位：pre-commit 钩子只扫暂存区，看不到"曾经提交过、后来又删掉"的内容。
#      密钥一旦入库就永远留在历史里，删文件无效；本脚本用于首次提交前自查、
#      定期巡检，以及推送前确认。
#
# 用法：bash history-scan.sh [仓库路径]     # 默认扫当前目录
# 退出码：0=通过 1=发现泄漏（阻断） 2=用法/环境错误
#
# 检查三类：
#   1. 密钥文件类是否曾入库（按文件名判定，不看内容）
#   2. 全量历史中的内容是否命中隐私模式（读 .privacy-patterns，缺失则 fail-closed）
#   3. 提交信息中是否含密钥/凭据模式
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
REPO="${1:-.}"

if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo -e "${RED}✗ $REPO 不是 git 仓库（或不在仓库内）${NC}"
  echo "  请在项目根目录下执行，或用参数指定仓库路径。"
  exit 2
fi

# ===== 1. 密钥文件类曾入库检查 =====
# 按文件名判定：这类文件只要出现在任何一个提交里，就说明曾经泄漏过。
# 注意：这里刻意扫描全量历史（--all），不只看当前工作区 —— 已删除的也算。
SECRET_FILE_PATTERN='(\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|keystore$|^id_rsa|^id_ed25519|\.netrc$|\.pgpass$|^\.aws/credentials|^\.kube/config|\.docker/config\.json$|\.sqlite$|\.sqlite3$|\.db$|\.dump$)'

echo "🔍 扫描仓库历史隐私泄漏..."
echo "   仓库：$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null)"
echo "   提交数：$(git -C "$REPO" rev-list --all --count 2>/dev/null || echo 0)"

FOUND=0

# git log --all --name-only 列出所有提交动过的路径；去掉空行后按文件名筛。
# --diff-filter=AM 才看"新增/修改"，删除不影响"曾入库"这个事实。
HIST_FILES=$(git -C "$REPO" log --all --name-only --diff-filter=AM --pretty=format: 2>/dev/null \
  | grep -v '^[[:space:]]*$' | sort -u || true)

if [ -n "$HIST_FILES" ]; then
  HIT_FILES=$(printf '%s\n' "$HIST_FILES" | grep -E "$SECRET_FILE_PATTERN" || true)
  if [ -n "$HIT_FILES" ]; then
    FOUND=1
    echo -e "${RED}✗ 发现密钥文件类曾经入库（${NC}这比删掉文件更严重 —— 凭据应视为已泄漏）"
    printf '%s\n' "$HIT_FILES" | sed 's/^/    /'
    echo ""
    echo "  处理方式（按顺序做，不要跳步）："
    echo "    (1) 先轮换所有相关凭据 —— 删除历史不等于凭据失效，这一步最优先"
    echo "    (2) 再清理历史：git filter-repo --path <路径> --invert-paths"
    echo "        （若历史已推送到远程，改写后需强制推送 + 通知协作者重拉）"
  fi
fi

# ===== 3. 提交信息扫描 =====
# 先扫提交信息：它不依赖 .privacy-patterns，放在前面才能在"模式文件缺失"时
# 也把已发现的问题报全 —— 一次跑完给完整清单，而不是让人修一次再跑一遍。
# 密钥常被写进 commit message（"配置 token 为 xxx"），内容扫描覆盖不到这一层。
MSG_PATTERN='(AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|-----BEGIN)'
MSG_HITS=$(git -C "$REPO" log --all --pretty=format:'%H %s%n%b' 2>/dev/null | grep -nE "$MSG_PATTERN" || true)
if [ -n "$MSG_HITS" ]; then
  FOUND=1
  echo -e "${RED}✗ 提交信息中含密钥/凭据模式${NC}"
  printf '%s\n' "$MSG_HITS" | head -10 | sed 's/^/    /'
  echo "  提交信息同样属于历史，删代码不会清掉它。"
  echo ""
fi

# ===== 2. 全量历史内容扫描 =====
# 模式从 .privacy-patterns 读；缺失即阻断（fail-closed），理由同 pre-commit 钩子。
PATTERNS_FILE="$REPO/.privacy-patterns"
if [ ! -f "$PATTERNS_FILE" ]; then
  echo -e "${RED}✗ 未找到 $PATTERNS_FILE，内容扫描无法进行${NC}"
  echo "  没有模式等于没扫，按 fail-closed 阻断，不做'扫过了所以安全'的宽松结论。"
  echo "  处理方式：cp templates/privacy-patterns.example .privacy-patterns 后重新执行。"
  exit 1
fi

mapfile -t PRIVACY_PATTERNS < <(grep -vE '^\s*(#|$)' "$PATTERNS_FILE" || true)
if [ "${#PRIVACY_PATTERNS[@]}" -eq 0 ]; then
  echo -e "${RED}✗ $PATTERNS_FILE 没有任何有效模式，内容扫描无法进行${NC}"
  exit 1
fi

for pattern in "${PRIVACY_PATTERNS[@]}"; do
  [ -z "$pattern" ] && continue
  # git grep 遍历历史提交；-I 跳过二进制文件（锁文件、图片等命中无意义）。
  # 模式文件自身按定义装满了待查模式，必须排除，否则每次扫都自我告警。
  REVS=$(git -C "$REPO" rev-list --all 2>/dev/null | head -200)
  matches=$(git -C "$REPO" grep -I -n -E "$pattern" $REVS -- \
             ':(exclude).privacy-patterns' 2>/dev/null || true)
  if [ -n "$matches" ]; then
    FOUND=1
    echo -e "${RED}✗ 历史内容命中隐私模式${NC}"
    printf '%s\n' "$matches" | head -20 | sed 's/^/    /'
    echo ""
    break
  fi
done

# ===== 汇总 =====
echo ""
if [ "$FOUND" -ne 0 ]; then
  echo -e "${RED}✗ RESULT(history): LEAK FOUND${NC} —— 仓库历史存在泄漏风险，不可推送"
  echo ""
  echo "  ${YELLOW}三条铁律：${NC}"
  echo "    1. 先轮换凭据，再清历史 —— 顺序反了等于没处理"
  echo "    2. 清理历史会改写 commit hash，已推送的需强推并通知协作者重新克隆"
  echo "    3. 若仓库已镜像到公开平台，按已泄漏处理，不做'删掉就没事'的假设"
  exit 1
fi

echo -e "${GREEN}✓ RESULT(history): LEAK=0${NC} —— 未发现历史泄漏"
echo "  建议：首次提交前、每次推送前、以及定期巡检各跑一次。"
exit 0
