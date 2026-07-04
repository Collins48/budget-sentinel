import os

import joblib
from sklearn.ensemble import IsolationForest


def save_model(model: IsolationForest, model_path: str) -> None:
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    joblib.dump(model, model_path)


def load_model(model_path: str) -> IsolationForest:
    if not os.path.exists(model_path):
        raise FileNotFoundError(
            f"No trained model found at {model_path}. Run scripts/train_model.py first."
        )
    return joblib.load(model_path)
