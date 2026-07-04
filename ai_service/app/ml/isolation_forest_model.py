import numpy as np
from sklearn.ensemble import IsolationForest


def train_isolation_forest(feature_matrix: np.ndarray, contamination: float) -> IsolationForest:
    model = IsolationForest(
        n_estimators=200,
        contamination=contamination,
        random_state=42,
    )
    model.fit(feature_matrix)
    return model


def anomaly_scores(model: IsolationForest, feature_matrix: np.ndarray) -> np.ndarray:
    raw_scores = model.score_samples(feature_matrix)
    normalized = (raw_scores.max() - raw_scores) / (
        raw_scores.max() - raw_scores.min() + 1e-9
    )
    return normalized
