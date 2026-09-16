"""Pluggable acoustic backend. Production scoring requires a configured model."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Protocol


class BackendUnavailable(RuntimeError):
    pass


class AcousticBackend(Protocol):
    model_version: str
    ready: bool

    def analyze(
        self, wav_path: Path, text: str, target_phone: str, position: str
    ) -> list[dict]: ...


class UnavailableBackend:
    model_version = "not-configured"
    ready = False

    def analyze(
        self, wav_path: Path, text: str, target_phone: str, position: str
    ) -> list[dict]:
        raise BackendUnavailable("검증된 한국어 음소 모델이 서버에 설정되지 않았습니다.")


class TransformersCtcBackend:
    """Disabled until alignment and dysarthric-speech score validity are established.

    A token's maximum probability anywhere in a recording is not pronunciation
    accuracy and cannot identify the requested occurrence reliably.
    """
    def __init__(self, model_id: str):
        self.model_version = f"unvalidated-ctc:{model_id}"
        self.ready = False

    def analyze(
        self, wav_path: Path, text: str, target_phone: str, position: str
    ) -> list[dict]:
        raise BackendUnavailable(
            "CTC pronunciation scoring is unavailable pending validated alignment and calibration."
        )


def backend_from_environment() -> AcousticBackend:
    backend = os.getenv("PRONUNCIATION_BACKEND", "mfa").strip().lower()
    if backend == "mfa":
        from .mfa_backend import backend_from_environment as mfa_from_environment

        return mfa_from_environment()
    if backend not in {"ctc", "transformers"}:
        return UnavailableBackend()
    model_id = os.getenv("PRONUNCIATION_MODEL_ID", "").strip()
    return TransformersCtcBackend(model_id) if model_id else UnavailableBackend()
