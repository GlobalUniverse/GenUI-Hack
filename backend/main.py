import os
import json
import threading
from datetime import datetime, timedelta, timezone

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException
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
# Demo accounts (hardcoded -- no real auth backend exists for the mock demo)
# ---------------------------------------------------------------------------

DEMO_USERS = {
    "alex@finpilot.app": {"password": "demo123", "profile_id": "alex"},
    "jordan@finpilot.app": {"password": "demo123", "profile_id": "jordan"},
    "sam@finpilot.app": {"password": "demo123", "profile_id": "sam"},
}


class LoginRequest(BaseModel):
    email: str
    password: str


@app.post("/login")
def login(req: LoginRequest):
    user = DEMO_USERS.get(req.email.strip().lower())
    if not user or user["password"] != req.password:
        raise HTTPException(status_code=401, detail="Invalid email or password.")
    return {"profile_id": user["profile_id"]}


# ---------------------------------------------------------------------------
# Mock data -- one persona per demo account (matches the Flutter GenUI
# dashboard's layout/tabs vocabulary in lib/screens/dashboard_screen.dart)
# ---------------------------------------------------------------------------

def _now():
    return datetime.now(timezone.utc)


MOCK_ALEX = {
    "checking_balance": 142.18,
    "savings_balance": 0.0,
    "monthly_income": 3100.00,
    "monthly_spending": 3340.55,
    "profile_name": "Alex Chen",
    "profile_tagline": "Checking balance trending toward zero",
    "layout": ["critical_banner", "overdraft_forecast", "balances", "cashflow", "merchant_breakdown", "weekly_spending", "spending_chart", "transactions"],
    "tabs": ["dashboard", "advisor"],
    "overdraft_days": 3,
    "critical_message": "Your checking balance will go negative in about 3 days at this spending rate.",
    "net_worth": 142.18,
    "net_worth_change": -240.0,
    "savings_rate": 0,
    "top_merchants": [
        {"name": "DoorDash", "amount": 312.40, "count": 14},
        {"name": "Uber", "amount": 248.75, "count": 11},
        {"name": "Starbucks", "amount": 96.20, "count": 9},
    ],
    "weekly_spending": [62.0, 48.5, 91.0, 120.0, 138.5, 165.0, 210.0],
    "top_categories": [
        {"name": "Dining", "amount": 620, "delta": 18},
        {"name": "Rideshare", "amount": 310, "delta": 42},
        {"name": "Groceries", "amount": 210, "delta": -5},
        {"name": "Entertainment", "amount": 180, "delta": 12},
    ],
    "recent_transactions": [
        {"name": "DoorDash", "amount": -28.40, "category": "Dining", "date": (_now() - timedelta(hours=5)).isoformat()},
        {"name": "Uber", "amount": -24.50, "category": "Rideshare", "date": (_now() - timedelta(hours=18)).isoformat()},
        {"name": "Starbucks", "amount": -7.20, "category": "Dining", "date": (_now() - timedelta(days=1)).isoformat()},
        {"name": "DoorDash", "amount": -33.10, "category": "Dining", "date": (_now() - timedelta(days=1)).isoformat()},
        {"name": "Direct Deposit", "amount": 1550.00, "category": "Income", "date": (_now() - timedelta(days=4)).isoformat()},
    ],
    "goals": [],
    "upcoming_bills": [
        {"name": "Rent", "amount": 1400, "due_date": (_now() + timedelta(days=5)).date().isoformat()},
    ],
}

MOCK_JORDAN = {
    "checking_balance": 4820.32,
    "savings_balance": 17938.10,
    "monthly_income": 6200.00,
    "monthly_spending": 3596.00,
    "profile_name": "Jordan Kim",
    "profile_tagline": "Healthy savings rate, on pace for every goal",
    "layout": ["balances", "net_worth", "savings_rate", "cashflow", "goals", "spending_chart", "transactions"],
    "tabs": ["dashboard", "advisor", "goals"],
    "overdraft_days": 0,
    "critical_message": "",
    "net_worth": 22758.42,
    "net_worth_change": 1180.0,
    "savings_rate": 42,
    "top_merchants": [
        {"name": "Whole Foods", "amount": 410.0, "count": 6},
        {"name": "REI", "amount": 180.0, "count": 2},
    ],
    "weekly_spending": [45.0, 38.0, 52.0, 40.0, 61.0, 88.0, 30.0],
    "top_categories": [
        {"name": "Groceries", "amount": 410, "delta": -3},
        {"name": "Utilities", "amount": 220, "delta": 0},
        {"name": "Entertainment", "amount": 150, "delta": 5},
    ],
    "recent_transactions": [
        {"name": "Whole Foods", "amount": -64.20, "category": "Groceries", "date": (_now() - timedelta(days=1)).isoformat()},
        {"name": "Direct Deposit", "amount": 3100.00, "category": "Income", "date": (_now() - timedelta(days=3)).isoformat()},
        {"name": "Auto-transfer to Savings", "amount": -1200.00, "category": "Transfer", "date": (_now() - timedelta(days=3)).isoformat()},
        {"name": "REI", "amount": -89.00, "category": "Shopping", "date": (_now() - timedelta(days=6)).isoformat()},
    ],
    "goals": [
        {"name": "Emergency Fund", "target_amount": 15000, "current_amount": 15000, "target_date": (_now() + timedelta(days=30)).date().isoformat()},
        {"name": "House Down Payment", "target_amount": 60000, "current_amount": 21000, "target_date": (_now() + timedelta(days=900)).date().isoformat()},
        {"name": "Travel Fund", "target_amount": 4000, "current_amount": 2400, "target_date": (_now() + timedelta(days=120)).date().isoformat()},
    ],
    "upcoming_bills": [
        {"name": "Mortgage", "amount": 1850, "due_date": (_now() + timedelta(days=9)).date().isoformat()},
    ],
}

MOCK_SAM = {
    "checking_balance": -42.50,
    "savings_balance": 110.00,
    "monthly_income": 2400.00,
    "monthly_spending": 2615.00,
    "profile_name": "Sam Rivera",
    "profile_tagline": "Rent is overdue and checking is already negative",
    "layout": ["critical_banner", "overdraft_forecast", "balances", "cashflow", "upcoming_bills", "transactions"],
    "tabs": ["dashboard", "advisor"],
    "overdraft_days": 0,
    "critical_message": "Rent ($1,350.00) is overdue and your checking balance is already negative.",
    "net_worth": 67.50,
    "net_worth_change": -310.0,
    "savings_rate": 0,
    "top_merchants": [],
    "weekly_spending": [12.0, 15.0, 9.0, 22.0, 18.0, 30.0, 14.0],
    "top_categories": [
        {"name": "Rent And Utilities", "amount": 1450, "delta": 8},
        {"name": "Groceries", "amount": 180, "delta": 0},
    ],
    "recent_transactions": [
        {"name": "Electric Co", "amount": -88.40, "category": "Rent And Utilities", "date": (_now() - timedelta(days=1)).isoformat()},
        {"name": "Gas Station", "amount": -32.00, "category": "Transport", "date": (_now() - timedelta(days=2)).isoformat()},
        {"name": "Paycheck", "amount": 1100.00, "category": "Income", "date": (_now() - timedelta(days=5)).isoformat()},
    ],
    "goals": [],
    "upcoming_bills": [
        {"name": "Rent", "amount": 1350, "due_date": (_now() - timedelta(days=2)).date().isoformat()},
        {"name": "Phone Bill", "amount": 65, "due_date": (_now() + timedelta(days=2)).date().isoformat()},
    ],
}

MOCK_BY_PROFILE = {"alex": MOCK_ALEX, "jordan": MOCK_JORDAN, "sam": MOCK_SAM}

MOCK_SNAPSHOT = MOCK_ALEX

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

_db_lock = threading.Lock()


def _get_conn():
    return psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)


def _fetch_snapshot_from_db(profile_id: str) -> dict:
    with _get_conn() as conn:
        with conn.cursor() as cur:
            # Accounts
            cur.execute(
                """
                SELECT type, balance FROM accounts
                WHERE profile_id = %s
                """,
                (profile_id,),
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
                (profile_id,),
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
                (profile_id,),
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
                (profile_id,),
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
                (profile_id,),
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
                (profile_id,),
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


def _snapshot_for(profile_id: str) -> dict:
    """DB-backed snapshot if reachable, else the per-profile mock persona."""
    try:
        return _fetch_snapshot_from_db(profile_id)
    except Exception:
        return MOCK_BY_PROFILE.get(profile_id, MOCK_ALEX)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.get("/snapshot")
def get_snapshot(profile_id: str = "alex"):
    return _snapshot_for(profile_id)


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
    profile_id: str = "alex"


@app.post("/advisor")
def ask_advisor(req: AdvisorRequest):
    snapshot = _snapshot_for(req.profile_id)

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
