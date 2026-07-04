from app.services import risk_scoring


def test_classify_detects_duplicate_payment():
    feature_row = [0.5, 0.2, 0.0, 1, 1.0, 0.0]
    classification = risk_scoring.classify(feature_row)
    assert classification.fraud_type == risk_scoring.DUPLICATE_PAYMENT


def test_classify_detects_ghost_project():
    feature_row = [0.5, 0.4, 0.0, 0, 1.0, 1.0]
    classification = risk_scoring.classify(feature_row)
    assert classification.fraud_type == risk_scoring.GHOST_PROJECT


def test_classify_detects_inflated_contract():
    feature_row = [0.5, 0.4, 0.0, 0, 2.0, 0.0]
    classification = risk_scoring.classify(feature_row)
    assert classification.fraud_type == risk_scoring.INFLATED_CONTRACT


def test_classify_detects_budget_overrun():
    feature_row = [1.2, 0.4, 0.0, 0, 1.0, 0.0]
    classification = risk_scoring.classify(feature_row)
    assert classification.fraud_type == risk_scoring.BUDGET_OVERRUN


def test_classify_normal_expenditure():
    feature_row = [0.5, 0.1, -10.0, 0, 1.0, 0.0]
    classification = risk_scoring.classify(feature_row)
    assert classification.fraud_type == risk_scoring.NORMAL


def test_severity_thresholds():
    assert risk_scoring.severity_for(80) == "high"
    assert risk_scoring.severity_for(50) == "medium"
    assert risk_scoring.severity_for(10) == "low"


def test_combine_risk_score_caps_at_100():
    classification = risk_scoring.classify([2.0, 0.9, 0.0, 3, 1.0, 0.0])
    risk_score, resolved = risk_scoring.combine_risk_score(1.0, classification)
    assert 0.0 <= risk_score <= 100.0
    assert resolved.fraud_type == risk_scoring.DUPLICATE_PAYMENT
