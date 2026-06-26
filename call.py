import os
from twilio.rest import Client
from dotenv import load_dotenv

load_dotenv()

account_sid = os.environ["TWILIO_ACCOUNT_SID"]
auth_token = os.environ["TWILIO_AUTH_TOKEN"]
client = Client(account_sid, auth_token)

call = client.calls.create(
    url="https://maggot-pushover-coliseum.ngrok-free.dev",
    to="+16266203838",
    from_="+19257225730",
)

print(call.sid)
