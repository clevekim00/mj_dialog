export type FacialRigTargetName =
  | "mouthOpen"
  | "mouthClose"
  | "jawOpen"
  | "jawForward"
  | "jawLeft"
  | "jawRight"
  | "lipWide"
  | "lipRound"
  | "lipSmile"
  | "lipPress"
  | "lipCornerUp"
  | "lipCornerDown"
  | "lipCornerRaise"
  | "lipCornerLower"
  | "cheekPuff"
  | "cheekRaise"
  | "tongueOut"
  | "tongueUp"
  | "tongueDown"
  | "tongueLeft"
  | "tongueRight"
  | "tongueCurl"
  | "tongueTipUp"
  | "eyeBlinkLeft"
  | "eyeBlinkRight"
  | "eyeLookLeft"
  | "eyeLookRight"
  | "eyeLookUp"
  | "eyeLookDown"
  | "browRaise"
  | "browLower"
  | "noseWrinkle"
  | "neckRotate"
  | "headTilt";

export type FacialRigState = Record<FacialRigTargetName, number>;

export const neutralFacialRig: FacialRigState = {
  mouthOpen: 0,
  mouthClose: 0,
  jawOpen: 0,
  jawForward: 0,
  jawLeft: 0,
  jawRight: 0,
  lipWide: 0,
  lipRound: 0,
  lipSmile: 0,
  lipPress: 0,
  lipCornerUp: 0,
  lipCornerDown: 0,
  lipCornerRaise: 0,
  lipCornerLower: 0,
  cheekPuff: 0,
  cheekRaise: 0,
  tongueOut: 0,
  tongueUp: 0,
  tongueDown: 0,
  tongueLeft: 0,
  tongueRight: 0,
  tongueCurl: 0,
  tongueTipUp: 0,
  eyeBlinkLeft: 0,
  eyeBlinkRight: 0,
  eyeLookLeft: 0,
  eyeLookRight: 0,
  eyeLookUp: 0,
  eyeLookDown: 0,
  browRaise: 0,
  browLower: 0,
  noseWrinkle: 0,
  neckRotate: 0,
  headTilt: 0,
};

export const arkitBlendshapeMap: Partial<Record<FacialRigTargetName, string>> = {
  mouthOpen: "jawOpen",
  mouthClose: "mouthClose",
  jawOpen: "jawOpen",
  jawForward: "jawForward",
  jawLeft: "jawLeft",
  jawRight: "jawRight",
  lipWide: "mouthStretchLeft",
  lipRound: "mouthFunnel",
  lipSmile: "mouthSmileLeft",
  lipPress: "mouthPressLeft",
  lipCornerUp: "mouthSmileRight",
  lipCornerDown: "mouthFrownLeft",
  lipCornerRaise: "mouthSmileRight",
  lipCornerLower: "mouthFrownRight",
  cheekPuff: "cheekPuff",
  cheekRaise: "cheekSquintLeft",
  tongueOut: "tongueOut",
  tongueUp: "tongueUp",
  tongueDown: "tongueDown",
  tongueLeft: "tongueLeft",
  tongueRight: "tongueRight",
  tongueCurl: "tongueCurl",
  tongueTipUp: "tongueTipUp",
  eyeBlinkLeft: "eyeBlinkLeft",
  eyeBlinkRight: "eyeBlinkRight",
  eyeLookLeft: "eyeLookOutRight",
  eyeLookRight: "eyeLookOutLeft",
  eyeLookUp: "eyeLookUpLeft",
  eyeLookDown: "eyeLookDownLeft",
  browRaise: "browInnerUp",
  browLower: "browDownLeft",
  noseWrinkle: "noseSneerLeft",
  neckRotate: "neckRotate",
  headTilt: "headTilt",
};

export function mergeRig(partial: Partial<FacialRigState>): FacialRigState {
  return { ...neutralFacialRig, ...partial };
}
