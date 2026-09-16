from __future__ import annotations

import asyncio
import contextlib
import os
import time
import tempfile
import uuid
from pathlib import Path
from threading import BoundedSemaphore, Lock
from contextlib import asynccontextmanager
from dataclasses import dataclass

from fastapi import BackgroundTasks, Depends, FastAPI, File, Form, HTTPException, UploadFile

from .acoustic import AcousticBackend, BackendUnavailable
from .security import AnalysisBodyLimitMiddleware, MAX_AUDIO_BYTES, require_client
from .audio import inspect_signal, normalize_to_wav
from .language_registry import (
    BackendRegistry,
    UnsupportedLanguage,
    registry_from_environment,
)

@dataclass
class AnalysisJob:
    owner: str
    expires_at: float
    result: dict


def _expire_jobs() -> None:
    now = time.monotonic()
    with _lock:
        for key in list(_jobs):
            if _jobs[key].expires_at <= now:
                del _jobs[key]


@asynccontextmanager
async def lifespan(app):
    async def sweep():
        while True:
            await asyncio.sleep(30)
            _expire_jobs()
    task = asyncio.create_task(sweep())
    try:
        yield
    finally:
        task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await task
        with _lock:
            _jobs.clear()


app = FastAPI(title="Speech Rehab Pronunciation Analysis", version="0.2.0", lifespan=lifespan)
app.add_middleware(AnalysisBodyLimitMiddleware)
_jobs: dict[str, AnalysisJob] = {}
_lock = Lock()
_worker_slots = BoundedSemaphore(2)
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
    owner: str = Depends(require_client),
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
    if len(text) > 500 or len(target_phone) > 32 or len(content_version) > 100:
        raise HTTPException(422, "Analysis metadata is too long.")
    if not text.strip() or not target_phone.strip():
        raise HTTPException(422, "text와 target_phone은 필수입니다.")
    payload = await audio.read(MAX_AUDIO_BYTES + 1)
    await audio.close()
    if not payload or len(payload) > MAX_AUDIO_BYTES:
        raise HTTPException(413, "오디오 크기는 1바이트 이상 20MB 이하여야 합니다.")
    job_id = str(uuid.uuid4())
    _expire_jobs()
    with _lock:
        active = [job for job in _jobs.values() if job.result["status"] in {"queued", "processing"}]
        if len(active) >= 2 or any(job.owner == owner for job in active):
            raise HTTPException(429, "An analysis is already running. Please wait.", headers={"Retry-After": "5"})
        if len(_jobs) >= 100:
            raise HTTPException(503, "Analysis capacity is temporarily full.")
        ttl = min(900, max(30, int(os.getenv("PRONUNCIATION_RESULT_TTL_SECONDS", "300"))))
        if not _worker_slots.acquire(blocking=False):
            raise HTTPException(429, "Analysis workers are busy.", headers={"Retry-After": "5"})
        _jobs[job_id] = AnalysisJob(owner, time.monotonic() + ttl, {"jobId": job_id, "status": "queued"})
    background_tasks.add_task(
        _run_reserved_job, job_id, payload, audio.filename or "recording.m4a", text,
        language, target_phone, position, target_occurrence, content_version,
        baseline_score, backend,
    )
    return {"jobId": job_id, "status": "queued"}


def _run_reserved_job(*args) -> None:
    try:
        _analyze_job(*args)
    finally:
        _worker_slots.release()


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
        job = _jobs.get(job_id)
        if job is None or job.expires_at <= time.monotonic():
            return
        job.result = {"jobId": job_id, "status": "processing"}
    try:
        with tempfile.TemporaryDirectory(prefix="speech_rehab_") as directory:
            source = Path(directory) / ("input" + Path(filename).suffix[:12])
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
                score_validated = bool(getattr(backend, "score_validated", False))
                phonemes = [dict(matches[target_occurrence])]
                if not score_validated:
                    for phone in phonemes:
                        phone.update(practiceScore=None, gop=None, scoreAvailable=False)
                scores = [item["practiceScore"] for item in phonemes if item.get("practiceScore") is not None]
                score = round(sum(scores) / len(scores)) if scores else None
                confidences = [float(item.get("confidence", 0)) for item in phonemes]
                confidence = sum(confidences) / len(confidences) if confidences else 0.0
                result = {
                    "jobId": job_id, "status": "completed", "language": language,
                    "modelVersion": backend.model_version,
                    "contentVersion": content_version, "overallPracticeScore": score,
                    "confidence": confidence, "phonemes": phonemes,
                    "scoreValidated": score_validated,
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
        job = _jobs.get(job_id)
        # Cancellation or expiry must not resurrect a deleted health record.
        if job is not None and job.expires_at > time.monotonic():
            job.result = result


@app.get("/v1/analysis/jobs/{job_id}")
def get_job(job_id: str, owner: str = Depends(require_client)) -> dict:
    _expire_jobs()
    with _lock:
        job = _jobs.get(job_id)
        if job is None or job.owner != owner:
            raise HTTPException(404, "분석 작업을 찾을 수 없습니다.")
        return dict(job.result)


@app.delete("/v1/analysis/jobs/{job_id}", status_code=204)
def delete_job(job_id: str, owner: str = Depends(require_client)) -> None:
    _expire_jobs()
    with _lock:
        job = _jobs.get(job_id)
        if job is None or job.owner != owner:
            raise HTTPException(404, "분석 작업을 찾을 수 없습니다.")
        del _jobs[job_id]


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
        "aligned": "MFA 음소 정렬을 완료했습니다. 정확도 점수는 환자 발화에 대해 검증된 채점 모델이 준비된 뒤 제공합니다.",
        "failed": "오디오 분석에 실패했습니다.",
    }[kind]
