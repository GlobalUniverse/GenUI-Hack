from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_defaults() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["ok"] is True


def test_snapshot_requires_plaid_data() -> None:
    response = client.get("/api/snapshot")
    assert response.status_code == 404


def test_advisor_requires_plaid_data() -> None:
    response = client.post(
        "/api/advisor",
        json={"profile_id": "demo", "message": "Can I afford a $120 dinner tonight?"},
    )
    assert response.status_code == 404
