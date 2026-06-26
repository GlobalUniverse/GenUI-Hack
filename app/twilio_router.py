from fastapi import APIRouter, Form
from twilio.rest import Client
import os

router = APIRouter()

@router.post("/sms/inbound")
async def inbound_sms(From: str = Form(...), Body: str = Form(...)):
    # 1. receive user's text
    # 2. send to Gemini advisor (E1's endpoint)
    # 3. reply back via Twilio
    client = Client(os.getenv("TWILIO_ACCOUNT_SID"), os.getenv("TWILIO_AUTH_TOKEN"))
    client.messages.create(
        body="Got your message, working on it...",  # placeholder
        from_=os.getenv("TWILIO_PHONE_NUMBER"),
        to=From
    )
    return {"status": "ok"}
