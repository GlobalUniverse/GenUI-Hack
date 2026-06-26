from fastapi import APIRouter, HTTPException

from app.core.config import get_settings
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
def exchange_token(request: ExchangeTokenRequest) -> ExchangeTokenResponse:
    try:
        payload = PlaidService(get_settings()).exchange_public_token(request.public_token)
        return ExchangeTokenResponse(item_id=payload.get("item_id"), stored=False, snapshot_synced=False)
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
