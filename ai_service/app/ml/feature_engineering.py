from collections import defaultdict
from typing import Dict, List, Tuple

import numpy as np

from app.domain.entities import ExpenditureRecord, ProjectContext

FEATURE_NAMES = [
    "budget_ratio",
    "amount_to_budget_fraction",
    "completion_payment_gap",
    "duplicate_payment_count",
    "inflated_contract_ratio",
    "zero_completion_full_payment",
]


def _milestone_key(expenditure: ExpenditureRecord) -> Tuple[str, str, str]:
    return (expenditure.project_id, expenditure.contractor, expenditure.milestone)


def build_feature_matrix(
    projects: Dict[str, ProjectContext],
    expenditures: List[ExpenditureRecord],
) -> np.ndarray:
    cumulative_by_project: Dict[str, float] = defaultdict(float)
    payments_by_milestone: Dict[Tuple[str, str, str], int] = defaultdict(int)
    for expenditure in expenditures:
        payments_by_milestone[_milestone_key(expenditure)] += 1

    rows = []
    for expenditure in sorted(expenditures, key=lambda record: record.date):
        project = projects[expenditure.project_id]
        cumulative_by_project[project.id] += expenditure.amount
        budget_ratio = cumulative_by_project[project.id] / max(project.approved_budget, 1.0)
        amount_to_budget_fraction = expenditure.amount / max(project.approved_budget, 1.0)
        payment_completion_pct = amount_to_budget_fraction * 100
        completion_payment_gap = payment_completion_pct - project.completion_rate
        duplicate_payment_count = payments_by_milestone[_milestone_key(expenditure)] - 1
        benchmark = project.market_benchmark or project.approved_budget
        inflated_contract_ratio = expenditure.amount / max(benchmark, 1.0)
        zero_completion_full_payment = (
            1.0 if project.completion_rate <= 0 and amount_to_budget_fraction > 0.05 else 0.0
        )

        rows.append(
            [
                budget_ratio,
                amount_to_budget_fraction,
                completion_payment_gap,
                float(duplicate_payment_count),
                inflated_contract_ratio,
                zero_completion_full_payment,
            ]
        )

    return np.array(rows, dtype=float)


def ordered_expenditures(expenditures: List[ExpenditureRecord]) -> List[ExpenditureRecord]:
    return sorted(expenditures, key=lambda record: record.date)
