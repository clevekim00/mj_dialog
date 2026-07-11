export const defaultInstructorAvatarUrl =
  import.meta.env.VITE_INSTRUCTOR_AVATAR_URL ||
  "/models/speech_therapy_instructor.glb";

export const requiredAvatarBlendshapes = [
  "mouthOpen",
  "jawOpen",
  "jawForward",
  "lipRound",
  "lipWide",
  "lipSmile",
  "lipCornerRaise",
  "lipCornerLower",
  "cheekRaise",
  "cheekPuff",
  "tongueOut",
  "tongueLeft",
  "tongueRight",
  "tongueCurl",
  "eyeBlink",
  "browRaise",
  "browLower",
  "neckRotate",
  "headTilt",
] as const;
