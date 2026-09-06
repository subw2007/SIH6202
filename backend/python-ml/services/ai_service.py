import whisper
from deep_translator import GoogleTranslator


model = whisper.load_model("small")

HINGLISH_TRANSLATION_SYSTEM_PROMPT = (
    "You are a Hinglish-to-English translator for civic reporting. "
    "Accurately translate colloquial Hinglish (e.g., 'gaddhe' = potholes, "
    "'paani bhara/mara' = waterlogging/stagnant water) into clear English. "
    "Return ONLY the English translation."
)


def transcribe_and_translate_audio(audio_path: str) -> str:
    result = model.transcribe(
        audio_path,
        task="translate",
        initial_prompt=HINGLISH_TRANSLATION_SYSTEM_PROMPT,
    )
    return str(result.get("text", "")).strip()


def translate_text(text: str) -> str:
    if not text.strip():
        return ""
    return GoogleTranslator(source="auto", target="en").translate(text) or ""