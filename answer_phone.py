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

GEMINI_MODEL = "models/gemini-2.5-flash-native-audio-preview-12-2025"
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
                                parts=[types.Part(text="Greet the user as FinPilot and ask what financial question you can help with.")]
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
