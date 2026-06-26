from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.schemas.financial import AlertSnapshot
from app.services.snapshot_service import SnapshotService

router = APIRouter(prefix="/api/alerts", tags=["alerts"])


@router.post("/check", response_model=list[AlertSnapshot])
def check_alerts(profile_id: str = "demo", db: Session = Depends(get_db)) -> list[AlertSnapshot]:
    snapshot = SnapshotService(get_settings()).get_snapshot(db, profile_id)
    return snapshot.alerts
