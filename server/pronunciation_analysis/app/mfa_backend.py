"""Korean Montreal Forced Aligner adapter and dependency-free TextGrid parser."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from .acoustic import BackendUnavailable


@dataclass(frozen=True)
class TextGridInterval:
    tier: str
    start_seconds: float
    end_seconds: float
    label: str


CommandRunner = Callable[[list[str], float], subprocess.CompletedProcess[str]]


# 앱 콘텐츠에서 사용하는 단순 phone id를 Korean MFA IPA phone set으로 연결합니다.
# 초성의 유성 변이와 모음 앞 마찰 변이를 포함하되, 종성은 불파음으로 제한합니다.
KOREAN_MFA_PHONE_MAP: dict[tuple[str, str], frozenset[str]] = {
    ("k", "onset"): frozenset({"k", "ɡ"}),
    ("kk", "onset"): frozenset({"k͈"}),
    ("n", "onset"): frozenset({"n", "ɲ"}),
    ("t", "onset"): frozenset({"t", "d"}),
    ("tt", "onset"): frozenset({"t͈"}),
    ("r", "onset"): frozenset({"ɾ", "ɭ"}),
    ("m", "onset"): frozenset({"m"}),
    ("p", "onset"): frozenset({"p", "b"}),
    ("pp", "onset"): frozenset({"p͈"}),
    ("s", "onset"): frozenset({"s", "sʰ", "ɕʰ"}),
    ("ss", "onset"): frozenset({"s͈", "ɕ͈"}),
    ("j", "onset"): frozenset({"tɕ", "dʑ"}),
    ("jj", "onset"): frozenset({"tɕ͈"}),
    ("ch", "onset"): frozenset({"tɕʰ"}),
    ("kh", "onset"): frozenset({"kʰ"}),
    ("th", "onset"): frozenset({"tʰ"}),
    ("ph", "onset"): frozenset({"pʰ", "ɸ"}),
    ("h", "onset"): frozenset({"h", "ɦ", "x", "ç"}),
    ("kf", "coda"): frozenset({"k̚"}),
    ("nf", "coda"): frozenset({"n"}),
    ("tf", "coda"): frozenset({"t̚"}),
    ("lf", "coda"): frozenset({"ɭ"}),
    ("mf", "coda"): frozenset({"m"}),
    ("pf", "coda"): frozenset({"p̚"}),
    ("ngf", "coda"): frozenset({"ŋ"}),
}


def parse_textgrid(text: str) -> list[TextGridInterval]:
    """Parse long-form Praat TextGrid IntervalTiers without praatio."""
    intervals: list[TextGridInterval] = []
    tier_name = ""
    in_interval = False
    start: float | None = None
    end: float | None = None
    label: str | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        name_match = re.fullmatch(r'name\s*=\s*"(.*)"', line)
        if name_match:
            if in_interval:
                _append_interval(intervals, tier_name, start, end, label)
                in_interval = False
                start = end = None
                label = None
            tier_name = _unescape_textgrid(name_match.group(1))
            continue
        if re.fullmatch(r"intervals \[\d+\]:", line):
            if in_interval:
                _append_interval(intervals, tier_name, start, end, label)
            in_interval = True
            start = end = None
            label = None
            continue
        if not in_interval:
            continue
        xmin_match = re.fullmatch(r"xmin\s*=\s*(-?[0-9.eE+]+)", line)
        xmax_match = re.fullmatch(r"xmax\s*=\s*(-?[0-9.eE+]+)", line)
        text_match = re.fullmatch(r'text\s*=\s*"(.*)"', line)
        if xmin_match:
            start = float(xmin_match.group(1))
        elif xmax_match:
            end = float(xmax_match.group(1))
        elif text_match:
            label = _unescape_textgrid(text_match.group(1))
    if in_interval:
        _append_interval(intervals, tier_name, start, end, label)
    return intervals


def _unescape_textgrid(value: str) -> str:
    return value.replace('""', '"').strip()


def _append_interval(
    output: list[TextGridInterval],
    tier: str,
    start: float | None,
    end: float | None,
    label: str | None,
) -> None:
    if start is None or end is None or label is None:
        return
    output.append(TextGridInterval(tier, start, end, label))


def _default_runner(command: list[str], timeout: float) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


class KoreanMfaBackend:
    """Use Korean MFA for phone segmentation; deliberately does not invent a score."""

    def __init__(
        self,
        *,
        command: str = "mfa",
        dictionary: str = "korean_mfa",
        acoustic_model: str = "korean_mfa",
        model_revision: str = "v3.0.0",
        timeout_seconds: float = 45,
        runner: CommandRunner = _default_runner,
        executable_lookup: Callable[[str], str | None] = shutil.which,
    ):
        self.command = command
        self.dictionary = dictionary
        self.acoustic_model = acoustic_model
        self.timeout_seconds = timeout_seconds
        self._runner = runner
        self._executable_lookup = executable_lookup
        self.model_version = f"mfa-korean-{model_revision}"

    @property
    def ready(self) -> bool:
        return self._executable_lookup(self.command) is not None

    def analyze(
        self,
        wav_path: Path,
        text: str,
        target_phone: str,
        position: str,
    ) -> list[dict]:
        executable = self._executable_lookup(self.command)
        if executable is None:
            raise BackendUnavailable(
                "Montreal Forced Aligner가 설치되지 않았습니다. README의 MFA 설치 단계를 확인해 주세요."
            )
        expected_labels = KOREAN_MFA_PHONE_MAP.get((target_phone, position))
        if expected_labels is None:
            raise BackendUnavailable(f"MFA phone 매핑이 없는 대상입니다: {target_phone}/{position}")

        with tempfile.TemporaryDirectory(prefix="speech_rehab_mfa_") as directory:
            work = Path(directory)
            transcript_path = work / "utterance.lab"
            output_path = work / "utterance.TextGrid"
            transcript_path.write_text(_normalize_transcript(text), encoding="utf-8")
            command = [
                executable,
                "align_one",
                str(wav_path),
                str(transcript_path),
                self.dictionary,
                self.acoustic_model,
                str(output_path),
                "--temporary_directory",
                str(work / "mfa_temp"),
                "--single_speaker",
                "--clean",
                "--no_verbose",
            ]
            try:
                completed = self._runner(command, self.timeout_seconds)
            except subprocess.TimeoutExpired as error:
                raise BackendUnavailable("MFA 정렬 시간이 초과되었습니다.") from error
            if completed.returncode != 0:
                detail = _safe_error(completed.stderr or completed.stdout)
                raise BackendUnavailable(f"MFA 정렬에 실패했습니다: {detail}")
            if not output_path.exists():
                candidates = list(work.rglob("*.TextGrid"))
                if not candidates:
                    raise BackendUnavailable("MFA가 TextGrid 결과를 만들지 않았습니다.")
                output_path = candidates[0]
            intervals = parse_textgrid(output_path.read_text(encoding="utf-8"))

        phone_intervals = [
            interval
            for interval in intervals
            if interval.tier.lower() in {"phones", "phone"}
            and interval.label in expected_labels
            and interval.end_seconds > interval.start_seconds
        ]
        if not phone_intervals:
            raise BackendUnavailable(
                f"정렬 결과에서 목표 음소 {target_phone} 구간을 찾지 못했습니다."
            )
        return [
            {
                "expected": target_phone,
                "alignedPhone": interval.label,
                "observedCandidates": [],
                "position": position,
                "startMs": round(interval.start_seconds * 1000),
                "endMs": round(interval.end_seconds * 1000),
                "gop": None,
                "practiceScore": None,
                "scoreAvailable": False,
                "confidence": 0.0,
                "status": "aligned",
                "errorType": None,
            }
            for interval in phone_intervals
        ]


def backend_from_environment() -> KoreanMfaBackend:
    return KoreanMfaBackend(
        command=os.getenv("MFA_COMMAND", "mfa"),
        dictionary=os.getenv("MFA_DICTIONARY", "korean_mfa"),
        acoustic_model=os.getenv("MFA_ACOUSTIC_MODEL", "korean_mfa"),
        model_revision=os.getenv("MFA_MODEL_REVISION", "v3.0.0"),
        timeout_seconds=float(os.getenv("MFA_TIMEOUT_SECONDS", "45")),
    )


def _normalize_transcript(text: str) -> str:
    normalized = " ".join(text.replace("\n", " ").split()).strip()
    if not normalized:
        raise BackendUnavailable("정렬할 문장이 비어 있습니다.")
    return normalized


def _safe_error(message: str, limit: int = 300) -> str:
    collapsed = " ".join(message.split())
    return (collapsed[:limit] or "알 수 없는 MFA 오류").replace(os.getcwd(), "<workdir>")
