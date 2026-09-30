#!/usr/bin/env bash
# skills-check.sh — 检测本项目所需 Agent Skills 是否就绪，缺失时可安装/给指引（模板）
# 用法：
#   bash skills-check.sh                 # 检测（--check 为默认）
#   bash skills-check.sh --check         # 显式检测
#   bash skills-check.sh --install       # 检测 + 补齐缺失（gl 自动、sp 给指引）
#   bash skills-check.sh --install --dry-run   # 演练：只打印将做的事，不落盘
# 说明：
#   - 技能三层来源检测：项目级 .opencode/skills → 全局个人级 ~/.config/opencode/skills → superpowers 插件
#   - 两层清单：sp:（superpowers 流程型）/ gl:（全局个人型）；可经 SKILLS_REQUIRED_FILE 覆盖清单
#   - 非破坏性原则：只新增，绝不覆盖既有内容；不改动全局 opencode.json
set -euo pipefail

# ===== 可配置项 =====
# 所需技能清单（sp: = superpowers 插件层；gl: = 全局个人层 ~/.config/opencode/skills）
REQUIRED_FILE="${SKILLS_REQUIRED_FILE:-$(dirname "$0")/skills-required.txt}"
SUPERPOWERS_SKILLS_DIR="${SUPERPOWERS_SKILLS_DIR:-}"
GLOBAL_SKILLS_DIR="${GLOBAL_SKILLS_DIR:-${HOME}/.config/opencode/skills}"
PROJECT_SKILLS_DIR="${PROJECT_SKILLS_DIR:-.opencode/skills}"

GREEN=''; RED=''; YELLOW=''; CYAN=''; NC=''
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
fi
say() { echo -e "${CYAN}== $*${NC}"; }

# ===== 参数解析 =====
MODE="check"; DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    --install) MODE="install" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $arg（支持 --check / --install / --dry-run / -h）" >&2; exit 2 ;;
  esac
done

# ===== 定位 superpowers 技能目录 =====
if [ -z "$SUPERPOWERS_SKILLS_DIR" ]; then
  # 允许中间任意层（如 git-superpowers-<hash>/<ver>/node_modules/superpowers/skills）
  SUPERPOWERS_SKILLS_DIR=$(find "$HOME/.cache/opencode/npm" -maxdepth 6 -type d -path '*/node_modules/superpowers/skills' 2>/dev/null | head -1 || true)
fi

# ===== 技能存在性检测 =====
# 返回 0=存在 1=缺失；不存在时回显 0（防 set -e）
skill_present() {  # $1=技能名
  local name="$1"
  [ -f "$PROJECT_SKILLS_DIR/$name/SKILL.md" ] && return 0
  [ -f "$GLOBAL_SKILLS_DIR/$name/SKILL.md" ] && return 0
  [ -n "$SUPERPOWERS_SKILLS_DIR" ] && [ -f "$SUPERPOWERS_SKILLS_DIR/$name/SKILL.md" ] && return 0
  return 1
}

# ===== 读取清单 =====
if [ ! -f "$REQUIRED_FILE" ]; then
  echo -e "${RED}✗ 技能清单文件缺失: $REQUIRED_FILE（可用 SKILLS_REQUIRED_FILE 覆盖）${NC}" >&2
  exit 2
fi
mapfile -t REQUIRED < <(grep -vE '^\s*(#|$)' "$REQUIRED_FILE" || true)

# ===== check 模式 =====
declare -i OK=0 MISSING=0
MISSING_SKILLS=()
echo "== Skills 检测（清单: $REQUIRED_FILE）=="
for entry in "${REQUIRED[@]}"; do
  layer="${entry%%:*}"; name="${entry#*:}"
  if skill_present "$name"; then
    OK+=1
    echo -e "  ${GREEN}✓${NC} ${name}（$layer）"
  else
    MISSING+=1; MISSING_SKILLS+=("$entry")
    echo -e "  ${RED}✗${NC} ${name}（$layer）"
  fi
done
echo "RESULT(skills): OK=${OK} MISSING=${MISSING}"

# ===== install 模式 =====
if [ "$MODE" = "install" ] && [ "$MISSING" -gt 0 ]; then
  say "尝试补齐缺失技能（非破坏性：只新增，不覆盖；不改全局 opencode.json）"
  for entry in "${MISSING_SKILLS[@]}"; do
    layer="${entry%%:*}"; name="${entry#*:}"
    case "$layer" in
      sp)
        echo -e "  ${YELLOW}↪${NC} $name 属 superpowers 插件层，需在 opencode.json 的 plugins 增加："
        echo -e "      ${YELLOW}\"plugins\": [\"superpowers@git+https://github.com/obra/superpowers.git\"]${NC}"
        echo -e "    然后重启 opencode（opencode service restart）并再次 --check。"
        ;;
      gl)
        target="$GLOBAL_SKILLS_DIR/$name"
        if [ "$DRY_RUN" -eq 1 ]; then
          echo -e "  ${YELLOW}↪${NC} [dry-run] 将创建 $target/SKILL.md（骨架）"
          continue
        fi
        # superpowers 包内有同名技能时先复制其完整内容；否则生成骨架
        if [ -n "$SUPERPOWERS_SKILLS_DIR" ] && [ -f "$SUPERPOWERS_SKILLS_DIR/$name/SKILL.md" ]; then
          mkdir -p "$target"
          cp "$SUPERPOWERS_SKILLS_DIR/$name/SKILL.md" "$target/SKILL.md"
          echo -e "  ${GREEN}✓${NC} 已复制 superpowers 同名技能 → $target/SKILL.md"
        else
          mkdir -p "$target"
          cat > "$target/SKILL.md" <<SKEL
---
name: $name
description: Use when [条件] - [本技能做什么]。占位骨架，请按实际用途补全描述。
---

# $name

[技能内容：请按项目实际需要编写]
SKEL
          echo -e "  ${GREEN}✓${NC} 已生成骨架 → $target/SKILL.md（请补充 description 与正文）"
        fi
        ;;
      *)
        echo -e "  ${YELLOW}↪${NC} 未知图层 $layer（跳过）"
        ;;
    esac
  done
  echo "（如需演练可用 --dry-run 预览；已存在技能不会被覆盖）"
fi

# ===== 退出码：0=全就绪 1=有缺失 2=配置错误 =====
[ "$MISSING" -eq 0 ]