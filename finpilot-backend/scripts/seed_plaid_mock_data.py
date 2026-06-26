"""Hackathon-only seed script. DELETE after Plaid Sandbox linking is demoed live.

Builds a payload shaped exactly like Plaid's /transactions/sync response and
feeds it through the same `replace_plaid_snapshot` function the real
/api/plaid/exchange-token flow uses, so seeded data is indistinguishable from
a real Plaid Sandbox link. Goals/alerts aren't part of Plaid sync, so those
are inserted directly via the ORM.

Run from finpilot-backend/:
    python scripts/seed_plaid_mock_data.py [profile_id]
"""

import sys
from datetime import date, timedelta
from pathlib import Path
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db.session import Base, SessionLocal, engine  # noqa: E402
from app.models import Alert, Goal  # noqa: E402
from app.repositories import ensure_profile, replace_plaid_snapshot, store_plaid_item  # noqa: E402


def build_plaid_sync_payload(today: date) -> dict:
    return {
        "accounts": [
            {
                "account_id": "checking_demo",
                "name": "Everyday Checking",
                "type": "depository",
                "subtype": "checking",
                "balances": {"current": 842.12, "available": 790.12, "iso_currency_code": "USD"},
            },
            {
                "account_id": "savings_demo",
                "name": "Starter Savings",
                "type": "depository",
                "subtype": "savings",
                "balances": {"current": 460.00, "available": 460.00, "iso_currency_code": "USD"},
            },
            {
                "account_id": "credit_demo",
                "name": "Rewards Card",
                "type": "credit",
                "subtype": "credit card",
                "balances": {"current": 1264.40, "available": 1735.60, "iso_currency_code": "USD"},
            },
        ],
        "added": [
            # Plaid convention: positive amount = outflow/debit, negative = inflow/credit.
            {
                "transaction_id": "txn_paycheck",
                "account_id": "checking_demo",
                "name": "Direct Deposit",
                "merchant_name": "Acme Studio",
                "amount": -4200.00,
                "date": (today - timedelta(days=6)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "INCOME"},
            },
            {
                "transaction_id": "txn_rent",
                "account_id": "checking_demo",
                "name": "Rent",
                "amount": 1500.00,
                "date": (today + timedelta(days=1)).isoformat(),
                "pending": True,
                "personal_finance_category": {"primary": "RENT_AND_UTILITIES"},
            },
            {
                "transaction_id": "txn_electric",
                "account_id": "checking_demo",
                "name": "Electric Bill",
                "merchant_name": "City Power",
                "amount": 95.00,
                "date": (today + timedelta(days=8)).isoformat(),
                "pending": True,
                "personal_finance_category": {"primary": "RENT_AND_UTILITIES"},
            },
            {
                "transaction_id": "txn_dinner",
                "account_id": "credit_demo",
                "name": "Dinner",
                "merchant_name": "Local Bistro",
                "amount": 64.22,
                "date": (today - timedelta(days=1)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "FOOD_AND_DRINK"},
            },
            {
                "transaction_id": "txn_coffee",
                "account_id": "credit_demo",
                "name": "Coffee",
                "merchant_name": "Blue Bottle",
                "amount": 6.75,
                "date": (today - timedelta(days=1)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "FOOD_AND_DRINK"},
            },
            {
                "transaction_id": "txn_groceries",
                "account_id": "credit_demo",
                "name": "Groceries",
                "merchant_name": "Trader Joe's",
                "amount": 96.43,
                "date": (today - timedelta(days=3)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "FOOD_AND_DRINK"},
            },
            {
                "transaction_id": "txn_rideshare_1",
                "account_id": "credit_demo",
                "name": "Ride Share",
                "merchant_name": "Lyft",
                "amount": 38.90,
                "date": (today - timedelta(days=2)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "TRANSPORTATION"},
            },
            {
                "transaction_id": "txn_rideshare_2",
                "account_id": "credit_demo",
                "name": "Ride Share",
                "merchant_name": "Uber",
                "amount": 24.50,
                "date": (today - timedelta(days=5)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "TRANSPORTATION"},
            },
            {
                "transaction_id": "txn_streaming",
                "account_id": "credit_demo",
                "name": "Streaming Subscription",
                "merchant_name": "Streamly",
                "amount": 18.99,
                "date": (today - timedelta(days=4)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "ENTERTAINMENT"},
            },
            {
                "transaction_id": "txn_shopping",
                "account_id": "credit_demo",
                "name": "Online Shopping",
                "merchant_name": "Amazon",
                "amount": 142.18,
                "date": (today - timedelta(days=7)).isoformat(),
                "pending": False,
                "personal_finance_category": {"primary": "GENERAL_MERCHANDISE"},
            },
        ],
        "modified": [],
        "removed": [],
        "next_cursor": "seed-cursor-1",
        "has_more": False,
        "request_id": "seed-request",
    }


def seed(profile_id: str) -> None:
    today = date.today()
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        ensure_profile(db, profile_id, display_name="Demo User")
        store_plaid_item(
            db,
            profile_id=profile_id,
            access_token="sandbox-mock-access-token",
            plaid_item_id="sandbox-mock-item",
            institution_name="First Platypus Bank (Mock)",
        )
        replace_plaid_snapshot(db, profile_id=profile_id, plaid_payload=build_plaid_sync_payload(today))

        db.add_all(
            [
                Goal(
                    id=str(uuid4()),
                    profile_id=profile_id,
                    title="Emergency Fund",
                    target_amount=5000.00,
                    current_amount=3420.00,
                    target_date=today + timedelta(days=90),
                    status="active",
                ),
                Goal(
                    id=str(uuid4()),
                    profile_id=profile_id,
                    title="Travel Fund",
                    target_amount=2000.00,
                    current_amount=640.00,
                    target_date=today + timedelta(days=180),
                    status="active",
                ),
                Alert(
                    id=str(uuid4()),
                    profile_id=profile_id,
                    type="low_buffer",
                    severity="warning",
                    title="Rent posts tomorrow",
                    body="Rent posts tomorrow and your checking buffer will be tight after it clears.",
                    payload={"bill": "Rent", "amount": 1500.00, "buffer_after_bill": 84.00},
                    status="pending",
                ),
            ]
        )
        db.commit()
    finally:
        db.close()

    print(f"Seeded Plaid-shaped mock data for profile_id={profile_id!r}.")
    print("Try: GET /api/snapshot?profile_id=" + profile_id)


if __name__ == "__main__":
    target_profile = sys.argv[1] if len(sys.argv) > 1 else "demo"
    seed(target_profile)
