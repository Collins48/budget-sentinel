def test_health_endpoint(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"


def test_detect_anomalies_rejects_invalid_body(client):
    response = client.post("/api/v1/anomalies/detect", json={})
    assert response.status_code == 400


def test_detect_anomalies_returns_results(client):
    body = {
        "projects": [
            {"id": "PRJ-001", "sector": "infrastructure", "approved_budget": 100000, "completion_rate": 0.0}
        ],
        "expenditures": [
            {
                "id": "EXP-001",
                "project_id": "PRJ-001",
                "contractor": "Kivu Builders Ltd",
                "amount": 60000,
                "milestone": "handover",
                "date": "2024-03-01",
            }
        ],
    }
    response = client.post("/api/v1/anomalies/detect", json=body)
    assert response.status_code == 200
    anomalies = response.get_json()["anomalies"]
    assert len(anomalies) == 1
    assert anomalies[0]["fraud_type"] == "ghost_project"


def test_generate_audit_report_uses_fallback_without_api_key(client):
    body = {
        "anomaly": {
            "fraud_type": "ghost_project",
            "risk_score": 85.0,
            "severity": "high",
            "explanation": "Full payment disbursed against zero completion.",
        },
        "project": {
            "id": "PRJ-001",
            "sector": "infrastructure",
            "approved_budget": 100000,
            "completion_rate": 0.0,
        },
        "expenditure": {
            "id": "EXP-001",
            "project_id": "PRJ-001",
            "contractor": "Kivu Builders Ltd",
            "amount": 60000,
            "milestone": "handover",
            "date": "2024-03-01",
        },
    }
    response = client.post("/api/v1/audit-reports/generate", json=body)
    assert response.status_code == 200
    report = response.get_json()
    assert "summary" in report and report["summary"]
