"""Durable, owner-bound sentence jobs. Local Whisper ASR, no diagnostic scores.

Run one application process; two async workers claim SQLite jobs atomically.
The model must be installed by the operator; requests never download a model.
"""
from __future__ import annotations
import asyncio
import contextlib
import difflib
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sqlite3
import struct
import threading
import time
import uuid
import wave

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile
from .security import MAX_AUDIO_BYTES, require_client

router = APIRouter(prefix='/v1/sentence-analysis')
VERSION = 'sentence-v1'
POLICY = 'sentence-local-v1'
TTL = 900
_model = None
_model_lock = threading.Lock()


def root() -> Path:
    path = Path(os.environ.get('SENTENCE_DATA_DIR', './sentence_jobs')).resolve()
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    return path


@contextlib.contextmanager
def database():
    db = sqlite3.connect(root() / 'jobs.sqlite', timeout=10)
    db.row_factory = sqlite3.Row
    db.execute('PRAGMA journal_mode=WAL')
    db.execute('PRAGMA secure_delete=ON')
    db.execute('''CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY, owner TEXT NOT NULL, idem TEXT NOT NULL,
        fingerprint TEXT NOT NULL, status TEXT NOT NULL, expires REAL NOT NULL,
        metadata TEXT NOT NULL, result TEXT, UNIQUE(owner,idem))''')
    try:
        with db:
            yield db
    finally:
        db.close()


def model_ready():
    path = os.environ.get('SENTENCE_WHISPER_MODEL', '')
    if not path or not Path(path).is_dir():
        return False
    try:
        import faster_whisper  # noqa: F401
        return (Path(path) / 'model.bin').is_file()
    except ImportError:
        return False


@router.get('/capabilities')
def capabilities(owner: str = Depends(require_client)):
    return dict(ready=model_ready(), languages=['ko-KR', 'en-US'], analysisVersion=VERSION,
                maxSeconds=120, maxBytes=MAX_AUDIO_BYTES, retentionSeconds=TTL,
                consentPolicyVersion=POLICY, processor='Local faster-whisper ASR; measured observations and fixed guidance',
                metrics=['duration', 'lowEnergyPauses', 'transcriptDifference'], scoreAvailable=False)


def sweep():
    with database() as db:
        rows = db.execute('SELECT id FROM jobs WHERE expires<=? OR status="cancelled"', (time.time(),)).fetchall()
        for row in rows:
            (root() / (row['id'] + '.wav')).unlink(missing_ok=True)
        db.execute('DELETE FROM jobs WHERE expires<=?', (time.time(),))
        referenced = {r['id'] for r in db.execute('SELECT id FROM jobs')}
        # Recover files left by a crash between writing audio and committing a job.
        for audio in root().glob('*.wav'):
            try:
                if audio.stem not in referenced and audio.stat().st_mtime < time.time() - TTL:
                    audio.unlink(missing_ok=True)
            except FileNotFoundError:
                pass  # Another worker may have removed it.


@router.post('/jobs', status_code=202)
async def create_job(audio: UploadFile = File(...), recordingId: str = Form(...),
                     assessmentId: str = Form(...), sentenceRevisionId: str = Form(...),
                     confirmedText: str = Form(...), language: str = Form(...),
                     audioSha256: str = Form(...), analysisVersion: str = Form(...),
                     consentPolicyVersion: str = Form(...),
                     idempotency_key: str = Header(..., alias='Idempotency-Key'),
                     owner: str = Depends(require_client)):
    if (language not in ('ko-KR', 'en-US') or not confirmedText.strip()
            or any(not 1 <= len(x) <= 100 for x in (recordingId, assessmentId, sentenceRevisionId, idempotency_key))):
        raise HTTPException(422, 'Invalid sentence metadata')
    if analysisVersion != VERSION or consentPolicyVersion != POLICY:
        raise HTTPException(409, 'Unsupported version or consent policy')
    payload = await audio.read(MAX_AUDIO_BYTES + 1)
    await audio.close()
    if not payload or len(payload) > MAX_AUDIO_BYTES:
        raise HTTPException(413, 'Invalid audio size')
    digest = hashlib.sha256(payload).hexdigest()
    if digest != audioSha256:
        raise HTTPException(422, 'Audio hash mismatch')
    metadata = dict(id=assessmentId, recordingId=recordingId, sentenceRevisionId=sentenceRevisionId,
                    confirmedText=confirmedText, language=language, audioSha256=digest, analysisVersion=VERSION)
    encoded = json.dumps(metadata, sort_keys=True)
    fingerprint = hashlib.sha256(encoded.encode()).hexdigest()
    sweep()
    with database() as db:
        db.execute('BEGIN IMMEDIATE')
        existing = db.execute('SELECT * FROM jobs WHERE owner=? AND idem=?', (owner, idempotency_key)).fetchone()
        if existing:
            if existing['fingerprint'] != fingerprint:
                raise HTTPException(409, 'Idempotency key was used for another recording')
            if existing['status'] in ('cancelled', 'failed', 'unavailable'):
                db.execute('DELETE FROM jobs WHERE id=?', (existing['id'],))
            else:
                return dict(jobId=existing['id'], status=existing['status'], expiresAt=existing['expires'])
        if not model_ready():
            raise HTTPException(503, 'Local speech model is not installed')
        active = db.execute('SELECT owner FROM jobs WHERE status IN ("queued","running")').fetchall()
        if len(active) >= 100 or sum(r['owner'] == owner for r in active) >= 4:
            raise HTTPException(429, 'Queue is full', headers={'Retry-After': '5'})
        job = str(uuid.uuid4())
        path = root() / (job + '.wav')
        path.write_bytes(payload)
        try:
            validate_wav(path)
            expires = time.time() + TTL
            db.execute('INSERT INTO jobs VALUES(?,?,?,?,?,?,?,?)',
                       (job, owner, idempotency_key, fingerprint, 'queued', expires, encoded, None))
        except Exception:
            path.unlink(missing_ok=True)
            raise
    return dict(jobId=job, status='queued', expiresAt=expires)


def validate_wav(path):
    try:
        with wave.open(str(path), 'rb') as reader:
            if (reader.getnchannels(), reader.getsampwidth(), reader.getframerate()) != (1, 2, 16000):
                raise ValueError('Only mono 16kHz PCM16 WAV is supported')
            frames = reader.getnframes()
            if not 1 <= frames <= 120 * 16000:
                raise ValueError('Recording must be within 120 seconds')
            raw = reader.readframes(frames)
            if len(raw) != frames * 2:
                raise ValueError('Truncated audio')
            return raw, frames / 16000
    except (wave.Error, EOFError, ValueError) as error:
        raise HTTPException(422, 'Invalid PCM WAV') from error


@router.get('/jobs/{job}')
def get_job(job: str, owner: str = Depends(require_client)):
    sweep()
    with database() as db:
        row = db.execute('SELECT * FROM jobs WHERE id=? AND owner=?', (job, owner)).fetchone()
    if row is None:
        raise HTTPException(404, 'Job not found or expired')
    meta = json.loads(row['metadata'])
    meta.pop('confirmedText', None)
    return {**meta, **(json.loads(row['result']) if row['result'] else {}), 'jobId': job, 'status': row['status']}


@router.delete('/jobs/{job}', status_code=204)
def delete_job(job: str, owner: str = Depends(require_client)):
    with database() as db:
        row = db.execute('SELECT id FROM jobs WHERE id=? AND owner=?', (job, owner)).fetchone()
        if row is None:
            return  # Idempotent and does not disclose another owner's jobs.
        db.execute('UPDATE jobs SET status="cancelled", result=NULL, metadata="{}" WHERE id=?', (job,))
    (root() / (job + '.wav')).unlink(missing_ok=True)


def transcribe(path: Path, language: str) -> str:
    global _model
    with _model_lock:
        if _model is None:
            from faster_whisper import WhisperModel
            _model = WhisperModel(os.environ['SENTENCE_WHISPER_MODEL'], device='cpu', compute_type='int8', local_files_only=True)
        # No target-text prompt: recognition must remain independent.
        import numpy as np
        raw, _ = validate_wav(path)
        samples = np.frombuffer(raw, dtype='<i2').astype(np.float32) / 32768.0
        segments, _ = _model.transcribe(samples, language='ko' if language == 'ko-KR' else 'en', beam_size=5, vad_filter=True)
        return ' '.join(segment.text.strip() for segment in segments).strip()


def feedback(path, meta):
    raw, duration = validate_wav(path)
    values = struct.unpack(f'<{len(raw)//2}h', raw)
    rms = math.sqrt(sum(v*v for v in values)/len(values))/32768
    clipping = sum(abs(v) >= 32700 for v in values)/len(values)
    reason = 'too_short' if duration < .25 else 'too_quiet' if rms < .008 else 'clipping' if clipping > .03 else None
    result = dict(score=None, modelVersion=Path(os.environ.get('SENTENCE_WHISPER_MODEL', 'unconfigured')).name,
                  promptVersion='fixed-guidance-v1', qualityFlags=[], observations=[], createdAt=time.time())
    if reason:
        return dict(result, status='unavailable', unavailableReason=reason, qualityFlags=[reason])
    text = transcribe(path, meta['language'])
    if not text:
        return dict(result, status='unavailable', unavailableReason='no_transcript')
    en = meta['language'] == 'en-US'
    # Low-energy gaps are signal observations, not respiratory events.
    quiet_frames = 0
    gaps = 0
    for start in range(0, len(values), 320):
        frame = values[start:start+320]
        quiet = math.sqrt(sum(v*v for v in frame)/len(frame))/32768 < .008
        if quiet:
            quiet_frames += 1
        else:
            if quiet_frames >= 15 and start > quiet_frames * 320:
                gaps += 1
            quiet_frames = 0
    def normalize(s):
        s = re.sub(r'[^\w\s]', '', s.lower())
        return s.split() if en else list(re.sub(r'\s', '', s))
    a, b = normalize(meta['confirmedText']), normalize(text)
    differences = [{'kind': tag, 'target': ''.join(a[i:j]) if not en else ' '.join(a[i:j]),
                    'recognized': ''.join(b[k:l]) if not en else ' '.join(b[k:l])}
                   for tag, i, j, k, l in difflib.SequenceMatcher(a=a, b=b, autojunk=False).get_opcodes() if tag != 'equal']
    return dict(result, status='completed', transcript=text, transcriptDifferences=differences,
                observations=[dict(kind='duration', value=round(duration, 2), unit='s'), dict(kind='lowEnergyPauses', value=gaps, unit='')],
                nextPracticeTip=('Choose one comfortable pause in the sentence for your next reading. Recognition differences may be ASR errors.' if en else
                                 '다음에는 문장에서 편하게 쉴 곳 한 군데를 정해 보세요. 인식된 글의 차이는 AI 인식 오류일 수도 있어요.'))


def run_one():
    sweep()
    with database() as db:
        db.execute('BEGIN IMMEDIATE')
        row = db.execute('SELECT * FROM jobs WHERE status="queued" ORDER BY expires LIMIT 1').fetchone()
        if row is None:
            return False
        db.execute('UPDATE jobs SET status="running" WHERE id=?', (row['id'],))
    path = root() / (row['id'] + '.wav')
    try:
        result = feedback(path, json.loads(row['metadata']))
    except Exception:
        result = dict(status='failed', score=None, unavailableReason='analysis_failed')
    finally:
        path.unlink(missing_ok=True)
    with database() as db:
        db.execute('UPDATE jobs SET status=?, result=? WHERE id=? AND status="running" AND expires>?',
                   (result['status'], json.dumps(result), row['id'], time.time()))
    return True


async def worker():
    while True:
        await asyncio.to_thread(run_one)
        await asyncio.sleep(.5)


@contextlib.asynccontextmanager
async def lifecycle():
    with database() as db:
        # Restart recovery. A missing audio file becomes failed, never fabricated.
        db.execute('UPDATE jobs SET status="queued" WHERE status="running"')
    tasks = [asyncio.create_task(worker()) for _ in range(2)]
    try:
        yield
    finally:
        for task in tasks:
            task.cancel()
        for task in tasks:
            with contextlib.suppress(asyncio.CancelledError):
                await task
