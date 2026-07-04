from flask import Flask

from app.config import Config
from app.ml.model_store import load_model
from app.services.anomaly_detection_service import AnomalyDetectionService
from app.services.audit_report_service import AuditReportService


def create_app(config: Config = None) -> Flask:
    config = config or Config.from_env()
    app = Flask(__name__)

    model = load_model(config.model_path)
    app.extensions["anomaly_detection_service"] = AnomalyDetectionService(model)
    app.extensions["audit_report_service"] = AuditReportService(
        config.anthropic_api_key, config.anthropic_model
    )

    from app.api.routes import bp as api_bp

    app.register_blueprint(api_bp)
    return app
