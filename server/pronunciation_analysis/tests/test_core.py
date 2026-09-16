import math
import struct
import tempfile
import unittest
import wave
from pathlib import Path

from app.alignment import ctc_viterbi
from app.audio import inspect_signal
from app.g2p import decompose_hangul, target_occurrences


class CoreTests(unittest.TestCase):
    def test_hangul_onset_and_surface_coda(self):
        decomposed = decompose_hangul("각옷")
        self.assertEqual(decomposed[0]["onset"], "ㄱ")
        self.assertEqual(decomposed[0]["coda"], "k_f")
        self.assertEqual(decomposed[1]["coda"], "t_f")
        self.assertEqual(target_occurrences("옷과 꽃", "tf", "coda"), 2)

    def test_signal_quality_accepts_clear_wav(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "sample.wav"
            rate = 16000
            samples = [int(math.sin(2 * math.pi * 220 * i / rate) * 6000) for i in range(rate)]
            with wave.open(str(output), "wb") as writer:
                writer.setnchannels(1)
                writer.setsampwidth(2)
                writer.setframerate(rate)
                writer.writeframes(struct.pack(f"<{len(samples)}h", *samples))
            quality = inspect_signal(output)
            self.assertTrue(quality.accepted)
            self.assertEqual(quality.duration_ms, 1000)

    def test_ctc_alignment_returns_token_spans(self):
        low = -9.0
        probabilities = [
            [0.0, low, low],
            [low, 0.0, low],
            [0.0, low, low],
            [low, low, 0.0],
            [0.0, low, low],
        ]
        self.assertEqual(ctc_viterbi(probabilities, [1, 2]), [(1, 2), (3, 4)])


if __name__ == "__main__":
    unittest.main()
