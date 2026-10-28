"""Build local production cards from the current catalog; never alter app assets."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/training-video-prompts/production'
PILOT = ['lip_03_a_to_i', 'lip_04_u_to_a', 'lip_05_kiss',
         'lip_06_spread_pucker', 'tongue_02_touch_lips']
FACE_POLICY = ('중립·목표·복귀의 얼굴 전체 자세를 먼저 설계한다. 운동에 필요한 '
               '턱·볼·입꼬리·턱선을 함께 연동하고 선화·명암·질감을 맞춘다. '
               '정지 얼굴 위에 입 도형만 교체하는 방식은 사용하지 않는다. '
               '혀 독립 운동의 턱 안정은 해당 운동 의도를 따른다.')


def main():
    catalog = (ROOT / 'lib/features/guided_training/data/guided_training_catalog.dart').read_text()
    spec = (ROOT / 'docs/training-video-prompts/training-video-production-plan.md').read_text()
    prompts = {}
    for line in spec.splitlines():
        if line.startswith('| `') and '.mp4`' in line:
            cells = [c.strip() for c in line.strip('|').split('|')]
            if len(cells) >= 4:
                prompts[cells[0].strip('`').removesuffix('.mp4')] = cells[2]
    jobs, existing = [], []
    for block in re.findall(r'  _exercise\(\n(.*?)\n  \),', catalog, re.S):
        def field(name, default=''):
            match = re.search(rf"\b{name}: '([^']*)'", block)
            return match.group(1) if match else default
        ident = field('id')
        if not ident.startswith(('tongue_', 'lip_')):
            continue
        video = field('video')
        target = ROOT / 'assets/videos/training' / (ident + '.mp4')
        if video and (ROOT / video).is_file():
            existing.append({'id': ident, 'path': video,
                             'sha256': hashlib.sha256((ROOT / video).read_bytes()).hexdigest()})
            continue
        seconds = re.search(r'\bseconds: (\d+)', block)
        safety = re.search(r'safety: GuidedTrainingSafetyTier\.(\w+)', block)
        visual = re.search(r'visual: GuidedTrainingVisualMode\.(\w+)', block)
        candidates = sorted((ROOT / 'output/training_video' / ident).glob('v*/review/render.json'))
        candidate = None
        if candidates:
            work = candidates[-1].parent.parent
            exports = sorted((work / 'exports').glob(f'{ident}_{work.name}_review.mp4'))
            if exports:
                candidate = str(exports[0].relative_to(ROOT))
        jobs.append({'id': ident, 'title': field('title'), 'instruction': field('instruction'),
                     'caption': field('caption'), 'seconds': int(seconds.group(1)) if seconds else 5,
                     'safety': safety.group(1) if safety else 'general',
                     'visual': visual.group(1) if visual else None,
                     'pilot_order': PILOT.index(ident)+1 if ident in PILOT else None,
                     'motion_prompt': prompts.get(ident),
                     'face_animation_policy': FACE_POLICY,
                     'destination_after_review': str(target.relative_to(ROOT)),
                     'unlinked_file_exists': target.exists(),
                     'status': 'rendered_review_draft' if candidate else 'planned',
                     'candidate_video': candidate,
                     'clinical_review': 'pending'})
    jobs.sort(key=lambda j: (j['pilot_order'] or 99, j['id']))
    result = {'scope': 'Missing tongue and lip exercises only',
              'face_animation_policy': FACE_POLICY,
              'render': {'width': 1280, 'height': 720, 'fps': 24,
                         'codec': 'h264', 'pixel_format': 'yuv420p', 'audio': False},
              'reference_warning': 'Tutor PNG contains subtitles and playback UI. Prepare clean layered art before rendering. Existing MP4 frames are reference only.',
              'existing_assets': existing, 'jobs': jobs}
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'jobs.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    lines = ['# 혀·입술 누락 영상 제작 카드', '',
             '카탈로그와 로컬 렌더 결과에서 생성한 작업 카드다. 임상 승인 결과가 아니다.',
             '제작 결과: output/training_video/batch_2026-10-27/README.md 및 index.html 참고.', '',
             '공통 출력: 1280×720, 24fps, H.264, yuv420p, 오디오 트랙 없음.',
             '기준 PNG에는 자막·플레이어 UI가 있다. 기존 MP4를 참고해 얼굴 전체의 연동 자세를 준비한다.',
             FACE_POLICY,
             'lip_03_a_to_i/v001은 입만 교체해 어색하다는 피드백을 받은 초안으로, 후속 제작 템플릿으로 사용하지 않는다.',
             '기존 6개 혀·입술 MP4는 보존하고, 검토 후보를 앱 assets에 연결하지 않는다.', '',
             '먼저 파일럿 1–5의 정지 자세·캐릭터 일치·접촉 위치를 확인한 뒤 프레임을 렌더링한다.', '']
    for j in jobs:
        lines += [f"## {j['id']} — {j['title']}", '',
                  f"- 제작 순서: 파일럿 {j['pilot_order']}" if j['pilot_order'] else '- 제작 순서: 파일럿 검토 후',
                  f"- 지시문: {j['instruction']}",
                  f"- 길이: {j['seconds']}초 / {j['seconds']*24}프레임",
                  f"- 시각 모드: {j['visual']} / 안전 등급: {j['safety']}",
                  f"- 동작 초안: {j['motion_prompt']}",
                  f'- 얼굴 연동 기준: {FACE_POLICY}',
                  '- 검토: 중립 → 목표 자세/교대 → 유지 → 중립. 순서·접촉점·유지 시간·가림을 검토한다.',
                  ('- 상태: 검토용 MP4 렌더 완료 / 임상 검토 대기' if j['candidate_video']
                   else '- 상태: 소스 미제작 / 렌더 미실시 / 임상 검토 대기'),
                  f"- 검토용 영상: {j['candidate_video'] or '미제작'}", '']
    (OUT / 'cards.md').write_text('\n'.join(lines))
    print(f'Prepared {len(jobs)} missing exercises; preserved {len(existing)} linked assets.')
    assert len(jobs) == 20, 'Catalog changed: recheck scope'
    assert all(j['motion_prompt'] for j in jobs), 'Missing motion prompt'

if __name__ == '__main__':
    main()
