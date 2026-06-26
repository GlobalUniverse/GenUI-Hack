from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.repositories import replace_plaid_snapshot, store_plaid_item
from app.schemas.plaid import (
    ExchangeTokenRequest,
    ExchangeTokenResponse,
    LinkTokenRequest,
    LinkTokenResponse,
    SandboxPublicTokenRequest,
    SandboxPublicTokenResponse,
)
from app.services.plaid_service import PlaidService

router = APIRouter(prefix="/api/plaid", tags=["plaid"])


@router.post("/sandbox/public-token", response_model=SandboxPublicTokenResponse)
def create_sandbox_public_token(request: SandboxPublicTokenRequest) -> SandboxPublicTokenResponse:
    try:
        payload = PlaidService(get_settings()).create_sandbox_public_token(
            request.institution_id, request.products
        )
        return SandboxPublicTokenResponse(
            public_token=payload["public_token"], request_id=payload.get("request_id")
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.post("/exchange-token", response_model=ExchangeTokenResponse)
def exchange_token(
    request: ExchangeTokenRequest, db: Session = Depends(get_db)
) -> ExchangeTokenResponse:
    try:
        service = PlaidService(get_settings())
        payload = service.exchange_public_token(request.public_token)
        store_plaid_item(
            db,
            profile_id=request.profile_id,
            access_token=payload["access_token"],
            plaid_item_id=payload.get("item_id"),
        )
        sync_payload = service.sync_transactions(payload["access_token"])
        replace_plaid_snapshot(db, profile_id=request.profile_id, plaid_payload=sync_payload)
        return ExchangeTokenResponse(
            item_id=payload.get("item_id"), stored=True, snapshot_synced=True
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.post("/link-token", response_model=LinkTokenResponse)
def create_link_token(request: LinkTokenRequest) -> LinkTokenResponse:
    try:
        payload = PlaidService(get_settings()).create_link_token(request.profile_id)
        return LinkTokenResponse(
            link_token=payload["link_token"],
            expiration=str(payload.get("expiration")) if payload.get("expiration") else None,
            request_id=payload.get("request_id"),
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
