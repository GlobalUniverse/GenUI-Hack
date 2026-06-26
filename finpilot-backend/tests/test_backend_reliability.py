from pytest import approx

from app.core.config import Settings
from app.db.session import Base, SessionLocal, engine
from app.repositories import build_snapshot_from_db, replace_plaid_snapshot
from app.services.plaid_service import PlaidService


class _PlaidResponse:
    def __init__(self, payload: dict):
        self.payload = payload

    def to_dict(self) -> dict:
        return self.payload


class _PagedPlaidClient:
    def __init__(self) -> None:
        self.cursors: list[str | None] = []

    def transactions_sync(self, request) -> _PlaidResponse:
        cursor = request.to_dict().get("cursor")
        self.cursors.append(cursor)
        if cursor is None:
            return _PlaidResponse(
                {
                    "accounts": [{"account_id": "checking-1", "name": "Checking"}],
                    "added": [{"transaction_id": "txn-1", "amount": 12.5}],
                    "modified": [],
                    "removed": [],
                    "next_cursor": "cursor-1",
                    "has_more": True,
                    "request_id": "first",
                }
            )
        return _PlaidResponse(
            {
                "accounts": [{"account_id": "checking-1", "name": "Checking"}],
                "added": [{"transaction_id": "txn-2", "amount": 3.25}],
                "modified": [{"transaction_id": "txn-3", "amount": 7.0}],
                "removed": [{"transaction_id": "old-txn"}],
                "next_cursor": "cursor-2",
                "has_more": False,
                "request_id": "second",
            }
        )


def test_plaid_transaction_sync_paginates_until_complete() -> None:
    service = PlaidService.__new__(PlaidService)
    service.settings = Settings(PLAID_CLIENT_ID="client", PLAID_SECRET="secret")
    service.client = _PagedPlaidClient()

    payload = service.sync_transactions("access-token")

    assert service.client.cursors == [None, "cursor-1"]
    assert [txn["transaction_id"] for txn in payload["added"]] == ["txn-1", "txn-2"]
    assert [txn["transaction_id"] for txn in payload["modified"]] == ["txn-3"]
    assert [txn["transaction_id"] for txn in payload["removed"]] == ["old-txn"]
    assert payload["next_cursor"] == "cursor-2"
    assert payload["has_more"] is False


def test_replace_plaid_snapshot_builds_cashflow_and_categories() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        replace_plaid_snapshot(
            db,
            profile_id="demo",
            plaid_payload={
                "accounts": [
                    {
                        "account_id": "checking-1",
                        "name": "Plaid Checking",
                        "type": "depository",
                        "subtype": "checking",
                        "balances": {
                            "current": 1000,
                            "available": 900,
                            "iso_currency_code": "USD",
                        },
                    }
                ],
                "added": [
                    {
                        "transaction_id": "coffee",
                        "account_id": "checking-1",
                        "name": "Coffee Shop",
                        "amount": 12.34,
                        "date": "2026-06-20",
                        "pending": False,
                        "personal_finance_category": {"primary": "FOOD_AND_DRINK"},
                    },
                    {
                        "transaction_id": "payroll",
                        "account_id": "checking-1",
                        "name": "Payroll",
                        "amount": -2500,
                        "date": "2026-06-21",
                        "pending": False,
                        "personal_finance_category": {"primary": "INCOME"},
                    },
                ],
            },
        )

        snapshot = build_snapshot_from_db(db, "demo")

        assert snapshot is not None
        assert snapshot.source == "plaid_sandbox"
        assert snapshot.accounts[0].name == "Plaid Checking"
        assert {txn.direction for txn in snapshot.transactions} == {"inflow", "outflow"}
        assert snapshot.spending_by_category[0].category == "Food And Drink"
        assert snapshot.spending_by_category[0].amount == approx(12.34)
        assert snapshot.cashflow.income_month_to_date == approx(2500)
        assert snapshot.cashflow.spend_month_to_date == approx(12.34)
        assert snapshot.cashflow.projected_month_end_balance == approx(3387.66)
    finally:
        db.close()
