from flask import Blueprint, current_app, jsonify, request

from app.api.schemas import ValidationError, parse_detection_request, parse_report_request
from app.domain.entities import AnomalyResult, ExpenditureRecord, ProjectContext

bp = Blueprint("api", __name__, url_prefix="/api/v1")


@bp.get("/health")
def health():
    return jsonify(status="ok")


@bp.post("/anomalies/detect")
def detect_anomalies():
    try:
        projects, expenditures = parse_detection_request(request.get_json(force=True) or {})
    except ValidationError as error:
        return jsonify(error=str(error)), 400

    service = current_app.extensions["anomaly_detection_service"]
    anomalies = service.detect(projects, expenditures)
    return jsonify(anomalies=[anomaly.to_dict() for anomaly in anomalies])


@bp.post("/audit-reports/generate")
def generate_audit_report():
    try:
        body = parse_report_request(request.get_json(force=True) or {})
    except ValidationError as error:
        return jsonify(error=str(error)), 400

    anomaly = AnomalyResult(
        expenditure_id=body["expenditure"]["id"],
        project_id=body["project"]["id"],
        fraud_type=body["anomaly"]["fraud_type"],
        risk_score=float(body["anomaly"]["risk_score"]),
        severity=body["anomaly"]["severity"],
        anomaly_score=float(body["anomaly"].get("anomaly_score", 0.0)),
        explanation=body["anomaly"]["explanation"],
    )
    project = ProjectContext(
        id=body["project"]["id"],
        sector=body["project"]["sector"],
        approved_budget=float(body["project"]["approved_budget"]),
        completion_rate=float(body["project"]["completion_rate"]),
        market_benchmark=body["project"].get("market_benchmark"),
    )
    expenditure = ExpenditureRecord(
        id=body["expenditure"]["id"],
        project_id=body["expenditure"]["project_id"],
        contractor=body["expenditure"]["contractor"],
        amount=float(body["expenditure"]["amount"]),
        milestone=body["expenditure"]["milestone"],
        date=body["expenditure"]["date"],
    )

    service = current_app.extensions["audit_report_service"]
    report = service.generate(anomaly, project, expenditure)
    return jsonify(report)
