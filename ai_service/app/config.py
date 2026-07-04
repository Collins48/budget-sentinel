import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Config:
    anthropic_api_key: str
    anthropic_model: str
    flask_port: int
    isolation_forest_contamination: float
    high_risk_threshold: float
    model_path: str

    @staticmethod
    def from_env() -> "Config":
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        return Config(
            anthropic_api_key=os.environ.get("ANTHROPIC_API_KEY", ""),
            anthropic_model=os.environ.get("ANTHROPIC_MODEL", "claude-sonnet-4-6"),
            flask_port=int(os.environ.get("FLASK_PORT", "5000")),
            isolation_forest_contamination=float(
                os.environ.get("ISOLATION_FOREST_CONTAMINATION", "0.08")
            ),
            high_risk_threshold=float(os.environ.get("HIGH_RISK_THRESHOLD", "70")),
            model_path=os.path.join(base_dir, "models", "isolation_forest.joblib"),
        )
