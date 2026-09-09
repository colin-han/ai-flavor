# 草稿区（drafts）

存放**规则未定案**的回归 case。

## 与正式回归集的区别

| 目录 | 内容 | 参与回归 | 受 lint 强校验 |
|---|---|---|---|
| `regression/quantitative/` | 定量：文本 × 规则命中期望 | 是 | 是 |
| `regression/qualitative/` | 定性：同背景多版本 × 分数序期望 | 是 | 是 |
| `regression/drafts/` | 两类都可以放，但规则未定案 | **否** | **否**（`lint-regression.sh` 整个跳过本目录） |

lint 跳过草稿区是**硬需求**：草稿 case 常常引用尚不存在的 rule id（那正是它还是草稿的原因），不跳过必然报错。

## 什么时候用

`add-flavor-case` 走到步骤 5「判断 rules.md 变更类型」时，若样本量不足以定阈值、或新规则与现有规则存在正面冲突而取舍未定，**不要硬凑规则**——把 case 存进本目录，等同类样本积累到 2~3 个再回头统一立规则。

定性 case 与具体规则无关，天然适合先落草稿：即使一条规则都还没有，「同背景下 A 比 B 更像 AI」这个判断本身已经可以记录下来。

## 格式

与正式 case 相同（`meta.md` + 文本文件），额外要求两个字段：

```
- kind: quantitative | qualitative
- status: draft（一句话说明卡在哪）
```

并在 `meta.md` 里写明**未决问题**——晋升前必须逐条回答的东西。

## 晋升

规则定案后 `git mv` 进 `quantitative/` 或 `qualitative/`，删掉 `status` 字段，补 `verified_at`，跑一次回归。

## 现有草稿

| id | kind | 一句话 | 卡在哪 |
|---|---|---|---|
| [wechat-incident-01](wechat-incident-01/) | qualitative | 朋友圈技术事故文案，AI 版被废弃改用人写版 | 候选规则 4 条（对仗格言收尾 / 表演性笔法 / 细节密度过载 / 完成时姿态）+ G-06 文体档 + R-04 短文案例外，均未定案；且 #5 与 C-01/C-06/D-01 极性冲突 |
