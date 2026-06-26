from fastapi import APIRouter

from app.core.config import get_settings

router = APIRouter()


@router.get("/health")
def health() -> dict:
    settings = get_settings()
    return {
        "ok": True,
        "gemini_configured": settings.gemini_configured,
        "plaid_configured": settings.plaid_configured,
        "supabase_configured": settings.supabase_configured,
        "use_seeded_data": settings.use_seeded_data,
    }
