import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  MorphTargetValues,
  mouthExerciseSteps,
  neutralMorphTargets,
} from "../data/mouthExerciseSteps";

type UseExerciseAnimationOptions = {
  stepModeInitial?: boolean;
};

export function useExerciseAnimation(options: UseExerciseAnimationOptions = {}) {
  const [isPlaying, setIsPlaying] = useState(true);
  const [stepMode, setStepMode] = useState(options.stepModeInitial ?? false);
  const [speed, setSpeed] = useState(1);
  const [stepIndex, setStepIndex] = useState(0);
  const [stepElapsed, setStepElapsed] = useState(0);
  const lastTimeRef = useRef<number | null>(null);

  const currentStep = mouthExerciseSteps[stepIndex];
  const countdown = Math.max(
    0,
    Math.ceil(currentStep.durationSeconds - stepElapsed),
  );

  const restart = useCallback(() => {
    setStepIndex(0);
    setStepElapsed(0);
    setIsPlaying(true);
    lastTimeRef.current = null;
  }, []);

  const goToStep = useCallback((index: number) => {
    setStepIndex(index);
    setStepElapsed(0);
    lastTimeRef.current = null;
  }, []);

  const nextStep = useCallback(() => {
    setStepIndex((index) => (index + 1) % mouthExerciseSteps.length);
    setStepElapsed(0);
    lastTimeRef.current = null;
  }, []);

  useEffect(() => {
    let frame = 0;

    const tick = (time: number) => {
      if (isPlaying) {
        if (lastTimeRef.current == null) {
          lastTimeRef.current = time;
        }
        const delta = ((time - lastTimeRef.current) / 1000) * speed;
        lastTimeRef.current = time;
        setStepElapsed((elapsed) => {
          const nextElapsed = elapsed + delta;
          if (nextElapsed < currentStep.durationSeconds) {
            return nextElapsed;
          }
          if (stepMode) {
            setIsPlaying(false);
            return currentStep.durationSeconds;
          }
          setStepIndex((index) => (index + 1) % mouthExerciseSteps.length);
          return 0;
        });
      } else {
        lastTimeRef.current = null;
      }

      frame = requestAnimationFrame(tick);
    };

    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [currentStep.durationSeconds, isPlaying, speed, stepMode]);

  const morphTargets = useMemo<MorphTargetValues>(() => {
    const target = {
      ...neutralMorphTargets,
      ...currentStep.morphTargets,
    };
    const progress = currentStep.durationSeconds === 0
      ? 1
      : Math.min(1, stepElapsed / currentStep.durationSeconds);
    const ease = 0.5 - Math.cos(progress * Math.PI) / 2;

    return Object.fromEntries(
      Object.entries(target).map(([key, value]) => [key, value * ease]),
    ) as MorphTargetValues;
  }, [currentStep, stepElapsed]);

  return {
    steps: mouthExerciseSteps,
    currentStep,
    stepIndex,
    isPlaying,
    setIsPlaying,
    restart,
    nextStep,
    goToStep,
    speed,
    setSpeed,
    stepMode,
    setStepMode,
    countdown,
    morphTargets,
  };
}
