from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class ProjectContext:
    id: str
    sector: str
    approved_budget: float
    completion_rate: float
    market_benchmark: Optional[float] = None


@dataclass(frozen=True)
class ExpenditureRecord:
    id: str
    project_id: str
    contractor: str
    amount: float
    milestone: str
    date: str


@dataclass(frozen=True)
class AnomalyResult:
    expenditure_id: str
    project_id: str
    fraud_type: str
    risk_score: float
    severity: str
    anomaly_score: float
    explanation: str

    def to_dict(self) -> dict:
        return {
            "expenditure_id": self.expenditure_id,
            "project_id": self.project_id,
            "fraud_type": self.fraud_type,
            "risk_score": round(self.risk_score, 2),
            "severity": self.severity,
            "anomaly_score": round(self.anomaly_score, 4),
            "explanation": self.explanation,
        }
