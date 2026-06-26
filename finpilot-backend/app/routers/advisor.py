from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.schemas.advisor import AdvisorRequest, AdvisorResponse
from app.services.gemini_advisor import GeminiAdvisor
from app.services.snapshot_service import SnapshotService

router = APIRouter(prefix="/api", tags=["advisor"])
client_router = APIRouter(tags=["advisor-client"])


def get_advisor_response(
    db: Session,
    settings: Settings,
    *,
    profile_id: str,
    message: str,
    channel: str = "app",
) -> AdvisorResponse:
    """Shared core: build the snapshot, ask Gemini, return the response.

    Used by both the app-facing routes below and the Twilio SMS webhook so
    every channel goes through identical advisor logic.
    """
    snapshot = SnapshotService(settings).get_snapshot(db, profile_id)
    return GeminiAdvisor(settings).answer(message, snapshot, channel)


@router.post("/advisor", response_model=AdvisorResponse)
def ask_advisor(request: AdvisorRequest, db: Session = Depends(get_db)) -> AdvisorResponse:
    settings = get_settings()
    try:
        return get_advisor_response(
            db, settings, profile_id=request.profile_id, message=request.message, channel=request.channel
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


class FlutterAdvisorRequest(BaseModel):
    """Matches Flutter's ApiService.askAdvisor body exactly: {question, history}."""

    question: str
    history: list[dict[str, Any]] = Field(default_factory=list)


@client_router.post("/advisor", response_model=AdvisorResponse)
def ask_advisor_for_client(request: FlutterAdvisorRequest, db: Session = Depends(get_db)) -> AdvisorResponse:
    settings = get_settings()
    try:
        return get_advisor_response(
            db, settings, profile_id=settings.demo_profile_id, message=request.question, channel="app"
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
