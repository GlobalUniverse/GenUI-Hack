from typing import Callable

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.models import Alert, Profile
from app.repositories import replace_proactive_alerts
from app.schemas.financial import AlertSnapshot
from app.services.proactive_advisor import run_proactive_scan
from app.services.snapshot_service import SnapshotService
from app.services.twilio_client import send_proactive_sms

router = APIRouter(prefix="/api/alerts", tags=["alerts"])

# type -> handler. Each handler executes whatever action this alert type
# allows and returns the new status. This is the ONLY place a proposal can
# turn into a real (paper) trade -- nothing in the scan or in Gemini's
# tool-calling loop can reach this. A human tap on /approve is required.
# The Alpaca tool agent registers "fixed_income_proposal" here; until then
# it falls through to the generic acknowledge-only default below.
APPROVAL_HANDLERS: dict[str, Callable[[Session, Alert], str]] = {}


def register_approval_handler(alert_type: str) -> Callable[[Callable[[Session, Alert], str]], Callable]:
    def decorator(fn: Callable[[Session, Alert], str]) -> Callable:
        APPROVAL_HANDLERS[alert_type] = fn
        return fn

    return decorator


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


@router.post("/{alert_id}/approve")
def approve_alert(alert_id: str, db: Session = Depends(get_db)) -> dict:
    """User explicitly approved this finding. Only place a proposal can become a real action."""
    alert = db.get(Alert, alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")

    handler = APPROVAL_HANDLERS.get(alert.type)
    alert.status = handler(db, alert) if handler else "accepted"
    db.commit()
    return {"id": alert.id, "type": alert.type, "status": alert.status}


@router.post("/{alert_id}/dismiss")
def dismiss_alert(alert_id: str, db: Session = Depends(get_db)) -> dict:
    alert = db.get(Alert, alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert.status = "dismissed"
    db.commit()
    return {"id": alert.id, "status": alert.status}
