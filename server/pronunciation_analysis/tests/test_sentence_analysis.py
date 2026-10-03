import hashlib
import io
import math
import os
from pathlib import Path
import struct
import tempfile
import time
import unittest
from unittest.mock import patch
import wave
from fastapi.testclient import TestClient
from app.main import app
from app import sentence_analysis as sa, security

def wav(seconds=1, silent=False):
    output=io.BytesIO()
    with wave.open(output, 'wb') as w:
        w.setparams((1,2,16000,0,'NONE','not compressed'))
        samples=[0 if silent else int(6000*math.sin(i*.1)) for i in range(int(16000*seconds))]
        w.writeframes(struct.pack(f'<{len(samples)}h',*samples))
    return output.getvalue()

class SentenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.env=patch.dict(os.environ,{'SENTENCE_DATA_DIR':self.tmp.name,'PRONUNCIATION_ENV':'development'});self.env.start()
        self.ready=patch.object(sa,'model_ready',return_value=True);self.ready.start()
        self.asr=patch.object(sa,'transcribe',return_value='물을 주세요');self.asr.start()
        security._rates.clear();self.client=TestClient(app,client=('127.0.0.1',50001))
    def tearDown(self):
        self.client.close();self.asr.stop();self.ready.stop();self.env.stop();self.tmp.cleanup()
    def submit(self,payload=None,**changes):
        payload=payload if payload is not None else wav()
        data=dict(recordingId='rA',assessmentId='aA',sentenceRevisionId='s1',confirmedText='물을 주세요',language='ko-KR',audioSha256=hashlib.sha256(payload).hexdigest(),analysisVersion='sentence-v1',consentPolicyVersion='sentence-local-v1')
        data.update(changes)
        return self.client.post('/v1/sentence-analysis/jobs',files={'audio':('test.wav',payload,'audio/wav')},data=data,headers={'Idempotency-Key':data['assessmentId']})
    def test_persistent_job_and_bound_result(self):
        response=self.submit();self.assertEqual(response.status_code,202,response.text)
        job=response.json()['jobId'];self.assertTrue(sa.run_one())
        result=self.client.get('/v1/sentence-analysis/jobs/'+job).json()
        self.assertEqual(result['status'],'completed');self.assertEqual(result['recordingId'],'rA')
        self.assertIsNone(result['score']);self.assertEqual(result['transcript'],'물을 주세요')
        self.assertFalse((Path(self.tmp.name)/(job+'.wav')).exists());self.assertNotIn('confirmedText',result)
    def test_idempotency_and_conflict(self):
        first=self.submit().json()['jobId'];self.assertEqual(self.submit().json()['jobId'],first)
        self.assertEqual(self.submit(confirmedText='다른 문장').status_code,409)
    def test_hash_language_version_validation(self):
        self.assertEqual(self.submit(audioSha256='wrong').status_code,422)
        self.assertEqual(self.submit(language='xx').status_code,422)
        self.assertEqual(self.submit(analysisVersion='future').status_code,409)
    def test_silence_is_not_zero_score(self):
        job=self.submit(payload=wav(silent=True)).json()['jobId'];sa.run_one()
        r=self.client.get('/v1/sentence-analysis/jobs/'+job).json()
        self.assertEqual(r['status'],'unavailable');self.assertIsNone(r['score']);self.assertEqual(r['unavailableReason'],'too_quiet')
    def test_long_sentence_audio_not_old_twenty_second_limit(self):
        self.assertEqual(self.submit(payload=wav(21)).status_code,202)
    def test_long_text_is_accepted_and_blank_text_is_rejected(self):
        self.assertEqual(self.submit(confirmedText='긴 문장 ' * 1200).status_code,202)
        self.assertEqual(self.submit(confirmedText='  ').status_code,422)
    def test_invalid_audio(self):
        self.assertEqual(self.submit(payload=b'bad audio').status_code,422)
        self.assertEqual(list(Path(self.tmp.name).glob('*.wav')),[])
    def test_delete_is_idempotent_and_prevents_worker_resurrection(self):
        job=self.submit().json()['jobId']
        self.assertEqual(self.client.delete('/v1/sentence-analysis/jobs/'+job).status_code,204)
        self.assertEqual(self.client.delete('/v1/sentence-analysis/jobs/'+job).status_code,204)
        self.assertFalse(sa.run_one());self.assertFalse((Path(self.tmp.name)/(job+'.wav')).exists())
    def test_delete_during_analysis_cannot_restore_result(self):
        job=self.submit().json()['jobId']
        def transcribe(*args):sa.delete_job(job,'local-development');return '물을 주세요'
        with patch.object(sa,'transcribe',side_effect=transcribe):sa.run_one()
        self.assertEqual(self.client.get('/v1/sentence-analysis/jobs/'+job).json()['status'],'cancelled')
    def test_owner_isolation(self):
        job=self.submit().json()['jobId']
        with self.assertRaises(Exception):sa.get_job(job,'someone-else')
        sa.delete_job(job,'someone-else');self.assertEqual(sa.get_job(job,'local-development')['status'],'queued')
    def test_expiry_removes_audio_and_metadata(self):
        job=self.submit().json()['jobId']
        with sa.database() as db:db.execute('UPDATE jobs SET expires=? WHERE id=?',(time.time()-1,job))
        sa.sweep();self.assertEqual(self.client.get('/v1/sentence-analysis/jobs/'+job).status_code,404)
        self.assertFalse((Path(self.tmp.name)/(job+'.wav')).exists())
    def test_model_missing_reports_not_ready(self):
        with patch.object(sa,'model_ready',return_value=False):
            self.assertFalse(self.client.get('/v1/sentence-analysis/capabilities').json()['ready'])
            self.assertEqual(self.submit().status_code,503)
    def test_orphan_sweep_keeps_new_uploads_and_removes_old_crash_files(self):
        old = Path(self.tmp.name) / 'old-orphan.wav'
        fresh = Path(self.tmp.name) / 'new-upload.wav'
        old.write_bytes(b'old'); fresh.write_bytes(b'new')
        os.utime(old, (time.time()-sa.TTL-1, time.time()-sa.TTL-1))
        sa.sweep()
        self.assertFalse(old.exists()); self.assertTrue(fresh.exists())
