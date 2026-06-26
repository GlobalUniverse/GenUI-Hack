# FinPilot - Agentic Mobile Financial Advisor

FinPilot is a hackathon-built mobile financial advisor that helps people understand their money, set goals, and act on recommendations through an AI-first interface. The app combines a Flutter mobile experience, Gemini-powered reasoning, dynamic financial widgets, and Plaid Sandbox data to create a personal teller that feels proactive instead of passive.

The hackathon goal is simple: in six hours, three engineers should be able to demo a mobile advisor that can answer financial questions, render the right UI on demand, and proactively surface one useful money move.

## Demo Pitch

Most finance apps make users dig through charts. FinPilot lets users ask natural-language questions like:

- "Can I afford a $120 dinner tonight?"
- "Where did my money go this month?"
- "How do I save $1,000 in the next 60 days?"
- "What should I do before rent hits tomorrow?"

Gemini interprets the user's financial snapshot, chooses the right visual widgets, and returns concise recommendations. The Flutter app renders those widgets as charts, summary cards, transaction views, goal progress, and action cards.

## 6-Hour MVP

The demo should prioritize a tight, reliable experience over production completeness.

Must-have:

- Flutter mobile app shell with dashboard, advisor chat, and dynamic widget canvas
- FastAPI backend with a compact financial snapshot endpoint
- Plaid Sandbox integration, with seeded mock data as a fallback
- Gemini advisor endpoint that returns text plus structured widget specs
- Dynamic Flutter widget renderer for summaries, charts, transactions, goals, and recommendations
- Goal recommendation flow, such as saving for rent, emergency fund, or upcoming travel
- One proactive agent moment, such as warning about a low balance before a bill

Nice-to-have:

- Twilio SMS alert prototype
- Voice-call brainstorm or stub
- Real Plaid Link flow
- Persistent conversation history
- Alpaca paper trading concept screen

## Architecture

```text
Flutter Mobile App
  Auth-lite / demo profile
  Advisor chat
  Dynamic widget renderer
  Goal and recommendation views
        |
        | REST / streaming response
        v
FastAPI Backend
  Financial snapshot service
  Gemini advisor service
  Widget spec resolver
  Plaid Sandbox or seeded data
  Optional Twilio webhook
        |
        v
Gemini API + Plaid Sandbox + Local DB
```

For the hackathon, the backend can use SQLite or lightweight local Postgres. The important interface is the advisor response contract: natural-language text plus structured widget specs the Flutter app can render immediately.

## Dynamic Gemini UI

FinPilot's core idea is generative UI for personal finance. Instead of a fixed dashboard, the advisor chooses the right interface for the user's question.

Example:

```text
User: "Where did I overspend this month?"

Gemini response:
  Text: "Dining and rideshare were the biggest changes..."
  Widgets:
    - spending_bar_chart
    - category_delta_card
    - transaction_table
    - recommendation_card
```

Initial widget types:

- `summary_card` for balances, cashflow, upcoming bills, or savings rate
- `spending_chart` for category and time-based spending
- `transaction_table` for explainable drill-downs
- `goal_progress` for savings or debt payoff targets
- `recommendation_card` for suggested actions the user can accept, snooze, or reject

## Twilio: Why It Makes Sense

Twilio should not duplicate the app. If the user already has a rich Flutter interface, SMS and voice only make sense for moments when opening the app is inconvenient or when the agent needs to reach the user first.

Good Twilio use cases:

- Proactive alerts: "Rent posts tomorrow and your checking buffer is only $84."
- Quick replies: user texts "move $50 to savings", "remind me Friday", or "show options."
- Hands-busy voice: user calls while walking or commuting and asks, "Can I afford dinner tonight?"
- Re-engagement: FinPilot nudges the user when a goal is drifting or a bill changes the plan.

Trust boundary:

- SMS should send short, low-risk summaries only.
- Sensitive details, account views, and approvals should deep-link back into the app.
- Transfers, investing, or risky actions should require explicit in-app confirmation.

Hackathon demo version:

1. Backend detects a low-buffer scenario from seeded data.
2. It sends or simulates a Twilio SMS alert.
3. User replies with a short intent like "what should I do?"
4. The same Gemini advisor backend returns a concise recommendation.
5. The response links back to the Flutter app for the full plan.

## Team Delegation

Three engineers can work in parallel without stepping on each other.

### Engineer 1 - Backend and Data

Owns:

- FastAPI scaffolding
- Plaid Sandbox or seeded transaction data
- Financial snapshot builder
- Gemini advisor endpoint
- Widget spec response contract

Demo output:

- API returns realistic financial snapshot data
- Advisor endpoint answers questions with text and widget specs

### Engineer 2 - Flutter App and Dynamic UI

Owns:

- Flutter app shell
- Advisor chat interface
- Dynamic widget renderer
- Dashboard and goal screens
- Mobile polish for the final demo

Demo output:

- User can ask a question in the app
- App renders Gemini-selected financial widgets cleanly

### Engineer 3 - Recommendations, Twilio, and Demo Flow

Owns:

- Goal recommendation scenarios
- Proactive alert logic
- Twilio SMS prototype or simulation
- Seed data quality
- Final demo script and fallback paths

Demo output:

- One compelling proactive money moment
- One clean end-to-end story judges can understand quickly

## 6-Hour Build Timeline

### 0:00-0:30 - Align and Scaffold

- Confirm demo story and fallback data
- Create Flutter and FastAPI skeletons
- Define advisor response JSON shape
- Add `.env.example` files

### 0:30-2:00 - Parallel Foundations

- Backend: financial snapshot and seeded/Plaid data
- Flutter: mobile shell, chat UI, placeholder widgets
- Recommendations: goals and proactive alert scenario

### 2:00-4:00 - AI and Dynamic UI

- Connect Gemini advisor endpoint
- Return structured widget specs
- Render widgets in Flutter
- Add transaction/category/goal data to responses

### 4:00-5:00 - Proactive Agent Moment

- Implement or simulate low-buffer alert
- Add Twilio webhook/SMS stub if time allows
- Deep-link or route user from alert back to app context

### 5:00-6:00 - Polish and Demo

- Tighten mobile UI
- Prepare seed data for predictable questions
- Record backup screenshots or screen capture
- Run final end-to-end demo script

## Local Development

### Backend

```bash
cd finpilot-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

### Flutter

```bash
cd finpilot-mobile
flutter pub get
cp .env.example .env
flutter run
```

### Environment Variables

```bash
# Backend
GEMINI_API_KEY=
PLAID_CLIENT_ID=
PLAID_SECRET=
PLAID_ENV=sandbox
DATABASE_URL=sqlite:///./finpilot.db
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Flutter
API_BASE_URL=http://localhost:8000
```

## Stretch Goals

- Real Plaid Link flow instead of seeded fallback data
- Twilio voice call using speech-to-text and text-to-speech
- PayPal transaction import
- Alpaca paper trading recommendations
- Persistent user accounts and conversation history
- Push notifications for proactive advice

## Demo Success Criteria

The hackathon demo is successful if a judge can see:

1. A user asks a money question in a mobile app.
2. FinPilot answers with personalized reasoning.
3. The UI changes dynamically based on the question.
4. The agent recommends a concrete next action.
5. A proactive alert demonstrates why this is an agent, not just a dashboard.
