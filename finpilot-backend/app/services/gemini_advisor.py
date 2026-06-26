import json
from datetime import date
from typing import Any

import google.generativeai as genai

from app.core.config import Settings
from app.schemas.advisor import ALLOWED_WIDGET_TYPES, AdvisorResponse, WidgetSpec
from app.schemas.financial import FinancialSnapshot


class GeminiAdvisor:
    def __init__(self, settings: Settings):
        self.settings = settings
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)

    def answer(self, message: str, snapshot: FinancialSnapshot, channel: str = "app") -> AdvisorResponse:
        if not self.settings.gemini_api_key:
            return self._fallback(message, snapshot)

        prompt = self._build_prompt(message, snapshot, channel)
        try:
            model = genai.GenerativeModel(self.settings.gemini_model)
            response = model.generate_content(prompt)
            payload = self._extract_json(response.text or "")
            parsed = AdvisorResponse.model_validate(payload)
            parsed.source = "gemini"
            parsed.snapshot_source = snapshot.source
            return parsed
        except Exception as exc:
            fallback = self._fallback(message, snapshot)
            fallback.warnings.append(f"Gemini fallback used: {exc.__class__.__name__}")
            return fallback

    def _build_prompt(self, message: str, snapshot: FinancialSnapshot, channel: str) -> str:
        schema_hint = {
            "text": "short user-facing answer",
            "intent": "snake_case intent",
            "widgets": [
                {"id": "optional_id", "type": "summary_card", "title": "Widget title", "data": {}}
            ],
            "follow_ups": ["short next question"],
            "warnings": [],
        }
        widget_data_conventions = {
            "summary_card": {"label": "string", "value": "signed number, negative renders red", "subtitle": "string"},
            "goal_progress": {"name": "string", "target": "number", "current": "number", "days_left": "integer"},
            "recommendation_card": {"title": "string", "body": "string", "action": "string, a single button label"},
            "spending_chart": "leave data empty -- client renders this from its own loaded snapshot",
            "transaction_table": "leave data empty -- client renders this from its own loaded snapshot",
            "upcoming_bills": "leave data empty -- client renders this from its own loaded snapshot",
        }
        return (
            "You are FinPilot, a concise personal finance advisor. "
            "Use only the provided financial snapshot. Never invent balances, bills, or transactions. "
            "Return JSON only, with no markdown. "
            f"Allowed widget types: {sorted(ALLOWED_WIDGET_TYPES)}. "
            f"Widget data field conventions per type: {json.dumps(widget_data_conventions)}. "
            f"Response schema example: {json.dumps(schema_hint)}. "
            f"Channel: {channel}. Keep sms/voice responses shorter. "
            f"Financial snapshot: {snapshot.model_dump_json()}. "
            f"User question: {message}"
        )

    def _extract_json(self, text: str) -> dict[str, Any]:
        cleaned = text.strip()
        if cleaned.startswith("```"):
            cleaned = cleaned.strip("`")
            cleaned = cleaned.removeprefix("json").strip()
        return json.loads(cleaned)

    def _fallback(self, message: str, snapshot: FinancialSnapshot) -> AdvisorResponse:
        lower = message.lower()
        checking = next(
            (account for account in snapshot.accounts if account.subtype == "checking"),
            snapshot.accounts[0],
        )
        top_categories = [
            {"name": item.category, "amount": item.amount}
            for item in snapshot.spending_by_category[:5]
        ]
        widgets = [
            WidgetSpec(
                id="cash_position",
                type="summary_card",
                title="Current cash position",
                data={
                    "label": checking.name,
                    "value": checking.balance_available or checking.balance_current,
                    "subtitle": "Available now",
                },
            ),
            WidgetSpec(
                id="spending_categories",
                type="spending_chart",
                title="Top spending categories",
                data={},
            ),
        ]

        if "dinner" in lower or "afford" in lower:
            intent = "affordability_check"
            text = "Based on your Plaid Sandbox balances and upcoming activity, keep this purchase small enough to preserve your cash buffer."
            action = "Set a spending limit"
        elif "save" in lower or "1,000" in lower or "1000" in lower:
            intent = "savings_plan"
            text = "Use your largest flexible spending categories as the first source of savings, then automate the weekly amount toward the goal."
            action = "Set up auto-transfer"
            goal = snapshot.goals[0] if snapshot.goals else None
            days_left = (goal.target_date - date.today()).days if goal and goal.target_date else 60
            widgets.append(
                WidgetSpec(
                    id="savings_goal",
                    type="goal_progress",
                    title="Goal progress",
                    data={
                        "name": goal.title if goal else "New Goal",
                        "target": goal.target_amount if goal else 1000,
                        "current": goal.current_amount if goal else 0,
                        "days_left": max(days_left, 1),
                    },
                )
            )
        elif "rent" in lower or "tomorrow" in lower:
            intent = "proactive_bill_buffer"
            text = "Check pending bills before making new discretionary purchases; your safest move is to protect the checking buffer until the bill clears."
            action = "Review upcoming bills"
            widgets.append(WidgetSpec(id="upcoming_bills", type="upcoming_bills", title="Upcoming bills", data={}))
        elif "spend" in lower or "money" in lower or "overspend" in lower:
            intent = "spending_review"
            text = "Your Plaid Sandbox transactions show the highest pressure in the categories below."
            action = "View transactions"
            widgets.append(
                WidgetSpec(id="recent_transactions", type="transaction_table", title="Recent transactions", data={})
            )
        else:
            intent = "general_advice"
            text = "Here is the current Plaid-backed snapshot I would use to guide your next money decision."
            action = "Show details"

        widgets.append(
            WidgetSpec(
                id="next_action",
                type="recommendation_card",
                title="Suggested next action",
                data={"title": "Suggested next action", "body": text, "action": action},
            )
        )
        return AdvisorResponse(
            text=text,
            intent=intent,
            widgets=widgets,
            source="fallback",
            snapshot_source=snapshot.source,
            follow_ups=["Show recent transactions", "What should I do next?"],
        )
