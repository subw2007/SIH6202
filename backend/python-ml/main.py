import json
import os
from pathlib import Path
from typing import Any
from urllib.parse import urlparse
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from fastapi import FastAPI, HTTPException
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


class DuplicateEvaluationInput(BaseModel):
    new_submission: dict[str, Any]
    candidate_reports: list[dict[str, Any]]


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


@app.post("/evaluate-duplicate")
def evaluate_duplicate(payload: DuplicateEvaluationInput) -> dict[str, Any]:
    system_prompt = (
        "Are these describing the exact same physical problem? "
        "Ignore minor category mismatches. Return ONLY strict JSON with keys "
        "is_duplicate (boolean) and matched_report_id (string or null)."
    )
    user_prompt = json.dumps(
        {
            "new_submission": payload.new_submission,
            "candidate_reports": payload.candidate_reports,
        },
        ensure_ascii=True,
    )
    model_names = [
        model.strip()
        for model in os.getenv(
            "OLLAMA_MODELS",
            "llama3.2:3b,qwen2.5,llama3.2:1b",
        ).split(",")
        if model.strip()
    ]
    
    print("\n--- STARTING DUPLICATE EVALUATION ---")
    print(f"Models to try: {model_names}")
    
    response_body = None
    last_error: Exception | None = None
    
    for model_name in model_names:
        print(f"Trying model: {model_name}...")
        request_body = json.dumps(
            {
                "model": model_name,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "format": "json",
                "stream": False,
            }
        ).encode("utf-8")
        
        request = Request(
            f"{os.getenv('OLLAMA_BASE_URL', 'http://127.0.0.1:11434')}/api/chat",
            data=request_body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urlopen(request, timeout=60) as response:
                response_body = json.loads(response.read().decode("utf-8"))
            print(f"Model {model_name} succeeded!")
            break
        except Exception as error:
            print(f"Model {model_name} failed with error: {error}")
            if hasattr(error, 'read'):
                print(f"Error body: {error.read().decode('utf-8')}")
            last_error = error

    if response_body is None:
        print(f"All models failed. Last error: {last_error}")
        raise HTTPException(status_code=502, detail=f"Local LLM evaluation failed: {last_error}") from last_error

    content = response_body.get("message", {}).get("content", "")
    print(f"LLM Raw Output: {content}")
    
    try:
        result = json.loads(content)
    except json.JSONDecodeError as error:
        print(f"Warning: JSON Decode Error: {error}")
        return {"is_duplicate": False, "matched_report_id": None}

    if not isinstance(result, dict):
        print(f"Warning: LLM returned a non-object JSON value: {type(result)}")
        result = {}

    is_duplicate = result.get("is_duplicate")
    matched_report_id = result.get("matched_report_id")
    
    print(f"Parsed is_duplicate: {is_duplicate} (type: {type(is_duplicate)})")
    
    # SAFETY NET: Small LLMs often return "true" (string) instead of true (boolean)
    if is_duplicate is None:
        is_duplicate = False
    elif isinstance(is_duplicate, str):
        is_duplicate = is_duplicate.lower() == "true"
    elif not isinstance(is_duplicate, bool):
        print(f"Warning: invalid boolean value, defaulting to false: {is_duplicate}")
        is_duplicate = False
            
    if matched_report_id is not None and not isinstance(matched_report_id, str):
        print("Warning: invalid report ID, defaulting to None")
        matched_report_id = None
        
    print("--- EVALUATION SUCCESSFUL ---\n")
    return {
        "is_duplicate": is_duplicate,
        "matched_report_id": matched_report_id,
    }

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)