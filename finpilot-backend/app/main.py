from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db.session import Base, engine
from app.routers import advisor, alerts, health, plaid, snapshot

Base.metadata.create_all(bind=engine)

app = FastAPI(title="FinPilot Backend", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(snapshot.router)
app.include_router(snapshot.client_router)
app.include_router(advisor.router)
app.include_router(advisor.client_router)
app.include_router(plaid.router)
app.include_router(alerts.router)
