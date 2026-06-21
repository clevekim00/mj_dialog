import { ExerciseControls } from "./ExerciseControls";
import { useOralAlternatingPlayer } from "../hooks/useExercisePlayer";
import { usePronunciationAudio } from "../hooks/usePronunciationAudio";
import { mergeRig } from "../data/facialRig";
import { ProfessionalAvatarStage } from "./ProfessionalAvatarStage";

export type OralAlternatingExercise3DProps = {
  autoPlay?: boolean;
  loop?: boolean;
  defaultSpeed?: number;
  onStepChange?: (stepIndex: number, stepId: string) => void;
  onComplete?: () => void;
};

export function OralAlternatingExercise3D({
  autoPlay = false,
  loop = true,
  defaultSpeed = 1,
  onStepChange,
  onComplete,
}: OralAlternatingExercise3DProps) {
  const player = useOralAlternatingPlayer({
    autoPlay,
    loop,
    defaultSpeed,
    onStepChange,
    onComplete,
  });
  const audio = usePronunciationAudio({
    step: player.currentStep,
    enabled: player.isPlaying,
  });

  const handlePlayPause = () => {
    audio.markUserInteracted();
    player.setIsPlaying(!player.isPlaying);
  };

  const handleRestart = () => {
    audio.markUserInteracted();
    player.restart();
  };

  return (
    <section
      className="mouth-exercise-shell"
      aria-label="연속 교대 구강운동 3D 애니메이션"
    >
      <ProfessionalAvatarStage
        closeUp={Boolean(player.currentStep.pronunciation)}
        ariaLabel="전문 GLB 강사 연속 교대 구강운동 애니메이션"
        rig={mergeRig({
          mouthOpen: player.morphTargets.mouthOpen,
          mouthClose: player.morphTargets.mouthClose,
          jawOpen: Math.max(
            player.morphTargets.mouthOpen,
            player.morphTargets.jawOpen,
          ),
          jawForward: player.morphTargets.jawForward,
          jawLeft: player.morphTargets.jawLeft,
          jawRight: player.morphTargets.jawRight,
          lipWide: player.morphTargets.lipWide,
          lipRound: player.morphTargets.lipRound,
          lipSmile: Math.max(
            player.morphTargets.lipSmile,
            player.morphTargets.lipWide * 0.35,
          ),
          lipPress: player.morphTargets.lipPress,
          lipCornerUp: player.morphTargets.lipCornerUp,
          cheekPuff: player.morphTargets.cheekPuff,
          tongueOut: player.morphTargets.tongueOut,
          tongueUp: player.morphTargets.tongueUp,
          tongueDown: player.morphTargets.tongueDown,
          tongueLeft: player.morphTargets.tongueLeft,
          tongueRight: player.morphTargets.tongueRight,
          tongueCurl: player.morphTargets.tongueCurl,
          tongueTipUp: player.morphTargets.tongueTipUp,
          cheekRaise: Math.max(
            player.morphTargets.cheekRaise,
            player.morphTargets.lipWide * 0.2,
          ),
          browRaise: player.isPlaying ? 0.08 : 0,
        })}
      />

      <ExerciseControls
        steps={player.steps.map((step) => ({
          id: step.id,
          name: step.titleKo,
        }))}
        stepIndex={player.stepIndex}
        currentExerciseName={player.currentStep.titleKo}
        pronunciationText={player.currentStep.pronunciation}
        countdown={player.countdown}
        isPlaying={player.isPlaying}
        speed={player.speed}
        stepMode={player.stepMode}
        loop={player.loopMode}
        muted={audio.muted}
        audioNotice={audio.notice}
        labels={{
          eyebrow: "현재 연속 교대운동",
          play: "재생",
          pause: "일시정지",
          restart: "처음부터",
          speed: "속도",
          stepMode: "단계별 모드",
          loop: "반복 모드",
          mute: "음소거",
          unmute: "소리 켜기",
          replay: "발음 다시 듣기",
          pronunciation: "현재 발음",
          stepsAria: "연속 교대운동 단계",
        }}
        onPlayPause={handlePlayPause}
        onRestart={handleRestart}
        onSpeedChange={player.setSpeed}
        onStepModeChange={player.setStepMode}
        onLoopChange={player.setLoopMode}
        onMuteToggle={() => audio.setMuted(!audio.muted)}
        onReplayPronunciation={() => {
          audio.markUserInteracted();
          void audio.replay();
        }}
        onStepSelect={(index) => {
          audio.markUserInteracted();
          player.goToStep(index);
        }}
      />
    </section>
  );
}
