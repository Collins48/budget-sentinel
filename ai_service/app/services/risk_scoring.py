from dataclasses import dataclass

DUPLICATE_PAYMENT = "duplicate_payment"
GHOST_PROJECT = "ghost_project"
PREMATURE_PAYMENT = "premature_payment"
INFLATED_CONTRACT = "inflated_contract"
BUDGET_OVERRUN = "budget_overrun"
UNCLASSIFIED_ANOMALY = "unclassified_anomaly"
NORMAL = "normal"

_EXPLANATIONS = {
    DUPLICATE_PAYMENT: "Same contractor was paid more than once for the same milestone.",
    GHOST_PROJECT: "Full payment was disbursed against a project reporting zero completion.",
    PREMATURE_PAYMENT: "Payment amount far exceeds the project's reported completion percentage.",
    INFLATED_CONTRACT: "Payment amount is well above the market benchmark for this project type.",
    BUDGET_OVERRUN: "Cumulative project spending has exceeded the approved budget.",
    UNCLASSIFIED_ANOMALY: "Expenditure pattern deviates from normal behavior but does not match a known fraud signature.",
    NORMAL: "Expenditure is consistent with approved budget and project progress.",
}


@dataclass(frozen=True)
class Classification:
    fraud_type: str
    rule_strength: float
    explanation: str


def classify(feature_row) -> Classification:
    (
        budget_ratio,
        amount_to_budget_fraction,
        completion_payment_gap,
        duplicate_payment_count,
        inflated_contract_ratio,
        zero_completion_full_payment,
    ) = feature_row

    if duplicate_payment_count >= 1:
        strength = min(100.0, 50.0 + duplicate_payment_count * 25.0)
        return Classification(DUPLICATE_PAYMENT, strength, _EXPLANATIONS[DUPLICATE_PAYMENT])

    if zero_completion_full_payment >= 1:
        strength = min(100.0, 70.0 + amount_to_budget_fraction * 30.0)
        return Classification(GHOST_PROJECT, strength, _EXPLANATIONS[GHOST_PROJECT])

    if completion_payment_gap > 40:
        strength = min(100.0, max(50.0, completion_payment_gap))
        return Classification(PREMATURE_PAYMENT, strength, _EXPLANATIONS[PREMATURE_PAYMENT])

    if inflated_contract_ratio > 1.5:
        strength = min(100.0, (inflated_contract_ratio - 1.0) * 100.0)
        return Classification(INFLATED_CONTRACT, strength, _EXPLANATIONS[INFLATED_CONTRACT])

    if budget_ratio > 1.0:
        strength = min(100.0, (budget_ratio - 1.0) * 100.0 + 40.0)
        return Classification(BUDGET_OVERRUN, strength, _EXPLANATIONS[BUDGET_OVERRUN])

    return Classification(NORMAL, 0.0, _EXPLANATIONS[NORMAL])


def severity_for(risk_score: float) -> str:
    if risk_score >= 70:
        return "high"
    if risk_score >= 40:
        return "medium"
    return "low"


def combine_risk_score(anomaly_score: float, classification: Classification):
    if classification.fraud_type == NORMAL and anomaly_score > 0.6:
        classification = Classification(
            UNCLASSIFIED_ANOMALY, anomaly_score * 100.0, _EXPLANATIONS[UNCLASSIFIED_ANOMALY]
        )
    return _score(anomaly_score, classification), classification


def _score(anomaly_score: float, classification: Classification) -> float:
    raw = 0.5 * anomaly_score * 100.0 + 0.5 * classification.rule_strength
    return max(0.0, min(100.0, raw))
