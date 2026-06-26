import os
import json
import base64
import asyncio
import audioop
from dotenv import load_dotenv
from fastapi import FastAPI, WebSocket, Request
from fastapi.responses import PlainTextResponse
from twilio.twiml.voice_response import VoiceResponse, Connect
from google import genai
from google.genai import types

load_dotenv()

app = FastAPI()

GEMINI_MODEL = "gemini-2.5-flash-preview-native-audio-dialog"
SYSTEM_PROMPT = (
    "You are FinPilot, an AI financial advisor on a phone call. "
    "Be concise — this is voice, so keep replies to 2-3 sentences max. "
    "The user's snapshot: checking $84, savings $420, rent $1200 due tomorrow, "
    "monthly income $3200, top spending: dining $340, rideshare $120, groceries $210."
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

    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    config = types.LiveConnectConfig(
        response_modalities=["AUDIO"],
        system_instruction=SYSTEM_PROMPT,
        speech_config=types.SpeechConfig(
            voice_config=types.VoiceConfig(
                prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Charon")
            )
        ),
    )

    async with client.aio.live.connect(model=GEMINI_MODEL, config=config) as session:
        stream_sid = None

        async def receive_from_twilio():
            nonlocal stream_sid
            try:
                async for raw in websocket.iter_text():
                    data = json.loads(raw)
                    event = data.get("event")
                    if event == "start":
                        stream_sid = data["start"]["streamSid"]
                        # Kick off the conversation
                        await session.send(
                            input="Greet the user as FinPilot and ask what financial question you can help with.",
                            end_of_turn=True,
                        )
                    elif event == "media":
                        ulaw = base64.b64decode(data["media"]["payload"])
                        # µ-law 8 kHz → PCM 16-bit 8 kHz → 16 kHz
                        pcm_8k = audioop.ulaw2lin(ulaw, 2)
                        pcm_16k, _ = audioop.ratecv(pcm_8k, 2, 1, 8000, 16000, None)
                        await session.send_realtime_input(
                            audio=types.Blob(data=pcm_16k, mime_type="audio/pcm;rate=16000")
                        )
                    elif event == "stop":
                        break
            except Exception as e:
                print(f"[twilio→gemini] {e}")

        async def send_to_twilio():
            try:
                async for response in session.receive():
                    if not response.server_content:
                        continue
                    turn = response.server_content.model_turn
                    if not turn:
                        continue
                    for part in turn.parts:
                        if part.inline_data and "audio" in part.inline_data.mime_type:
                            # PCM 24 kHz → 8 kHz → µ-law
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
            except Exception as e:
                print(f"[gemini→twilio] {e}")

        await asyncio.gather(receive_from_twilio(), send_to_twilio())


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 5001))
    uvicorn.run(app, host="0.0.0.0", port=port)
