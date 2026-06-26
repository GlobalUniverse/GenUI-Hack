"""Proactive financial monitoring: the 'mother agent' layer.

Unlike gemini_advisor.py (reactive: user asks, Gemini answers), this module is
meant to run on a schedule (or on-demand) and look for opportunities the user
didn't ask about. The arithmetic lives in plain Python functions ("tools")
that Gemini calls via function-calling -- the LLM reasons over the *results*
of those checks and writes the user-facing copy, it never computes the
numbers itself. This avoids arithmetic hallucination and keeps every dollar
figure traceable back to a deterministic check.

Trade-related checks only ever PROPOSE. Nothing in this module is capable of
executing a trade, moving money, or calling Alpaca/any brokerage API -- that
requires a separate, explicit user-approval step in a later phase.
"""

import json
from dataclasses import dataclass
from typing import Any, Callable

import google.generativeai as genai

from app.core.config import Settings
from app.schemas.financial import FinancialSnapshot


@dataclass
class ProactiveFinding:
    type: str
    severity: str  # "info" | "warning" | "critical"
    title: str
    body: str
    payload: dict[str, Any]


def build_tools(snapshot: FinancialSnapshot) -> list[Callable[[], dict[str, Any]]]:
    """Bind the snapshot into a fresh set of zero-arg tool functions for one scan."""

    def check_upcoming_bill_buffer() -> dict[str, Any]:
        """Check whether checking balance can absorb the next upcoming bill without going negative."""
        checking = next((a for a in snapshot.accounts if a.subtype == "checking"), None)
        if not checking or not snapshot.upcoming_bills:
            return {"at_risk": False}
        bill = min(snapshot.upcoming_bills, key=lambda b: b.due_date)
        available = checking.balance_available or checking.balance_current
        buffer_after = available - bill.amount
        return {
            "at_risk": buffer_after < 100,
            "bill_name": bill.name,
            "bill_amount": bill.amount,
            "due_date": bill.due_date.isoformat(),
            "checking_available": available,
            "buffer_after_bill": buffer_after,
        }

    def check_idle_cash() -> dict[str, Any]:
        """Check whether checking/savings holds far more cash than near-term spending needs, suggesting some could move to a fixed-income or money-market vehicle."""
        checking = next((a for a in snapshot.accounts if a.subtype == "checking"), None)
        savings = next((a for a in snapshot.accounts if a.subtype == "savings"), None)
        monthly_spend = snapshot.cashflow.spend_month_to_date or 1.0
        idle_total = (savings.balance_current if savings else 0) + max(
            0, (checking.balance_current if checking else 0) - 2 * monthly_spend
        )
        threshold = 3 * monthly_spend
        return {
            "idle_cash_estimate": idle_total,
            "monthly_spend": monthly_spend,
            "exceeds_recommended_buffer": idle_total > threshold,
            "recommended_buffer": threshold,
        }

    def check_credit_utilization() -> dict[str, Any]:
        """Check revolving credit utilization ratio across credit card accounts; high utilization hurts credit score and signals refinance/payoff opportunity."""
        cards = [a for a in snapshot.accounts if a.type == "credit"]
        if not cards:
            return {"has_credit_accounts": False}
        results = []
        for card in cards:
            owed = card.balance_current
            available = card.balance_available or 0
            limit = owed + available
            utilization = owed / limit if limit else 0
            results.append(
                {
                    "account": card.name,
                    "balance_owed": owed,
                    "limit_estimate": limit,
                    "utilization_pct": round(utilization * 100, 1),
                    "above_30_pct": utilization > 0.30,
                }
            )
        return {"has_credit_accounts": True, "cards": results}

    def check_budget_drift() -> dict[str, Any]:
        """Find the spending category with the largest month-over-month increase."""
        if not snapshot.spending_by_category:
            return {"has_drift": False}
        worst = max(
            snapshot.spending_by_category,
            key=lambda c: c.delta_vs_previous_month or 0,
        )
        return {
            "has_drift": (worst.delta_vs_previous_month or 0) > 0,
            "category": worst.category,
            "amount": worst.amount,
            "delta_vs_previous_month": worst.delta_vs_previous_month or 0,
        }

    def check_goal_pace() -> dict[str, Any]:
        """For each savings goal, compute whether current progress is on pace to hit the target by the target date."""
        from datetime import date

        today = date.today()
        results = []
        for goal in snapshot.goals:
            if not goal.target_date:
                continue
            days_left = max((goal.target_date - today).days, 1)
            remaining = goal.target_amount - goal.current_amount
            required_weekly = remaining / days_left * 7
            results.append(
                {
                    "goal": goal.title,
                    "remaining_amount": remaining,
                    "days_left": days_left,
                    "required_weekly_savings": round(required_weekly, 2),
                    "on_track": remaining <= 0,
                }
            )
        return {"goals": results}

    def propose_fixed_income_allocation(amount: float, vehicle: str) -> dict[str, Any]:
        """Propose moving a specific dollar amount from idle cash into a fixed-income or ETF vehicle (e.g. a treasury ETF or money market fund). This NEVER executes -- it only returns a structured proposal for the user to review and approve in the app."""
        return {
            "proposal_type": "fixed_income_allocation",
            "amount": amount,
            "vehicle": vehicle,
            "requires_user_approval": True,
            "executable": False,
        }

    return [
        check_upcoming_bill_buffer,
        check_idle_cash,
        check_credit_utilization,
        check_budget_drift,
        check_goal_pace,
        propose_fixed_income_allocation,
    ]


SCAN_PROMPT = (
    "You are FinPilot's proactive monitoring agent. You are not responding to a user "
    "question -- you are scanning their finances for opportunities or risks they haven't "
    "asked about. Call the available tools to check: upcoming bill buffer risk, idle cash "
    "that could earn more in a fixed-income/ETF vehicle, credit utilization, budget drift, "
    "and savings goal pace. Only use propose_fixed_income_allocation for amounts and vehicles "
    "directly supported by check_idle_cash's output -- never invent numbers. "
    "Use severity 'critical' only when a bill would push checking negative (buffer_after_bill < 0) -- "
    "that severity triggers an immediate outbound SMS to the user, so reserve it for things that "
    "genuinely need same-day attention. Everything else is 'warning' or 'info'. "
    "After calling the tools you need, return ONLY a JSON array (no markdown) of findings worth "
    "surfacing to the user, each shaped as: "
    '{"type": "snake_case_type", "severity": "info|warning|critical", "title": "short title", '
    '"body": "one or two sentence explanation grounded in the tool results", "payload": {}}. '
    "Skip checks that came back with nothing actionable. Return an empty array if nothing is worth surfacing."
)


def run_proactive_scan(settings: Settings, snapshot: FinancialSnapshot) -> list[ProactiveFinding]:
    if not settings.gemini_api_key:
        return _fallback_scan(snapshot)

    try:
        genai.configure(api_key=settings.gemini_api_key)
        tools = build_tools(snapshot)
        model = genai.GenerativeModel(settings.gemini_model, tools=tools)
        chat = model.start_chat(enable_automatic_function_calling=True)
        response = chat.send_message(SCAN_PROMPT)
        payload = _extract_json(response.text or "[]")
        return [ProactiveFinding(**item) for item in payload]
    except Exception:
        return _fallback_scan(snapshot)


def _fallback_scan(snapshot: FinancialSnapshot) -> list[ProactiveFinding]:
    """Deterministic-only scan used when Gemini is unavailable -- runs the same tools, skips the LLM write-up."""
    tools = {fn.__name__: fn for fn in build_tools(snapshot)}
    findings: list[ProactiveFinding] = []

    bill_check = tools["check_upcoming_bill_buffer"]()
    if bill_check.get("at_risk"):
        findings.append(
            ProactiveFinding(
                type="low_buffer",
                severity="critical" if bill_check["buffer_after_bill"] < 0 else "warning",
                title=f"{bill_check['bill_name']} posts {bill_check['due_date']}",
                body=(
                    f"After {bill_check['bill_name']} (${bill_check['bill_amount']:.2f}) clears, "
                    f"your checking buffer drops to ${bill_check['buffer_after_bill']:.2f}."
                ),
                payload=bill_check,
            )
        )

    idle_check = tools["check_idle_cash"]()
    if idle_check.get("exceeds_recommended_buffer"):
        findings.append(
            ProactiveFinding(
                type="idle_cash",
                severity="info",
                title="Cash sitting idle could be earning more",
                body=(
                    f"You're holding about ${idle_check['idle_cash_estimate']:.2f} beyond your "
                    "recommended spending buffer. Consider a short-term treasury ETF or money market fund."
                ),
                payload=idle_check,
            )
        )

    credit_check = tools["check_credit_utilization"]()
    for card in credit_check.get("cards", []):
        if card["above_30_pct"]:
            findings.append(
                ProactiveFinding(
                    type="high_utilization",
                    severity="warning",
                    title=f"{card['account']} utilization is {card['utilization_pct']}%",
                    body="Paying this down before your statement closes can improve your credit score.",
                    payload=card,
                )
            )

    drift_check = tools["check_budget_drift"]()
    if drift_check.get("has_drift"):
        findings.append(
            ProactiveFinding(
                type="budget_drift",
                severity="info",
                title=f"{drift_check['category']} spending is climbing",
                body=f"Up ${drift_check['delta_vs_previous_month']:.2f} vs last month.",
                payload=drift_check,
            )
        )

    for goal in tools["check_goal_pace"]().get("goals", []):
        if not goal["on_track"]:
            findings.append(
                ProactiveFinding(
                    type="goal_drift",
                    severity="info",
                    title=f"{goal['goal']} needs ${goal['required_weekly_savings']}/week",
                    body=f"At the current pace you won't hit this goal by the target date.",
                    payload=goal,
                )
            )

    return findings


def _extract_json(text: str) -> list[dict[str, Any]]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`").removeprefix("json").strip()
    return json.loads(cleaned)
