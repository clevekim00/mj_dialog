# Professional Instructor Avatar Model

Place the production GLB model here:

```text
public/models/speech_therapy_instructor.glb
```

If this GLB is missing, the exercise viewer displays the temporary development fallback avatar.
Replace the fallback with this production GLB before release.

Required blendshape names:

- `mouthOpen`
- `jawOpen`
- `jawForward`
- `lipRound`
- `lipWide`
- `lipSmile`
- `lipCornerRaise`
- `lipCornerLower`
- `cheekRaise`
- `cheekPuff`
- `tongueOut`
- `tongueLeft`
- `tongueRight`
- `tongueCurl`
- `eyeBlink`
- `browRaise`
- `browLower`
- `neckRotate`
- `headTilt`

Recommended optional names:

- `mouthClose`
- `jawLeft`
- `jawRight`
- `lipPress`
- `lipCornerUp`
- `lipCornerDown`
- `tongueUp`
- `tongueDown`
- `tongueTipUp`
- `eyeBlinkLeft`
- `eyeBlinkRight`
- `eyeLookLeft`
- `eyeLookRight`
- `eyeLookUp`
- `eyeLookDown`
- `noseWrinkle`

You can also provide another model URL:

```bash
VITE_INSTRUCTOR_AVATAR_URL=/models/my_professional_avatar.glb npm run dev
```
