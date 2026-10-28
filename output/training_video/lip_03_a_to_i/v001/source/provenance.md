# lip_03_a_to_i v001

Created 2026-10-27. Review draft only; no app registration or existing video replacement.

Reference: first decoded frame of assets/videos/training/lip_02_u_to_i.mp4.
Static plate: built-in image_gen edit, no fallback API/CLI. Requested removal of mouth only while preserving character, ponytail, eyes, nose, chin, uniform, framing, background and lighting. Output contains featureless skin where a separate mouth layer is rendered. Generated original: exec-12753e51-3b80-4d67-a7a2-0ff3ef20cf35.png.

Prompt:
“Use case: precise-object-edit. Create a background plate for deterministic 2D mouth animation. Preserve this exact adult female illustrated character, identity, ponytail, eyes, nose, chin, white uniform, framing, background and illumination. Change ONLY the small mouth region: remove the entire visible lips, mouth opening and mouth shadow and replace it with seamless smooth natural facial skin matching the surrounding cheeks. This is an animation base plate awaiting a separately drawn mouth, so the mouth area should be completely featureless skin, no lip line at all. Keep face proportions and head unchanged. Output same 16:9 1280x720 composition. No text, captions, UI, watermark. Do not add any other objects or modify any other region.”

Animation: local editable Bezier geometry, sampled deterministically at frameIndex / 24. Neutral → A → I → A → neutral. A has vertical opening; I has horizontal widening and a visible upper tooth band. Static head and jaw; this simplification and the stylized lip geometry require human review. Character fidelity also requires user review after the image edit.

Export: 120 frames, 5 seconds, 1280×720, 24fps, H.264 / yuv420p, no audio. Technical validation is in exports/technical_validation.json. Render configuration and SHA-256 are in review/render.json. Keyframe comparison: review/keyframes.jpg. Clinical review pending.

Reproduce from the repository root using python3 tools/training_video/render_lip_pilot.py. The renderer refuses to overwrite an existing export; use a new version directory for another candidate. The copied source is archival; execute the canonical tools path because it resolves the project root relative to itself.
