# Database Design

PostgreSQL, owned entirely by the Elixir service through Ecto. The Python AI microservice has no database access.

## Entity-relationship overview

```
projects 1───* expenditures 1───* anomalies 1───1 audit_reports
                                      │
                                      *
                                   alerts
```

## Tables

### `projects`
| Column | Type | Notes |
|---|---|---|
| name | string | |
| sector | string | one of `infrastructure, education, health, water, energy` |
| approved_budget | decimal(14,2) | |
| market_benchmark | decimal(14,2) | nullable; typical cost for this project type |
| completion_rate | decimal(5,1) | 0–100 |
| milestones | array(string) | |

### `expenditures`
| Column | Type | Notes |
|---|---|---|
| project_id | references projects | `on_delete: :delete_all` |
| contractor | string | |
| amount | decimal(14,2) | |
| milestone | string | |
| paid_on | date | |

### `anomalies`
| Column | Type | Notes |
|---|---|---|
| project_id | references projects | |
| expenditure_id | references expenditures | |
| fraud_type | string | `budget_overrun \| duplicate_payment \| ghost_project \| inflated_contract \| premature_payment \| unclassified_anomaly` |
| risk_score | decimal(5,2) | 0–100, from the AI service |
| severity | string | `low \| medium \| high` |
| anomaly_score | decimal(6,4) | raw normalized Isolation Forest score |
| explanation | text | |
| detected_at | utc_datetime | |

### `audit_reports`
| Column | Type | Notes |
|---|---|---|
| anomaly_id | references anomalies, unique | one report per anomaly |
| summary | text | |
| severity_assessment | text | |
| recommended_actions | text | |

### `alerts`
| Column | Type | Notes |
|---|---|---|
| anomaly_id | references anomalies | |
| recipient | string | oversight officer email |
| status | string | `pending \| sent \| failed` |
| dispatched_at | utc_datetime | nullable |

## Seeding

`priv/repo/seeds.exs` generates the full simulated Rwanda dataset described in the proposal directly in Elixir (no dependency on the Python service or any external file): 50 projects across the five sectors, 190 ordinary expenditures, and 10 embedded fraud scenarios — two each of the five known patterns (`budget_overrun`, `duplicate_payment`, `ghost_project`, `inflated_contract`, `premature_payment`). Run it with `mix ecto.setup` (or `mix run priv/repo/seeds.exs` against an already-migrated database).
