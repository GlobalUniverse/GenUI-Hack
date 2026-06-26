from app.schemas.financial import (
    ClientCategorySpend,
    ClientGoal,
    ClientSnapshot,
    ClientTransaction,
    ClientUpcomingBill,
    FinancialSnapshot,
)


def to_client_snapshot(snapshot: FinancialSnapshot) -> ClientSnapshot:
    checking = next((a for a in snapshot.accounts if a.subtype == "checking"), None)
    savings = next((a for a in snapshot.accounts if a.subtype == "savings"), None)

    return ClientSnapshot(
        checking_balance=checking.balance_available or checking.balance_current if checking else 0.0,
        savings_balance=savings.balance_available or savings.balance_current if savings else 0.0,
        monthly_income=snapshot.cashflow.income_month_to_date,
        monthly_spending=snapshot.cashflow.spend_month_to_date,
        top_categories=[
            ClientCategorySpend(
                name=item.category,
                amount=item.amount,
                delta=item.delta_vs_previous_month or 0,
            )
            for item in snapshot.spending_by_category
        ],
        recent_transactions=[
            ClientTransaction(
                name=txn.name,
                amount=-abs(txn.amount) if txn.direction == "outflow" else abs(txn.amount),
                category=txn.category,
                date=txn.date,
            )
            for txn in snapshot.transactions
        ],
        goals=[
            ClientGoal(
                name=goal.title,
                target_amount=goal.target_amount,
                current_amount=goal.current_amount,
                target_date=goal.target_date or snapshot.as_of.date(),
            )
            for goal in snapshot.goals
        ],
        upcoming_bills=[
            ClientUpcomingBill(name=bill.name, amount=bill.amount, due_date=bill.due_date)
            for bill in snapshot.upcoming_bills
        ],
    )
