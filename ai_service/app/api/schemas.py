from typing import Dict, List, Tuple

from app.domain.entities import ExpenditureRecord, ProjectContext

_PROJECT_FIELDS = ("id", "sector", "approved_budget", "completion_rate")
_EXPENDITURE_FIELDS = ("id", "project_id", "contractor", "amount", "milestone", "date")


class ValidationError(Exception):
    pass


def _require(payload: dict, fields: Tuple[str, ...], label: str) -> None:
    missing = [field for field in fields if field not in payload]
    if missing:
        raise ValidationError(f"{label} missing required fields: {', '.join(missing)}")


def parse_detection_request(body: dict) -> Tuple[Dict[str, ProjectContext], List[ExpenditureRecord]]:
    if not isinstance(body, dict) or "projects" not in body or "expenditures" not in body:
        raise ValidationError("Request body must contain 'projects' and 'expenditures'")

    projects: Dict[str, ProjectContext] = {}
    for raw_project in body["projects"]:
        _require(raw_project, _PROJECT_FIELDS, "project")
        project = ProjectContext(
            id=str(raw_project["id"]),
            sector=raw_project["sector"],
            approved_budget=float(raw_project["approved_budget"]),
            completion_rate=float(raw_project["completion_rate"]),
            market_benchmark=(
                float(raw_project["market_benchmark"])
                if raw_project.get("market_benchmark") is not None
                else None
            ),
        )
        projects[project.id] = project

    expenditures: List[ExpenditureRecord] = []
    for raw_expenditure in body["expenditures"]:
        _require(raw_expenditure, _EXPENDITURE_FIELDS, "expenditure")
        if raw_expenditure["project_id"] not in projects:
            raise ValidationError(
                f"Expenditure {raw_expenditure['id']} references unknown project "
                f"{raw_expenditure['project_id']}"
            )
        expenditures.append(
            ExpenditureRecord(
                id=str(raw_expenditure["id"]),
                project_id=str(raw_expenditure["project_id"]),
                contractor=raw_expenditure["contractor"],
                amount=float(raw_expenditure["amount"]),
                milestone=raw_expenditure["milestone"],
                date=raw_expenditure["date"],
            )
        )

    return projects, expenditures


def parse_report_request(body: dict) -> dict:
    required = ("anomaly", "project", "expenditure")
    _require(body, required, "report request")
    _require(body["anomaly"], ("fraud_type", "risk_score", "severity", "explanation"), "anomaly")
    _require(body["project"], _PROJECT_FIELDS, "project")
    _require(body["expenditure"], _EXPENDITURE_FIELDS, "expenditure")
    return body
