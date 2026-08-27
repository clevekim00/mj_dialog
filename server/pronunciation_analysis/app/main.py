from __future__ import annotations

import tempfile
import uuid
from pathlib import Path
from threading import Lock

from fastapi import BackgroundTasks, FastAPI, File, Form, HTTPException, UploadFile

from .acoustic import AcousticBackend, BackendUnavailable
from .audio import inspect_signal, normalize_to_wav
from .language_registry import (
    BackendRegistry,
    UnsupportedLanguage,
    registry_from_environment,
)

app = FastAPI(title="Speech Rehab Pronunciation Analysis", version="0.1.0")
_jobs: dict[str, dict] = {}
_lock = Lock()
_registry = registry_from_environment()


def configure_backend(backend: AcousticBackend, language: str = "ko-KR") -> None:
    _registry.backends[language] = backend


def configure_registry(registry: BackendRegistry) -> None:
    global _registry
    _registry = registry


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict:
    languages = _registry.readiness()
    return {
        "ready": bool(languages) and all(item["ready"] for item in languages.values()),
        "languages": languages,
    }


@app.post("/v1/analysis/jobs", status_code=202)
async def create_job(
    background_tasks: BackgroundTasks,
    audio: UploadFile = File(...),
    text: str = Form(...),
    language: str = Form(...),
    target_phone: str = Form(...),
    position: str = Form(...),
    target_occurrence: int = Form(0),
    content_version: str = Form(...),
    baseline_score: float | None = Form(None),
) -> dict:
    if position not in {"onset", "medial", "coda"}:
        raise HTTPException(422, "position은 onset, medial 또는 coda여야 합니다.")
    if target_occurrence < 0:
        raise HTTPException(422, "target_occurrence는 0 이상이어야 합니다.")
    try:
        backend = _registry.resolve(language)
    except UnsupportedLanguage as error:
        raise HTTPException(
            422,
            {"code": "unsupported_language", "language": language},
        ) from error
    if not text.strip() or not target_phone.strip():
        raise HTTPException(422, "text와 target_phone은 필수입니다.")
    payload = await audio.read()
    if not payload or len(payload) > 20 * 1024 * 1024:
        raise HTTPException(413, "오디오 크기는 1바이트 이상 20MB 이하여야 합니다.")
    job_id = str(uuid.uuid4())
    with _lock:
        _jobs[job_id] = {"jobId": job_id, "status": "queued"}
    background_tasks.add_task(
        _analyze_job, job_id, payload, audio.filename or "recording.m4a", text,
        language, target_phone, position, target_occurrence, content_version,
        baseline_score, backend,
    )
    return {"jobId": job_id, "status": "queued"}


def _analyze_job(
    job_id: str,
    payload: bytes,
    filename: str,
    text: str,
    language: str,
    target_phone: str,
    position: str,
    target_occurrence: int,
    content_version: str,
    baseline_score: float | None,
    backend: AcousticBackend,
) -> None:
    with _lock:
        _jobs[job_id] = {"jobId": job_id, "status": "processing"}
    try:
        with tempfile.TemporaryDirectory(prefix="speech_rehab_") as directory:
            source = Path(directory) / Path(filename).name
            source.write_bytes(payload)
            wav_path = Path(directory) / "normalized.wav"
            normalize_to_wav(source, wav_path)
            quality = inspect_signal(wav_path)
            if not quality.accepted:
                result = {
                    "jobId": job_id, "status": "unavailable", "language": language,
                    "modelVersion": backend.model_version,
                    "contentVersion": content_version, "overallPracticeScore": None,
                    "confidence": 0.0, "phonemes": [], "baselineDelta": None,
                    "signalQuality": quality.to_dict(),
                    "message": _message(language, "quality", quality.reason),
                    "disclaimer": _disclaimer(language),
                }
            else:
                matches = backend.analyze(wav_path, text, target_phone, position)
                if target_occurrence >= len(matches):
                    raise BackendUnavailable(
                        _message(language, "occurrence", str(target_occurrence + 1))
                    )
                phonemes = [matches[target_occurrence]]
                scores = [item["practiceScore"] for item in phonemes if item.get("practiceScore") is not None]
                score = round(sum(scores) / len(scores)) if scores else None
                confidences = [float(item.get("confidence", 0)) for item in phonemes]
                confidence = sum(confidences) / len(confidences) if confidences else 0.0
                result = {
                    "jobId": job_id, "status": "completed", "language": language,
                    "modelVersion": backend.model_version,
                    "contentVersion": content_version, "overallPracticeScore": score,
                    "confidence": confidence, "phonemes": phonemes,
                    "baselineDelta": score - baseline_score if score is not None and baseline_score is not None else None,
                    "signalQuality": quality.to_dict(),
                    "message": None if score is not None else _message(language, "aligned"),
                    "disclaimer": _disclaimer(language),
                }
    except BackendUnavailable as error:
        result = {
            "jobId": job_id, "status": "unavailable", "language": language,
            "modelVersion": backend.model_version,
            "contentVersion": content_version, "overallPracticeScore": None,
            "confidence": 0.0, "phonemes": [], "baselineDelta": None,
            "signalQuality": {"accepted": True}, "message": str(error),
            "disclaimer": _disclaimer(language),
        }
    except Exception:
        result = {
            "jobId": job_id, "status": "failed", "language": language,
            "modelVersion": backend.model_version,
            "contentVersion": content_version, "overallPracticeScore": None,
            "confidence": 0.0, "phonemes": [], "baselineDelta": None,
            "signalQuality": {"accepted": False},
            "message": _message(language, "failed"),
            "disclaimer": _disclaimer(language),
        }
    with _lock:
        _jobs[job_id] = result


@app.get("/v1/analysis/jobs/{job_id}")
def get_job(job_id: str) -> dict:
    with _lock:
        result = _jobs.get(job_id)
    if result is None:
        raise HTTPException(404, "분석 작업을 찾을 수 없습니다.")
    return result


@app.delete("/v1/analysis/jobs/{job_id}", status_code=204)
def delete_job(job_id: str) -> None:
    with _lock:
        if _jobs.pop(job_id, None) is None:
            raise HTTPException(404, "분석 작업을 찾을 수 없습니다.")


def _disclaimer(language: str) -> str:
    if language == "en-US":
        return "Automated practice feedback; not a clinical diagnosis."
    return "훈련 참고용 자동 분석이며 임상 진단이 아닙니다."


def _message(language: str, kind: str, detail: str = "") -> str:
    if language == "en-US":
        return {
            "quality": f"Please check the recording quality: {detail}",
            "occurrence": f"Target phone occurrence {detail} was not found.",
            "aligned": "MFA phone alignment is complete. Accuracy scoring requires a validated CTC/GoP model.",
            "failed": "Audio analysis failed.",
        }[kind]
    return {
        "quality": f"녹음 품질을 확인해 주세요: {detail}",
        "occurrence": f"목표 음소의 {detail}번째 구간을 찾지 못했습니다.",
        "aligned": "MFA 음소 정렬을 완료했습니다. 정확도 점수는 CTC/GoP 모델을 연결한 뒤 제공합니다.",
        "failed": "오디오 분석에 실패했습니다.",
    }[kind]
