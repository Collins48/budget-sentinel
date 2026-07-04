from app.domain.entities import ExpenditureRecord, ProjectContext
from app.ml import feature_engineering


def _project(**overrides) -> ProjectContext:
    base = dict(id="PRJ-001", sector="infrastructure", approved_budget=100_000, completion_rate=50.0)
    base.update(overrides)
    return ProjectContext(**base)


def _expenditure(**overrides) -> ExpenditureRecord:
    base = dict(
        id="EXP-001",
        project_id="PRJ-001",
        contractor="Kivu Builders Ltd",
        amount=10_000,
        milestone="foundation",
        date="2024-02-01",
    )
    base.update(overrides)
    return ExpenditureRecord(**base)


def test_budget_ratio_accumulates_across_expenditures():
    project = _project(approved_budget=100_000)
    expenditures = [
        _expenditure(id="EXP-001", amount=40_000, date="2024-01-01"),
        _expenditure(id="EXP-002", amount=70_000, date="2024-01-02"),
    ]

    matrix = feature_engineering.build_feature_matrix({project.id: project}, expenditures)

    assert matrix[0][0] == 0.4
    assert matrix[1][0] == 1.1


def test_duplicate_payment_count_detected():
    project = _project()
    expenditures = [
        _expenditure(id="EXP-001", contractor="A", milestone="foundation", date="2024-01-01"),
        _expenditure(id="EXP-002", contractor="A", milestone="foundation", date="2024-01-02"),
    ]

    matrix = feature_engineering.build_feature_matrix({project.id: project}, expenditures)

    assert matrix[0][3] == 1.0
    assert matrix[1][3] == 1.0


def test_zero_completion_full_payment_flag():
    project = _project(completion_rate=0.0)
    expenditures = [_expenditure(amount=50_000)]

    matrix = feature_engineering.build_feature_matrix({project.id: project}, expenditures)

    assert matrix[0][5] == 1.0
