import json
from typing import Any

import google.generativeai as genai

from app.core.config import Settings
from app.schemas.advisor import ALLOWED_WIDGET_TYPES, AdvisorResponse, WidgetSpec
from app.schemas.financial import FinancialSnapshot


DEMO_FALLBACKS = {
    "dinner": AdvisorResponse(
        text="You can afford a $120 dinner, but it would leave a thin buffer before rent. I would cap tonight near $70-$90 and move the difference to savings after your next paycheck.",
        intent="affordability_check",
        widgets=[
            WidgetSpec(
                id="cash_buffer",
                type="summary_card",
                title="Cash buffer after rent",
                data={"amount": 84, "label": "estimated available buffer"},
            ),
            WidgetSpec(
                id="dining_spend",
                type="spending_chart",
                title="Flexible spending this month",
                data={
                    "categories": [
                        {"name": "Dining", "amount": 412},
                        {"name": "Rideshare", "amount": 138},
                        {"name": "Shopping", "amount": 244},
                    ]
                },
            ),
            WidgetSpec(
                id="dinner_recommendation",
                type="recommendation_card",
                title="Safer dinner budget",
                data={
                    "recommendation": "Cap dinner at $90 tonight; $70 is safer if rent posts before payday.",
                    "actions": ["accept", "snooze", "show_details"],
                },
            ),
        ],
        follow_ups=["Which bills are coming up?", "Show me cheaper tradeoffs"],
    ),
    "save": AdvisorResponse(
        text="To save $1,000 in 60 days, you need about $125 per week. Dining and rideshare are the best places to cut without touching essentials.",
        intent="savings_plan",
        widgets=[
            WidgetSpec(
                id="goal_progress",
                type="goal_progress",
                title="Save $1,000 in 60 days",
                data={"target_amount": 1000, "current_amount": 420, "weekly_needed": 125},
            ),
            WidgetSpec(
                id="savings_action",
                type="recommendation_card",
                title="Weekly savings plan",
                data={
                    "recommendation": "Move $125 weekly after payday and cut dining by $35 plus rideshare by $25 per week.",
                    "actions": ["accept", "snooze", "reject"],
                },
            ),
        ],
        follow_ups=["Build a weekly budget", "What should I cut first?"],
    ),
    "rent": AdvisorResponse(
        text="Rent posts tomorrow, and your checking buffer is tight. Avoid new discretionary spending until rent clears, then reassess after your next deposit.",
        intent="proactive_rent_buffer",
        widgets=[
            WidgetSpec(
                id="rent_alert",
                type="summary_card",
                title="Rent buffer warning",
                data={"rent_due": 1500, "estimated_buffer_after_rent": 84, "severity": "warning"},
            ),
            WidgetSpec(
                id="rent_recommendation",
                type="recommendation_card",
                title="Protect your buffer",
                data={
                    "recommendation": "Pause dining and rideshare for 48 hours and keep at least $75 untouched.",
                    "actions": ["accept", "remind_me", "show_details"],
                },
            ),
        ],
        warnings=["Rent timing may change if pending transactions settle differently."],
    ),
    "spending": AdvisorResponse(
        text="Dining, shopping, and rideshare are driving most of the flexible spend this month. Dining is the biggest jump versus last month.",
        intent="spending_review",
        widgets=[
            WidgetSpec(
                id="category_spend",
                type="spending_chart",
                title="Spending by category",
                data={
                    "categories": [
                        {"name": "Dining", "amount": 412, "delta": 118},
                        {"name": "Groceries", "amount": 386, "delta": -24},
                        {"name": "Shopping", "amount": 244, "delta": 67},
                        {"name": "Rideshare", "amount": 138, "delta": 52},
                    ]
                },
            ),
            WidgetSpec(
                id="recent_transactions",
                type="transaction_table",
                title="Recent flexible transactions",
                data={"categories": ["Dining", "Rideshare", "Shopping"], "limit": 8},
            ),
        ],
    ),
}


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
        del snapshot
        lower = message.lower()
        if "dinner" in lower or "afford" in lower:
            response = DEMO_FALLBACKS["dinner"]
        elif "save" in lower or "1,000" in lower or "1000" in lower:
            response = DEMO_FALLBACKS["save"]
        elif "rent" in lower or "tomorrow" in lower:
            response = DEMO_FALLBACKS["rent"]
        elif "spend" in lower or "money" in lower or "overspend" in lower:
            response = DEMO_FALLBACKS["spending"]
        else:
            response = DEMO_FALLBACKS["spending"]

        payload = response.model_dump()
        payload["source"] = "fallback"
        payload["snapshot_source"] = "seeded"
        return AdvisorResponse.model_validate(payload)
