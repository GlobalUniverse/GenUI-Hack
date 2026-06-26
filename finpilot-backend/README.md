# FinPilot Backend

FastAPI backend for the FinPilot hackathon demo. It owns Plaid Sandbox access, Supabase/Postgres persistence, Gemini advisor orchestration, and stable contracts for Flutter and Twilio.

## Quick Start

```bash
cd finpilot-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

Defaults use SQLite plus seeded demo data. Set `DATABASE_URL` to a Supabase Postgres connection string when ready.

## Core Endpoints

```text
GET  /health
GET  /api/snapshot?profile_id=demo
POST /api/advisor
POST /api/plaid/sandbox/public-token
POST /api/plaid/exchange-token
POST /api/plaid/link-token
POST /api/alerts/check
```
