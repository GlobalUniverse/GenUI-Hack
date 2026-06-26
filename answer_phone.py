import os
import json
import base64
import asyncio
import audioop
import psycopg2
import psycopg2.extras
from datetime import date
from dotenv import load_dotenv
from fastapi import FastAPI, WebSocket, Request
from fastapi.responses import PlainTextResponse
from twilio.twiml.voice_response import VoiceResponse, Connect
from google import genai
from google.genai import types

load_dotenv()

app = FastAPI()

GEMINI_MODEL = "models/gemini-2.5-flash-native-audio-preview-12-2025"
DATABASE_URL = os.getenv("DATABASE_URL")
VOICE_PROFILE_ID = os.getenv("VOICE_PROFILE_ID", "jordan")


def _fetch_snapshot(profile_id: str) -> dict:
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)
    cur = conn.cursor()

    cur.execute("SELECT display_name FROM profiles WHERE id=%s", (profile_id,))
    row = cur.fetchone()
    display_name = row["display_name"] if row else profile_id

    cur.execute(
        "SELECT subtype, current_balance FROM accounts WHERE profile_id=%s AND type='depository'",
        (profile_id,),
    )
    accounts = {r["subtype"]: float(r["current_balance"]) for r in cur.fetchall()}

    cur.execute(
        """SELECT
            COALESCE(SUM(amount) FILTER (WHERE direction='inflow'), 0) AS income,
            COALESCE(SUM(amount) FILTER (WHERE direction='outflow'), 0) AS spending
           FROM transactions
           WHERE profile_id=%s AND date >= date_trunc('month', now())""",
        (profile_id,),
    )
    totals = cur.fetchone()

    cur.execute(
        """SELECT category AS name, SUM(amount) AS amount
           FROM transactions
           WHERE profile_id=%s AND direction='outflow'
             AND date >= date_trunc('month', now()) AND category IS NOT NULL
           GROUP BY category ORDER BY amount DESC LIMIT 5""",
        (profile_id,),
    )
    top_categories = [{"name": r["name"], "amount": float(r["amount"])} for r in cur.fetchall()]

    cur.execute(
        """SELECT name, amount, date FROM transactions
           WHERE profile_id=%s ORDER BY date DESC LIMIT 8""",
        (profile_id,),
    )
    recent = [{"name": r["name"], "amount": float(r["amount"]), "date": str(r["date"])} for r in cur.fetchall()]

    cur.execute(
        "SELECT title, target_amount, current_amount, target_date FROM goals WHERE profile_id=%s AND status='active'",
        (profile_id,),
    )
    goals = [
        {"name": r["title"], "target": float(r["target_amount"]),
         "saved": float(r["current_amount"]), "due": str(r["target_date"])}
        for r in cur.fetchall()
    ]

    conn.close()
    return {
        "name": display_name,
        "checking": accounts.get("checking", 0),
        "savings": accounts.get("savings", 0),
        "monthly_income": float(totals["income"]),
        "monthly_spending": float(totals["spending"]),
        "top_categories": top_categories,
        "recent_transactions": recent,
        "goals": goals,
    }


def _build_system_prompt(snap: dict) -> str:
    cats = ", ".join(f"{c['name']} ${c['amount']:.0f}" for c in snap["top_categories"])
    goals = "; ".join(
        f"{g['name']} (${g['saved']:.0f} of ${g['target']:.0f})" for g in snap["goals"]
    )
    recent = ", ".join(f"{t['name']} ${abs(t['amount']):.2f}" for t in snap["recent_transactions"][:5])
    return (
        f"You are FinPilot, an AI financial advisor on a phone call with {snap['name']}. "
        f"Be concise — this is voice, so keep replies to 2-3 sentences max. "
        f"Here is {snap['name']}'s current financial snapshot:\n"
        f"- Checking: ${snap['checking']:,.2f}\n"
        f"- Savings: ${snap['savings']:,.2f}\n"
        f"- Monthly income: ${snap['monthly_income']:,.2f}\n"
        f"- Monthly spending so far: ${snap['monthly_spending']:,.2f}\n"
        f"- Top spending categories: {cats}\n"
        f"- Recent transactions: {recent}\n"
        f"- Goals: {goals}\n"
        f"Use this data to give personalized, specific advice. Address them by first name."
    )


@app.api_route("/", methods=["GET", "POST"])
async def incoming_call(request: Request):
    host = request.headers.get("host")
    resp = VoiceResponse()
    connect = Connect()
    connect.stream(url=f"wss://{host}/media")
    resp.append(connect)
    return PlainTextResponse(str(resp), media_type="text/xml")


@app.websocket("/media")
async def media_stream(websocket: WebSocket):
    await websocket.accept()

    try:
        snap = _fetch_snapshot(VOICE_PROFILE_ID)
        system_prompt = _build_system_prompt(snap)
        print(f"[init] Loaded profile: {snap['name']} (checking=${snap['checking']})")
    except Exception as e:
        print(f"[init] DB fetch failed, using fallback: {e}")
        snap = {"name": "the user"}
        system_prompt = (
            "You are FinPilot, an AI financial advisor on a phone call. "
            "Be concise — this is voice, so keep replies to 2-3 sentences max."
        )

    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    config = types.LiveConnectConfig(
        response_modalities=["AUDIO"],
        system_instruction=system_prompt,
        speech_config=types.SpeechConfig(
            voice_config=types.VoiceConfig(
                prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Charon")
            )
        ),
        realtime_input_config=types.RealtimeInputConfig(
            automatic_activity_detection=types.AutomaticActivityDetection(
                disabled=False,
                start_of_speech_sensitivity=types.StartSensitivity.START_SENSITIVITY_HIGH,
                end_of_speech_sensitivity=types.EndSensitivity.END_SENSITIVITY_LOW,
            )
        ),
    )

    async with client.aio.live.connect(model=GEMINI_MODEL, config=config) as session:
        stream_sid = None

        async def receive_from_twilio():
            nonlocal stream_sid
            media_count = 0
            try:
                async for raw in websocket.iter_text():
                    data = json.loads(raw)
                    event = data.get("event")
                    if event == "start":
                        stream_sid = data["start"]["streamSid"]
                        print(f"[start] stream_sid={stream_sid}")
                        await session.send_client_content(
                            turns=types.Content(
                                role="user",
                                parts=[types.Part(text=f"Greet {snap['name']} by name as FinPilot and ask what financial question you can help with today.")]
                            ),
                            turn_complete=True,
                        )
                    elif event == "media":
                        ulaw = base64.b64decode(data["media"]["payload"])
                        pcm_8k = audioop.ulaw2lin(ulaw, 2)
                        pcm_16k, _ = audioop.ratecv(pcm_8k, 2, 1, 8000, 16000, None)
                        await session.send_realtime_input(
                            audio=types.Blob(data=pcm_16k, mime_type="audio/pcm;rate=16000")
                        )
                        media_count += 1
                        if media_count % 50 == 0:
                            print(f"[twilio->gemini] {media_count} audio chunks sent")
                    elif event == "stop":
                        print("[stop] Twilio stream ended")
                        break
            except Exception as e:
                print(f"[twilio->gemini] error: {e}")

        async def send_to_twilio():
            audio_chunks = 0
            try:
                while True:
                    async for response in session.receive():
                        sc = response.server_content
                        if not sc:
                            continue
                        if sc.turn_complete:
                            print(f"[gemini->twilio] turn complete, sent {audio_chunks} audio chunks")
                            audio_chunks = 0
                        turn = sc.model_turn
                        if not turn:
                            continue
                        for part in turn.parts:
                            if part.inline_data and "audio" in part.inline_data.mime_type:
                                pcm_24k = part.inline_data.data
                                pcm_8k, _ = audioop.ratecv(pcm_24k, 2, 1, 24000, 8000, None)
                                ulaw = audioop.lin2ulaw(pcm_8k, 2)
                                payload = base64.b64encode(ulaw).decode()
                                if stream_sid:
                                    await websocket.send_json({
                                        "event": "media",
                                        "streamSid": stream_sid,
                                        "media": {"payload": payload},
                                    })
                                    audio_chunks += 1
                    print("[gemini->twilio] receive() turn ended, restarting listener")
            except Exception as e:
                print(f"[gemini->twilio] error: {e}")

        await asyncio.gather(receive_from_twilio(), send_to_twilio())


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 5001))
    uvicorn.run(app, host="0.0.0.0", port=port)
