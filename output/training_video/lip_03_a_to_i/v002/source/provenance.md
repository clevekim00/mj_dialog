# Full-face pilot v002 — 2026-10-27

User request: remake the A–I sample with coordinated jaw, cheeks and mouth corners; provide a direct comparison with v001.

## Source and generation

Reference: v001/source/character_reference.png, extracted from the existing lip_02_u_to_i.mp4. Existing app assets remain unchanged.

Keyframe artwork: built-in image_gen, reference-guided full-face keyframe atlas. No fallback CLI/API. Generated file: exec-bd29cac2-36b8-4ebb-ab84-379267088ea8.png, copied here as full_face_atlas.png. This is newly generated artwork; it is not a clinical anatomy model.

Prompt:

Create an animation keyframe atlas from the attached illustrated adult woman. THREE equal 16:9 panels STACKED VERTICALLY, edge-to-edge, no gaps, no borders, no labels, overall aspect ratio 16:27. Each panel shows the SAME original 16:9 camera framing as reference, same woman, identical centered head position, same ponytail, eyes, nose, white uniform, background and lighting. Keep all backgrounds and upper-face features pixel-aligned across panels as closely as possible for morph animation. DO NOT zoom or change identity. TOP panel: relaxed NEUTRAL mouth, lips gently closed, relaxed cheeks and jaw. MIDDLE panel: Korean AH vowel /a/: comfortable vertically open mouth, jaw visibly lowered, chin slightly lowered and jawline lengthened naturally, lower cheeks relax and stretch down subtly, upper lip and mouth corners adapt naturally. Clearly visible dark oral cavity, subtle tongue and upper teeth, no exaggerated strain. BOTTOM panel: Korean EE vowel /i/: lips naturally spread sideways with gently visible upper teeth, mouth corners retract laterally, cheeks lift subtly, jaw returns higher than AH and chin/jawline follows naturally. This is speech articulation not an emotional grin; keep eyes calm and same gaze. Crucial: render the ENTIRE lower face as coherent artwork in each pose, coordinated jaw, cheeks, lip corners and chin. Mouth lips must match original painterly linework, shading and skin texture; not pasted vector shapes. No duplicated lips, no lip sticker effect, no distorted teeth. No text, no UI, no watermark. Full scene is repeated once in each panel; exactly three panels.

## Local animation

Canonical source: tools/training_video/render_full_face_pilot.py. Python + OpenCV + Pillow + imageio-ffmpeg. No package installation, network, cloud video generation, or app registration is performed by the renderer.

The atlas is unpacked into neutral/A/I poses, camera drift is aligned from upper-face/hair features, and a broad lower-face/neck region preserves coordinated cheeks, jaw, chin and lip motion while stabilizing the background. Dense bidirectional optical flow interpolates the generated poses. This differs from the rejected v001, which placed independent vector mouth geometry on a static face. It remains an image-based motion draft and can soften teeth/lip detail in intermediate frames.

Timing matches v001: neutral → A → I → A → neutral, 5 seconds, 120 frames at 24fps. New standalone: 1280×720; comparison: 1440×800 with equal 720px face closeups and English labels. LEFT = v001 mouth overlay; RIGHT = v002 full-face motion. Labels occur only in the comparison artifact.

Review includes endpoint poses and intermediate frames. Technical validation and image inspection do not establish clinical correctness. Neither candidate is connected to the app.
