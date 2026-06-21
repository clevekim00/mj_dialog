export type MorphTargetName =
  | "mouthOpen"
  | "smile"
  | "lipsPucker"
  | "jawLeft"
  | "jawRight"
  | "cheekPuffLeft"
  | "cheekPuffRight";

export type MorphTargetValues = Record<MorphTargetName, number>;

export type MouthExerciseStep = {
  id: string;
  name: string;
  durationSeconds: number;
  morphTargets: Partial<MorphTargetValues>;
};

export const neutralMorphTargets: MorphTargetValues = {
  mouthOpen: 0,
  smile: 0,
  lipsPucker: 0,
  jawLeft: 0,
  jawRight: 0,
  cheekPuffLeft: 0,
  cheekPuffRight: 0,
};

export const mouthExerciseSteps: MouthExerciseStep[] = [
  {
    id: "relaxed",
    name: "Relaxed face",
    durationSeconds: 3,
    morphTargets: {},
  },
  {
    id: "open-wide",
    name: "Open mouth wide",
    durationSeconds: 3,
    morphTargets: { mouthOpen: 1 },
  },
  {
    id: "close",
    name: "Close mouth",
    durationSeconds: 3,
    morphTargets: { mouthOpen: 0 },
  },
  {
    id: "oo",
    name: "Move lips forward like oo",
    durationSeconds: 3,
    morphTargets: { lipsPucker: 1, mouthOpen: 0.18 },
  },
  {
    id: "smile",
    name: "Smile wide",
    durationSeconds: 3,
    morphTargets: { smile: 1 },
  },
  {
    id: "jaw-left",
    name: "Move jaw left",
    durationSeconds: 2,
    morphTargets: { jawLeft: 1, mouthOpen: 0.2 },
  },
  {
    id: "jaw-right",
    name: "Move jaw right",
    durationSeconds: 2,
    morphTargets: { jawRight: 1, mouthOpen: 0.2 },
  },
  {
    id: "cheek-puff",
    name: "Puff cheeks",
    durationSeconds: 3,
    morphTargets: {
      cheekPuffLeft: 1,
      cheekPuffRight: 1,
      lipsPucker: 0.25,
    },
  },
];
