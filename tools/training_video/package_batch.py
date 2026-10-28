"""Decode/validate every exported clip and build a local review gallery/reel."""
import hashlib
import html
import json
from pathlib import Path
import subprocess

import cv2
import imageio_ffmpeg
import numpy as np
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2]
BATCH=ROOT/'output/training_video/batch_2026-10-27'
FONT='/System/Library/Fonts/AppleSDGothicNeo.ttc'
cv2.setNumThreads(2)


def validate(path,seconds):
    v=cv2.VideoCapture(str(path));fps=v.get(cv2.CAP_PROP_FPS);w=v.get(3);h=v.get(4);n=0;first=last=None
    while True:
        ok,f=v.read()
        if not ok:break
        if first is None:first=f.copy()
        last=f;n+=1
    v.release()
    r=subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-i',str(path),'-f','null','-'],capture_output=True,text=True)
    result={'width':w,'height':h,'fps':fps,'decoded_frames':n,'seconds':n/fps if fps else 0,
            'h264':'Video: h264' in r.stderr,'yuv420p':'yuv420p' in r.stderr,'audio_absent':'Audio:' not in r.stderr,
            'decode_exit_code':r.returncode,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'loop_mean_pixel_error':float(cv2.absdiff(first,last).mean()) if first is not None else None}
    assert w==1280 and h==720 and fps==24 and n==seconds*24,result
    assert all(result[x] for x in ['h264','yuv420p','audio_absent']) and r.returncode==0,result
    return result


def items():
    catalog=json.loads((ROOT/'docs/training-video-prompts/production/jobs.json').read_text())
    output=[]
    for job in catalog['jobs']:
        sample=job['id']=='lip_03_a_to_i';version='v002' if sample else 'v001'
        work=ROOT/'output/training_video'/job['id']/version
        video=work/'exports'/f"{job['id']}_{version}_review.mp4"
        poster=work/'review'/('i.png' if sample else 'poster.jpg')
        timeline=work/'review'/('comparison_keyframes.jpg' if sample else 'timeline.jpg')
        output.append({**job,'version':version,'video':str(video),'poster':str(poster),'timeline':str(timeline),
                       'sample':sample,'status':'rendered_review_draft','clinical_review':'pending'})
    return output,catalog


def gallery(data):
    def rel(p):return '../'+str(Path(p).relative_to(ROOT/'output/training_video'))
    cards=[]
    for j in data:
        safe={'general':'일반','caution':'주의 항목','clinicianOnly':'전문가 지도 항목'}[j['safety']]
        category='lip' if j['id'].startswith('lip_') else 'tongue'
        note='입술 겹침 방향 추가 검토' if j['id']=='lip_08_lip_cover' else '확인한 기준 샘플' if j['sample'] else '검토용 후보'
        cards.append(f'''<article data-category="{category}"><h2>{html.escape(j['title'])}</h2>
<p class="meta">{j['id']} · {j['seconds']}초 · {safe} · {note}</p>
<video controls loop muted playsinline preload="none" poster="{rel(j['poster'])}"><source src="{rel(j['video'])}" type="video/mp4"></video>
<p>{html.escape(j['instruction'])}</p><div class="actions"><a href="{rel(j['video'])}" download>MP4 저장</a><a href="{rel(j['timeline'])}">주요 자세·전환 보기</a></div>
<details><summary>검토 항목</summary><p>캐릭터 일치, 운동 구분, 접촉 위치, 턱·볼 연동, 치아·혀 경계, 반복 연결을 확인하세요. 임상 검토 대기입니다.</p></details></article>''')
    document='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>혀·입술 훈련 영상 모음</title>
<style>*{box-sizing:border-box}body{margin:0;background:#101820;color:#f0f4f6;font:16px/1.6 system-ui,sans-serif}header,main{max-width:1450px;margin:auto;padding:24px}h1{margin:0;font-size:30px}h2{font-size:20px;margin:0 0 4px}.lead,.meta{color:#b6c9d4}.meta{font-size:13px;overflow-wrap:anywhere}nav{display:flex;gap:12px;flex-wrap:wrap;margin:20px 0}button,select,a{font:inherit}button,select{background:#233544;color:white;border:1px solid #456074;border-radius:8px;padding:9px 14px}button[aria-pressed=true]{background:#316e66}a{color:#9fe5d6}#grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr));gap:20px}article{padding:18px;background:#1b2834;border:1px solid #314858;border-radius:12px}video{width:100%;aspect-ratio:16/9;background:black;border-radius:6px}.actions{display:flex;gap:24px}summary{cursor:pointer;color:#c5d6e1}details{margin-top:16px}article[hidden]{display:none}.reel{max-width:950px}</style>
<header><h1>혀·입술 훈련 영상 모음</h1><p class="lead">새 영상 19개 + 확인한 아–이 샘플 1개 · 720p · 24fps · 무음 · 2026-10-27</p><p>얼굴 전체 연동 또는 구강 단면으로 제작한 검토용 후보입니다. 입술 덮기는 겹침 방향 추가 검토가 필요합니다. 앱 연결·임상 승인은 포함하지 않습니다.</p>
<details class="reel"><summary>전체 이어보기 (104초)</summary><video controls preload="none" src="all_training_review.mp4"></video></details>
<nav aria-label="분류"><button data-filter="all" aria-pressed="true">전체 20</button><button data-filter="lip" aria-pressed="false">입술 10</button><button data-filter="tongue" aria-pressed="false">혀 10</button><label>재생 속도 <select id="speed"><option value="0.5">0.5배</option><option value="0.75">0.75배</option><option value="1" selected>1배</option></select></label><button id="pause">모두 일시정지</button></nav></header><main id="grid">'''+''.join(cards)+'''</main><script>
const vids=[...document.querySelectorAll('video')];for(const v of vids){v.addEventListener('play',()=>{for(const other of vids)if(other!==v)other.pause()})}
document.querySelector('#speed').addEventListener('change',e=>{for(const v of vids)v.playbackRate=Number(e.target.value)});
document.querySelector('#pause').onclick=()=>vids.forEach(v=>v.pause());
for(const b of document.querySelectorAll('[data-filter]'))b.onclick=()=>{for(const x of document.querySelectorAll('[data-filter]'))x.setAttribute('aria-pressed',String(x===b));for(const card of document.querySelectorAll('article')){card.hidden=b.dataset.filter!=='all'&&card.dataset.category!==b.dataset.filter;if(card.hidden)card.querySelector('video').pause()}};
</script></html>'''
    (BATCH/'index.html').write_text(document)


def boards(data):
    for start in range(0,len(data),5):
        group=data[start:start+5];board=Image.new('RGB',(1280,len(group)*220),(20,30,40))
        for row,j in enumerate(group):
            work=Path(j['video']).parents[1]
            if j['sample']:paths=[work/'review/neutral.png',work/'review/a.png',work/'review/i.png']
            else:
                source=work/'source';paths=sorted(source.glob('pose_*.png'))
                if len(paths)>3:paths=[paths[0],paths[len(paths)//2],paths[-1]]
            tile=Image.new('RGB',(1280,220),(20,30,40));draw=ImageDraw.Draw(tile)
            draw.text((12,4),j['title']+'  |  '+j['id'],font=ImageFont.truetype(FONT,20),fill='white')
            for k,p in enumerate(paths[:3]):tile.paste(Image.open(p).convert('RGB').resize((384,180)),(k*426,35))
            board.paste(tile,(0,row*220))
        board.save(BATCH/f'review_board_{start//5+1}.jpg',quality=93)


def reel(data):
    dest=BATCH/'all_training_review.mp4'
    if dest.exists():return
    proc=subprocess.Popen([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-n','-f','rawvideo','-pix_fmt','rgb24',
        '-s','1280x784','-r','24','-i','-','-an','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(dest)],stdin=subprocess.PIPE)
    try:
        for index,j in enumerate(data,1):
            header=Image.new('RGB',(1280,64),(20,30,40));d=ImageDraw.Draw(header)
            d.text((20,12),f"{index:02d}/20  {j['title']}    ({j['seconds']}초)",font=ImageFont.truetype(FONT,30),fill='white')
            v=cv2.VideoCapture(j['video'])
            while True:
                ok,f=v.read()
                if not ok:break
                frame=np.empty((784,1280,3),np.uint8);frame[:64]=np.array(header);frame[64:]=cv2.cvtColor(f,cv2.COLOR_BGR2RGB)
                proc.stdin.write(frame.tobytes())
            v.release()
            print('REEL',index,j['id'],flush=True)
    finally:proc.stdin.close()
    if proc.wait()!=0:raise RuntimeError('Reel encoding failed')


def main():
    data,catalog=items();validation={}
    for j in data:
        validation[j['id']]=validate(Path(j['video']),j['seconds'])
        print('VALIDATED',j['id'],flush=True)
    preserved=[]
    for asset in catalog['existing_assets']:
        digest=hashlib.sha256((ROOT/asset['path']).read_bytes()).hexdigest()
        assert digest==asset['sha256'],'Existing asset changed: '+asset['id']
        preserved.append(asset['id'])
    summary={'new_clips':19,'existing_sample':1,'total_review_clips':20,'seconds':sum(j['seconds'] for j in data),
             'all_technical_checks_passed':True,'clinical_review':'pending','existing_assets_preserved':preserved,
             'additional_review':['lip_08_lip_cover: verify actual upper/lower lip overlap',
                                  'oral contact and resistance exercises: professional verification required'],
             'clips':validation}
    (BATCH/'technical_validation.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    (BATCH/'manifest.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    gallery(data);boards(data);reel(data)
    lines=['# 혀·입술 훈련 영상 제작 결과', '',
           '2026-10-27. 새 영상 19개와 확인한 아–이 샘플 1개. 모두 검토용 후보이며 임상 검토 대기다.',
           '모든 개별 영상: 1280×720 / 24fps / H.264 / yuv420p / 오디오 없음. 전체 프레임 디코딩 검사 통과.',
           '입술 덮기는 3/4 측면으로 보완했으나 실제 겹침 방향은 추가 검토가 필요하다.',
           '혀 차기·내부 접촉은 단면으로, 저항 운동은 교육용 모형으로 표현했다.',
           '기존 6개 혀·입술 영상의 SHA-256 보존 확인. 앱 연결·푸시·배포는 하지 않았다.',
           '', '[모음 페이지](index.html) | [전체 이어보기](all_training_review.mp4) | [기술 검사](technical_validation.json)', '',
           '| 운동 | 길이 | 영상 | 주요 자세 |','|---|---:|---|---|']
    for j in data:
        def rel(p):return '../'+str(Path(p).relative_to(ROOT/'output/training_video'))
        lines.append(f"| {j['title']} | {j['seconds']}초 | [MP4]({rel(j['video'])}) | [이미지]({rel(j['timeline'])}) |")
    lines+=['','이미지 생성: built-in image_gen. 운동별 최종 프롬프트는 각 source/generation.json의 revised_prompt 또는 prompt, 생성 파일 대응은 generation_provenance.json에 보관했다.',
            '렌더 소스: tools/training_video/render_batch.py. 전체 얼굴/구강 자세를 이미지 기반으로 보간하므로 중간 전환의 치아·혀 경계가 흐려질 수 있다. 기술 검사 통과가 동작 정확성·임상 승인을 의미하지 않는다.']
    (BATCH/'README.md').write_text('\n'.join(lines)+'\n')
    print(json.dumps({k:v for k,v in summary.items() if k!='clips'},ensure_ascii=False),flush=True)
if __name__=='__main__':main()
