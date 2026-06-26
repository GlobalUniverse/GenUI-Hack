from sqlalchemy.orm import Session

from app.core.config import Settings
from app.repositories import build_snapshot_from_db
from app.schemas.financial import FinancialSnapshot


class SnapshotService:
    def __init__(self, settings: Settings):
        self.settings = settings

    def get_snapshot(self, db: Session | None = None, profile_id: str | None = None) -> FinancialSnapshot:
        if db is None:
            raise RuntimeError("Database session is required for Plaid-backed snapshots.")

        snapshot = build_snapshot_from_db(db, profile_id or self.settings.demo_profile_id)
        if snapshot is None:
            raise LookupError("No Plaid Sandbox data found. Connect and sync a Plaid item first.")
        return snapshot
