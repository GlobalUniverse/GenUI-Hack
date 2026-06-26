# FinPilot — AI-Powered Personal Finance Platform

An AI financial advisor that aggregates your banking data, generates dynamic visualizations on demand, and provides personalized recommendations with autopilot investing capabilities.

---

## Overview

FinPilot connects to your financial accounts (Plaid Sandbox + PayPal), feeds your real financial data to Claude AI, and lets you ask natural-language questions like _"show me my spending last 3 months"_ or _"how do I save $10k by December?"_ — the AI picks the right charts and tables to render alongside its answer.

### Core Features

| Feature | Description |
|---|---|
| **Account Aggregation** | Link bank accounts via Plaid Sandbox; PayPal transaction history via OAuth |
| **Dynamic AI Dashboard** | Claude picks and renders charts/tables based on your questions (no fixed layout) |
| **AI Financial Advisor** | Goal-aware recommendations backed by your real financial snapshot |
| **Autopilot Investing** | Phase 1: AI trade recommendations. Phase 2: execution via Alpaca paper trading |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Browser (Next.js)                      │
│  NextAuth.js session ──► JWT bearer ──► FastAPI             │
│  Chat UI + DynamicCanvas ──► SSE stream ──► WidgetRenderer  │
└─────────────────────────┬───────────────────────────────────┘
                          │ REST + SSE
┌─────────────────────────▼───────────────────────────────────┐
│                     FastAPI (Python)                        │
│  Auth ▸ Plaid ▸ PayPal ▸ AI Service ▸ Portfolio            │
│  Background: APScheduler (nightly sync, Plaid webhooks)     │
└──────┬───────────────────┬──────────────────┬───────────────┘
       │                   │                  │
  PostgreSQL         Anthropic API    Plaid / PayPal / Alpaca
  (SQLAlchemy)     claude-sonnet-4-6   (sandboxes + paper)
```

**Stack:**
- **Frontend** — Next.js 14 (App Router), TypeScript, Shadcn/ui, Recharts, TanStack Table
- **Backend** — Python FastAPI, SQLAlchemy, Alembic, APScheduler
- **AI** — Claude claude-sonnet-4-6 via Anthropic API (tool use + SSE streaming)
- **Data** — Plaid Sandbox, PayPal REST API
- **Investing** — Alpaca Paper Trading API (Phase 2)

---

## Repository Structure

```
finpilot/
├── finpilot-frontend/          # Next.js app
│   ├── app/
│   │   ├── (auth)/             # login, register
│   │   └── (dashboard)/        # accounts, transactions, advisor, goals, portfolio
│   ├── components/
│   │   ├── widgets/            # 10 dynamic financial widgets
│   │   ├── advisor/            # Chat UI + DynamicCanvas
│   │   └── layout/             # Sidebar, TopNav
│   ├── hooks/                  # useChat (SSE), useFinancialData, usePortfolio
│   ├── store/                  # Zustand global state
│   └── types/
│
└── finpilot-backend/           # FastAPI app
    ├── app/
    │   ├── models/             # SQLAlchemy ORM models
    │   ├── schemas/            # Pydantic request/response models
    │   ├── routers/            # auth, plaid, paypal, advisor, goals, portfolio, webhooks
    │   ├── services/
    │   │   ├── ai_service.py           # Claude streaming + tool use
    │   │   ├── financial_snapshot.py   # compact context builder for Claude
    │   │   ├── widget_resolver.py      # tool calls → real DB data → WidgetSpec
    │   │   ├── plaid_service.py
    │   │   ├── paypal_service.py
    │   │   └── alpaca_service.py       # Phase 2
    │   └── core/               # JWT auth, security, dependencies
    └── alembic/                # DB migrations
```

---

## How the AI UI Works

The dynamic widget system is the core innovation. When you ask a question:

1. **Snapshot** — Backend builds a compact (~2500 token) JSON summary of your accounts, balances, spending, and goals.
2. **Claude with tool use** — The AI receives 10 widget tool definitions (`render_bar_chart`, `render_line_chart`, `render_pie_chart`, `render_summary_card`, `render_transaction_table`, `render_goal_progress`, `render_budget_tracker`, `render_net_worth_timeline`, `render_investment_portfolio`, `render_recommendation_card`). It decides which to call.
3. **Widget resolver** — Each tool call maps to a DB query that returns a `WidgetSpec` with real data.
4. **SSE stream** — Text chunks and widget specs stream to the frontend in real time.
5. **WidgetRenderer** — Dispatches each `widget_type` to its React component.

```
User: "How much did I spend on food last 3 months?"
  → Claude calls render_bar_chart(data_query="spending_by_category", date_range_months=3)
  → Backend queries DB, returns real bar chart data
  → Frontend renders BarChartWidget alongside Claude's text response
```

---

## Data Models

| Table | Purpose |
|---|---|
| `users` | Auth, preferences |
| `linked_accounts` | Plaid/PayPal/Alpaca accounts with AES-256 encrypted tokens |
| `transactions` | All transactions from all sources, categorized |
| `goals` | Savings/debt/retirement goals with AI-generated action plans |
| `recommendations` | AI advisory items the user can accept/reject |
| `portfolio_holdings` | Investment positions (Phase 2) |
| `trade_orders` | AI-recommended + executed trades (Phase 2) |
| `ai_conversations` | Conversation history |
| `ai_messages` | Messages with widget specs stored as JSONB |

Sensitive third-party tokens (Plaid, PayPal, Alpaca) are encrypted with AES-256-GCM before storage. The encryption key lives in an environment variable, never in the database.

---

## API Endpoints

### Auth
```
POST /api/auth/register
POST /api/auth/login        → JWT
POST /api/auth/refresh
```

### Plaid
```
POST /api/plaid/create-link-token
POST /api/plaid/exchange-token
GET  /api/plaid/accounts
POST /api/plaid/sync
POST /api/webhooks/plaid
```

### PayPal
```
GET /api/paypal/auth-url
GET /api/paypal/callback
POST /api/paypal/sync
```

### AI Advisor
```
POST /api/advisor/conversations
GET  /api/advisor/conversations/{id}/messages
POST /api/advisor/conversations/{id}/chat    → SSE stream
GET  /api/advisor/recommendations
POST /api/advisor/recommendations/{id}/accept
```

### Portfolio (Phase 2)
```
GET  /api/portfolio/holdings
GET  /api/portfolio/performance
POST /api/portfolio/orders
```

---

## Phase Roadmap

### Phase 1 — MVP (Weeks 1–10)
- [ ] User auth (NextAuth + FastAPI JWT)
- [ ] Plaid Sandbox: account linking, transaction sync, webhooks
- [ ] PayPal OAuth: transaction history import
- [ ] Static dashboard (prebuilt summary widgets)
- [ ] AI Advisor chat with dynamic widget rendering
- [ ] Goal management with AI action plans
- [ ] Financial recommendations engine
- [ ] Nightly sync via APScheduler

### Phase 2 — Autopilot (Weeks 11–16)
- [ ] Alpaca paper trading account linking
- [ ] Portfolio holdings display + P&L tracking
- [ ] AI investment recommendations with reasoning
- [ ] Trade review UI (approve/reject)
- [ ] Paper trade execution
- [ ] Trade order history + notifications

---

## Team Task Breakdown

Three full-stack developers, split by feature domain:

### Dev 1 — Backend Core
FastAPI scaffolding, PostgreSQL/Alembic setup, auth (JWT), Plaid Sandbox integration, PayPal OAuth flow, transaction sync, financial data models, Plaid webhook handler, APScheduler sync jobs.

**Owns:** `finpilot-backend/app/routers/auth.py`, `plaid.py`, `paypal.py`, `accounts.py`, `transactions.py`, `webhooks.py` and all corresponding models, schemas, and services.

### Dev 2 — AI + Frontend
Next.js scaffolding, all dashboard pages, widget component library (10 widgets), AI advisor chat UI with SSE streaming, Claude tool-use integration (`ai_service.py`, `financial_snapshot.py`, `widget_resolver.py`), goal management UI.

**Owns:** `finpilot-frontend/` (all), `finpilot-backend/app/routers/advisor.py`, `goals.py`, and corresponding AI services.

### Dev 3 — Portfolio + Investing
Alpaca paper trading integration, portfolio holdings backend, investment recommendations engine, portfolio frontend pages, trade review UI, Docker Compose setup, CI/CD pipeline.

**Owns:** `finpilot-backend/app/routers/portfolio.py`, `app/services/alpaca_service.py`, `finpilot-frontend/app/(dashboard)/portfolio/`, `docker-compose.yml`, `.github/workflows/`.

---

## Local Development Setup

### Prerequisites
```bash
# Node.js 20+, Python 3.12+, PostgreSQL 15+
brew install node python postgresql
```

### Backend
```bash
cd finpilot-backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # fill in your keys
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

### Frontend
```bash
cd finpilot-frontend
npm install
cp .env.example .env.local  # fill in your keys
npm run dev  # http://localhost:3000
```

### Plaid Sandbox Credentials
1. Create account at `dashboard.plaid.com`
2. Create a Sandbox app → copy Client ID and Secret
3. Test institution: First Platypus Bank (`ins_109508`)
4. Test credentials: `user_good` / `pass_good`

### PayPal Sandbox
1. Create account at `developer.paypal.com`
2. Create Sandbox app → copy Client ID and Secret

---

## Environment Variables

```bash
# finpilot-backend/.env
DATABASE_URL=postgresql://finpilot:password@localhost:5432/finpilot
JWT_SECRET=<64-char random hex>
TOKEN_ENCRYPTION_KEY=<32-byte base64 AES key>
PLAID_CLIENT_ID=
PLAID_SECRET=
PLAID_ENV=sandbox
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
PAYPAL_ENV=sandbox
ANTHROPIC_API_KEY=
ALPACA_API_KEY=           # Phase 2
ALPACA_SECRET_KEY=        # Phase 2
ALPACA_BASE_URL=https://paper-api.alpaca.markets

# finpilot-frontend/.env.local
NEXTAUTH_SECRET=<32-char random>
NEXTAUTH_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:8000
```
