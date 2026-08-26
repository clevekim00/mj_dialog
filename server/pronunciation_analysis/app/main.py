from __future__ import annotations

import tempfile
import uuid
from pathlib import Path
from threading import Lock

from fastapi import BackgroundTasks, FastAPI, File, Form, HTTPException, UploadFile

from .acoustic import AcousticBackend, BackendUnavailable, backend_from_environment
from .audio import inspect_signal, normalize_to_wav

app = FastAPI(title="Speech Rehab Pronunciation Analysis", version="0.1.0")
_jobs: dict[str, dict] = {}
_lock = Lock()
_backend: AcousticBackend = backend_from_environment()


def configure_backend(backend: AcousticBackend) -> None:
    global _backend
    _backend = backend


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict:
    return {"ready": _backend.ready, "modelVersion": _backend.model_version}


@app.post("/v1/analysis/jobs", status_code=202)
async def create_job(
    background_tasks: BackgroundTasks,
    audio: UploadFile = File(...),
    text: str = Form(...),
    target_phone: str = Form(...),
    position: str = Form(...),
    content_version: str = Form(...),
    baseline_score: float | None = Form(None),
) -> dict:
    if position not in {"onset", "coda"}:
        raise HTTPException(422, "position은 onset 또는 coda여야 합니다.")
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
        target_phone, position, content_version, baseline_score,
    )
    return {"jobId": job_id, "status": "queued"}


def _analyze_job(job_id: str, payload: bytes, filename: str, text: str, target_phone: str, position: str, content_version: str, baseline_score: float | None) -> None:
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
                    "jobId": job_id, "status": "unavailable", "modelVersion": _backend.model_version,
                    "contentVersion": content_version, "overallPracticeScore": None,
                    "confidence": 0.0, "phonemes": [], "baselineDelta": None,
                    "signalQuality": quality.to_dict(), "message": f"녹음 품질을 확인해 주세요: {quality.reason}",
                    "disclaimer": "훈련 참고용 자동 분석이며 임상 진단이 아닙니다.",
                }
            else:
                phonemes = _backend.analyze(wav_path, text, target_phone, position)
                scores = [item["practiceScore"] for item in phonemes if item.get("practiceScore") is not None]
                score = round(sum(scores) / len(scores)) if scores else None
                confidences = [float(item.get("confidence", 0)) for item in phonemes]
                confidence = sum(confidences) / len(confidences) if confidences else 0.0
                result = {
                    "jobId": job_id, "status": "completed", "modelVersion": _backend.model_version,
                    "contentVersion": content_version, "overallPracticeScore": score,
                    "confidence": confidence, "phonemes": phonemes,
                    "baselineDelta": score - baseline_score if score is not None and baseline_score is not None else None,
                    "signalQuality": quality.to_dict(),
                    "message": None if score is not None else "MFA 음소 정렬을 완료했습니다. 정확도 점수는 CTC/GoP 모델을 연결한 뒤 제공합니다.",
                    "disclaimer": "훈련 참고용 자동 분석이며 임상 진단이 아닙니다.",
                }
    except BackendUnavailable as error:
        result = {
            "jobId": job_id, "status": "unavailable", "modelVersion": _backend.model_version,
            "contentVersion": content_version, "overallPracticeScore": None,
            "confidence": 0.0, "phonemes": [], "baselineDelta": None,
            "signalQuality": {"accepted": True}, "message": str(error),
            "disclaimer": "훈련 참고용 자동 분석이며 임상 진단이 아닙니다.",
        }
    except Exception:
        result = {
            "jobId": job_id, "status": "failed", "modelVersion": _backend.model_version,
            "contentVersion": content_version, "overallPracticeScore": None,
            "confidence": 0.0, "phonemes": [], "baselineDelta": None,
            "signalQuality": {"accepted": False}, "message": "오디오 분석에 실패했습니다.",
            "disclaimer": "훈련 참고용 자동 분석이며 임상 진단이 아닙니다.",
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
