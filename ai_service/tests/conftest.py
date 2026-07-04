import numpy as np
import pytest
from sklearn.ensemble import IsolationForest


@pytest.fixture
def app(monkeypatch):
    dummy_data = np.random.default_rng(42).normal(size=(50, 6))
    stub_model = IsolationForest(n_estimators=20, random_state=42).fit(dummy_data)

    monkeypatch.setenv("ANTHROPIC_API_KEY", "")

    import app as app_package

    monkeypatch.setattr(app_package, "load_model", lambda path: stub_model)

    flask_app = app_package.create_app()
    flask_app.config.update(TESTING=True)
    return flask_app


@pytest.fixture
def client(app):
    return app.test_client()
