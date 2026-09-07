---
name: add-flavor-case
description: 本仓库自用。用户给一段有 AI 味的例句，走"发散识别 → 确认 → 最小修复 → 确认 → 生成回归 case → 更新 references/rules.md → 回归验证 → 精简扫描"全流程。当用户说"加一个 AI 味 case / 这句有 AI 味帮我入库 / 更新规则"时使用。
---

# add-flavor-case

## 依赖

- 规则：`references/rules.md`（唯一事实来源，每次重新读全文）。
- 回归集：`regression/cases/<case-id>/`，格式见任一现有 case 的 `meta.md`。
- 校验：`scripts/lint-regression.sh --final`。
- 严格判定：`skills/ai-flavor-detect/SKILL.md`（回归步骤调用它，不自己另写判定逻辑）。
- 日志：`references/cases.md`。

## 两种识别的边界

本 skill 的识别是**发散模式**：假设用户给的例句必然有 AI 味，努力理解用户为什么觉得它像 AI，找出所有疑似点——包括 rules.md 尚未覆盖的新模式。
`ai-flavor-detect` 是**严格模式**：只按现有规则判。回归验证必须用它，不能用本 skill 的发散判断代替。

## 输入

用户在对话中贴的例句 / 段落。不要求结构化字段。本 skill 产出的所有 case 与规则条目，`origin` 一律为 **主观样本**。

## 流程（每个 ⏸ 都要停下等用户明确回复，不得跳步）

1. **重读** `references/rules.md` 全文，记下当前版本号。
2. **发散识别**：列出例句中所有疑似点，每条：`证据原文` · 为什么像 AI 味 · 对应规则 id 或 "规则未覆盖"。
   ⏸ 请用户删减 / 补充 / 纠正。若一条都找不到，如实说明并询问用户具体觉得哪里像 AI，不硬凑。
3. **最小修复**：只针对确认过的疑似点改，不做无关改写，给出 after 文本与逐条改动说明。
   ⏸ 请用户确认修复效果。
4. **生成 case 草稿**：
   - case-id = `<主目标规则id>-<下一个可用两位序号>`；若目标是"规则未覆盖"的新规则，先在步骤 5 定下新 id 再命名。
   - `meta.md`：`target_rules`、`source: 用户提供`、`origin: 主观样本`、`created`、`verified_at: 未验证`、`known_other_issues`、`score_ref`、文本与期望表、说明。
   - `before.md` / `after.md`。
5. **判断 rules.md 变更类型**（可组合）：
   - 追加已有规则的样本引用（`见 case <id>`）；
   - 调整已有规则的阈值 / 降权系数；
   - 新增规则（分配新 id：同层下一个编号，或某维度下一个子规则号）；
   - 废弃 / 收窄规则；
   - 新增 Layer D 反例。
6. **证据强度说明**：不设硬门槛，但必须写一句评估，例如"仅 1 个主观样本，建议只追加样本引用，暂不调阈值"。由用户拍板。
7. **变更预览**（不落盘）：
   - rules.md 每处改动的"原文 → 新文"；
   - 版本号 +0.1（如 v3 → v3.1）及"## 版本"新增一行（写明来源为主观样本）；
   - `references/cases.md` 追加条目草稿。
   ⏸ 请用户确认 / 修改 / 拒绝。
8. **落盘**：写 rules.md（标题版本、日期行、版本记录）、写 case 目录、追加 cases.md。三处版本号一致。跑 `scripts/lint-regression.sh --final` 必须通过。
9. **回归验证**：
   - 受影响规则 = 本次 rules.md 改动涉及的全部 id（含新 case 的 target_rules）。
   - 受影响 case = `regression/cases/*/meta.md` 中 `target_rules` 或期望表含任一受影响规则的 case。
   - 对每个受影响 case 的每个文本，用 Agent 工具派子代理执行 `skills/ai-flavor-detect/SKILL.md`（`CLAUDE_PLUGIN_ROOT` 视为仓库根目录），只取"## 命中清单"。可按 case 分批并行。
   - 比对：A/B/C-xx 看 `有效命中`；D-xx 看 `Layer D 命中`；G-xx 看 `文体先验`；A-04.2 / A-06.2 看 `排除项应用`。
   - 结果写 `regression/runs/<YYYY-MM-DD>-<case-id>.md`（格式同 `regression/runs/2026-09-07-baseline.md`）。
   - 默认只跑受影响子集；用户明确要求"全量回归"时才跑全部 case。
   - 通过的 case 把 `verified_at` 更新为新版本号。
10. **冲突处理**：若有旧 case 从通过变为不通过，**停下**，给出：新 case 要求什么 · 旧 case 要求什么 · 当前规则写法为何满足不了两者 · 至少两种取舍方案。
    ⏸ 由用户裁决。不得自行选边、不得静默改旧 case 的期望。
11. **精简扫描**：
    - 合并表述冗余的条目（保留判断，删重复措辞）；
    - 跑 `scripts/lint-regression.sh --final --coverage`，把"待补 case"的规则列出来（只标注，不删除）；
    - 给出精简理由与预览。
    ⏸ 用户确认后落盘，计入同一次版本变更（不再 +0.1）。
12. 报告本次结果：case-id、rules.md 新版本、回归范围与结果、runs 文件路径。

## 错误处理

- 例句与现有规则冲突（如同一形态已有相反的降权结论）：停下提问，不猜着改。
- lint 不通过：修到通过再继续，不得跳过。
- 用户在任一 ⏸ 拒绝：回到上一步修改，不跳步。

## 不做的事

- 不做无依据的整体重写。
- 不改 rules.md §0.0 的判据取向。
- 不 commit；落盘后提示用户自行检查并提交。
