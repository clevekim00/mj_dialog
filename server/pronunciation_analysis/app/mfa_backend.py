"""Multilingual Montreal Forced Aligner adapters and TextGrid parser."""

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
    ("k0", "onset"): frozenset({"k", "ɡ"}),
    ("kk", "onset"): frozenset({"k͈"}),
    ("n", "onset"): frozenset({"n", "ɲ"}),
    ("t", "onset"): frozenset({"t", "d"}),
    ("t0", "onset"): frozenset({"t", "d"}),
    ("tt", "onset"): frozenset({"t͈"}),
    ("r", "onset"): frozenset({"ɾ", "ɭ"}),
    ("m", "onset"): frozenset({"m"}),
    ("p", "onset"): frozenset({"p", "b"}),
    ("p0", "onset"): frozenset({"p", "b"}),
    ("pp", "onset"): frozenset({"p͈"}),
    ("s", "onset"): frozenset({"s", "sʰ", "ɕʰ"}),
    ("s0", "onset"): frozenset({"s", "sʰ", "ɕʰ"}),
    ("ss", "onset"): frozenset({"s͈", "ɕ͈"}),
    ("j", "onset"): frozenset({"tɕ", "dʑ"}),
    ("c0", "onset"): frozenset({"tɕ", "dʑ"}),
    ("jj", "onset"): frozenset({"tɕ͈"}),
    ("cc", "onset"): frozenset({"tɕ͈"}),
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
    ("ng", "coda"): frozenset({"ŋ"}),
}


def _all_positions(*labels: str) -> dict[str, frozenset[str]]:
    values = frozenset(labels)
    return {position: values for position in ("onset", "medial", "coda")}


_ENGLISH_PHONE_LABELS: dict[str, dict[str, frozenset[str]]] = {
    "p": _all_positions("p", "pʰ", "pʲ", "pʷ"),
    "b": _all_positions("b", "bʲ", "bʷ"),
    "t": _all_positions("t", "tʰ", "tʲ", "tʷ"),
    "d": _all_positions("d", "dʲ", "dʷ", "ɾ"),
    "k": _all_positions("k", "kʰ", "kʷ", "c", "cʷ"),
    "g": _all_positions("ɡ", "ɡʷ", "ɟ", "ɟʷ"),
    "f": _all_positions("f", "fʲ"),
    "v": _all_positions("v", "vʲ"),
    "theta": _all_positions("θ", "t̪"),
    "eth": _all_positions("ð", "d̪"),
    "s": _all_positions("s", "sʲ"),
    "z": _all_positions("z", "zʲ"),
    "sh": _all_positions("ʃ"),
    "zh": _all_positions("ʒ"),
    "ch": _all_positions("tʃ"),
    "jh": _all_positions("dʒ"),
    "m": _all_positions("m", "mʲ"),
    "n": _all_positions("n", "nʲ"),
    "ng": _all_positions("ŋ"),
    "w": _all_positions("w"),
    "y": _all_positions("j"),
    "r": _all_positions("ɹ", "ɻ"),
    "l": _all_positions("l", "ɫ", "ʎ"),
    "h": _all_positions("h"),
}

ENGLISH_MFA_PHONE_MAP: dict[tuple[str, str], frozenset[str]] = {
    (phone, position): labels
    for phone, positions in _ENGLISH_PHONE_LABELS.items()
    for position, labels in positions.items()
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


class MfaBackend:
    """Use MFA for phone segmentation; deliberately does not invent a score."""

    def __init__(
        self,
        *,
        language: str,
        model_name: str,
        phone_map: dict[tuple[str, str], frozenset[str]],
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
        self.language = language
        self.phone_map = phone_map
        self._runner = runner
        self._executable_lookup = executable_lookup
        self.model_version = f"mfa-{model_name}-{model_revision}"

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
            raise BackendUnavailable(self._error("not_installed"))
        expected_labels = self.phone_map.get((target_phone, position))
        if expected_labels is None:
            raise BackendUnavailable(
                self._error("missing_mapping", f"{target_phone}/{position}")
            )

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
                raise BackendUnavailable(self._error("timeout")) from error
            if completed.returncode != 0:
                detail = _safe_error(completed.stderr or completed.stdout)
                raise BackendUnavailable(self._error("failed", detail))
            if not output_path.exists():
                candidates = list(work.rglob("*.TextGrid"))
                if not candidates:
                    raise BackendUnavailable(self._error("no_textgrid"))
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
            raise BackendUnavailable(self._error("phone_not_found", target_phone))
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

    def _error(self, kind: str, detail: str = "") -> str:
        if self.language == "en-US":
            return {
                "not_installed": "Montreal Forced Aligner is not installed. See the server README.",
                "missing_mapping": f"No MFA phone mapping exists for {detail}.",
                "timeout": "MFA alignment timed out.",
                "failed": f"MFA alignment failed: {detail}",
                "no_textgrid": "MFA did not create a TextGrid result.",
                "phone_not_found": f"Target phone {detail} was not found in the alignment.",
            }[kind]
        return {
            "not_installed": "Montreal Forced Aligner가 설치되지 않았습니다. README의 MFA 설치 단계를 확인해 주세요.",
            "missing_mapping": f"MFA phone 매핑이 없는 대상입니다: {detail}",
            "timeout": "MFA 정렬 시간이 초과되었습니다.",
            "failed": f"MFA 정렬에 실패했습니다: {detail}",
            "no_textgrid": "MFA가 TextGrid 결과를 만들지 않았습니다.",
            "phone_not_found": f"정렬 결과에서 목표 음소 {detail} 구간을 찾지 못했습니다.",
        }[kind]


class KoreanMfaBackend(MfaBackend):
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
        super().__init__(
            command=command,
            dictionary=dictionary,
            acoustic_model=acoustic_model,
            model_revision=model_revision,
            language="ko-KR",
            model_name="korean",
            phone_map=KOREAN_MFA_PHONE_MAP,
            timeout_seconds=timeout_seconds,
            runner=runner,
            executable_lookup=executable_lookup,
        )


class EnglishMfaBackend(MfaBackend):
    def __init__(
        self,
        *,
        command: str = "mfa",
        dictionary: str = "english_us_mfa",
        acoustic_model: str = "english_mfa",
        model_revision: str = "v3.1.0",
        timeout_seconds: float = 45,
        runner: CommandRunner = _default_runner,
        executable_lookup: Callable[[str], str | None] = shutil.which,
    ):
        super().__init__(
            command=command,
            dictionary=dictionary,
            acoustic_model=acoustic_model,
            model_revision=model_revision,
            language="en-US",
            model_name="english",
            phone_map=ENGLISH_MFA_PHONE_MAP,
            timeout_seconds=timeout_seconds,
            runner=runner,
            executable_lookup=executable_lookup,
        )


def backend_from_environment() -> KoreanMfaBackend:
    return KoreanMfaBackend(
        command=os.getenv("MFA_COMMAND", "mfa"),
        dictionary=os.getenv("MFA_DICTIONARY", "korean_mfa"),
        acoustic_model=os.getenv("MFA_ACOUSTIC_MODEL", "korean_mfa"),
        model_revision=os.getenv("MFA_MODEL_REVISION", "v3.0.0"),
        timeout_seconds=float(os.getenv("MFA_TIMEOUT_SECONDS", "45")),
    )


def english_backend_from_environment() -> EnglishMfaBackend:
    return EnglishMfaBackend(
        command=os.getenv("MFA_COMMAND", "mfa"),
        dictionary=os.getenv("MFA_EN_US_DICTIONARY", "english_us_mfa"),
        acoustic_model=os.getenv("MFA_EN_US_ACOUSTIC_MODEL", "english_mfa"),
        model_revision=os.getenv("MFA_EN_US_MODEL_REVISION", "v3.1.0"),
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
