# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定位

这是一个 **AI 味识别与修复** 的 Claude Code Skill 项目：识别 AI 生成内容中容易引发读者反感、被网友"一眼认出是 AI"的句式/结构特征，并给出可操作的修改建议。

判断标准不是"文本客观上是不是 AI 生成的"（困惑度、AI 检测器结论等一律不采信），而是主观阅读感受口径，不是统计显著性口径。这个主观判据有两类同等有效的来源：① **舆论实证**——真实网友因此吐槽/指认过 AI 的争议案例；② **主观样本**——维护者本人日常阅读中主观感受到"AI 味"的具体示例，无需网友群体讨论佐证。这个判据取向是理解所有规则设计的前提，务必先读 `rules/rules.md` 的 §0.0。

## 核心资料

`rules/rules.md`（AI 味特征检测清单 v3）是本项目的唯一事实来源（source of truth），所有 skill 的判断逻辑都必须以它为准，不要凭经验另起一套标准。关键结构：

- **Layer A**：句式/词汇/结构/标点等表面特征，规则可程序化（正则+统计），分四个小节（句式层、词汇层、结构层、标点/格式层），v3 起不再用字母组标签，以免与 Layer B/D 混淆。
- **Layer B**：小说/长篇特有的叙事级特征（前精后 AI、长程崩塌、人物声音扁平等），需结构化统计 + LLM-judge。
- **Layer C**：LLM-judge 打分的风格性软维度（具体细节密度、立场明确度、个人声音等），规则无法程序化，靠提示词评分。
- **Layer D**（反向降噪）：网友"一眼认出是真人"的加分证据，用于对冲 Layer A 软线索的误判——命中 Layer A 时必须先查 Layer D 是否有对冲证据，不能只扣分不加分。
- **Layer 0**：误判保护红线（R-01～R-06），规定"永远给疑似度区间而非二元判决"、"按文体先验调阈值"、"降权要细化到维度级"等硬约束。文体先验档和维度级降权表决定了同一特征在不同文体（小说/文学、古典文白、公文应试、营销等）里权重完全不同。
- 末尾的"评分与定级"给出了疑似度分的计算公式和 0–100 的锚点样本，用于避免多 agent 并行打分时刻度漂移。

`rules.md` 会持续演进（当前 v3），版本变更记录在文件末尾"版本"一节；改规则本身只能通过 `/add-flavor-case` 完成，不要手工改写规则条目而不经过实例校验。rule id 形如 `A-01.1` / `G-03` / `R-04`，定义位置为 `####` 标题、表格首列 `**ID**`，或子规则的列表项 `- **A-01.1**`。

## 目录结构

```
rules/          核心输出 ①：判据
  rules.md        唯一事实来源
  changelog.md    规则演进日志（记"为什么改"）
skills/         核心输出 ②：随 plugin 分发的 skill
regression/     验证
  quantitative/   定量 case：文本 × 规则命中期望
  qualitative/    定性 case：同背景多版本 × 疑似度分排序期望
  drafts/         草稿：规则未定案，不参与回归、lint 跳过
  runs/           每次回归跑测的记录
.claude/skills/ 工具：本仓库自用、不随 plugin 分发
scripts/        工具：结构校验
```

**输出与工具的分界线就是"随不随 plugin 分发"**：`skills/` 分发，`.claude/skills/` 与 `scripts/` 不分发。`add-flavor-case` 属工具，不属项目输出。

## Skill 与目录

| skill | 位置 | 面向 | 职责 |
|---|---|---|---|
| `ai-flavor-detect` | `skills/ai-flavor-detect/` | 对外（随 plugin 分发） | **严格模式**：只按 `rules.md` 现有规则判定，输出 §0.2 报告 + 机器可比对的"命中清单" |
| `ai-flavor-fix`（未实现） | `skills/ai-flavor-fix/` | 对外 | 输入识别报告 + 原文，只修报告标出的维度/段落 |
| `add-flavor-case` | `.claude/skills/add-flavor-case/` | 本仓库自用 | **发散模式**：从用户例句找 AI 味 → 修复 → 生成回归 case → 更新 `rules.md` → 用 `ai-flavor-detect` 回归 → 精简扫描 |

两种"识别"性质相反、不共享逻辑：detect 不发散，add-flavor-case 不严格。所有 skill 只引用 `rules/rules.md`，不内嵌规则摘要。

本仓库是一个 Claude Code plugin（`.claude-plugin/plugin.json`），本地测试用 `claude --plugin-dir .`。

## 不入库的东西

**superpowers 生成的文件一律不提交**：`.superpowers/` 与 `docs/superpowers/`（brainstorming / writing-plans 产出的 spec 与 plan）都在 `.gitignore` 里。这些是过程产物，不是项目输出——项目的事实来源是 `rules/rules.md`，设计决策记录在 `rules/changelog.md` 与各 case 的 `meta.md` 里，不靠 plan 文档追溯。

2026-09-09 已用 `git filter-repo` 把 `docs/superpowers/` 从全部历史中移除并 force-push，早于该日期的 commit hash 全部失效。

## 回归集

分两类，验收标准不同：

- **定量** `regression/quantitative/<ruleid>-<nn>/`：`meta.md`（`target_rules`、`origin`、文本与期望表）+ 文本文件。验收标准是**目标规则**是否命中（A/B/C 看有效命中、D 看 Layer D 命中、G 看文体先验、A-04.2/A-06.2 看排除项应用），疑似度分只作参考。
- **定性** `regression/qualitative/<topic>-<nn>/`：`meta.md`（`kind: qualitative`、`expect_order`、必需的 `## 背景` 小节）+ 各版本文本。验收标准是同背景下多个版本的疑似度分**排序**是否符合预期。**只比序**——按分数锚点表，跨文本绝对分不可比，写最小分差是假精度。同一 case 的所有版本必须由同一 agent 串行跑，跨 agent 有刻度漂移。
- **草稿** `regression/drafts/<id>/`：规则未定案的 case，两类都可以放。不参与回归，lint 整个跳过（草稿常引用尚不存在的 rule id，这正是它还是草稿的原因）。见其 `README.md`。
- `regression/runs/`：每次回归跑测的记录。
- `rules/changelog.md`：`add-flavor-case` 的叙述性日志，记"为什么改"。
- `scripts/lint-regression.sh [--final] [--coverage]`：结构校验（id 唯一且存在、文件存在、rules.md 无书名引用 / 占位符）。任何改动 `rules.md` 或 case 后必须跑通。
- B-01 / B-05 为全书级规则，回归集不覆盖。

## 修改 rules.md 的唯一途径

通过 `/add-flavor-case`。不要手工改判断口径；每次变更必须有 case 保护、经回归、版本 +0.1 并写入"## 版本"。

规则一时定不下来（样本量不够定阈值、或新规则与现有规则极性冲突）时**不要硬凑**——把 case 落到 `regression/drafts/`，攒够同类样本再统一立规则。宁可草稿堆着，也不要靠单样本拍一个阈值进 rules.md。
