import { ExerciseControls } from "./ExerciseControls";
import { useExercisePlayer } from "../hooks/useExercisePlayer";
import { mergeRig } from "../data/facialRig";
import { ProfessionalAvatarStage } from "./ProfessionalAvatarStage";

export type MouthSpeechExercise3DProps = {
  autoPlay?: boolean;
  loop?: boolean;
  defaultSpeed?: number;
  onStepChange?: (stepIndex: number, stepId: string) => void;
  onComplete?: () => void;
};

export function MouthSpeechExercise3D({
  autoPlay = true,
  loop = true,
  defaultSpeed = 1,
  onStepChange,
  onComplete,
}: MouthSpeechExercise3DProps) {
  const player = useExercisePlayer({
    autoPlay,
    loop,
    defaultSpeed,
    onStepChange,
    onComplete,
  });

  return (
    <section
      className="mouth-exercise-shell"
      aria-label="3D 말 명료도 구강 운동 안내"
    >
      <ProfessionalAvatarStage
        closeUp={player.currentStep.id.includes("tongue") || player.currentStep.id.includes("mouth")}
        ariaLabel="전문 GLB 강사 호흡훈련 애니메이션"
        rig={mergeRig({
          mouthOpen: player.morphTargets.mouthOpen,
          jawOpen: player.morphTargets.mouthOpen,
          jawLeft: player.morphTargets.jawLeft,
          jawRight: player.morphTargets.jawRight,
          lipRound: player.morphTargets.lipRound,
          lipSmile: player.morphTargets.smile,
          lipWide: player.morphTargets.smile,
          cheekPuff: player.morphTargets.cheekPuff,
          tongueOut: player.morphTargets.tongueOut,
          tongueLeft: player.morphTargets.tongueLeft,
          tongueRight: player.morphTargets.tongueRight,
        })}
      />

      <ExerciseControls
        steps={player.steps.map((step) => ({
          id: step.id,
          name: step.koreanName,
        }))}
        stepIndex={player.stepIndex}
        currentExerciseName={player.currentStep.koreanName}
        countdown={player.countdown}
        isPlaying={player.isPlaying}
        speed={player.speed}
        stepMode={player.stepMode}
        loop={player.loopMode}
        labels={{
          eyebrow: "현재 호흡훈련",
          play: "재생",
          pause: "일시정지",
          restart: "처음부터",
          speed: "속도",
          stepMode: "단계별 모드",
          loop: "반복 모드",
          stepsAria: "호흡훈련 단계",
        }}
        onPlayPause={() => player.setIsPlaying(!player.isPlaying)}
        onRestart={player.restart}
        onSpeedChange={player.setSpeed}
        onStepModeChange={player.setStepMode}
        onLoopChange={player.setLoopMode}
        onStepSelect={player.goToStep}
      />
    </section>
  );
}
