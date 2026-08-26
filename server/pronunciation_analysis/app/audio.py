"""Audio normalization and conservative signal-quality gates."""

from __future__ import annotations

import math
import shutil
import struct
import subprocess
import wave
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class SignalQuality:
    accepted: bool
    duration_ms: int
    rms: float
    clipping_ratio: float
    reason: str | None = None

    def to_dict(self) -> dict:
        return {
            "accepted": self.accepted,
            "durationMs": self.duration_ms,
            "rms": self.rms,
            "clippingRatio": self.clipping_ratio,
            "reason": self.reason,
        }


def normalize_to_wav(source: Path, destination: Path) -> Path:
    if source.suffix.lower() == ".wav":
        try:
            with wave.open(str(source), "rb") as reader:
                is_normalized = (
                    reader.getnchannels() == 1
                    and reader.getsampwidth() == 2
                    and reader.getframerate() == 16000
                )
        except wave.Error:
            is_normalized = False
        if is_normalized:
            shutil.copyfile(source, destination)
            return destination
    command = [
        "ffmpeg", "-y", "-i", str(source), "-ac", "1", "-ar", "16000",
        "-sample_fmt", "s16", str(destination),
    ]
    try:
        subprocess.run(command, check=True, capture_output=True, timeout=20)
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        raise ValueError("오디오 변환에 실패했습니다. 서버에 ffmpeg가 필요합니다.") from error
    return destination


def inspect_signal(wav_path: Path) -> SignalQuality:
    try:
        with wave.open(str(wav_path), "rb") as reader:
            channels = reader.getnchannels()
            width = reader.getsampwidth()
            rate = reader.getframerate()
            frames = reader.getnframes()
            raw = reader.readframes(frames)
    except (wave.Error, EOFError) as error:
        raise ValueError("지원하지 않는 WAV 파일입니다.") from error
    if width != 2 or channels < 1 or rate <= 0:
        raise ValueError("16-bit PCM WAV만 분석할 수 있습니다.")
    values = struct.unpack(f"<{len(raw) // 2}h", raw)
    mono = values[::channels]
    if not mono:
        return SignalQuality(False, 0, 0, 0, "empty")
    duration_ms = round(len(mono) / rate * 1000)
    rms = math.sqrt(sum(value * value for value in mono) / len(mono)) / 32768
    clipping_ratio = sum(abs(value) >= 32700 for value in mono) / len(mono)
    reason = None
    if duration_ms < 250:
        reason = "too_short"
    elif duration_ms > 20000:
        reason = "too_long"
    elif rms < 0.008:
        reason = "too_quiet"
    elif clipping_ratio > 0.03:
        reason = "clipping"
    return SignalQuality(reason is None, duration_ms, rms, clipping_ratio, reason)
