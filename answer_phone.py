import os
from flask import Flask, request
from twilio.twiml.voice_response import VoiceResponse, Gather

app = Flask(__name__)


@app.route("/", methods=['GET', 'POST'])
def hello_monkey():
    resp = VoiceResponse()
    gather = Gather(input='speech', action='/respond', timeout=5, speech_timeout='auto')
    gather.say("Hey, I'm FinPilot, your AI financial advisor. What can I help you with today?")
    resp.append(gather)
    return str(resp)


@app.route("/respond", methods=['GET', 'POST'])
def respond():
    user_said = request.form.get('SpeechResult', '')
    print(f"User said: {user_said}")

    # TODO: replace this stub with a call to the Gemini advisor endpoint
    reply = get_ai_reply(user_said)

    resp = VoiceResponse()
    gather = Gather(input='speech', action='/respond', timeout=5, speech_timeout='auto')
    gather.say(reply)
    resp.append(gather)

    # If user goes silent, prompt again
    resp.redirect('/')
    return str(resp)


def get_ai_reply(user_input: str) -> str:
    """Stub — swap this out for a real Gemini call."""
    user_input_lower = user_input.lower()
    if 'balance' in user_input_lower or 'money' in user_input_lower:
        return "Your checking balance is 84 dollars and your savings is 420 dollars. Rent is due tomorrow. What would you like to do?"
    elif 'rent' in user_input_lower:
        return "Rent is 1200 dollars due tomorrow but you only have 84 in checking. I'd recommend transferring from savings. Want me to walk you through that?"
    elif 'save' in user_input_lower or 'saving' in user_input_lower:
        return "You're currently saving about 13 percent of your income. To hit your emergency fund goal you need 580 more dollars. Want a savings plan?"
    else:
        return f"You said: {user_input}. I'm still learning. Try asking about your balance, rent, or savings goals."


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port)
