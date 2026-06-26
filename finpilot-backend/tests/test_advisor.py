from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_defaults() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["ok"] is True


def test_snapshot_seeded() -> None:
    response = client.get("/api/snapshot")
    assert response.status_code == 200
    payload = response.json()
    assert payload["source"] == "seeded"
    assert payload["accounts"]
    assert payload["alerts"]


def test_advisor_fallback_dinner() -> None:
    response = client.post(
        "/api/advisor",
        json={"profile_id": "demo", "message": "Can I afford a $120 dinner tonight?"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["source"] == "fallback"
    assert any(widget["type"] == "recommendation_card" for widget in payload["widgets"])
