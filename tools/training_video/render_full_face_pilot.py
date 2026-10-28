"""Render full-face keyframes as a reproducible 24fps review animation.

Image creation/editing is performed with image_gen; this local animation stage
unpacks the keyframe atlas, stabilizes the camera, interpolates face motion and
encodes MP4. No separate drawn mouth is pasted into a static face.
"""
from pathlib import Path
import hashlib
import json
import subprocess

import cv2
import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'output/training_video/lip_03_a_to_i/v002'
OLD=ROOT/'output/training_video/lip_03_a_to_i/v001/exports/lip_03_a_to_i_v001_review.mp4'
W,H,FPS,N=1280,720,24,120
# Match the first pilot timing to make the comparison meaningful.
TIMELINE=[(0,'neutral'),(.55,'neutral'),(1.15,'a'),(1.8,'a'),
          (2.45,'i'),(3.25,'i'),(3.85,'a'),(4.10,'a'),(4.65,'neutral'),(5,'neutral')]


def writer(path,w,h):
    if path.exists():raise FileExistsError(path)
    return subprocess.Popen([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-n',
        '-f','rawvideo','-pix_fmt','rgb24','-s',f'{w}x{h}','-r',str(FPS),'-i','-',
        '-an','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(path)],stdin=subprocess.PIPE)


def stabilize(img,base):
    # Estimate only camera/head drift from the upper face and hair, excluding
    # the animated mouth, jaw and cheeks. Preserve lower-face deformation.
    gray0=cv2.cvtColor(base,cv2.COLOR_RGB2GRAY)
    gray1=cv2.cvtColor(img,cv2.COLOR_RGB2GRAY)
    mask=np.zeros((H,W),np.uint8);mask[95:330,430:835]=255
    p=cv2.goodFeaturesToTrack(gray0,250,.01,6,mask=mask)
    q,ok,_=cv2.calcOpticalFlowPyrLK(gray0,gray1,p,None,winSize=(31,31),maxLevel=4)
    use=ok.ravel()==1
    matrix,inliers=cv2.estimateAffinePartial2D(q[use],p[use],method=cv2.RANSAC,ransacReprojThreshold=2.5)
    if matrix is None:raise RuntimeError('Could not stabilize full-face pose')
    return cv2.warpAffine(img,matrix,(W,H),flags=cv2.INTER_CUBIC,borderMode=cv2.BORDER_REFLECT_101),matrix.tolist()


def prepare():
    atlas=Image.open(WORK/'source/full_face_atlas.png').convert('RGB')
    aw,ah=atlas.size
    assert ah%3==0
    raw={name:np.array(atlas.crop((0,k*ah//3,aw,(k+1)*ah//3)).resize((W,H),Image.Resampling.LANCZOS)) for k,name in enumerate(['neutral','a','i'])}
    neutral=raw['neutral'];poses={'neutral':neutral};matrices={}
    # Broad lower-face AND neck region, not an isolated mouth patch. Maintain
    # a fixed camera/background while allowing cheek/chin/jawline deformation.
    region=np.zeros((H,W),np.float32)
    cv2.ellipse(region,(650,470),(215,185),0,0,360,1,-1)
    region=cv2.GaussianBlur(region,(0,0),18)[...,None]
    for name in ['a','i']:
        aligned,matrices[name]=stabilize(raw[name],neutral)
        poses[name]=np.uint8(np.clip(neutral*(1-region)+aligned*region,0,255))
    for name,img in poses.items():Image.fromarray(img).save(WORK/f'source/pose_{name}.png')
    return poses,matrices


def motion(a,b):
    # Dense bidirectional optical flow; this is image-based animation, not a
    # validated anatomical rig. Work at half-size then restore vector scale.
    engine=cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    def small(img):return cv2.resize(cv2.cvtColor(img,cv2.COLOR_RGB2GRAY),(W//2,H//2))
    f=engine.calc(small(a),small(b),None)
    return cv2.resize(f,(W,H),interpolation=cv2.INTER_LINEAR)*2


def state(t):
    for (t0,a),(t1,b) in zip(TIMELINE,TIMELINE[1:]):
        if t0<=t<=t1:
            u=(t-t0)/(t1-t0);return a,b,u*u*(3-2*u)
    return 'neutral','neutral',0


def font(size):
    for path in ['/System/Library/Fonts/Supplemental/Arial.ttf','/System/Library/Fonts/Helvetica.ttc']:
        if Path(path).exists():return ImageFont.truetype(path,size)
    return ImageFont.load_default()


def compare(left,right):
    # Face closeups make the chin and cheeks readable on a normal chat screen.
    canvas=Image.new('RGB',(1440,800),(25,30,39))
    d=ImageDraw.Draw(canvas)
    d.text((28,19),'BEFORE  |  mouth overlay',font=font(30),fill=(235,235,235))
    d.text((748,19),'AFTER  |  full-face motion',font=font(30),fill=(160,228,211))
    box=(415,190,895,670)
    canvas.paste(Image.fromarray(left).crop(box).resize((720,720),Image.Resampling.LANCZOS),(0,80))
    canvas.paste(Image.fromarray(right).crop(box).resize((720,720),Image.Resampling.LANCZOS),(720,80))
    return canvas


def main():
    poses,matrices=prepare()
    flows={}
    for a,b in [('neutral','a'),('a','i')]:
        flows[a,b]=motion(poses[a],poses[b]);flows[b,a]=motion(poses[b],poses[a])
    yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
    dest=WORK/'exports/lip_03_a_to_i_v002_review.mp4'
    side=WORK/'exports/lip_03_a_to_i_v001_vs_v002.mp4'
    video=writer(dest,W,H);comparison=writer(side,1440,800)
    old=cv2.VideoCapture(str(OLD))
    snapshots={0:'neutral',20:'opening_transition',36:'a',50:'a_to_i_transition',66:'i',96:'a_return',119:'end'}
    tiles=[]
    try:
        for k in range(N):
            a,b,u=state(k/FPS)
            if a==b or u==0: frame=poses[a].copy()
            elif u==1:frame=poses[b].copy()
            else:
                f=flows[a,b];r=flows[b,a]
                wa=cv2.remap(poses[a],xx-u*f[...,0],yy-u*f[...,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_REFLECT_101)
                wb=cv2.remap(poses[b],xx-(1-u)*r[...,0],yy-(1-u)*r[...,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_REFLECT_101)
                frame=cv2.addWeighted(wa,1-u,wb,u,0)
            ok,previous=old.read()
            if not ok:raise RuntimeError('Old reference ended early')
            previous=cv2.cvtColor(previous,cv2.COLOR_BGR2RGB)
            pair=compare(previous,frame)
            video.stdin.write(frame.tobytes());comparison.stdin.write(pair.tobytes())
            if k in snapshots:
                Image.fromarray(frame).save(WORK/f'review/{snapshots[k]}.png')
                pair.save(WORK/f'review/compare_{snapshots[k]}.jpg',quality=93)
                if k in [0,36,66,119]:tiles.append(pair.resize((576,320)))
    finally:
        old.release();video.stdin.close();comparison.stdin.close()
    if video.wait()!=0 or comparison.wait()!=0:raise RuntimeError('Encoding failed')
    contact=Image.new('RGB',(1152,640))
    for k,p in enumerate(tiles):contact.paste(p,((k%2)*576,(k//2)*320))
    contact.save(WORK/'review/comparison_keyframes.jpg',quality=95)
    info={'status':'visual_review_draft','clinical_review':'pending','method':'image_gen full-face keyframes + local bidirectional optical flow',
          'timeline':TIMELINE,'stabilization':matrices,'fps':FPS,'frames':N,'seconds':N/FPS,
          'limitations':['Image-based interpolation can soften lips or teeth during transitions.',
                         'Character identity and motion naturalness require user review; no anatomical rig or clinical validation.'],
          'outputs':{p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in [dest,side]}}
    (WORK/'review/render.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
    print(dest);print(side)

if __name__=='__main__':main()
