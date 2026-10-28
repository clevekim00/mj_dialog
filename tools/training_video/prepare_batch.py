"""Prepare per-exercise image-generation and animation inputs for the accepted style."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'output/training_video/batch_2026-10-27'
REF=ROOT/'output/training_video/lip_03_a_to_i/v002/source/pose_neutral.png'
D={
'lip_04_u_to_a':('face',['relaxed neutral closed lips','Korean U vowel: rounded protruded lips, small central opening, cheeks and chin follow the pucker naturally','Korean A vowel: comfortably open mouth vertically, lowered jaw and chin, gently elongated lower cheeks'],[0,1,2,0]),
'lip_05_kiss':('face',['relaxed neutral closed lips','gentle closed kiss pucker, both lips project forward, mouth corners draw inward, cheeks and chin adapt naturally'],[0,1,0,1,0]),
'lip_06_spread_pucker':('face',['relaxed neutral closed lips','lips stretched broadly sideways with relaxed corners, subtle cheeks lift, slight tooth visibility','gentle rounded kiss pucker with lips projecting forward and corners drawn inward; cheeks follow naturally'],[0,1,2,0]),
'lip_01_tuck_extend':('face',['relaxed neutral closed lips','BOTH lips rolled inward over the teeth; red lip surfaces are tucked away, a soft compressed closed seam visible; cheeks and chin adapt naturally','both lips released and extended forward in a gentle pucker; natural lip texture and cheeks'],[0,1,2,0]),
'lip_08_lip_cover':('face',['relaxed neutral closed lips','LOWER lip lifted over and visibly covering the upper lip; lower red lip is on top, no tongue visible, subtle chin elevation','UPPER lip lowered over and visibly covering the lower lip; upper red lip is on top, subtle relaxed chin lowering, no tongue visible'],[0,1,0,2,0]),
'lip_09_one_side_grimace':('face',['relaxed neutral closed lips','pull the VIEWER-LEFT mouth corner sideways, lips shifted to viewer-left, left cheek retracts subtly; head and gaze remain front-facing','pull the VIEWER-RIGHT mouth corner sideways, lips shifted to viewer-right, right cheek retracts subtly; head and gaze remain front-facing'],[0,1,0,2,0]),
'lip_10_ppa_release':('face',['relaxed neutral closed lips','both lips gently and firmly sealed, slightly compressed, cheeks relaxed, no puffing or strain','lips just released into an open A vowel after the bilabial closure, jaw lowers comfortably, soft cheeks and chin follow'],[0,1,2,1,2,0]),
'lip_11_fish_mouth':('face',['relaxed neutral closed lips','gentle fish mouth: BOTH cheeks drawn slightly inward with subtle visible hollows, rounded closed lips protruded forward; comfortable relaxed eyes'],[0,1,0]),
'lip_12_sad_smile':('face',['relaxed neutral closed lips','gentle sad mouth with both lip corners downturned, lower cheeks and chin follow; no tears, no extreme emotion','broad relaxed smile with mouth corners raised and cheeks gently lifted, subtle upper teeth, natural not strained'],[0,1,2,0]),
 'tongue_02_touch_lips':('face',['lips comfortably parted, single tongue resting inside mouth, neutral jaw','single tongue extends upward and the TIP visibly TOUCHES the OUTSIDE upper lip at the center; tongue curves up, upper lip contact clear, jaw and head remain stable','single tongue extends downward and the TIP visibly TOUCHES the OUTSIDE lower lip at the center; tongue curves down, lower lip contact clear, jaw and head remain stable'],[0,1,0,2,0]),
 'tongue_09_monkey_lips':('face',['relaxed softly CLOSED lips, tongue NOT visible','tongue stays INSIDE closed mouth and gently pushes the UPPER lip outward from behind; upper lip bulges forward, no external tongue; cheeks and chin adapt','tongue stays INSIDE closed mouth and gently pushes the LOWER lip outward from behind; lower lip bulges forward, no external tongue; cheeks and chin adapt'],[0,1,0,2,0]),
 'tongue_14_tongue_click':('face',['lips slightly parted with tongue resting, comfortable jaw','mouth slightly open, SINGLE tongue tip raised to touch the ridge just behind upper front teeth, contact visible; sides of tongue not duplicated','tongue released from ridge and lowered inside mouth, lips still slightly parted, stable relaxed jaw'],[0,1,2,1,2,1,2,0]),
 'tongue_05_soft_palate_click':('sagittal',['tongue resting low inside the mouth, hard palate and soft palate clearly distinct','POSTERIOR tongue dorsum raised toward and gently contacting the SOFT PALATE behind the hard palate; tongue TIP stays forward and relatively low, no tip-to-front-palate substitute','posterior tongue relaxed and lowered again, no contact, calm comfortable open airway schematic'],[0,1,2,0]),
 'tongue_06_palate_sweep':('sagittal',['tongue resting low inside mouth','tongue TIP contacting alveolar ridge directly behind UPPER FRONT TEETH, broad tongue body curves naturally','tongue TIP curled and moved BACKWARD along the roof to the middle HARD PALATE; visible contact target behind previous pose, tongue body follows without penetrating palate'],[0,1,2,0]),
 'tongue_07_hard_palate_hold':('sagittal',['comfortable open jaw, single tongue resting low','broad upper surface of tongue gently contacting the HARD PALATE along its anterior-to-middle roof; jaw remains comfortably open, no contact with soft palate required'],[0,1,0]),
 'tongue_08_resistance':('resistance',['mouth comfortably open with single tongue slightly protruded; a gloved clinician hand holds a flat tongue depressor OUTSIDE lips, ready without contact','tongue gently presses FORWARD against the flat tongue depressor held by a gloved clinician OUTSIDE lips; no deep insertion, no strain','tongue gently presses toward VIEWER-LEFT against a flat tongue depressor held at its left edge by clinician hand OUTSIDE lips; head and jaw stable','tongue gently presses toward VIEWER-RIGHT against a flat tongue depressor held at its right edge by clinician hand OUTSIDE lips; head and jaw stable'],[0,1,0,2,0,3,0]),
 'tongue_10_molars':('frontal_cutaway',['single tongue resting centrally low, both UPPER and LOWER tooth arches and posterior molars visible','single tongue curves toward VIEWER-LEFT and tongue TIP touches inner surface of LEFT POSTERIOR MOLAR area; keep both arches visible and jaw fixed','single tongue curves toward VIEWER-RIGHT and tongue TIP touches inner surface of RIGHT POSTERIOR MOLAR area; keep both arches visible and jaw fixed'],[0,1,0,2,0]),
 'tongue_11_trace_teeth':('frontal_cutaway',['single tongue resting centrally low, upper and lower dental arches visible','tongue TIP touching inside of UPPER VIEWER-LEFT tooth row near molars','tongue TIP touching inside of UPPER FRONT teeth at center','tongue TIP touching inside of UPPER VIEWER-RIGHT tooth row near molars','tongue TIP touching inside of LOWER VIEWER-RIGHT tooth row near molars','tongue TIP touching inside of LOWER FRONT teeth at center','tongue TIP touching inside of LOWER VIEWER-LEFT tooth row near molars'],[0,1,2,3,4,5,6,0]),
 'tongue_13_clock_click':('sagittal',['tongue tip resting low behind lower front teeth','tongue TIP gently touching alveolar ridge just behind UPPER FRONT TEETH; anterior tongue raised while posterior tongue relaxed','tongue tip just RELEASED from upper ridge and lowered, contact clearly absent'],[0,1,2,1,2,0]),
}
FACE='Use the attached adult Korean female illustrated therapist as the exact character and style reference. Same face, dark ponytail, white uniform, warm clinic background. Same front-facing head-and-shoulders framing in every tile, mouth and whole jaw clearly visible, same scale and head position, calm gaze. Render each WHOLE face as coherent artwork, including coordinated lip corners, cheeks, jaw, chin and natural linework, texture and shadows. No separately pasted vector mouth. Head/camera stable; jaw moves naturally for lip shapes, remains stable for independent tongue exercises.'
CUT='Create a clean non-graphic clinical educational 2D illustration matching the warm cel-shaded palette of the reference. Neutral pale warm background, large isolated mouth anatomy, no extra therapist portrait or inset. Keep the exact SAME oral geometry, camera and scale across all tiles. Distinguish ivory teeth, pink gingiva and hard/soft palate, single pink muscular tongue. Clear natural contact surfaces, no intersection through teeth or roof. No gore, saliva or surgery. This is an illustrative draft for professional review.'

def main():
 jobs=json.loads((ROOT/'docs/training-video-prompts/production/jobs.json').read_text())['jobs']
 specs=[]
 for j in jobs:
  if j['id']=='lip_03_a_to_i':continue
  mode,poses,seq=D[j['id']];count=len(poses)
  if count<=3:cols,rows=1,count
  elif count==4:cols,rows=2,2
  else:cols,rows=3,3
  layout=f'EXACTLY {cols} columns and {rows} rows of equal rectangular 16:9 tiles, edge-to-edge, NO gaps, NO borders, NO labels. Overall aspect ratio {16*cols}:{9*rows}. Read tiles row-major left-to-right then top-to-bottom. Each tile contains ONE complete scene, not multiple views.'
  if mode in ['face','resistance']:base=FACE
  else:base=CUT
  if mode=='sagittal':base+=' Stable SIDE SAGITTAL mouth cutaway facing VIEWER-LEFT: lips/front teeth at left, throat at right; upper/lower jaw, alveolar ridge, hard palate and posterior soft palate visible. Do not show a frontal view.'
  if mode=='frontal_cutaway':base+=' Stable FRONT/SLIGHTLY TOP-DOWN transparent-cheek oral cutaway that clearly reveals BOTH left and right posterior molars and upper/lower dental arches at once; use this same view in every tile. A sagittal profile cannot show both molar sides, so do not use it.'
  if mode=='resistance':base+=' Clinician-supervised illustrative demonstration. Include only one gloved clinician hand and its flat tongue depressor, outside the lips, never deep insertion, never a self-use gesture. Keep face and working area unobstructed.'
  actions=poses+[poses[0]]*(cols*rows-count)
  prompt='Use case: scientific-educational. Animation keyframe atlas for '+j['id']+'. '+layout+' '+base+' Tile poses: '+' '.join(f'TILE {i+1}: {p}.' for i,p in enumerate(actions))+' Crucial: each pose must differ by the REQUESTED movement, not random expression. One tongue only, no extra teeth, no detached lips, no camera cuts, no text, numbers, arrows, captions, logos, watermark or UI.'
  # Explicit holds, neutral returns and useful contact intervals.
  if j['id']=='tongue_07_hard_palate_hold':timeline=[(0,0),(.7,0),(1.7,1),(3.7,1),(5.3,0),(6,0)]
  elif j['id']=='lip_05_kiss':timeline=[(0,0),(.5,0),(1.35,1),(2.0,1),(2.7,0),(3.2,0),(3.65,1),(3.9,1),(4.45,0),(5,0)]
  elif len(seq)==3:timeline=[(0,0),(.6,0),(1.6,1),(3.2,1),(4.5,0),(5,0)]
  else:
   # Allocate a short neutral lead/tail and retain every contact pose.
   length=j['seconds'];step=(length-1.0)/(len(seq)-1)
   timeline=[(0,0),(.5,0)]
   for k,idx in enumerate(seq[1:],1):
    center=.5+step*k
    timeline += [(max(timeline[-1][0]+.01,center-step*.28),idx),(center,idx)]
   timeline.append((length,0))
  spec={**j,'mode':mode,'poses':poses,'layout':{'columns':cols,'rows':rows},'timeline':timeline,'prompt':prompt,'reference':str(REF),'version':'v001','status':'awaiting_atlas'}
  folder=ROOT/'output/training_video'/j['id']/'v001'
  for sub in ['source','review','exports']:(folder/sub).mkdir(parents=True,exist_ok=True)
  (folder/'source/generation.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n')
  specs.append(spec)
 OUT.mkdir(parents=True,exist_ok=True)
 (OUT/'batch.json').write_text(json.dumps(specs,ensure_ascii=False,indent=2)+'\n')
 print('Prepared',len(specs),'remaining exercises')
if __name__=='__main__':main()
