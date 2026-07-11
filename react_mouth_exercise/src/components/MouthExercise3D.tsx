import { ExerciseControls } from "./ExerciseControls";
import { useExerciseAnimation } from "../hooks/useExerciseAnimation";
import { mergeRig } from "../data/facialRig";
import { ProfessionalAvatarStage } from "./ProfessionalAvatarStage";

export function MouthExercise3D() {
  const exercise = useExerciseAnimation();

  return (
    <section className="mouth-exercise-shell">
      <ProfessionalAvatarStage
        closeUp={exercise.currentStep.id !== "relaxed"}
        rig={mergeRig({
          mouthOpen: exercise.morphTargets.mouthOpen,
          jawOpen: exercise.morphTargets.mouthOpen,
          jawLeft: exercise.morphTargets.jawLeft,
          jawRight: exercise.morphTargets.jawRight,
          lipWide: exercise.morphTargets.smile,
          lipSmile: exercise.morphTargets.smile,
          lipRound: exercise.morphTargets.lipsPucker,
          cheekPuff:
            (exercise.morphTargets.cheekPuffLeft +
              exercise.morphTargets.cheekPuffRight) /
            2,
        })}
        ariaLabel="전문 GLB 강사 입 운동 애니메이션"
      />

      <ExerciseControls
        steps={exercise.steps}
        stepIndex={exercise.stepIndex}
        currentExerciseName={exercise.currentStep.name}
        countdown={exercise.countdown}
        isPlaying={exercise.isPlaying}
        speed={exercise.speed}
        stepMode={exercise.stepMode}
        onPlayPause={() => exercise.setIsPlaying(!exercise.isPlaying)}
        onRestart={exercise.restart}
        onSpeedChange={exercise.setSpeed}
        onStepModeChange={exercise.setStepMode}
        onStepSelect={exercise.goToStep}
      />
    </section>
  );
}
