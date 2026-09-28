# Spider 评测版本记录（单一事实源）

> **用途**：统一 CertusBI 对外口径。任何文档中的 Spider 数字，若与此表冲突，以本表 + `docs/eval_spider.json` 为准。
> **评测协议（两轮一致）**：Spider dev 集全部 20 个异构数据库；每库按 seed=42 采样 5 题，共 99 题；zero-shot（无 few-shot、无自我一致性投票）、温度 0.0；Prompt = 完整 CREATE TABLE DDL + 外键 + 每表 3 行采样；在真实 SQLite 数据库上执行 Agent SQL 与 Gold SQL 并比较结果集。模型：deepseek-v4-flash。

## 对外口径（2026-09 起）

- **EX（执行准确率，严格判等）= 80.8%（80/99）** —— 以 2026-08-28 最新一次运行为准。
- 另有 **4 题 Jaccard ≥ 0.8 的部分正确**，不计入 EX（宽松参考口径 84.8%）。
- **满分库 = 7/20**（car_1、employee_hire_evaluation、museum_visit、network_1、poker_player、singer、voter_1）。
- 字段级指标（表命中率 97.0% / 行召回率 0.851 / 字段准确率 0.898）来自 **2026-08-25 详细评测轮**；最新一轮的落盘格式未包含字段级逐题数据，复算需升级 `scripts/eval_spider.py` 后重跑（见「后续动作」）。

## 运行记录

| 轮次 | 日期 | 模型 | 口径 | EX | 部分正确（Jaccard≥0.8） | 宽松参考 | 满分库 | 说明 |
|---|---|---|---|---|---|---|---|---|
| Run 1（详细评测轮） | 2026-08-25 | deepseek-v4-flash | 先宽松后严格 | 78/99 = **78.8%**（严格） | 3 题 | 81.8%（81/99） | 10/20 | 首轮全量落盘字段级指标（表命中/行召回/字段准确）与 A/B/C 失败归因；2026-08-27 收紧为严格判等并写入文档 |
| Run 2（对外口径轮） | 2026-08-28 | deepseek-v4-flash | 严格判等 | 80/99 = **80.8%** | 4 题 | 84.8%（84/99） | 7/20 | 最新运行，结果逐题落盘于 `docs/eval_spider.json`；未复算字段级指标 |

> 说明：Run 2 是代码/提示词微调后的最新复跑，严格判等口径不变。与 Run 1 的差异来自生成结果分布变化（8 题从失败变为通过、部分正确从 3 变为 4），属于正常 run-to-run 波动；对外一律引用 Run 2 的 80.8%，Run 1 仅作为「字段级诊断 + 口径演进」的历史依据。

## 逐库明细（Run 2，2026-08-28，严格判等）

| 数据库 | EX |
|---|---|| battle_death | 4/5 |
| car_1 | 5/5 |
| concert_singer | 4/5 |
| course_teach | 3/5 |
| cre_Doc_Template_Mgt | 4/5 |
| dog_kennels | 4/5 |
| employee_hire_evaluation | 5/5 |
| flight_2 | 4/5 |
| museum_visit | 5/5 |
| network_1 | 5/5 |
| orchestra | 4/5 |
| pets_1 | 4/5 |
| poker_player | 5/5 |
| real_estate_properties | 3/4 |
| singer | 5/5 |
| student_transcripts_tracking | 2/5 |
| tvshow | 3/5 |
| voter_1 | 5/5 |
| world_1 | 3/5 |
| wta_1 | 3/5 |
合计：**80/99 = 80.8%**；7 库满分。

## 口径演进说明

1. **为何严格判等**：结果集完全一致（忽略行序）才计 EX；Jaccard≥0.8 只记 partial_match 参考项，避免“宽松口径自嗨”。最早版本把 Jaccard≥0.8 计入 EX（Run 1 宽松参考 81.8%），2026-08-27 收紧后 Run 1 严格口径为 78.8%。
2. **为何不能与 Spider test SOTA 直接比**：我们评测的是 dev 采样 99 题（1034 题中的子集），zero-shot 单次生成；test SOTA（86-91%）普遍使用 few-shot + 自我一致性投票，协议不同。可比对象是同协议的 zero-shot 基线（业界参考：GPT-4 zero-shot 约 60-75%）。
3. **为何字段级指标来自 Run 1**：Run 2 的落盘脚本只写 EX/Jaccard，未逐题写表命中/行召回/字段准确。Run 1 的字段级诊断结论（表命中 97% 显著高于行召回 0.851，瓶颈在复杂过滤与 JOIN 完整性）仍作为方向性结论使用。

## 后续动作（防再漂移）

- 升级 `scripts/eval_spider.py`：每次运行同时落盘四项字段级指标与评测元数据（commit / prompt hash / 模型版本 / seed），并把 JSON 文件名带上日期（如 `eval_spider_20260828.json`）。
- 把「单一事实源」链接进 README；发布前跑一次 `rg "78.8|81.8|81/99" docs README.md` 做口径回归检查。