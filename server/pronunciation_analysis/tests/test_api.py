import io
import math
import struct
import unittest
import wave

try:
    from fastapi.testclient import TestClient
    from app.main import app, configure_backend
except (ImportError, RuntimeError):
    TestClient = None


class FakeBackend:
    model_version = "validated-test-model"
    ready = True

    def analyze(self, wav_path, text, target_phone, position):
        return [{
            "expected": target_phone,
            "observedCandidates": [{"phone": target_phone, "probability": 0.9}],
            "position": position,
            "startMs": 50,
            "endMs": 200,
            "gop": -0.1,
            "practiceScore": 88,
            "confidence": 0.9,
            "status": "accurate",
            "errorType": None,
        }]


class FakeMfaBackend:
    model_version = "mfa-korean-test"
    ready = True

    def analyze(self, wav_path, text, target_phone, position):
        return [{
            "expected": target_phone,
            "alignedPhone": "k",
            "observedCandidates": [],
            "position": position,
            "startMs": 40,
            "endMs": 160,
            "gop": None,
            "practiceScore": None,
            "scoreAvailable": False,
            "confidence": 0.0,
            "status": "aligned",
            "errorType": None,
        }]


def make_wav():
    output = io.BytesIO()
    rate = 16000
    samples = [int(math.sin(2 * math.pi * 220 * i / rate) * 6000) for i in range(rate)]
    with wave.open(output, "wb") as writer:
        writer.setnchannels(1)
        writer.setsampwidth(2)
        writer.setframerate(rate)
        writer.writeframes(struct.pack(f"<{len(samples)}h", *samples))
    return output.getvalue()


@unittest.skipIf(TestClient is None, "FastAPI test dependencies are unavailable")
class ApiTests(unittest.TestCase):
    def setUp(self):
        configure_backend(FakeBackend())
        self.client = TestClient(app)

    def test_create_and_read_analysis_job(self):
        response = self.client.post(
            "/v1/analysis/jobs",
            files={"audio": ("sample.wav", make_wav(), "audio/wav")},
            data={
                "text": "가", "target_phone": "k", "position": "onset",
                "content_version": "1.0.0", "baseline_score": "80",
            },
        )
        self.assertEqual(response.status_code, 202)
        result = self.client.get(f"/v1/analysis/jobs/{response.json()['jobId']}")
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()["status"], "completed")
        self.assertEqual(result.json()["overallPracticeScore"], 88)
        self.assertEqual(result.json()["baselineDelta"], 8)

    def test_mfa_alignment_returns_timing_without_score(self):
        configure_backend(FakeMfaBackend())
        response = self.client.post(
            "/v1/analysis/jobs",
            files={"audio": ("sample.wav", make_wav(), "audio/wav")},
            data={
                "text": "가", "target_phone": "k", "position": "onset",
                "content_version": "1.0.0",
            },
        )
        result = self.client.get(f"/v1/analysis/jobs/{response.json()['jobId']}").json()
        self.assertEqual(result["status"], "completed")
        self.assertIsNone(result["overallPracticeScore"])
        self.assertEqual(result["phonemes"][0]["status"], "aligned")
        self.assertIn("MFA 음소 정렬", result["message"])


if __name__ == "__main__":
    unittest.main()
