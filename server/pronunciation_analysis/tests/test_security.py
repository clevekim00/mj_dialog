import os
import time
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient
from app import main, security
from app.acoustic import BackendUnavailable, TransformersCtcBackend
from test_api import FakeBackend, make_wav


class SecurityTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {"PRONUNCIATION_ENV": "production", "PRONUNCIATION_AUTH_SECRET": "test-only-" * 8})
        self.env.start()
        self.addCleanup(self.env.stop)
        main._jobs.clear()
        security._rates.clear()
        main.configure_backend(FakeBackend())
        self.client = TestClient(main.app, base_url="https://analysis.test", client=("203.0.113.1", 50000))

    def headers(self, owner="alice"):
        return {"Authorization": f"Bearer {security.issue_access_token(owner)}"}

    def create(self, headers=None):
        return self.client.post("/v1/analysis/jobs", headers=headers or self.headers(), files={"audio": ("sample.wav", make_wav(), "audio/wav")}, data={
            "text": "가", "language": "ko-KR", "target_phone": "k", "position": "onset", "content_version": "1",
        })

    def test_remote_development_is_denied_even_with_forwarded_header(self):
        with patch.dict(os.environ, {"PRONUNCIATION_ENV": "development"}):
            self.assertEqual(self.client.get("/v1/analysis/jobs/x").status_code, 403)
            local = TestClient(main.app, client=("127.0.0.1", 50000))
            self.assertEqual(local.get("/v1/analysis/jobs/x", headers={"x-forwarded-for": "127.0.0.1"}).status_code, 403)

    def test_production_requires_configured_secret_https_and_valid_token(self):
        self.assertEqual(self.client.get("/v1/analysis/jobs/x").status_code, 401)
        self.assertEqual(self.client.get("/v1/analysis/jobs/x", headers={"Authorization": "Bearer invalid"}).status_code, 401)
        http = TestClient(main.app, base_url="http://analysis.test")
        self.assertEqual(http.get("/v1/analysis/jobs/x", headers=self.headers()).status_code, 403)
        with patch.dict(os.environ, {"PRONUNCIATION_AUTH_SECRET": ""}):
            self.assertEqual(self.client.get("/v1/analysis/jobs/x").status_code, 503)

    def test_token_expires(self):
        with patch("app.security.time.time", return_value=time.time() - 1000):
            expired = self.headers()
        self.assertEqual(self.client.get("/v1/analysis/jobs/x", headers=expired).status_code, 401)

    def test_job_is_private_to_owner_and_deletable(self):
        response = self.create()
        self.assertEqual(response.status_code, 202, response.text)
        url = "/v1/analysis/jobs/" + response.json()["jobId"]
        self.assertEqual(self.client.get(url, headers=self.headers("bob")).status_code, 404)
        self.assertEqual(self.client.delete(url, headers=self.headers("bob")).status_code, 404)
        self.assertEqual(self.client.get(url, headers=self.headers()).status_code, 200)
        self.assertEqual(self.client.delete(url, headers=self.headers()).status_code, 204)
        self.assertEqual(self.client.get(url, headers=self.headers()).status_code, 404)

    def test_expired_result_is_unavailable(self):
        response = self.create()
        job_id = response.json()["jobId"]
        main._jobs[job_id].expires_at = time.monotonic() - 1
        self.assertEqual(self.client.get(f"/v1/analysis/jobs/{job_id}", headers=self.headers()).status_code, 404)
        self.assertNotIn(job_id, main._jobs)

    def test_request_body_limit_precedes_multipart_parse(self):
        with patch.object(security, "MAX_BODY_BYTES", 100):
            response = self.client.post("/v1/analysis/jobs", headers=self.headers(), content=b"x" * 101)
        self.assertEqual(response.status_code, 413)
        self.assertFalse(main._jobs)

    def test_upload_rate_limit(self):
        for _ in range(6):
            response = self.create()
            self.assertEqual(response.status_code, 202)
        self.assertEqual(self.create().status_code, 429)

    def test_cancel_during_backend_does_not_resurrect_result(self):
        class CancellingBackend(FakeBackend):
            def analyze(self, *args):
                main._jobs.clear()
                return super().analyze(*args)
        main.configure_backend(CancellingBackend())
        response = self.create()
        self.assertEqual(response.status_code, 202)
        self.assertFalse(main._jobs)

    def test_unvalidated_ctc_cannot_produce_a_score(self):
        backend = TransformersCtcBackend("any-model")
        self.assertFalse(backend.ready)
        with self.assertRaises(BackendUnavailable):
            backend.analyze(Path("nonexistent.wav"), "가", "k", "onset")


class UploadDeadlineTests(unittest.IsolatedAsyncioTestCase):
    async def test_slow_chunks_cannot_extend_total_upload_deadline(self):
        calls = []
        events = []
        async def application(scope, receive, send):
            self.fail("Timed-out uploads must not reach multipart parsing.")
        async def receive():
            calls.append(True)
            return {"type": "http.request", "body": b"x", "more_body": True}
        async def send(event):
            events.append(event)
        middleware = security.AnalysisBodyLimitMiddleware(application)
        scope = {"type": "http", "method": "POST", "path": "/v1/analysis/jobs", "headers": []}
        with patch.object(security, "require_client", return_value="alice"), patch.object(security, "_upload_clock", side_effect=[100, 100, 129, 131]):
            await middleware(scope, receive, send)
        self.assertEqual(len(calls), 2)
        self.assertEqual(events[0]["status"], 408)
