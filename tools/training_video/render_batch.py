"""Render remaining full-face/cutaway review clips from image_gen keyframe atlases.

No network, installation, app writes, anatomical approval or asset replacement.
Safe to resume: skips completed exports with matching local render manifests.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

import cv2
import imageio_ffmpeg
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parents[2]
BATCH=ROOT/'output/training_video/batch_2026-10-27'
W,H,FPS=1280,720,24
cv2.setNumThreads(2)


def align(img,base,face):
    g0=cv2.cvtColor(base,cv2.COLOR_RGB2GRAY);g1=cv2.cvtColor(img,cv2.COLOR_RGB2GRAY)
    mask=np.zeros((H,W),np.uint8)
    if face:mask[70:330,370:930]=255
    else:
        mask[:180]=255;mask[:, :85]=255;mask[:,-85:]=255
    p=cv2.goodFeaturesToTrack(g0,250,.01,8,mask=mask)
    if p is None:return img,{'applied':False,'reason':'insufficient rigid features'}
    q,ok,_=cv2.calcOpticalFlowPyrLK(g0,g1,p,None,winSize=(31,31),maxLevel=4)
    good=ok.ravel()==1
    if good.sum()<6:return img,{'applied':False,'reason':'insufficient tracks'}
    m,inliers=cv2.estimateAffinePartial2D(q[good],p[good],method=cv2.RANSAC,ransacReprojThreshold=2.5)
    if m is None:return img,{'applied':False,'reason':'no stable transform'}
    scale=float(np.hypot(m[0,0],m[0,1]));angle=float(np.degrees(np.arctan2(m[1,0],m[0,0])))
    if not(.94<scale<1.06 and abs(angle)<5 and abs(m[0,2])<65 and abs(m[1,2])<65):
        return img,{'applied':False,'reason':'reject large transform','matrix':m.tolist()}
    return cv2.warpAffine(img,m,(W,H),flags=cv2.INTER_CUBIC,borderMode=cv2.BORDER_REFLECT_101),{'applied':True,'matrix':m.tolist()}


def prepare(spec,work):
    atlas=Image.open(work/'source/atlas.png').convert('RGB');aw,ah=atlas.size
    cols=spec['layout']['columns'];rows=spec['layout']['rows']
    raw=[]
    for k in range(len(spec['poses'])):
        x,y=k%cols,k//cols
        tile=atlas.crop((round(x*aw/cols),round(y*ah/rows),round((x+1)*aw/cols),round((y+1)*ah/rows)))
        raw.append(np.array(ImageOps.fit(tile,(W,H),method=Image.Resampling.LANCZOS)))
    mode=spec.get('render_mode',spec['mode']);face=mode in ['face','face_profile']
    poses=[raw[0]];alignments=[]
    for img in raw[1:]:
        aligned,info=align(img,raw[0],face);alignments.append(info)
        if face:
            # Preserve the full lower face including cheeks, chin, jawline and
            # neck, with a feathered transition into the stabilized upper face.
            region=np.zeros((H,W),np.float32)
            center=(740,465) if mode=='face_profile' else (650,470)
            cv2.ellipse(region,center,(290,205) if mode=='face_profile' else (230,195),0,0,360,1,-1)
            region=cv2.GaussianBlur(region,(0,0),18)[...,None]
            aligned=np.uint8(np.clip(raw[0]*(1-region)+aligned*region,0,255))
        poses.append(aligned)
    for k,frame in enumerate(poses):Image.fromarray(frame).save(work/f'source/pose_{k:02d}.png')
    return poses,alignments


def flow(a,b):
    engine=cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    def small(img):return cv2.resize(cv2.cvtColor(img,cv2.COLOR_RGB2GRAY),(W//2,H//2))
    return cv2.resize(engine.calc(small(a),small(b),None),(W,H))*2


def state(t,timeline):
    for (ta,a),(tb,b) in zip(timeline,timeline[1:]):
        if ta<=t<=tb:
            u=(t-ta)/(tb-ta);return a,b,u*u*(3-2*u)
    return 0,0,0


def font(size):
    path='/System/Library/Fonts/Supplemental/Arial.ttf'
    return ImageFont.truetype(path,size) if Path(path).exists() else ImageFont.load_default()


def render(spec):
    work=ROOT/'output/training_video'/spec['id']/'v001'
    spec=json.loads((work/'source/generation.json').read_text())
    dest=work/'exports'/f"{spec['id']}_v001_review.mp4"
    manifest=work/'review/render.json'
    if dest.exists():
        if manifest.exists():print('SKIP',spec['id'],flush=True);return
        raise FileExistsError('Unverified existing export: '+str(dest))
    poses,alignments=prepare(spec,work)
    timeline=spec['timeline'];pairs=set()
    for (_,a),(_,b) in zip(timeline,timeline[1:]):
        if a!=b:pairs.update([(a,b),(b,a)])
    flows={key:flow(poses[key[0]],poses[key[1]]) for key in pairs}
    yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    args=[ffmpeg,'-hide_banner','-loglevel','error','-n','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}',
          '-r',str(FPS),'-i','-','-an','-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(dest)]
    proc=subprocess.Popen(args,stdin=subprocess.PIPE)
    count=spec['seconds']*FPS
    picks={0,count-1}
    for (ta,a),(tb,b) in zip(timeline,timeline[1:]):
        picks.add(min(count-1,round(tb*FPS)))
        if a!=b:picks.add(round((ta+tb)/2*FPS))
    thumbs=[]
    try:
        for k in range(count):
            a,b,u=state(k/FPS,timeline)
            if a==b or u<1e-6:frame=poses[a].copy()
            elif u>1-1e-6:frame=poses[b].copy()
            else:
                f,r=flows[a,b],flows[b,a]
                wa=cv2.remap(poses[a],xx-u*f[...,0],yy-u*f[...,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_REFLECT_101)
                wb=cv2.remap(poses[b],xx-(1-u)*r[...,0],yy-(1-u)*r[...,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_REFLECT_101)
                frame=cv2.addWeighted(wa,1-u,wb,u,0)
            proc.stdin.write(frame.tobytes())
            if k in picks:
                Image.fromarray(frame).save(work/f'review/frame_{k:03d}.jpg',quality=92)
                tile=Image.new('RGB',(320,204),(24,29,37));tile.paste(Image.fromarray(frame).resize((320,180)),(0,24))
                ImageDraw.Draw(tile).text((8,4),f'{k/FPS:.2f}s   pose {a} > {b}',font=font(14),fill='white');thumbs.append(tile)
    finally:proc.stdin.close()
    if proc.wait()!=0:raise RuntimeError('FFmpeg failed')
    grid=Image.new('RGB',(1280,204*((len(thumbs)+3)//4)),(24,29,37))
    for k,tile in enumerate(thumbs):grid.paste(tile,((k%4)*320,(k//4)*204))
    grid.save(work/'review/timeline.jpg',quality=93)
    # Poster shows first target pose, not a static neutral mouth.
    Image.fromarray(poses[1]).save(work/'review/poster.jpg',quality=93)
    info={'id':spec['id'],'title':spec['title'],'status':'rendered_review_draft','clinical_review':'pending',
          'safety':spec['safety'],'method':'image_gen whole-face/whole-oral keyframes + local bidirectional optical-flow animation',
          'render_mode':spec.get('render_mode',spec['mode']),'timeline':timeline,'alignments':alignments,
          'width':W,'height':H,'fps':FPS,'frames':count,'seconds':spec['seconds'],'audio':False,
          'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'file_bytes':dest.stat().st_size,
          'atlas_sha256':hashlib.sha256((work/'source/atlas.png').read_bytes()).hexdigest(),
          'limitations':['Interpolation can soften teeth or tongue borders. Human movement/contact review pending.','Muted visual articulation cannot establish actual click sound, airflow, pressure or therapeutic effects.']}
    if spec['id']=='lip_08_lip_cover':info['review_focus']='Lip overlap needs close review; three-quarter view improves visibility but does not confirm correct overlap.'
    (work/'review/render.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
    print('RENDERED',spec['id'],count,'frames',flush=True)


def main():
    p=argparse.ArgumentParser();p.add_argument('--id');args=p.parse_args()
    specs=json.loads((BATCH/'batch.json').read_text());errors=[]
    for spec in specs:
        if args.id and spec['id']!=args.id:continue
        try:render(spec)
        except Exception as exc:
            errors.append({'id':spec['id'],'error':str(exc)});print('FAILED',spec['id'],str(exc),flush=True)
    (BATCH/'render_errors.json').write_text(json.dumps(errors,indent=2)+'\n')
    if errors:sys.exit(1)
if __name__=='__main__':main()
