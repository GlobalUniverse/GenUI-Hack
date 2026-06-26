from datetime import date, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


class AccountSnapshot(BaseModel):
    id: str
    name: str
    type: str
    subtype: str | None = None
    balance_current: float
    balance_available: float | None = None
    iso_currency_code: str = "USD"


class TransactionSnapshot(BaseModel):
    id: str
    date: date
    name: str
    amount: float
    direction: Literal["inflow", "outflow"]
    category: str
    account_id: str | None = None
    merchant_name: str | None = None
    pending: bool = False


class SpendingCategory(BaseModel):
    category: str
    amount: float
    delta_vs_previous_month: float | None = None


class UpcomingBill(BaseModel):
    name: str
    amount: float
    due_date: date


class CashflowSnapshot(BaseModel):
    income_month_to_date: float
    spend_month_to_date: float
    projected_month_end_balance: float


class GoalSnapshot(BaseModel):
    id: str
    title: str
    target_amount: float
    current_amount: float
    target_date: date | None = None
    status: str = "active"


class AlertSnapshot(BaseModel):
    id: str
    type: str
    severity: Literal["info", "warning", "critical"] = "warning"
    message: str
    payload: dict[str, Any] = Field(default_factory=dict)


class FinancialSnapshot(BaseModel):
    profile_id: str
    source: Literal["plaid_sandbox", "supabase"]
    as_of: datetime
    accounts: list[AccountSnapshot]
    transactions: list[TransactionSnapshot]
    spending_by_category: list[SpendingCategory]
    upcoming_bills: list[UpcomingBill]
    cashflow: CashflowSnapshot
    goals: list[GoalSnapshot]
    alerts: list[AlertSnapshot]


class ClientCategorySpend(BaseModel):
    """Matches Flutter's CategorySpend.fromJson."""

    name: str
    amount: float
    delta: float = 0


class ClientTransaction(BaseModel):
    """Matches Flutter's Transaction.fromJson. amount is signed: negative = outflow, positive = inflow."""

    name: str
    amount: float
    category: str
    date: date


class ClientGoal(BaseModel):
    """Matches Flutter's Goal.fromJson."""

    name: str
    target_amount: float
    current_amount: float
    target_date: date


class ClientUpcomingBill(BaseModel):
    """Matches Flutter's UpcomingBill.fromJson."""

    name: str
    amount: float
    due_date: date


class ClientSnapshot(BaseModel):
    """Flat shape consumed directly by Flutter's FinancialSnapshot.fromJson at GET /snapshot."""

    checking_balance: float
    savings_balance: float
    monthly_income: float
    monthly_spending: float
    top_categories: list[ClientCategorySpend]
    recent_transactions: list[ClientTransaction]
    goals: list[ClientGoal]
    upcoming_bills: list[ClientUpcomingBill]
