from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator


WidgetType = Literal[
    "summary_card",
    "spending_chart",
    "transaction_table",
    "goal_progress",
    "recommendation_card",
]

ALLOWED_WIDGET_TYPES = {
    "summary_card",
    "spending_chart",
    "transaction_table",
    "goal_progress",
    "recommendation_card",
}


class WidgetSpec(BaseModel):
    type: WidgetType
    title: str
    data: dict[str, Any] = Field(default_factory=dict)
    id: str | None = None


class AdvisorRequest(BaseModel):
    profile_id: str = "demo"
    message: str
    channel: Literal["app", "sms", "voice"] = "app"
    context: dict[str, Any] = Field(default_factory=dict)


class AdvisorResponse(BaseModel):
    text: str
    widgets: list[WidgetSpec] = Field(default_factory=list)
    source: Literal["gemini", "fallback"] = "fallback"
    snapshot_source: str = "plaid_sandbox"
    follow_ups: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    intent: str | None = None

    @field_validator("widgets")
    @classmethod
    def validate_widget_types(cls, widgets: list[WidgetSpec]) -> list[WidgetSpec]:
        for widget in widgets:
            if widget.type not in ALLOWED_WIDGET_TYPES:
                raise ValueError(f"Unsupported widget type: {widget.type}")
        return widgets
