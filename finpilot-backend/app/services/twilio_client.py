"""Outbound notification channel for proactive alerts.

This is the inverse of the Twilio inbound SMS webhook (a separate track):
that one answers questions the user sends in. This one lets the agent reach
out first, for findings severe enough that waiting for the user to open the
app isn't good enough. It only ever sends a short, human-readable text --
it has no ability to move money or place trades.
"""

import logging

from app.core.config import Settings

logger = logging.getLogger(__name__)


def send_proactive_sms(settings: Settings, *, to_number: str, body: str) -> bool:
    if not settings.twilio_configured:
        logger.info("Twilio not configured; skipping outbound SMS: %s", body)
        return False

    from twilio.rest import Client

    client = Client(settings.twilio_account_sid, settings.twilio_auth_token)
    client.messages.create(body=body, from_=settings.twilio_phone_number, to=to_number)
    return True
