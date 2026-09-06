from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from fastapi import FastAPI
from pydantic import BaseModel, Field

from services.ai_service import transcribe_and_translate_audio, translate_text


app = FastAPI(title="CivicPulse ML Engine")


class ReportInput(BaseModel):
    title: str = ""
    description: str = ""
    category: str = "general"
    image_data: Any | None = None
    audio_url: str | None = None
    image_url: str | None = None
    video_url: str | None = None


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "python-ml"}


class AudioInput(BaseModel):
    audio_path: str


@app.post("/transcribe-audio")
def transcribe_audio(audio: AudioInput) -> dict[str, str]:
    audio_path = Path(audio.audio_path).resolve()
    uploads_directory = Path(__file__).resolve().parent.parent / "node-gateway" / "uploads"
    if uploads_directory not in audio_path.parents or not audio_path.is_file():
        raise ValueError("Audio upload was not found")
    return {"transcript": transcribe_and_translate_audio(str(audio_path))}


@app.post("/analyze-report")
def analyze_report(report: ReportInput) -> dict[str, Any]:
    category = report.category.strip().lower()
    urgent_categories = {"emergency", "crime", "fire", "flood", "medical"}
    translated_description = translate_text(report.description)
    audio_transcript = ""
    if report.audio_url:
        upload_name = Path(urlparse(report.audio_url).path).name
        audio_path = Path(__file__).resolve().parent.parent / "node-gateway" / "uploads" / upload_name
        if not upload_name or not audio_path.is_file():
            raise ValueError("Audio upload was not found")
        audio_transcript = transcribe_and_translate_audio(str(audio_path))

    combined_text = " ".join(
        part for part in (translated_description, audio_transcript) if part
    ).strip()
    description_length = len(combined_text)

    if category in urgent_categories:
        severity = "high"
        score = 0.9
    elif report.image_data is not None or report.image_url or description_length >= 120:
        severity = "medium"
        score = 0.6
    else:
        severity = "low"
        score = 0.3

    return {
        "severity": severity,
        "score": score,
        "category": category,
        "signals": {
            "has_image": report.image_data is not None,
            "has_image_url": bool(report.image_url),
            "has_audio": bool(report.audio_url),
            "audio_transcript": audio_transcript,
            "translated_description": translated_description,
            "combined_text": combined_text,
            "description_length": description_length,
        },
        "model": "rule-based-v1+whisper-small",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)