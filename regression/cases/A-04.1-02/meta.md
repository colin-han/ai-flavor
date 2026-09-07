# A-04.1-02

- target_rules: [A-04.1]
- source: 合成（英文技术评论，题材：modern data stack）
- origin: 规则覆盖夹具
- created: 2026-09-07
- verified_at: rules.md v3
- known_other_issues: []
- score_ref: before ≈ 90 / after ≈ 15

## 文本与期望

| 文件 | must_hit | must_not_hit |
|---|---|---|
| before.md | [A-04.1] | [] |
| after.md | [] | [A-04.1] |

## 说明

本 case 覆盖 A-04.1 的**英文实证清单**分支（Kobak et al. 2025《Science Advances》的 Z 分数词表），与 A-04.1-01 的中文经验清单分支互补。

**before 为什么命中**：约 192 词，**字面命中 rules.md A-04 英文清单（18 项）共 24 处**：landscape ×2、navigate ×2、tapestry ×2、meticulously ×2、pivotal ×2、paradigm ×2、underscores ×2，以及 delve、intricate、realm、foster、testament、leverage、robust、seamless、it's important to note、it's worth noting 各 1 处。密度 ≈ 125/千词。

另有两处**不计入**上述密度：`showcases`（清单收录的词形是 showcasing，属词形变体，另计 1 处）、`In conclusion`（不在 A-04 词表内，它属 A-07.1 的硬总结词；这是 before 侧的附带命中，after 已换成反收束句"None of this is a strategy."，故不入 `known_other_issues`）。delve 的 Z 分数是 28.0，是全表最高的单词；这里它与 tapestry、meticulously、pivotal 同段出现，属于清单描述的"裸 AI 输出"形态。

**after 改了什么**：保留全部技术判断（CDC 带来的实时性收益与 on-call 代价、declarative modeling 需要 ownership、lineage 的价值发生在审计时），把每一个词表词换成具体断言或数字：tapestry → 一句关于 "customer" 定义不一致的具体成本；delve into the pivotal considerations → "Start with ingestion."；robust lineage tooling → 一个具体场景（审计员问你删掉的那一列被哪些下游报表用过）；in conclusion + let us embrace → 一句反收束（"None of this is a strategy."）。同时补上 D-01 类人味证据：200ms、140 models、900 models、3am。

**after 为什么不再命中**：词表命中 0 处。

**边界**：A-04.1 判密度，不判"英文写得正式"。after 仍是一篇结构清晰的技术评论，仍用了 governance、lineage、declarative modeling 这类术语——术语不在词表内，词表针对的是"承载 0 信息的修饰性套话"。判别方法与中文分支一致：把这个词删掉，句子是否还成立。before 里删掉 tapestry / pivotal / meticulously，句子毫发无损，这就是病灶。
