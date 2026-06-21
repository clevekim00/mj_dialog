import type { FacialRigState, FacialRigTargetName } from "./facialRig";

export type KoreanPhoneme =
  | "아"
  | "야"
  | "어"
  | "여"
  | "오"
  | "요"
  | "우"
  | "유"
  | "으"
  | "이"
  | "ㅁ"
  | "ㅂ"
  | "ㅍ"
  | "ㄷ"
  | "ㅌ"
  | "ㄴ"
  | "ㄹ"
  | "ㄱ"
  | "ㅋ"
  | "ㅇ"
  | "ㅅ"
  | "ㅈ"
  | "ㅊ"
  | "ㅎ";

export type VisemePose = Partial<FacialRigState> & {
  labelKo: string;
  educationNoteKo: string;
};

export const koreanVisemeMap: Record<KoreanPhoneme, VisemePose> = {
  아: {
    labelKo: "아",
    educationNoteKo: "턱을 아래로 열고 입 안 공간을 크게 보여줍니다.",
    mouthOpen: 0.82,
    jawOpen: 0.78,
    tongueDown: 0.18,
  },
  야: {
    labelKo: "야",
    educationNoteKo: "이완된 이 입모양에서 아로 부드럽게 전환합니다.",
    mouthOpen: 0.66,
    jawOpen: 0.62,
    lipWide: 0.2,
    tongueUp: 0.14,
  },
  어: {
    labelKo: "어",
    educationNoteKo: "입을 중간 정도 열고 입술 긴장을 낮춥니다.",
    mouthOpen: 0.58,
    jawOpen: 0.5,
    lipRound: 0.1,
  },
  여: {
    labelKo: "여",
    educationNoteKo: "혀 앞부분을 살짝 올린 뒤 어 모양으로 이어갑니다.",
    mouthOpen: 0.52,
    jawOpen: 0.46,
    lipWide: 0.12,
    tongueUp: 0.18,
  },
  오: {
    labelKo: "오",
    educationNoteKo: "입술을 둥글게 모으고 턱은 과하게 열지 않습니다.",
    mouthOpen: 0.42,
    jawOpen: 0.32,
    lipRound: 0.76,
    jawForward: 0.12,
  },
  요: {
    labelKo: "요",
    educationNoteKo: "혀 앞쪽 움직임 뒤에 둥근 오 입모양을 만듭니다.",
    mouthOpen: 0.38,
    jawOpen: 0.28,
    lipRound: 0.72,
    tongueUp: 0.15,
    jawForward: 0.1,
  },
  우: {
    labelKo: "우",
    educationNoteKo: "입술을 앞으로 좁고 둥글게 내밉니다.",
    mouthOpen: 0.28,
    jawOpen: 0.18,
    lipRound: 0.92,
    jawForward: 0.2,
  },
  유: {
    labelKo: "유",
    educationNoteKo: "이완된 앞혀 위치에서 우 입모양으로 이어갑니다.",
    mouthOpen: 0.25,
    jawOpen: 0.16,
    lipRound: 0.9,
    tongueUp: 0.18,
    jawForward: 0.18,
  },
  으: {
    labelKo: "으",
    educationNoteKo: "입술을 편안히 두고 입 안쪽 공간을 좁게 유지합니다.",
    mouthOpen: 0.16,
    jawOpen: 0.12,
    lipPress: 0.12,
    tongueDown: 0.06,
  },
  이: {
    labelKo: "이",
    educationNoteKo: "입술을 양옆으로 넓히고 턱은 조금만 엽니다.",
    mouthOpen: 0.18,
    jawOpen: 0.12,
    lipWide: 0.88,
    lipSmile: 0.45,
    cheekRaise: 0.18,
  },
  "ㅁ": {
    labelKo: "ㅁ",
    educationNoteKo: "입술을 부드럽게 닫고 비강 울림을 준비합니다.",
    mouthClose: 0.92,
    lipPress: 0.58,
  },
  "ㅂ": {
    labelKo: "ㅂ",
    educationNoteKo: "입술을 닫았다가 짧게 떼며 소리를 냅니다.",
    mouthClose: 0.82,
    lipPress: 0.72,
    lipCornerUp: 0.06,
  },
  "ㅍ": {
    labelKo: "ㅍ",
    educationNoteKo: "입술을 닫은 뒤 공기를 살짝 밀어냅니다.",
    mouthClose: 0.78,
    lipPress: 0.66,
    cheekPuff: 0.16,
  },
  "ㄷ": {
    labelKo: "ㄷ",
    educationNoteKo: "혀끝을 윗잇몸 쪽에 가볍게 댑니다.",
    mouthOpen: 0.22,
    tongueTipUp: 0.76,
    tongueUp: 0.38,
  },
  "ㅌ": {
    labelKo: "ㅌ",
    educationNoteKo: "혀끝 접촉 뒤 공기를 더 선명하게 터뜨립니다.",
    mouthOpen: 0.24,
    tongueTipUp: 0.82,
    tongueUp: 0.45,
    cheekPuff: 0.08,
  },
  "ㄴ": {
    labelKo: "ㄴ",
    educationNoteKo: "혀끝을 올리고 입은 너무 크게 열지 않습니다.",
    mouthOpen: 0.2,
    tongueTipUp: 0.74,
    tongueUp: 0.42,
  },
  "ㄹ": {
    labelKo: "ㄹ",
    educationNoteKo: "혀끝이 위쪽을 빠르게 스치도록 안내합니다.",
    mouthOpen: 0.25,
    tongueTipUp: 0.82,
    tongueCurl: 0.28,
  },
  "ㄱ": {
    labelKo: "ㄱ",
    educationNoteKo: "혀 뒤쪽을 올리는 느낌을 시각적으로 표현합니다.",
    mouthOpen: 0.3,
    tongueUp: 0.24,
    tongueCurl: 0.18,
  },
  "ㅋ": {
    labelKo: "ㅋ",
    educationNoteKo: "혀 뒤쪽 움직임과 가벼운 공기 흐름을 함께 보여줍니다.",
    mouthOpen: 0.34,
    tongueUp: 0.28,
    tongueCurl: 0.22,
    cheekPuff: 0.1,
  },
  "ㅇ": {
    labelKo: "ㅇ",
    educationNoteKo: "받침 위치에서는 입 모양 변화가 작게 유지됩니다.",
    mouthOpen: 0.12,
    jawOpen: 0.08,
  },
  "ㅅ": {
    labelKo: "ㅅ",
    educationNoteKo: "입술을 살짝 넓히고 혀 중앙의 좁은 통로를 표현합니다.",
    mouthOpen: 0.14,
    lipWide: 0.42,
    tongueTipUp: 0.22,
  },
  "ㅈ": {
    labelKo: "ㅈ",
    educationNoteKo: "이 모양에 가까운 입술과 혀 앞쪽 움직임을 사용합니다.",
    mouthOpen: 0.22,
    lipWide: 0.44,
    tongueTipUp: 0.3,
  },
  "ㅊ": {
    labelKo: "ㅊ",
    educationNoteKo: "ㅈ보다 공기 흐름을 조금 더 크게 표현합니다.",
    mouthOpen: 0.26,
    lipWide: 0.42,
    tongueTipUp: 0.36,
    cheekPuff: 0.08,
  },
  "ㅎ": {
    labelKo: "ㅎ",
    educationNoteKo: "입을 편안히 열고 숨이 나가는 움직임을 보여줍니다.",
    mouthOpen: 0.36,
    jawOpen: 0.28,
  },
};

export function blendVisemes(
  from: Partial<FacialRigState>,
  to: Partial<FacialRigState>,
  amount: number,
): Partial<FacialRigState> {
  const t = Math.max(0, Math.min(1, amount));
  const keys = new Set([
    ...Object.keys(from),
    ...Object.keys(to),
  ] as FacialRigTargetName[]);
  const blended: Partial<FacialRigState> = {};

  keys.forEach((key) => {
    blended[key] = (from[key] ?? 0) * (1 - t) + (to[key] ?? 0) * t;
  });

  return blended;
}
