from datetime import UTC, date, datetime, timedelta

from app.schemas.financial import (
    AccountSnapshot,
    AlertSnapshot,
    CashflowSnapshot,
    FinancialSnapshot,
    GoalSnapshot,
    SpendingCategory,
    TransactionSnapshot,
    UpcomingBill,
)


def young_renter_snapshot(profile_id: str = "demo") -> FinancialSnapshot:
    today = date.today()
    return FinancialSnapshot(
        profile_id=profile_id,
        source="seeded",
        as_of=datetime.now(UTC),
        accounts=[
            AccountSnapshot(
                id="checking_demo",
                name="Everyday Checking",
                type="depository",
                subtype="checking",
                balance_current=842.12,
                balance_available=790.12,
            ),
            AccountSnapshot(
                id="savings_demo",
                name="Starter Savings",
                type="depository",
                subtype="savings",
                balance_current=460.0,
                balance_available=460.0,
            ),
            AccountSnapshot(
                id="credit_demo",
                name="Rewards Card",
                type="credit",
                subtype="credit card",
                balance_current=1264.4,
                balance_available=1735.6,
            ),
        ],
        transactions=[
            TransactionSnapshot(
                id="txn_paycheck",
                date=today - timedelta(days=6),
                name="Direct Deposit",
                merchant_name="Acme Studio",
                amount=4200.0,
                direction="inflow",
                category="Income",
                account_id="checking_demo",
            ),
            TransactionSnapshot(
                id="txn_rent",
                date=today + timedelta(days=1),
                name="Rent",
                amount=1500.0,
                direction="outflow",
                category="Housing",
                account_id="checking_demo",
                pending=True,
            ),
            TransactionSnapshot(
                id="txn_dinner",
                date=today - timedelta(days=1),
                name="Dinner",
                merchant_name="Local Bistro",
                amount=64.22,
                direction="outflow",
                category="Dining",
                account_id="credit_demo",
            ),
            TransactionSnapshot(
                id="txn_rideshare",
                date=today - timedelta(days=2),
                name="Ride Share",
                merchant_name="Lyft",
                amount=38.9,
                direction="outflow",
                category="Rideshare",
                account_id="credit_demo",
            ),
            TransactionSnapshot(
                id="txn_groceries",
                date=today - timedelta(days=3),
                name="Groceries",
                merchant_name="Trader Joe's",
                amount=96.43,
                direction="outflow",
                category="Groceries",
                account_id="credit_demo",
            ),
            TransactionSnapshot(
                id="txn_streaming",
                date=today - timedelta(days=4),
                name="Streaming Subscription",
                merchant_name="Streamly",
                amount=18.99,
                direction="outflow",
                category="Subscriptions",
                account_id="credit_demo",
            ),
        ],
        spending_by_category=[
            SpendingCategory(category="Dining", amount=412.0, delta_vs_previous_month=118.0),
            SpendingCategory(category="Rideshare", amount=138.0, delta_vs_previous_month=52.0),
            SpendingCategory(category="Groceries", amount=386.0, delta_vs_previous_month=-24.0),
            SpendingCategory(category="Subscriptions", amount=92.0, delta_vs_previous_month=14.0),
            SpendingCategory(category="Shopping", amount=244.0, delta_vs_previous_month=67.0),
        ],
        upcoming_bills=[
            UpcomingBill(name="Rent", amount=1500.0, due_date=today + timedelta(days=1)),
            UpcomingBill(name="Phone", amount=82.0, due_date=today + timedelta(days=5)),
        ],
        cashflow=CashflowSnapshot(
            income_month_to_date=4200.0,
            spend_month_to_date=2875.0,
            projected_month_end_balance=518.0,
        ),
        goals=[
            GoalSnapshot(
                id="save_1000",
                title="Save $1,000 in 60 days",
                target_amount=1000.0,
                current_amount=420.0,
                target_date=today + timedelta(days=60),
            )
        ],
        alerts=[
            AlertSnapshot(
                id="rent_buffer",
                type="low_buffer",
                severity="warning",
                message="Rent posts tomorrow and your checking buffer is tight.",
                payload={"bill": "Rent", "amount": 1500.0, "buffer_after_bill": 84.0},
            )
        ],
    )
