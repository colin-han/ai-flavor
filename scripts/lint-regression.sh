#!/usr/bin/env bash
# 回归集结构校验：rule id 定义唯一、case 引用的 id 存在、文件存在、rules.md 无书名引用；
# 扫 regression/quantitative（定量）与 regression/qualitative（定性）；regression/drafts 整个跳过（草稿允许引用未定义的 id）；
# --final 额外要求无 [→case] 占位符；--coverage 列出无 case 支撑的规则（仅提示）。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULES="$ROOT/rules/rules.md"
QUANT="$ROOT/regression/quantitative"
QUAL="$ROOT/regression/qualitative"
FINAL=0; COVERAGE=0
for a in "$@"; do
  case "$a" in
    --final) FINAL=1 ;;
    --coverage) COVERAGE=1 ;;
    *) echo "未知参数: $a"; exit 2 ;;
  esac
done
fail=0
err() { echo "✗ $*"; fail=1; }
ok()  { echo "✓ $*"; }

ID_RE='[ABCDGR]-[0-9]{2}(\.[0-9])?'
DEF_RE="^#### +[AB]-[0-9]{2}|^\| *\*\*${ID_RE}\*\* *\||^ *- \*\*A-[0-9]{2}\.[0-9]\*\*"

# 1. rule id 定义
defs=$(grep -oE "$DEF_RE" "$RULES" | grep -oE "$ID_RE" | sort)
[ -n "$defs" ] || err "rules.md 未找到任何 rule id 定义"
dups=$(echo "$defs" | uniq -d)
[ -z "$dups" ] || err "rules.md 重复定义 rule id: $(echo $dups)"
valid=$(echo "$defs" | sort -u)
ok "rules.md 定义了 $(echo "$valid" | wc -l | tr -d ' ') 个 rule id"

# 2. rules.md 正文无书名引用 / 死链
leak=$(awk '/^## 版本/{exit} {print}' "$RULES" | grep -nE 'two-cheng|cenji|el-nino|report\.md|monitoring-design|test-results|books/')
[ -z "$leak" ] || err "rules.md 正文含外部引用:"$'\n'"$leak"

# 3. 占位符
if [ "$FINAL" = 1 ]; then
  ph=$(grep -n '\[→case' "$RULES")
  [ -z "$ph" ] || err "rules.md 仍有占位符:"$'\n'"$ph"
fi

# 4. 逐 case 校验
in_set() { echo "$2" | grep -qxF "$1"; }
used=""

# 公共字段
common_fields() { # $1=id $2=meta
  for f in origin created verified_at; do grep -qE "^- $f:" "$2" || err "$1: meta.md 缺字段 $f"; done
}

# 定量 case：目录名 <ruleid>-<nn>，target_rules + 命中期望表
for dir in "$QUANT"/*/; do
  [ -d "$dir" ] || continue
  id=$(basename "$dir")
  meta="$dir/meta.md"
  [ -f "$meta" ] || { err "$id: 缺 meta.md"; continue; }
  echo "$id" | grep -qE "^${ID_RE}-[0-9]{2}$" || err "$id: 目录名不符合 <ruleid>-<nn>"
  main=$(echo "$id" | sed -E 's/-[0-9]{2}$//')
  targets=$(grep -E '^- target_rules:' "$meta" | grep -oE "$ID_RE")
  [ -n "$targets" ] || err "$id: meta.md 缺 target_rules"
  echo "$targets" | grep -qxF "$main" || err "$id: 目录名主规则 $main 不在 target_rules 中"
  for t in $targets; do in_set "$t" "$valid" || err "$id: target_rules 含未定义 id $t"; used="$used $t"; done
  common_fields "$id" "$meta"
  rows=$(grep -E '^\| *[^| ]+\.md *\|' "$meta")
  [ -n "$rows" ] || err "$id: meta.md 缺文本与期望表"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    file=$(echo "$row" | awk -F'|' '{gsub(/ /,"",$2); print $2}')
    [ -f "$dir/$file" ] || err "$id: 表中文件 $file 不存在"
    for rid in $(echo "$row" | grep -oE "$ID_RE"); do
      in_set "$rid" "$valid" || err "$id: 期望表含未定义 id $rid"
    done
  done <<< "$rows"
done
ok "定量 case 扫描完成（$(ls -1 "$QUANT" 2>/dev/null | wc -l | tr -d ' ') 个）"

# 定性 case：目录名 <topic>-<nn>，background + expect_order（≥2 个版本，只比序）
for dir in "$QUAL"/*/; do
  [ -d "$dir" ] || continue
  id=$(basename "$dir")
  meta="$dir/meta.md"
  [ -f "$meta" ] || { err "$id: 缺 meta.md"; continue; }
  echo "$id" | grep -qE '^[a-z0-9-]+-[0-9]{2}$' || err "$id: 目录名不符合 <topic>-<nn>（小写字母/数字/连字符）"
  grep -qE '^- kind: qualitative' "$meta" || err "$id: meta.md 缺 kind: qualitative"
  grep -qE '^## 背景' "$meta" || err "$id: meta.md 缺「## 背景」小节（定性比序的前提是背景相同且显式喂给 detect）"
  common_fields "$id" "$meta"
  order=$(grep -E '^- expect_order:' "$meta" | sed -E 's/^- expect_order: *\[(.*)\].*/\1/' | tr ',' ' ')
  [ -n "$order" ] || { err "$id: meta.md 缺 expect_order"; continue; }
  n=0
  for v in $order; do
    n=$((n+1))
    [ -f "$dir/$v.md" ] || err "$id: expect_order 中的 $v 没有对应的 $v.md"
  done
  [ "$n" -ge 2 ] || err "$id: expect_order 至少要两个版本才能比序"
done
ok "定性 case 扫描完成（$(ls -1 "$QUAL" 2>/dev/null | wc -l | tr -d ' ') 个）"

# 5. 覆盖提示
if [ "$COVERAGE" = 1 ]; then
  echo "— 无 case 支撑的规则（R-xx / B-01 / B-05 / 已拆分为子规则的父 id 除外）—"
  for v in $valid; do
    case "$v" in R-*|B-01|B-05) continue ;; esac
    # 已被子规则完整拆分的父 id 本身不是可独立命中的判定单元，不要求 case 覆盖
    echo "$valid" | grep -q "^${v}\." && continue
    echo "$used" | tr ' ' '\n' | grep -qxF "$v" || echo "  待补 case: $v"
  done
fi

[ "$fail" = 0 ] && { echo "通过"; exit 0; } || { echo "失败"; exit 1; }
