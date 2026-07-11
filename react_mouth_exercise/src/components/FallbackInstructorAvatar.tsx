import { useFrame } from "@react-three/fiber";
import { useRef } from "react";
import * as THREE from "three";
import { FacialRigState, neutralFacialRig } from "../data/facialRig";

type FallbackInstructorAvatarProps = {
  rig?: Partial<FacialRigState>;
  closeUp?: boolean;
};

export function FallbackInstructorAvatar({
  rig = {},
  closeUp = false,
}: FallbackInstructorAvatarProps) {
  const rootRef = useRef<THREE.Group>(null);
  const jawRef = useRef<THREE.Group>(null);
  const mouthRef = useRef<THREE.Mesh>(null);
  const tongueRef = useRef<THREE.Mesh>(null);
  const leftEyeRef = useRef<THREE.Group>(null);
  const rightEyeRef = useRef<THREE.Group>(null);
  const hairRef = useRef<THREE.Group>(null);

  useFrame(({ clock }) => {
    const time = clock.elapsedTime;
    const state = { ...neutralFacialRig, ...rig };
    const mouthOpen = Math.max(state.mouthOpen, state.jawOpen) * (1 - state.mouthClose);
    const blink = Math.max(0, Math.sin(time * 2.1) - 0.95) * 8;
    const jawShift = (state.jawRight - state.jawLeft) * 0.18;

    if (rootRef.current) {
      rootRef.current.position.y = Math.sin(time * 1.1) * 0.015;
      rootRef.current.rotation.y = Math.sin(time * 0.45) * 0.025 + state.neckRotate * 0.06;
      rootRef.current.scale.setScalar(closeUp ? 1.16 : 1);
    }
    if (hairRef.current) {
      hairRef.current.rotation.z = Math.sin(time * 1.35) * 0.045;
    }
    if (jawRef.current) {
      jawRef.current.position.x = jawShift;
      jawRef.current.position.y = -0.46 - mouthOpen * 0.1;
      jawRef.current.position.z = state.jawForward * 0.12;
    }
    if (mouthRef.current) {
      mouthRef.current.scale.set(
        0.6 + state.lipWide * 0.55 + state.lipSmile * 0.22 - state.lipRound * 0.28,
        0.08 + mouthOpen * 0.52 + state.lipRound * 0.1,
        0.04 + state.lipRound * 0.18,
      );
    }
    if (tongueRef.current) {
      tongueRef.current.position.x = (state.tongueRight - state.tongueLeft) * 0.28;
      tongueRef.current.position.y = -0.02 + (state.tongueUp - state.tongueDown) * 0.08;
      tongueRef.current.position.z = 0.08 + state.tongueOut * 0.34;
      tongueRef.current.rotation.x = -state.tongueCurl * 0.35;
    }
    if (leftEyeRef.current) {
      leftEyeRef.current.scale.y = 1 - Math.min(1, state.eyeBlinkLeft + blink) * 0.82;
    }
    if (rightEyeRef.current) {
      rightEyeRef.current.scale.y = 1 - Math.min(1, state.eyeBlinkRight + blink) * 0.82;
    }
  });

  return (
    <group ref={rootRef} position={[0, -0.08, 0]}>
      <group ref={hairRef}>
        <mesh position={[0, 0.78, -0.14]} rotation={[0.1, 0, 0]}>
          <sphereGeometry args={[1.05, 48, 28, 0, Math.PI * 2, 0, Math.PI * 0.78]} />
          <meshPhysicalMaterial color="#2b1a16" roughness={0.38} sheen={0.7} />
        </mesh>
        <mesh position={[0.72, 0.08, -0.24]} scale={[0.28, 1.0, 0.22]} rotation={[0, 0, -0.12]}>
          <sphereGeometry args={[1, 32, 22]} />
          <meshPhysicalMaterial color="#43251d" roughness={0.34} sheen={0.8} />
        </mesh>
      </group>

      <mesh position={[0, 0.06, 0]}>
        <sphereGeometry args={[1.02, 64, 42]} />
        <meshPhysicalMaterial color="#ffd6c7" roughness={0.62} clearcoat={0.08} />
      </mesh>

      <group ref={jawRef} position={[0, -0.46, 0]}>
        <mesh position={[0, -0.52, 0.04]} scale={[0.72, 0.56, 0.68]}>
          <sphereGeometry args={[1, 40, 24]} />
          <meshPhysicalMaterial color="#ffcbbb" roughness={0.64} />
        </mesh>
        <group position={[0, 0, 0.93]}>
          <mesh ref={mouthRef}>
            <sphereGeometry args={[1, 36, 16]} />
            <meshPhysicalMaterial color="#c75468" roughness={0.42} />
          </mesh>
          <mesh position={[0, 0, 0.036]} scale={[0.42, 0.08, 0.02]}>
            <sphereGeometry args={[1, 28, 12]} />
            <meshBasicMaterial color="#251018" />
          </mesh>
          <mesh ref={tongueRef} position={[0, -0.02, 0.08]} scale={[0.24, 0.055, 0.14]}>
            <sphereGeometry args={[1, 24, 12]} />
            <meshPhysicalMaterial color="#f48691" roughness={0.46} />
          </mesh>
          <mesh position={[0, 0.052, 0.058]} scale={[0.34, 0.032, 0.012]}>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="#fff8ef" roughness={0.38} />
          </mesh>
        </group>
      </group>

      <Eye refGroup={leftEyeRef} x={-0.32} />
      <Eye refGroup={rightEyeRef} x={0.32} />
      <mesh position={[-0.58, -0.06, 0.86]} scale={[0.18, 0.12, 0.04]}>
        <sphereGeometry args={[1, 20, 12]} />
        <meshBasicMaterial color="#ff9ca8" transparent opacity={0.32} />
      </mesh>
      <mesh position={[0.58, -0.06, 0.86]} scale={[0.18, 0.12, 0.04]}>
        <sphereGeometry args={[1, 20, 12]} />
        <meshBasicMaterial color="#ff9ca8" transparent opacity={0.32} />
      </mesh>
    </group>
  );
}

function Eye({
  x,
  refGroup,
}: {
  x: number;
  refGroup: React.RefObject<THREE.Group>;
}) {
  return (
    <group ref={refGroup} position={[x, 0.23, 0.94]}>
      <mesh scale={[0.15, 0.2, 0.04]}>
        <sphereGeometry args={[1, 32, 16]} />
        <meshBasicMaterial color="#2a1c1b" />
      </mesh>
      <mesh position={[0, -0.006, 0.02]} scale={[0.1, 0.14, 0.018]}>
        <sphereGeometry args={[1, 28, 14]} />
        <meshBasicMaterial color="#6c4638" />
      </mesh>
      <mesh position={[0.035, 0.055, 0.038]} scale={[0.034, 0.046, 0.012]}>
        <sphereGeometry args={[1, 12, 8]} />
        <meshBasicMaterial color="#ffffff" />
      </mesh>
    </group>
  );
}
