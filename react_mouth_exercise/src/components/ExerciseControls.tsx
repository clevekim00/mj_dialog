type ControlStep = {
  id: string;
  name: string;
};

type ExerciseControlsProps = {
  steps: ControlStep[];
  stepIndex: number;
  currentExerciseName: string;
  countdown: number;
  isPlaying: boolean;
  speed: number;
  stepMode: boolean;
  loop?: boolean;
  pronunciationText?: string;
  muted?: boolean;
  audioNotice?: string | null;
  labels?: {
    eyebrow?: string;
    play?: string;
    pause?: string;
    restart?: string;
    speed?: string;
    stepMode?: string;
    loop?: string;
    mute?: string;
    unmute?: string;
    replay?: string;
    pronunciation?: string;
    stepsAria?: string;
  };
  onPlayPause: () => void;
  onRestart: () => void;
  onSpeedChange: (speed: number) => void;
  onStepModeChange: (enabled: boolean) => void;
  onLoopChange?: (enabled: boolean) => void;
  onMuteToggle?: () => void;
  onReplayPronunciation?: () => void;
  onStepSelect: (index: number) => void;
};

export function ExerciseControls({
  steps,
  stepIndex,
  currentExerciseName,
  countdown,
  isPlaying,
  speed,
  stepMode,
  loop,
  pronunciationText,
  muted,
  audioNotice,
  labels,
  onPlayPause,
  onRestart,
  onSpeedChange,
  onStepModeChange,
  onLoopChange,
  onMuteToggle,
  onReplayPronunciation,
  onStepSelect,
}: ExerciseControlsProps) {
  const text = {
    eyebrow: "현재 운동",
    play: "재생",
    pause: "일시정지",
    restart: "처음부터",
    speed: "속도",
    stepMode: "단계별 모드",
    loop: "반복 재생",
    mute: "음소거",
    unmute: "소리 켜기",
    replay: "발음 다시 듣기",
    pronunciation: "현재 발음",
    stepsAria: "운동 단계",
    ...labels,
  };

  return (
    <aside className="exercise-controls" aria-label="운동 재생 컨트롤">
      <div className="exercise-status">
        <span className="eyebrow">{text.eyebrow}</span>
        <h2>{currentExerciseName}</h2>
        <strong aria-label={`남은 시간 ${countdown}초`}>{countdown}s</strong>
        {pronunciationText ? (
          <p className="pronunciation-text" aria-label={text.pronunciation}>
            {pronunciationText}
          </p>
        ) : null}
      </div>

      <div className="control-row">
        <button
          type="button"
          onClick={onPlayPause}
          aria-label={isPlaying ? text.pause : text.play}
        >
          {isPlaying ? text.pause : text.play}
        </button>
        <button type="button" onClick={onRestart} aria-label={text.restart}>
          {text.restart}
        </button>
      </div>

      {(onMuteToggle || onReplayPronunciation) && (
        <div className="control-row">
          {onMuteToggle ? (
            <button
              type="button"
              onClick={onMuteToggle}
              aria-label={muted ? text.unmute : text.mute}
            >
              {muted ? text.unmute : text.mute}
            </button>
          ) : null}
          {onReplayPronunciation ? (
            <button
              type="button"
              onClick={onReplayPronunciation}
              disabled={!pronunciationText || muted}
              aria-label={text.replay}
            >
              {text.replay}
            </button>
          ) : null}
        </div>
      )}

      {audioNotice ? <p className="audio-notice">{audioNotice}</p> : null}

      <label className="range-control">
        <span>
          {text.speed} {speed.toFixed(1)}x
        </span>
        <input
          aria-label={text.speed}
          type="range"
          min="0.5"
          max="2"
          step="0.25"
          value={speed}
          onChange={(event) => onSpeedChange(Number(event.target.value))}
        />
      </label>

      <label className="toggle-control">
        <input
          aria-label={text.stepMode}
          type="checkbox"
          checked={stepMode}
          onChange={(event) => onStepModeChange(event.target.checked)}
        />
        <span>{text.stepMode}</span>
      </label>

      {onLoopChange ? (
        <label className="toggle-control">
          <input
            aria-label={text.loop}
            type="checkbox"
            checked={Boolean(loop)}
            onChange={(event) => onLoopChange(event.target.checked)}
          />
          <span>{text.loop}</span>
        </label>
      ) : null}

      <div className="step-list" aria-label={text.stepsAria}>
        {steps.map((step, index) => (
          <button
            key={step.id}
            type="button"
            className={index === stepIndex ? "active" : ""}
            aria-current={index === stepIndex ? "step" : undefined}
            onClick={() => onStepSelect(index)}
          >
            {step.name}
          </button>
        ))}
      </div>
    </aside>
  );
}
