"""Deterministic, local 2D animation pilot. No network or app asset writes.

Requires Pillow, numpy, imageio-ffmpeg. Frame time is index / fps.
A generated character plate supplies the static scene; editable Bezier paths
supply lips, mouth cavity, teeth and tongue. This is a review draft.
"""
import hashlib
import json
from pathlib import Path
import subprocess

import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'output/training_video/lip_03_a_to_i/v001'
W, H, FPS, COUNT = 1280, 720, 24, 120
S = 4
# t, half-width, half-height, upper-teeth visibility
KEYS = [(0, 27, 1.5, 0), (.55, 27, 1.5, 0),
        (1.15, 33, 24, .14), (1.8, 33, 24, .14),
        (2.45, 48, 8, .70), (3.25, 48, 8, .70),
        (3.85, 33, 24, .14), (4.10, 33, 24, .14),
        (4.65, 27, 1.5, 0), (5, 27, 1.5, 0)]


def pose(t):
    for a, b in zip(KEYS, KEYS[1:]):
        if a[0] <= t <= b[0]:
            u = (t-a[0])/(b[0]-a[0])
            u = u*u*(3-2*u)
            return tuple(x+(y-x)*u for x,y in zip(a[1:],b[1:]))
    return KEYS[-1][1:]


def bezier(p0,p1,p2,p3):
    return [tuple((1-t)**3*p0[k]+3*(1-t)**2*t*p1[k]+3*(1-t)*t*t*p2[k]+t**3*p3[k] for k in (0,1)) for t in np.linspace(0,1,30)]


def mouth(t):
    w,h,teeth=pose(t)
    cx,cy=654.5,422
    # Local canvas bounds leave room for lips and a soft lower-lip shadow.
    ox,oy=580,375
    layer=Image.new('RGBA',(150*S,105*S))
    d=ImageDraw.Draw(layer)
    def points(pts): return [((x+cx-ox)*S,(y+cy-oy)*S) for x,y in pts]
    def poly(pts,fill): d.polygon(points(pts),fill=fill)
    # Closed bezier outlines: a cupid's bow above, curved lower lip below.
    outer=(bezier((-w-3,0),(-w*.7,-h-8),(-w*.28,-h-8),(0,-h-3))+
           bezier((0,-h-3),(w*.28,-h-8),(w*.7,-h-8),(w+3,0))+
           bezier((w+3,0),(w*.72,h+13),(-w*.72,h+13),(-w-3,0)))
    poly(outer,(146,76,69,255))
    innerlip=[(x*.97,y*.91) for x,y in outer]
    poly(innerlip,(207,123,112,255))
    # Opening is flatter and wider for /i/, taller for /a/.
    upper=bezier((-w,0),(-w*.62,-h*.95),(w*.62,-h*.95),(w,0))
    lower=bezier((w,0),(w*.70,h*1.25),(-w*.70,h*1.25),(-w,0))
    cavity=upper+lower
    mask=Image.new('L',layer.size)
    ImageDraw.Draw(mask).polygon(points(cavity),fill=255)
    content=Image.new('RGBA',layer.size,(78,32,37,255))
    cd=ImageDraw.Draw(content)
    def rect(box): return tuple(((v+cx-ox) if i%2==0 else (v+cy-oy))*S for i,v in enumerate(box))
    if h>3:
        # Upper tooth band clipped to cavity; tongue remains inside lower opening.
        cd.ellipse(rect((-w*.85,-h*1.3,w*.85,-h*.32+teeth*h)),fill=(243,231,214,255))
        cd.ellipse(rect((-w*.65,h*.35,w*.65,h*1.5)),fill=(182,91,94,255))
    layer.alpha_composite(Image.composite(content,Image.new('RGBA',layer.size),mask))
    # Subtle lower-lip highlight rather than a hard white outline.
    if h>3:
        curve=bezier((-w*.35,h+4),(-w*.1,h+6),(w*.2,h+6),(w*.39,h+3))
        d=ImageDraw.Draw(layer)
        d.line(points(curve),fill=(236,163,146,210),width=2*S)
    return layer.resize((150,105),Image.Resampling.LANCZOS),(ox,oy)


def main():
    plate=Image.open(WORK/'source/character_plate.png').convert('RGB').resize((W,H),Image.Resampling.LANCZOS)
    dest=WORK/'exports/lip_03_a_to_i_v001_review.mp4'
    if dest.exists(): raise FileExistsError(dest)
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    args=[ffmpeg,'-hide_banner','-loglevel','error','-n','-f','rawvideo','-vcodec','rawvideo','-pix_fmt','rgb24',
          '-s',f'{W}x{H}','-r',str(FPS),'-i','-','-an','-c:v','libx264','-preset','medium','-crf','18',
          '-pix_fmt','yuv420p','-movflags','+faststart',str(dest)]
    samples={0:'neutral',36:'a',66:'i',96:'a_return',119:'end'}
    thumbs=[]
    proc=subprocess.Popen(args,stdin=subprocess.PIPE)
    try:
        for i in range(COUNT):
            frame=plate.copy()
            layer,pos=mouth(i/FPS)
            frame.paste(layer,pos,layer)
            if i in samples:
                frame.save(WORK/f'review/{samples[i]}.png')
                thumbs.append(frame.resize((384,216)))
            proc.stdin.write(frame.tobytes())
    finally:
        proc.stdin.close()
    if proc.wait()!=0: raise RuntimeError('FFmpeg failed')
    contact=Image.new('RGB',(384*len(thumbs),216))
    for i,frame in enumerate(thumbs):contact.paste(frame,(384*i,0))
    contact.save(WORK/'review/keyframes.jpg',quality=93)
    metadata={'id':'lip_03_a_to_i','status':'review_draft','clinical_review':'pending',
              'width':W,'height':H,'fps':FPS,'frames':COUNT,'seconds':COUNT/FPS,'audio':False,
              'method':'Generated static character plate + deterministic local Bezier mouth animation',
              'limitations':['Lip geometry is an illustrative draft, not a validated physiological model.',
                              'Head and jaw remain fixed; clinical and character consistency review pending.'],
              'keyframes':KEYS,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
              'versions':{'ffmpeg':imageio_ffmpeg.get_ffmpeg_version()},
              'output':str(dest.relative_to(ROOT))}
    (WORK/'review/render.json').write_text(json.dumps(metadata,indent=2,ensure_ascii=False)+'\n')
    print(dest)

if __name__=='__main__':main()
