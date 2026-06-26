from fastapi import FastAPI
from dotenv import load_dotenv
from app.twilio_router import router as twilio_router

load_dotenv()

app = FastAPI(title="FinPilot Backend")
app.include_router(twilio_router)
