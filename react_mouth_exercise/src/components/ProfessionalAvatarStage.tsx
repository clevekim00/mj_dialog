import { Canvas, useThree } from "@react-three/fiber";
import { ContactShadows, Environment, OrbitControls } from "@react-three/drei";
import { Suspense, useEffect, useState } from "react";
import * as THREE from "three";
import { defaultInstructorAvatarUrl } from "../data/avatarModel";
import { FacialRigState } from "../data/facialRig";
import { FallbackInstructorAvatar } from "./FallbackInstructorAvatar";
import { ProfessionalInstructorAvatar } from "./ProfessionalInstructorAvatar";

type ProfessionalAvatarStageProps = {
  rig: Partial<FacialRigState>;
  modelUrl?: string;
  closeUp?: boolean;
  ariaLabel?: string;
};

export function ProfessionalAvatarStage({
  rig,
  modelUrl = defaultInstructorAvatarUrl,
  closeUp = false,
  ariaLabel = "전문 GLB 강사 아바타 애니메이션",
}: ProfessionalAvatarStageProps) {
  const availability = useAvatarAvailability(modelUrl);

  return (
    <div className="viewer-panel" aria-label={ariaLabel}>
      <Canvas
        camera={{ position: [0, closeUp ? 1.32 : 1.08, closeUp ? 2.55 : 3.2], fov: closeUp ? 26 : 32 }}
        dpr={[1, 2]}
        gl={{
          antialias: true,
          powerPreference: "high-performance",
          toneMapping: THREE.ACESFilmicToneMapping,
          outputColorSpace: THREE.SRGBColorSpace,
        }}
        shadows
      >
        <color attach="background" args={["#f8f3f1"]} />
        <Suspense fallback={null}>
          <ProfessionalCamera closeUp={closeUp} />
          <ambientLight intensity={0.55} />
          <directionalLight
            castShadow
            position={[-2.8, 4.2, 3.2]}
            intensity={2.35}
            color="#fff0dd"
            shadow-mapSize={[2048, 2048]}
          />
          <pointLight position={[2.8, 1.8, -2.6]} intensity={1.2} color="#9ec5ff" />
          <spotLight
            castShadow
            position={[0.2, 3.1, 2.1]}
            angle={0.38}
            penumbra={0.78}
            intensity={1.4}
            color="#ffffff"
          />
          {availability === "available" ? (
            <ProfessionalInstructorAvatar
              modelUrl={modelUrl}
              rig={rig}
              closeUp={closeUp}
            />
          ) : (
            <FallbackInstructorAvatar rig={rig} closeUp={closeUp} />
          )}
          <ContactShadows
            position={[0, -1.5, 0]}
            opacity={0.25}
            scale={4.2}
            blur={2.4}
            far={3.2}
          />
          <Environment preset="studio" />
          <OrbitControls
            enablePan={false}
            enableZoom={false}
            minPolarAngle={Math.PI / 2.75}
            maxPolarAngle={Math.PI / 1.92}
          />
        </Suspense>
      </Canvas>
    </div>
  );
}

function ProfessionalCamera({ closeUp }: { closeUp: boolean }) {
  const { camera } = useThree();

  useEffect(() => {
    camera.position.set(0, closeUp ? 1.32 : 1.08, closeUp ? 2.55 : 3.2);
    camera.lookAt(0, closeUp ? 0.76 : 0.52, 0);
  }, [camera, closeUp]);

  return null;
}

function useAvatarAvailability(modelUrl: string) {
  const [availability, setAvailability] = useState<"checking" | "available" | "missing">(
    "checking",
  );

  useEffect(() => {
    let cancelled = false;

    async function checkModel() {
      try {
        const response = await fetch(modelUrl, { method: "GET" });
        const contentType = response.headers.get("content-type") ?? "";
        const isLikelyModel =
          response.ok &&
          (modelUrl.endsWith(".glb") || modelUrl.endsWith(".gltf")) &&
          !contentType.includes("text/html");

        if (!cancelled) {
          setAvailability(isLikelyModel ? "available" : "missing");
        }
      } catch {
        if (!cancelled) setAvailability("missing");
      }
    }

    void checkModel();
    return () => {
      cancelled = true;
    };
  }, [modelUrl]);

  return availability;
}
