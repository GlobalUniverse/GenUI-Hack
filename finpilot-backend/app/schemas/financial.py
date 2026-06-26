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
    source: Literal["seeded", "plaid_sandbox", "supabase"]
    as_of: datetime
    accounts: list[AccountSnapshot]
    transactions: list[TransactionSnapshot]
    spending_by_category: list[SpendingCategory]
    upcoming_bills: list[UpcomingBill]
    cashflow: CashflowSnapshot
    goals: list[GoalSnapshot]
    alerts: list[AlertSnapshot]
