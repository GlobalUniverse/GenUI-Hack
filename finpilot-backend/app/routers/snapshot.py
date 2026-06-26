from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.schemas.financial import ClientSnapshot, FinancialSnapshot
from app.services.client_snapshot import to_client_snapshot
from app.services.snapshot_service import SnapshotService

router = APIRouter(prefix="/api", tags=["snapshot"])
client_router = APIRouter(tags=["snapshot-client"])


@router.get("/snapshot", response_model=FinancialSnapshot)
def get_snapshot(profile_id: str | None = None, db: Session = Depends(get_db)) -> FinancialSnapshot:
    service = SnapshotService(get_settings())
    try:
        return service.get_snapshot(db, profile_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@client_router.get("/snapshot", response_model=ClientSnapshot)
def get_snapshot_for_client(profile_id: str | None = None, db: Session = Depends(get_db)) -> ClientSnapshot:
    """Flat-shaped snapshot matching Flutter's FinancialSnapshot.fromJson exactly."""
    service = SnapshotService(get_settings())
    try:
        snapshot = service.get_snapshot(db, profile_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return to_client_snapshot(snapshot)
