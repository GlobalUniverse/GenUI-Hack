from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.models import Profile
from app.repositories import replace_proactive_alerts
from app.schemas.financial import AlertSnapshot
from app.services.proactive_advisor import run_proactive_scan
from app.services.snapshot_service import SnapshotService
from app.services.twilio_client import send_proactive_sms

router = APIRouter(prefix="/api/alerts", tags=["alerts"])


@router.post("/check", response_model=list[AlertSnapshot])
def check_alerts(profile_id: str = "demo", db: Session = Depends(get_db)) -> list[AlertSnapshot]:
    try:
        snapshot = SnapshotService(get_settings()).get_snapshot(db, profile_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return snapshot.alerts


@router.post("/scan", response_model=list[AlertSnapshot])
def scan_for_proactive_alerts(profile_id: str = "demo", db: Session = Depends(get_db)) -> list[AlertSnapshot]:
    """Run the proactive monitoring tools against the latest snapshot and persist fresh findings."""
    settings = get_settings()
    try:
        snapshot = SnapshotService(settings).get_snapshot(db, profile_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    findings = run_proactive_scan(settings, snapshot)
    rows = replace_proactive_alerts(db, profile_id=profile_id, findings=findings)

    critical = next((row for row in rows if row.severity == "critical"), None)
    if critical:
        profile = db.get(Profile, profile_id)
        if profile and profile.phone:
            send_proactive_sms(settings, to_number=profile.phone, body=f"{critical.title}: {critical.body}")

    return [
        AlertSnapshot(id=row.id, type=row.type, severity=row.severity, message=row.body, payload=row.payload or {})
        for row in rows
    ]
