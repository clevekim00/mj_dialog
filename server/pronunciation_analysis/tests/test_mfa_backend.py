import subprocess
import tempfile
import unittest
import wave
from pathlib import Path

from app.acoustic import BackendUnavailable
from app.mfa_backend import KoreanMfaBackend, parse_textgrid


TEXTGRID = '''File type = "ooTextFile"
Object class = "TextGrid"

xmin = 0
xmax = 0.8
tiers? <exists>
size = 2
item []:
    item [1]:
        class = "IntervalTier"
        name = "words"
        xmin = 0
        xmax = 0.8
        intervals: size = 1
        intervals [1]:
            xmin = 0.1
            xmax = 0.7
            text = "각"
    item [2]:
        class = "IntervalTier"
        name = "phones"
        xmin = 0
        xmax = 0.8
        intervals: size = 4
        intervals [1]:
            xmin = 0
            xmax = 0.1
            text = "sil"
        intervals [2]:
            xmin = 0.1
            xmax = 0.22
            text = "k"
        intervals [3]:
            xmin = 0.22
            xmax = 0.52
            text = "ɐ"
        intervals [4]:
            xmin = 0.52
            xmax = 0.7
            text = "k̚"
'''


class MfaBackendTests(unittest.TestCase):
    def test_parses_phone_tier_without_optional_dependency(self):
        intervals = parse_textgrid(TEXTGRID)
        phones = [item for item in intervals if item.tier == "phones"]
        self.assertEqual([item.label for item in phones], ["sil", "k", "ɐ", "k̚"])
        self.assertEqual(intervals[0].tier, "words")

    def test_aligns_onset_and_returns_timing_without_fake_score(self):
        commands = []

        def runner(command, timeout):
            commands.append((command, timeout))
            Path(command[6]).write_text(TEXTGRID, encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "", "")

        backend = KoreanMfaBackend(
            runner=runner,
            executable_lookup=lambda _: "/opt/mfa/bin/mfa",
        )
        with tempfile.TemporaryDirectory() as directory:
            wav_path = Path(directory) / "sample.wav"
            _empty_wav(wav_path)
            result = backend.analyze(wav_path, "각", "k", "onset")

        self.assertEqual(result[0]["alignedPhone"], "k")
        self.assertEqual(result[0]["startMs"], 100)
        self.assertEqual(result[0]["endMs"], 220)
        self.assertIsNone(result[0]["practiceScore"])
        self.assertFalse(result[0]["scoreAvailable"])
        self.assertIn("align_one", commands[0][0])
        self.assertIn("--temporary_directory", commands[0][0])

    def test_aligns_representative_coda_surface_phone(self):
        def runner(command, timeout):
            Path(command[6]).write_text(TEXTGRID, encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "", "")

        backend = KoreanMfaBackend(
            runner=runner,
            executable_lookup=lambda _: "mfa",
        )
        with tempfile.TemporaryDirectory() as directory:
            wav_path = Path(directory) / "sample.wav"
            _empty_wav(wav_path)
            result = backend.analyze(wav_path, "각", "kf", "coda")
        self.assertEqual(result[0]["alignedPhone"], "k̚")
        self.assertEqual(result[0]["startMs"], 520)

    def test_reports_unavailable_when_mfa_is_not_installed(self):
        backend = KoreanMfaBackend(executable_lookup=lambda _: None)
        with self.assertRaisesRegex(BackendUnavailable, "설치되지 않았습니다"):
            backend.analyze(Path("missing.wav"), "가", "k", "onset")


def _empty_wav(path: Path):
    with wave.open(str(path), "wb") as writer:
        writer.setnchannels(1)
        writer.setsampwidth(2)
        writer.setframerate(16000)
        writer.writeframes(b"\x00\x00" * 160)


if __name__ == "__main__":
    unittest.main()
