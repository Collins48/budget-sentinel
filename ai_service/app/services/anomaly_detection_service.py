from typing import Dict, List

from app.domain.entities import AnomalyResult, ExpenditureRecord, ProjectContext
from app.ml import feature_engineering
from app.ml.isolation_forest_model import anomaly_scores
from app.services import risk_scoring


class AnomalyDetectionService:
    def __init__(self, model):
        self._model = model

    def detect(
        self,
        projects: Dict[str, ProjectContext],
        expenditures: List[ExpenditureRecord],
    ) -> List[AnomalyResult]:
        if not expenditures:
            return []

        ordered = feature_engineering.ordered_expenditures(expenditures)
        feature_matrix = feature_engineering.build_feature_matrix(projects, expenditures)
        scores = anomaly_scores(self._model, feature_matrix)

        results: List[AnomalyResult] = []
        for expenditure, feature_row, anomaly_score in zip(ordered, feature_matrix, scores):
            classification = risk_scoring.classify(feature_row)
            risk_score, classification = risk_scoring.combine_risk_score(
                anomaly_score, classification
            )

            if classification.fraud_type == risk_scoring.NORMAL:
                continue

            results.append(
                AnomalyResult(
                    expenditure_id=expenditure.id,
                    project_id=expenditure.project_id,
                    fraud_type=classification.fraud_type,
                    risk_score=risk_score,
                    severity=risk_scoring.severity_for(risk_score),
                    anomaly_score=float(anomaly_score),
                    explanation=classification.explanation,
                )
            )

        results.sort(key=lambda anomaly: anomaly.risk_score, reverse=True)
        return results
