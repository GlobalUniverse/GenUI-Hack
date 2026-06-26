import json
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
        return (
            "You are FinPilot, a concise personal finance advisor. "
            "Use only the provided financial snapshot. Never invent balances, bills, or transactions. "
            "Return JSON only, with no markdown. "
            f"Allowed widget types: {sorted(ALLOWED_WIDGET_TYPES)}. "
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
                    "account": checking.name,
                    "available_balance": checking.balance_available,
                    "current_balance": checking.balance_current,
                },
            ),
            WidgetSpec(
                id="spending_categories",
                type="spending_chart",
                title="Top spending categories",
                data={"categories": top_categories},
            ),
        ]

        if "dinner" in lower or "afford" in lower:
            intent = "affordability_check"
            text = "Based on your Plaid Sandbox balances and upcoming activity, keep this purchase small enough to preserve your cash buffer."
        elif "save" in lower or "1,000" in lower or "1000" in lower:
            intent = "savings_plan"
            text = "Use your largest flexible spending categories as the first source of savings, then automate the weekly amount toward the goal."
        elif "rent" in lower or "tomorrow" in lower:
            intent = "proactive_bill_buffer"
            text = "Check pending bills before making new discretionary purchases; your safest move is to protect the checking buffer until the bill clears."
        elif "spend" in lower or "money" in lower or "overspend" in lower:
            intent = "spending_review"
            text = "Your Plaid Sandbox transactions show the highest pressure in the categories below."
        else:
            intent = "general_advice"
            text = "Here is the current Plaid-backed snapshot I would use to guide your next money decision."

        widgets.append(
            WidgetSpec(
                id="next_action",
                type="recommendation_card",
                title="Suggested next action",
                data={
                    "recommendation": text,
                    "actions": ["accept", "snooze", "show_details"],
                },
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
