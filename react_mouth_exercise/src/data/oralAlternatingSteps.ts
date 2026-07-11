export type MouthShape =
  | "neutral"
  | "open"
  | "wideSmile"
  | "round"
  | "pataka"
  | "lala"
  | "jawMove"
  | "tongueMove";

export type OralExerciseStep = {
  id: string;
  titleKo: string;
  descriptionKo: string;
  pronunciation?: string;
  audioSrc?: string;
  durationMs: number;
  mouthShape: MouthShape;
};

export type OralMorphTargets = {
  mouthOpen: number;
  mouthClose: number;
  jawOpen: number;
  jawForward: number;
  lipWide: number;
  lipRound: number;
  lipSmile: number;
  lipPress: number;
  lipCornerUp: number;
  jawLeft: number;
  jawRight: number;
  tongueOut: number;
  tongueUp: number;
  tongueDown: number;
  tongueLeft: number;
  tongueRight: number;
  tongueCurl: number;
  tongueTipUp: number;
  cheekPuff: number;
  cheekRaise: number;
};

export const neutralOralMorphTargets: OralMorphTargets = {
  mouthOpen: 0,
  mouthClose: 0,
  jawOpen: 0,
  jawForward: 0,
  lipWide: 0,
  lipRound: 0,
  lipSmile: 0,
  lipPress: 0,
  lipCornerUp: 0,
  jawLeft: 0,
  jawRight: 0,
  tongueOut: 0,
  tongueUp: 0,
  tongueDown: 0,
  tongueLeft: 0,
  tongueRight: 0,
  tongueCurl: 0,
  tongueTipUp: 0,
  cheekPuff: 0,
  cheekRaise: 0,
};

export const oralAlternatingSteps: OralExerciseStep[] = [
  {
    id: "neutral",
    titleKo: "중립 얼굴",
    descriptionKo: "입과 턱의 힘을 가볍게 풀고 정면을 바라봅니다.",
    durationMs: 2500,
    mouthShape: "neutral",
  },
  {
    id: "a",
    titleKo: "아 발음",
    descriptionKo: "입을 세로로 넓게 열며 아 소리를 냅니다.",
    pronunciation: "아",
    durationMs: 2600,
    mouthShape: "open",
  },
  {
    id: "i",
    titleKo: "이 발음",
    descriptionKo: "입술을 양옆으로 부드럽게 당기며 이 소리를 냅니다.",
    pronunciation: "이",
    durationMs: 2600,
    mouthShape: "wideSmile",
  },
  {
    id: "u",
    titleKo: "우 발음",
    descriptionKo: "입술을 앞으로 둥글게 모으며 우 소리를 냅니다.",
    pronunciation: "우",
    durationMs: 2600,
    mouthShape: "round",
  },
  {
    id: "aiu",
    titleKo: "아-이-우 연속",
    descriptionKo: "입 모양을 크게, 넓게, 둥글게 이어서 바꿉니다.",
    pronunciation: "아 이 우",
    durationMs: 4200,
    mouthShape: "pataka",
  },
  {
    id: "pataka",
    titleKo: "파-타-카 교대",
    descriptionKo: "입술, 혀끝, 뒤쪽 혀 움직임을 번갈아 사용합니다.",
    pronunciation: "파 타 카",
    durationMs: 4200,
    mouthShape: "pataka",
  },
  {
    id: "lalala",
    titleKo: "라-라-라 혀끝",
    descriptionKo: "혀끝이 위쪽 앞부분을 가볍게 치는 느낌으로 움직입니다.",
    pronunciation: "라 라 라",
    durationMs: 3600,
    mouthShape: "lala",
  },
  {
    id: "jaw",
    titleKo: "턱 좌우 움직임",
    descriptionKo: "무리하지 않는 범위에서 턱을 천천히 좌우로 움직입니다.",
    durationMs: 3600,
    mouthShape: "jawMove",
  },
  {
    id: "tongue-side",
    titleKo: "혀 좌우 움직임",
    descriptionKo: "입을 살짝 열고 혀를 좌우로 천천히 움직입니다.",
    durationMs: 3600,
    mouthShape: "tongueMove",
  },
  {
    id: "relax",
    titleKo: "편안히 쉬기",
    descriptionKo: "입과 볼, 턱의 힘을 빼고 편안히 마무리합니다.",
    durationMs: 3200,
    mouthShape: "neutral",
  },
];
