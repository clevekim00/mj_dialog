"""Local-only development and short-lived, subject-bound production access.

Only a trusted backend holds the signing secret. The mobile app receives a token,
never the secret. There is deliberately no public token-issuing endpoint here.
"""
from __future__ import annotations

import asyncio
import base64
import hashlib
import hmac
import ipaddress
import json
import os
import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import HTTPException, Request
from starlette.responses import JSONResponse

MAX_AUDIO_BYTES = 20 * 1024 * 1024
MAX_BODY_BYTES = MAX_AUDIO_BYTES + 64 * 1024
MAX_TOKEN_LIFETIME = 900
_upload_clock = time.monotonic
_rate_lock = Lock()
_rates: dict[str, deque[float]] = defaultdict(deque)


def production() -> bool:
    return os.getenv("PRONUNCIATION_ENV", "development") == "production"


def _secret() -> bytes:
    secret = os.getenv("PRONUNCIATION_AUTH_SECRET", "").encode()
    if len(secret) < 32:
        raise HTTPException(503, "Production authentication is not configured.")
    return secret


def _encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode()


def _decode(value: str) -> bytes:
    return base64.b64decode(value + "=" * (-len(value) % 4), altchars=b"-_", validate=True)


def issue_access_token(subject: str, lifetime_seconds: int = 300) -> str:
    """For trusted backend integration only; do not expose to unauthenticated callers."""
    if not subject or not 1 <= lifetime_seconds <= MAX_TOKEN_LIFETIME:
        raise ValueError("A subject and a lifetime of 1–900 seconds are required.")
    now = int(time.time())
    payload = _encode(json.dumps({
        "sub": subject, "iat": now, "exp": now + lifetime_seconds,
        "aud": "speech-rehab-analysis",
    }, separators=(",", ":")).encode())
    signature = _encode(hmac.new(_secret(), payload.encode(), hashlib.sha256).digest())
    return f"{payload}.{signature}"


def authenticate(request: Request) -> str:
    if not production():
        host = request.client.host if request.client else ""
        try:
            loopback = ipaddress.ip_address(host).is_loopback
        except ValueError:
            loopback = False
        # Forwarded headers must not turn a local development service into a
        # remotely accessible service through an accidentally added proxy.
        if not loopback or any(name in request.headers for name in (
            "forwarded", "x-forwarded-for", "x-forwarded-proto",
        )):
            raise HTTPException(403, "Development analysis is available on loopback only.")
        return "local-development"
    secret = _secret()
    if request.url.scheme != "https":
        raise HTTPException(403, "HTTPS is required.")
    authorization = request.headers.get("authorization", "")
    if not authorization.startswith("Bearer ") or len(authorization) > 4096:
        raise HTTPException(401, "A valid analysis access token is required.")
    try:
        payload, signature = authorization[7:].split(".")
        expected = hmac.new(secret, payload.encode(), hashlib.sha256).digest()
        if not hmac.compare_digest(expected, _decode(signature)):
            raise ValueError("signature")
        claims = json.loads(_decode(payload))
        now = time.time()
        exp, issued = claims["exp"], claims["iat"]
        if (type(exp) is not int or type(issued) is not int or
            not isinstance(claims["sub"], str) or not 1 <= len(claims["sub"]) <= 256 or
            claims["aud"] != "speech-rehab-analysis" or
            issued > now + 30 or exp <= now or not 0 < exp - issued <= MAX_TOKEN_LIFETIME):
            raise ValueError("claims")
        return claims["sub"]
    except (ValueError, KeyError, TypeError, UnicodeError):
        raise HTTPException(401, "The analysis access token is invalid or expired.") from None


def require_client(request: Request) -> str:
    cached = getattr(request.state, "analysis_owner", None)
    if cached is not None:
        return cached
    owner = authenticate(request)
    now = time.monotonic()
    # Separate the inexpensive poll budget from the costly upload budget.
    key = f"{owner}:{'upload' if request.method == 'POST' else 'read'}"
    limit = 6 if request.method == "POST" else 180
    with _rate_lock:
        for old_key in list(_rates):
            while _rates[old_key] and _rates[old_key][0] <= now - 60:
                _rates[old_key].popleft()
            if not _rates[old_key]:
                del _rates[old_key]
        entries = _rates[key]
        if len(entries) >= limit:
            raise HTTPException(429, "Please wait before submitting more requests.", headers={"Retry-After": "60"})
        entries.append(now)
    request.state.analysis_owner = owner
    return owner


class AnalysisBodyLimitMiddleware:
    """Bound bytes before multipart parsing (including chunked uploads)."""
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http" or not scope.get("path", "").startswith("/v1/analysis/"):
            return await self.app(scope, receive, send)
        request = Request(scope)
        try:
            # Authenticate before buffering potentially expensive multipart data.
            require_client(request)
        except HTTPException as error:
            return await JSONResponse({"detail": error.detail}, error.status_code)(scope, receive, send)
        if scope.get("method") != "POST":
            return await self.app(scope, receive, send)
        body = bytearray()
        deadline = _upload_clock() + 30
        while True:
            try:
                remaining = deadline - _upload_clock()
                if remaining <= 0:
                    raise asyncio.TimeoutError()
                event = await asyncio.wait_for(receive(), timeout=min(15, remaining))
            except asyncio.TimeoutError:
                return await JSONResponse({"detail": "Upload timed out."}, 408)(scope, receive, send)
            if event["type"] == "http.disconnect":
                return
            chunk = event.get("body", b"")
            if len(body) + len(chunk) > MAX_BODY_BYTES:
                return await JSONResponse({"detail": "Request body exceeds 20 MB audio limit."}, 413)(scope, receive, send)
            body.extend(chunk)
            if not event.get("more_body", False):
                break
        delivered = False
        async def bounded_receive():
            nonlocal delivered
            if delivered:
                return await receive()
            delivered = True
            return {"type": "http.request", "body": bytes(body), "more_body": False}
        await self.app(scope, bounded_receive, send)
