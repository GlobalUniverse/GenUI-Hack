import os
import json
import threading
from datetime import datetime, timedelta, timezone

import psycopg2
import psycopg2.extras
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai
from google.genai import types as genai_types

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")
PROFILE_ID = os.getenv("PROFILE_ID", "demo")

gemini_client = genai.Client(api_key=GEMINI_API_KEY)

app = FastAPI(title="FinPilot API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Mock data (matches Flutter app mock, used as fallback)
# ---------------------------------------------------------------------------

def _now():
    return datetime.now(timezone.utc)

MOCK_SNAPSHOT = {
    "checking_balance": 1284.50,
    "savings_balance": 3420.00,
    "monthly_income": 4200.00,
    "monthly_spending": 3180.00,
    "top_categories": [
        {"name": "Dining", "amount": 620, "delta": 18},
        {"name": "Rideshare", "amount": 310, "delta": 42},
        {"name": "Groceries", "amount": 480, "delta": -5},
        {"name": "Entertainment", "amount": 210, "delta": 12},
        {"name": "Utilities", "amount": 190, "delta": 0},
    ],
    "recent_transactions": [
        {"name": "Uber", "amount": -24.50, "category": "Rideshare",
         "date": (_now() - timedelta(hours=3)).isoformat()},
        {"name": "Whole Foods", "amount": -87.20, "category": "Groceries",
         "date": (_now() - timedelta(days=1)).isoformat()},
        {"name": "Chipotle", "amount": -13.80, "category": "Dining",
         "date": (_now() - timedelta(days=1)).isoformat()},
        {"name": "Netflix", "amount": -15.99, "category": "Entertainment",
         "date": (_now() - timedelta(days=2)).isoformat()},
        {"name": "Direct Deposit", "amount": 2100.00, "category": "Income",
         "date": (_now() - timedelta(days=3)).isoformat()},
    ],
    "goals": [
        {
            "name": "Emergency Fund",
            "target_amount": 5000,
            "current_amount": 3420,
            "target_date": (_now() + timedelta(days=90)).date().isoformat(),
        },
        {
            "name": "Travel Fund",
            "target_amount": 2000,
            "current_amount": 640,
            "target_date": (_now() + timedelta(days=180)).date().isoformat(),
        },
    ],
    "upcoming_bills": [
        {"name": "Rent", "amount": 1500,
         "due_date": (_now() + timedelta(days=2)).date().isoformat()},
        {"name": "Electric", "amount": 95,
         "due_date": (_now() + timedelta(days=8)).date().isoformat()},
        {"name": "Spotify", "amount": 9.99,
         "due_date": (_now() + timedelta(days=12)).date().isoformat()},
    ],
}

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

_db_lock = threading.Lock()


def _get_conn():
    return psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)


def _fetch_snapshot_from_db() -> dict:
    with _get_conn() as conn:
        with conn.cursor() as cur:
            # Accounts
            cur.execute(
                """
                SELECT type, balance FROM accounts
                WHERE profile_id = %s
                """,
                (PROFILE_ID,),
            )
            accounts = {row["type"]: float(row["balance"]) for row in cur.fetchall()}

            # Monthly income / spending (current calendar month)
            cur.execute(
                """
                SELECT
                    COALESCE(SUM(amount) FILTER (WHERE amount > 0), 0) AS income,
                    COALESCE(ABS(SUM(amount)) FILTER (WHERE amount < 0), 0) AS spending
                FROM transactions
                WHERE profile_id = %s
                  AND date >= date_trunc('month', now())
                """,
                (PROFILE_ID,),
            )
            row = cur.fetchone()
            monthly_income = float(row["income"])
            monthly_spending = float(row["spending"])

            # Top spending categories this month
            cur.execute(
                """
                SELECT
                    category AS name,
                    ABS(SUM(amount)) AS amount,
                    COALESCE(
                        ROUND(
                            100.0 * (
                                ABS(SUM(amount)) - ABS(SUM(amount) FILTER (
                                    WHERE date >= date_trunc('month', now()) - INTERVAL '1 month'
                                    AND date < date_trunc('month', now())
                                ))
                            ) / NULLIF(ABS(SUM(amount) FILTER (
                                WHERE date >= date_trunc('month', now()) - INTERVAL '1 month'
                                AND date < date_trunc('month', now())
                            )), 0),
                        0),
                    0) AS delta
                FROM transactions
                WHERE profile_id = %s
                  AND amount < 0
                  AND date >= date_trunc('month', now())
                  AND category IS NOT NULL
                GROUP BY category
                ORDER BY amount DESC
                LIMIT 5
                """,
                (PROFILE_ID,),
            )
            top_categories = [
                {"name": r["name"], "amount": float(r["amount"]), "delta": float(r["delta"])}
                for r in cur.fetchall()
            ]

            # Recent transactions
            cur.execute(
                """
                SELECT name, amount, category, date
                FROM transactions
                WHERE profile_id = %s
                ORDER BY date DESC
                LIMIT 10
                """,
                (PROFILE_ID,),
            )
            recent_transactions = [
                {
                    "name": r["name"],
                    "amount": float(r["amount"]),
                    "category": r["category"] or "Other",
                    "date": r["date"].isoformat(),
                }
                for r in cur.fetchall()
            ]

            # Goals
            cur.execute(
                """
                SELECT name, target_amount, current_amount, target_date
                FROM goals
                WHERE profile_id = %s
                ORDER BY target_date ASC
                """,
                (PROFILE_ID,),
            )
            goals = [
                {
                    "name": r["name"],
                    "target_amount": float(r["target_amount"]),
                    "current_amount": float(r["current_amount"]),
                    "target_date": r["target_date"].isoformat(),
                }
                for r in cur.fetchall()
            ]

            # Upcoming bills
            cur.execute(
                """
                SELECT name, amount, due_date
                FROM bills
                WHERE profile_id = %s
                  AND due_date >= CURRENT_DATE
                ORDER BY due_date ASC
                LIMIT 5
                """,
                (PROFILE_ID,),
            )
            upcoming_bills = [
                {
                    "name": r["name"],
                    "amount": float(r["amount"]),
                    "due_date": r["due_date"].isoformat(),
                }
                for r in cur.fetchall()
            ]

    return {
        "checking_balance": accounts.get("checking", 0.0),
        "savings_balance": accounts.get("savings", 0.0),
        "monthly_income": monthly_income,
        "monthly_spending": monthly_spending,
        "top_categories": top_categories,
        "recent_transactions": recent_transactions,
        "goals": goals,
        "upcoming_bills": upcoming_bills,
    }


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.get("/snapshot")
def get_snapshot():
    try:
        return _fetch_snapshot_from_db()
    except Exception:
        return MOCK_SNAPSHOT


# ---------------------------------------------------------------------------
# Advisor
# ---------------------------------------------------------------------------

ADVISOR_SYSTEM = """You are FinPilot, a concise and friendly AI financial advisor embedded in a mobile app.
Given the user's real financial snapshot and their question, respond helpfully in 1-3 sentences.
Then choose 1-3 widgets from the list below that best support your answer.

Widget types (include only what's useful):
- summary_card   — data: {label, value (number), subtitle}
- spending_chart  — data: {} (renders from snapshot)
- transaction_table — data: {} (renders from snapshot)
- goal_progress  — data: {name, target (number), current (number), days_left (number)} OR {} (renders from snapshot)
- recommendation_card — data: {title, body, action}
- upcoming_bills  — data: {} (renders from snapshot)

Respond ONLY with valid JSON in this exact shape:
{
  "text": "<your advice>",
  "widgets": [
    {"type": "<widget_type>", "data": {<widget_data>}}
  ]
}
No markdown, no extra keys."""


class AdvisorRequest(BaseModel):
    question: str
    history: list[dict] = []


@app.post("/advisor")
def ask_advisor(req: AdvisorRequest):
    try:
        snapshot = _fetch_snapshot_from_db()
    except Exception:
        snapshot = MOCK_SNAPSHOT

    history_text = ""
    if req.history:
        lines = []
        for msg in req.history[-6:]:  # last 3 exchanges
            role = msg.get("role", "user")
            lines.append(f"{role.capitalize()}: {msg.get('content', '')}")
        history_text = "\n".join(lines) + "\n"

    prompt = f"""{ADVISOR_SYSTEM}

Financial snapshot:
{json.dumps(snapshot, indent=2)}

{history_text}User: {req.question}"""

    try:
        response = gemini_client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=genai_types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.4,
            ),
        )
        result = json.loads(response.text)
        # Ensure required keys exist
        if "text" not in result:
            result["text"] = ""
        if "widgets" not in result:
            result["widgets"] = []
        return result
    except Exception as e:
        return {
            "text": "Sorry, I couldn't connect to the AI advisor right now. Here's a snapshot of your finances.",
            "widgets": [
                {"type": "summary_card", "data": {
                    "label": "Checking Balance",
                    "value": snapshot["checking_balance"],
                    "subtitle": "Available now",
                }},
                {"type": "spending_chart", "data": {}},
            ],
        }
