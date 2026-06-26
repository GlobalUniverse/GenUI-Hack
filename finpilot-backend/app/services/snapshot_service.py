from sqlalchemy.orm import Session

from app.core.config import Settings
from app.data.seed import young_renter_snapshot
from app.schemas.financial import FinancialSnapshot


class SnapshotService:
    def __init__(self, settings: Settings):
        self.settings = settings

    def get_snapshot(self, db: Session | None = None, profile_id: str | None = None) -> FinancialSnapshot:
        # Seeded data is the guaranteed hackathon path. DB/Plaid providers can slot in behind
        # this method without changing Gemini, Flutter, or Twilio contracts.
        del db
        return young_renter_snapshot(profile_id or self.settings.demo_profile_id)
