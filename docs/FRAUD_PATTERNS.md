# Embedded Fraud Patterns

Five procurement irregularity types are detected by the AI service (`ai_service/app/services/risk_scoring.py`), each backed by a specific signal computed in `ai_service/app/ml/feature_engineering.py`. Two scenarios of each are embedded in the simulated dataset (`web/priv/repo/seeds.exs`).

| Fraud type | Detection signal | Rule |
|---|---|---|
| `budget_overrun` | `budget_ratio` — cumulative project spend ÷ approved budget | triggers when cumulative spend exceeds 100% of approved budget |
| `duplicate_payment` | `duplicate_payment_count` — count of payments to the same contractor for the same milestone on the same project, minus one | triggers when a contractor is paid more than once for the same milestone |
| `ghost_project` | `zero_completion_full_payment` — flag set when a project reports 0% completion but still receives a non-trivial payment | triggers when completion is 0% and payment exceeds 5% of approved budget |
| `inflated_contract` | `inflated_contract_ratio` — payment amount ÷ market benchmark for the project type | triggers above 1.5x the benchmark |
| `premature_payment` | `completion_payment_gap` — (payment as % of budget) − (reported completion %) | triggers when the gap exceeds 40 percentage points |

Rule checks run in the order above (first match wins), because some fraud patterns overlap — e.g. a duplicate payment on an over-budget project is reported as `duplicate_payment` since that's the more specific, actionable finding for an auditor.

Each rule produces a "rule strength" (0–100) which is blended 50/50 with the normalized Isolation Forest anomaly score to produce the final `risk_score`. This means a transaction can be flagged even if it matches none of the five explicit rules, provided the unsupervised model still considers it statistically unusual — these surface as `unclassified_anomaly`, prompting manual review rather than a specific accusation.

Expenditures that match no rule and aren't flagged as statistically anomalous (`anomaly_score <= 0.6`) are not returned by `/api/v1/anomalies/detect` at all.
