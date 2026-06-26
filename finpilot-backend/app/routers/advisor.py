from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.schemas.advisor import AdvisorRequest, AdvisorResponse
from app.services.gemini_advisor import GeminiAdvisor
from app.services.snapshot_service import SnapshotService

router = APIRouter(prefix="/api", tags=["advisor"])


@router.post("/advisor", response_model=AdvisorResponse)
def ask_advisor(request: AdvisorRequest, db: Session = Depends(get_db)) -> AdvisorResponse:
    settings = get_settings()
    snapshot = SnapshotService(settings).get_snapshot(db, request.profile_id)
    return GeminiAdvisor(settings).answer(request.message, snapshot, request.channel)
