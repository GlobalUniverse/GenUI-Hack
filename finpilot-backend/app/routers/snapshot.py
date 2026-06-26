from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.schemas.financial import FinancialSnapshot
from app.services.snapshot_service import SnapshotService

router = APIRouter(prefix="/api", tags=["snapshot"])


@router.get("/snapshot", response_model=FinancialSnapshot)
def get_snapshot(profile_id: str | None = None, db: Session = Depends(get_db)) -> FinancialSnapshot:
    service = SnapshotService(get_settings())
    return service.get_snapshot(db, profile_id)
