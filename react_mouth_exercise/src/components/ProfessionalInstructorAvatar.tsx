import { useFrame } from "@react-three/fiber";
import { useGLTF } from "@react-three/drei";
import { useMemo, useRef } from "react";
import * as THREE from "three";
import { clone } from "three/examples/jsm/utils/SkeletonUtils.js";
import {
  arkitBlendshapeMap,
  FacialRigState,
  neutralFacialRig,
} from "../data/facialRig";

type ProfessionalInstructorAvatarProps = {
  modelUrl: string;
  rig?: Partial<FacialRigState>;
  closeUp?: boolean;
};

type MorphMesh = THREE.Mesh & {
  morphTargetDictionary?: Record<string, number>;
  morphTargetInfluences?: number[];
};

const morphAliases: Partial<Record<keyof FacialRigState, string[]>> = {
  mouthOpen: ["mouthOpen", "MouthOpen", "viseme_aa"],
  mouthClose: ["mouthClose", "MouthClose"],
  jawOpen: ["jawOpen", "JawOpen"],
  jawForward: ["jawForward", "JawForward"],
  jawLeft: ["jawLeft", "JawLeft"],
  jawRight: ["jawRight", "JawRight"],
  lipRound: ["lipRound", "LipRound", "mouthFunnel", "mouthPucker"],
  lipWide: ["lipWide", "LipWide", "mouthStretchLeft", "mouthStretchRight"],
  lipSmile: ["lipSmile", "LipSmile", "mouthSmileLeft", "mouthSmileRight"],
  lipPress: ["lipPress", "LipPress", "mouthPressLeft", "mouthPressRight"],
  lipCornerUp: ["lipCornerUp", "LipCornerUp", "lipCornerRaise"],
  lipCornerDown: ["lipCornerDown", "LipCornerDown", "lipCornerLower"],
  lipCornerRaise: ["lipCornerRaise", "LipCornerRaise", "lipCornerUp"],
  lipCornerLower: ["lipCornerLower", "LipCornerLower", "lipCornerDown"],
  cheekRaise: ["cheekRaise", "CheekRaise", "cheekSquintLeft", "cheekSquintRight"],
  cheekPuff: ["cheekPuff", "CheekPuff"],
  tongueOut: ["tongueOut", "TongueOut"],
  tongueUp: ["tongueUp", "TongueUp"],
  tongueDown: ["tongueDown", "TongueDown"],
  tongueLeft: ["tongueLeft", "TongueLeft"],
  tongueRight: ["tongueRight", "TongueRight"],
  tongueCurl: ["tongueCurl", "TongueCurl"],
  tongueTipUp: ["tongueTipUp", "TongueTipUp"],
  eyeBlinkLeft: ["eyeBlinkLeft", "EyeBlinkLeft", "eyeBlink"],
  eyeBlinkRight: ["eyeBlinkRight", "EyeBlinkRight", "eyeBlink"],
  browRaise: ["browRaise", "BrowRaise", "browInnerUp"],
  browLower: ["browLower", "BrowLower", "browDownLeft", "browDownRight"],
  neckRotate: ["neckRotate", "NeckRotate"],
  headTilt: ["headTilt", "HeadTilt"],
};

export function ProfessionalInstructorAvatar({
  modelUrl,
  rig = {},
  closeUp = false,
}: ProfessionalInstructorAvatarProps) {
  const groupRef = useRef<THREE.Group>(null);
  const gltf = useGLTF(modelUrl);
  const scene = useMemo(() => clone(gltf.scene), [gltf.scene]);

  useMemo(() => {
    scene.traverse((node) => {
      if (!(node instanceof THREE.Mesh)) return;
      node.castShadow = true;
      node.receiveShadow = true;

      const materials = Array.isArray(node.material) ? node.material : [node.material];
      materials.forEach((material) => {
        if (
          material instanceof THREE.MeshStandardMaterial ||
          material instanceof THREE.MeshPhysicalMaterial
        ) {
          material.envMapIntensity = 0.85;
          material.needsUpdate = true;
        }
      });
    });
  }, [scene]);

  useFrame(({ clock }, delta) => {
    const time = clock.elapsedTime;
    const currentRig = { ...neutralFacialRig, ...rig };
    const breathing = Math.sin(time * 1.1) * 0.012;
    const headSway = Math.sin(time * 0.42) * 0.018;
    const autoBlink = Math.max(0, Math.sin(time * 2.05) - 0.965) * 12;
    const blink = Math.min(
      1,
      Math.max(currentRig.eyeBlinkLeft, currentRig.eyeBlinkRight, autoBlink),
    );

    if (groupRef.current) {
      groupRef.current.position.y = -1.08 + breathing + (closeUp ? -0.08 : 0);
      groupRef.current.rotation.y = headSway + currentRig.neckRotate * 0.06;
      groupRef.current.rotation.x = Math.sin(time * 0.32) * 0.012 + currentRig.headTilt * 0.04;
      groupRef.current.scale.setScalar(closeUp ? 1.16 : 1);
    }

    scene.traverse((node) => {
      if (!(node instanceof THREE.Mesh)) return;
      const mesh = node as MorphMesh;
      if (!mesh.morphTargetDictionary || !mesh.morphTargetInfluences) return;

      applyMorph(mesh, "eyeBlink", blink, delta);

      (Object.keys(currentRig) as (keyof FacialRigState)[]).forEach((targetName) => {
        const targetValue = currentRig[targetName];
        const names = [
          targetName,
          arkitBlendshapeMap[targetName],
          ...(morphAliases[targetName] ?? []),
        ].filter(Boolean) as string[];

        names.forEach((name) => applyMorph(mesh, name, targetValue, delta));
      });
    });
  });

  return (
    <group ref={groupRef}>
      <primitive object={scene} />
    </group>
  );
}

function applyMorph(mesh: MorphMesh, name: string, value: number, delta: number) {
  const index = mesh.morphTargetDictionary?.[name];
  if (index == null || !mesh.morphTargetInfluences) return;

  const target = THREE.MathUtils.clamp(value, 0, 1);
  const current = mesh.morphTargetInfluences[index] ?? 0;
  mesh.morphTargetInfluences[index] = THREE.MathUtils.lerp(
    current,
    target,
    Math.min(1, delta * 14),
  );
}
