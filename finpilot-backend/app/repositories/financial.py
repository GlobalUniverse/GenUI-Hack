from datetime import UTC, date, datetime
from decimal import Decimal
from uuid import uuid4

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models import Account, Alert, Goal, PlaidItem, Profile, Transaction
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


def ensure_profile(db: Session, profile_id: str, display_name: str | None = None) -> Profile:
    profile = db.get(Profile, profile_id)
    if profile:
        return profile

    profile = Profile(id=profile_id, display_name=display_name or "Plaid Sandbox User")
    db.add(profile)
    db.flush()
    return profile


def store_plaid_item(
    db: Session,
    *,
    profile_id: str,
    access_token: str,
    plaid_item_id: str | None,
    institution_name: str | None = None,
) -> PlaidItem:
    ensure_profile(db, profile_id)
    item = PlaidItem(
        id=str(uuid4()),
        profile_id=profile_id,
        plaid_item_id=plaid_item_id,
        access_token=access_token,
        institution_name=institution_name,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def latest_plaid_item(db: Session, profile_id: str) -> PlaidItem | None:
    return db.scalars(
        select(PlaidItem)
        .where(PlaidItem.profile_id == profile_id)
        .order_by(PlaidItem.created_at.desc())
        .limit(1)
    ).first()


def replace_plaid_snapshot(db: Session, *, profile_id: str, plaid_payload: dict) -> None:
    ensure_profile(db, profile_id)
    db.execute(delete(Transaction).where(Transaction.profile_id == profile_id))
    db.execute(delete(Account).where(Account.profile_id == profile_id))
    db.flush()

    account_by_plaid_id: dict[str, Account] = {}
    for account_payload in plaid_payload.get("accounts", []):
        balances = account_payload.get("balances") or {}
        account = Account(
            id=str(uuid4()),
            profile_id=profile_id,
            plaid_account_id=account_payload.get("account_id"),
            name=account_payload.get("name") or "Plaid Account",
            type=str(account_payload.get("type") or "unknown"),
            subtype=str(account_payload.get("subtype") or ""),
            current_balance=_decimal_or_zero(balances.get("current")),
            available_balance=_decimal_or_none(balances.get("available")),
            iso_currency_code=balances.get("iso_currency_code") or "USD",
        )
        db.add(account)
        if account.plaid_account_id:
            account_by_plaid_id[account.plaid_account_id] = account

    db.flush()

    for txn_payload in plaid_payload.get("added", []) + plaid_payload.get("modified", []):
        amount = _decimal_or_zero(txn_payload.get("amount"))
        direction = "outflow" if amount >= 0 else "inflow"
        account = account_by_plaid_id.get(txn_payload.get("account_id"))
        db.add(
            Transaction(
                id=str(uuid4()),
                profile_id=profile_id,
                plaid_transaction_id=txn_payload.get("transaction_id"),
                account_id=account.id if account else None,
                name=txn_payload.get("name") or "Plaid Transaction",
                merchant_name=txn_payload.get("merchant_name"),
                amount=abs(amount),
                direction=direction,
                category=_simple_category(txn_payload),
                date=_date_or_today(txn_payload.get("date")),
                pending=bool(txn_payload.get("pending")),
            )
        )

    db.commit()


def build_snapshot_from_db(db: Session, profile_id: str) -> FinancialSnapshot | None:
    profile = db.get(Profile, profile_id)
    if not profile:
        return None

    accounts = db.scalars(select(Account).where(Account.profile_id == profile_id)).all()
    transactions = db.scalars(
        select(Transaction).where(Transaction.profile_id == profile_id).order_by(Transaction.date.desc())
    ).all()
    goals = db.scalars(select(Goal).where(Goal.profile_id == profile_id)).all()
    alerts = db.scalars(select(Alert).where(Alert.profile_id == profile_id)).all()

    if not accounts:
        return None

    return FinancialSnapshot(
        profile_id=profile_id,
        source="plaid_sandbox",
        as_of=datetime.now(UTC),
        accounts=[
            AccountSnapshot(
                id=account.id,
                name=account.name,
                type=account.type,
                subtype=account.subtype,
                balance_current=float(account.current_balance),
                balance_available=float(account.available_balance)
                if account.available_balance is not None
                else None,
                iso_currency_code=account.iso_currency_code,
            )
            for account in accounts
        ],
        transactions=[
            TransactionSnapshot(
                id=txn.id,
                date=txn.date,
                name=txn.name,
                amount=float(txn.amount),
                direction=txn.direction,  # type: ignore[arg-type]
                category=txn.category,
                account_id=txn.account_id,
                merchant_name=txn.merchant_name,
                pending=txn.pending,
            )
            for txn in transactions[:50]
        ],
        spending_by_category=_spending_by_category(transactions),
        upcoming_bills=_upcoming_bills(transactions),
        cashflow=_cashflow(accounts, transactions),
        goals=[
            GoalSnapshot(
                id=goal.id,
                title=goal.title,
                target_amount=float(goal.target_amount),
                current_amount=float(goal.current_amount),
                target_date=goal.target_date,
                status=goal.status,
            )
            for goal in goals
        ],
        alerts=[
            AlertSnapshot(
                id=alert.id,
                type=alert.type,
                severity=alert.severity,  # type: ignore[arg-type]
                message=alert.body,
                payload=alert.payload or {},
            )
            for alert in alerts
        ],
    )


def _spending_by_category(transactions: list[Transaction]) -> list[SpendingCategory]:
    totals: dict[str, Decimal] = {}
    for txn in transactions:
        if txn.direction == "outflow":
            totals[txn.category] = totals.get(txn.category, Decimal("0")) + txn.amount
    return [
        SpendingCategory(category=category, amount=float(amount))
        for category, amount in sorted(totals.items(), key=lambda item: item[1], reverse=True)
    ]


def _upcoming_bills(transactions: list[Transaction]) -> list[UpcomingBill]:
    today = date.today()
    bills = []
    for txn in transactions:
        if txn.pending and txn.direction == "outflow" and txn.date >= today:
            bills.append(UpcomingBill(name=txn.name, amount=float(txn.amount), due_date=txn.date))
    return bills


def _cashflow(accounts: list[Account], transactions: list[Transaction]) -> CashflowSnapshot:
    income = sum(txn.amount for txn in transactions if txn.direction == "inflow")
    spend = sum(txn.amount for txn in transactions if txn.direction == "outflow")
    checking = next((account for account in accounts if account.subtype == "checking"), accounts[0])
    projected = Decimal(checking.available_balance or checking.current_balance or 0) + income - spend
    return CashflowSnapshot(
        income_month_to_date=float(income),
        spend_month_to_date=float(spend),
        projected_month_end_balance=float(projected),
    )


def _simple_category(txn_payload: dict) -> str:
    personal = txn_payload.get("personal_finance_category") or {}
    if personal.get("primary"):
        return str(personal["primary"]).replace("_", " ").title()
    categories = txn_payload.get("category") or []
    if categories:
        return str(categories[0])
    return "Other"


def _decimal_or_zero(value: object) -> Decimal:
    parsed = _decimal_or_none(value)
    return parsed if parsed is not None else Decimal("0")


def _decimal_or_none(value: object) -> Decimal | None:
    if value is None:
        return None
    return Decimal(str(value))


def _date_or_today(value: object) -> date:
    if isinstance(value, date):
        return value
    if value:
        return date.fromisoformat(str(value))
    return date.today()
