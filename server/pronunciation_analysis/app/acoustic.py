"""Pluggable acoustic backend. Production scoring requires a configured model."""

from __future__ import annotations

import math
import os
import wave
from pathlib import Path
from typing import Protocol


class BackendUnavailable(RuntimeError):
    pass


class AcousticBackend(Protocol):
    model_version: str

    def analyze(self, wav_path: Path, target_phone: str, position: str) -> dict: ...


class UnavailableBackend:
    model_version = "not-configured"

    def analyze(self, wav_path: Path, target_phone: str, position: str) -> dict:
        raise BackendUnavailable("검증된 한국어 음소 모델이 서버에 설정되지 않았습니다.")


class TransformersCtcBackend:
    def __init__(self, model_id: str):
        try:
            import numpy as np
            import torch
            from transformers import AutoModelForCTC, AutoProcessor
        except ImportError as error:
            raise BackendUnavailable("ML 선택 의존성을 설치해야 합니다.") from error
        self.np = np
        self.torch = torch
        self.processor = AutoProcessor.from_pretrained(model_id)
        self.model = AutoModelForCTC.from_pretrained(model_id).eval()
        self.model_version = model_id

    def analyze(self, wav_path: Path, target_phone: str, position: str) -> dict:
        with wave.open(str(wav_path), "rb") as reader:
            rate = reader.getframerate()
            samples = self.np.frombuffer(reader.readframes(reader.getnframes()), dtype="<i2").astype("float32") / 32768
        inputs = self.processor(samples, sampling_rate=rate, return_tensors="pt")
        with self.torch.no_grad():
            logits = self.model(**inputs).logits[0]
        probabilities = logits.softmax(dim=-1)
        vocabulary = self.processor.tokenizer.get_vocab()
        candidate_ids = [vocabulary.get(target_phone), vocabulary.get(target_phone.replace("_", ""))]
        token_id = next((item for item in candidate_ids if item is not None), None)
        if token_id is None:
            raise BackendUnavailable(f"모델 어휘에 대상 음소 {target_phone}가 없습니다.")
        target_probs = probabilities[:, token_id]
        best_frame = int(target_probs.argmax().item())
        probability = float(target_probs[best_frame].item())
        top_values, top_ids = probabilities[best_frame].topk(min(3, probabilities.shape[-1]))
        candidates = [
            {"phone": self.processor.tokenizer.convert_ids_to_tokens(int(index)), "probability": float(value)}
            for value, index in zip(top_values, top_ids)
        ]
        duration_ms = round(len(samples) / rate * 1000)
        frame_ms = duration_ms / max(1, probabilities.shape[0])
        gop = math.log(max(probability, 1e-8)) - math.log(max(float(top_values[0]), 1e-8))
        score = max(0, min(100, round(probability * 100)))
        confidence = max(0.0, min(1.0, probability))
        return {
            "expected": target_phone,
            "observedCandidates": candidates,
            "position": position,
            "startMs": round(max(0, best_frame - 1) * frame_ms),
            "endMs": round(min(probabilities.shape[0], best_frame + 2) * frame_ms),
            "gop": gop,
            "practiceScore": score,
            "confidence": confidence,
            "status": "accurate" if score >= 75 else "caution" if score >= 55 else "retry",
            "errorType": None,
        }


def backend_from_environment() -> AcousticBackend:
    model_id = os.getenv("PRONUNCIATION_MODEL_ID", "").strip()
    return TransformersCtcBackend(model_id) if model_id else UnavailableBackend()
