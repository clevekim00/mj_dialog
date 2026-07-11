export type SpeechMorphTargetName =
  | "mouthOpen"
  | "smile"
  | "lipRound"
  | "jawLeft"
  | "jawRight"
  | "tongueOut"
  | "tongueLeft"
  | "tongueRight"
  | "cheekPuff";

export type SpeechMorphTargets = Record<SpeechMorphTargetName, number>;

export type SpeechExerciseStep = {
  id: string;
  name: string;
  koreanName: string;
  durationSeconds: number;
  morphTargets: Partial<SpeechMorphTargets>;
};

export const neutralSpeechMorphTargets: SpeechMorphTargets = {
  mouthOpen: 0,
  smile: 0,
  lipRound: 0,
  jawLeft: 0,
  jawRight: 0,
  tongueOut: 0,
  tongueLeft: 0,
  tongueRight: 0,
  cheekPuff: 0,
};

export const speechExerciseSteps: SpeechExerciseStep[] = [
  {
    id: "neutral",
    name: "Neutral face",
    koreanName: "중립 얼굴",
    durationSeconds: 3,
    morphTargets: {},
  },
  {
    id: "breath",
    name: "Deep breath preparation",
    koreanName: "깊은 호흡 준비",
    durationSeconds: 4,
    morphTargets: { mouthOpen: 0.12 },
  },
  {
    id: "open-wide",
    name: "Open mouth wide",
    koreanName: "입 크게 벌리기",
    durationSeconds: 3,
    morphTargets: { mouthOpen: 1 },
  },
  {
    id: "close-gently",
    name: "Close mouth gently",
    koreanName: "입 부드럽게 다물기",
    durationSeconds: 3,
    morphTargets: {},
  },
  {
    id: "smile-wide",
    name: "Smile wide",
    koreanName: "넓게 웃기",
    durationSeconds: 3,
    morphTargets: { smile: 1 },
  },
  {
    id: "oo-round",
    name: "Lip rounding oo",
    koreanName: "입술 둥글게 오",
    durationSeconds: 3,
    morphTargets: { lipRound: 1, mouthOpen: 0.2 },
  },
  {
    id: "tongue-out-back",
    name: "Tongue out and back",
    koreanName: "혀 내밀고 넣기",
    durationSeconds: 4,
    morphTargets: { tongueOut: 1, mouthOpen: 0.45 },
  },
  {
    id: "tongue-left-right",
    name: "Tongue left and right",
    koreanName: "혀 좌우 움직이기",
    durationSeconds: 4,
    morphTargets: { tongueLeft: 1, tongueRight: 1, mouthOpen: 0.38 },
  },
  {
    id: "cheek-puff",
    name: "Cheek puff",
    koreanName: "볼 부풀리기",
    durationSeconds: 3,
    morphTargets: { cheekPuff: 1, lipRound: 0.3 },
  },
  {
    id: "relax",
    name: "Relax",
    koreanName: "편안히 쉬기",
    durationSeconds: 4,
    morphTargets: {},
  },
];
