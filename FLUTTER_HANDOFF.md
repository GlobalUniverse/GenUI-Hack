# Backend → Flutter handoff

Short version: **you don't need to change any of your Dart models.** The backend
was adapted to match what your `ApiService`, `FinancialSnapshot`, and
`AdvisorResponse` already expect, not the other way around. Point your app at
a live backend and real(-ish) data should just render.

## Point your app here

```
# finpilot-frontend/.env.local
API_BASE_URL=http://localhost:8001
```

Note the port: **8001, not 8000** — something unrelated on this machine is
already squatting on 8000.

The backend is currently running with seeded data for `profile_id=demo`. The
seed script (`finpilot-backend/scripts/seed_plaid_mock_data.py`) builds a
payload shaped exactly like Plaid's real `/transactions/sync` response and
feeds it through the same code path a real Plaid Sandbox link uses — so
what you're hitting is indistinguishable from a real linked account. It's
temporary scaffolding, deleted once the real Plaid Link flow is wired up
end-to-end in the app.

## Endpoints (already matching your existing models)

### `GET /snapshot?profile_id=demo`

Returns exactly the shape `FinancialSnapshot.fromJson` expects:

```json
{
  "checking_balance": 790.12,
  "savings_balance": 460.0,
  "monthly_income": 4200.0,
  "monthly_spending": 1986.97,
  "top_categories": [{"name": "Food And Drink", "amount": 167.4, "delta": 0.0}],
  "recent_transactions": [{"name": "Rent", "amount": -1500.0, "category": "Rent And Utilities", "date": "2026-06-27"}],
  "goals": [{"name": "Emergency Fund", "target_amount": 5000.0, "current_amount": 3420.0, "target_date": "2026-09-24"}],
  "upcoming_bills": [{"name": "Rent", "amount": 1500.0, "due_date": "2026-06-27"}]
}
```

`recent_transactions[].amount` is signed (negative = money out, positive =
money in) — same convention your mock data already used.

### `POST /advisor`

Request body matches what `askAdvisor` already sends:

```json
{"question": "Can I afford a $120 dinner tonight?", "history": []}
```

Response matches `AdvisorResponse.fromJson` / `WidgetSpec.fromJson`:

```json
{
  "text": "...",
  "widgets": [
    {"type": "summary_card", "data": {"label": "Everyday Checking", "value": 790.12, "subtitle": "Available now"}},
    {"type": "recommendation_card", "data": {"title": "Suggested next action", "body": "...", "action": "Set a spending limit"}}
  ]
}
```

Widget `data` conventions, for reference (these match what your widget
classes already read):

| widget type | data keys |
|---|---|
| `summary_card` | `label`, `value` (signed), `subtitle` |
| `goal_progress` | `name`, `target`, `current`, `days_left` |
| `recommendation_card` | `title`, `body`, `action` |
| `spending_chart`, `transaction_table`, `upcoming_bills` | `data` is empty — your renderer already pulls these from the loaded `FinancialSnapshot`, not from the widget spec, so nothing to change here |

`upcoming_bills` is now a backend-allowed widget type too (it wasn't before —
Gemini can emit it without being rejected server-side).

## New: proactive alerts (not yet in the UI — this is the opening)

### `POST /api/alerts/scan?profile_id=demo`

This is new. It's the "mother agent" scanning finances for things the user
didn't ask about — low bill buffer, high credit utilization, idle cash,
goal pace drift. Returns a list of `AlertSnapshot`:

```json
[
  {
    "id": "...",
    "type": "low_buffer",
    "severity": "critical",
    "message": "After Rent ($1500.00) clears, your checking buffer drops to $-709.88.",
    "payload": {"bill_name": "Rent", "amount": 1500.0, "buffer_after_bill": -709.88}
  }
]
```

`severity` is `info` | `warning` | `critical`. `critical` also triggers an
outbound SMS to the user right now (separate from the inbound Twilio
webhook track) — so a `critical` finding means "the agent already texted
them about this," and the in-app surface should treat it as already-seen,
not a fresh ping.

There's no UI for this yet. Suggested first cut: a dismissible banner/feed
on the dashboard, sourced from this endpoint, styled by severity — this is
the actual "proactive, not reactive" surface for the demo, so it's worth
prioritizing over more chat polish if you're choosing where to spend time.
Your existing `RecommendationCard` accept/snooze/dismiss buttons are already
built for this kind of thing; right now they're local-only state with no
backend call behind them, which is fine for the demo unless we decide we
need persistence.

## Branch status (as of this handoff)

PR #1 (Flutter scaffold) and #8 (light theme redesign, currently wrongly
based on `main` instead of `feat/flutter-app`, so it duplicates the whole
scaffold) are being cleaned up by an automated pass right now — merge order
and conflict resolution will be reported separately. Don't rebase your own
work on top of either until that lands, to avoid fighting a moving target.
