import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  SpeechMorphTargets,
  neutralSpeechMorphTargets,
  speechExerciseSteps,
} from "../data/speechExerciseSteps";
import {
  OralMorphTargets,
  neutralOralMorphTargets,
  oralAlternatingSteps,
} from "../data/oralAlternatingSteps";
import { koreanVisemeMap } from "../data/koreanVisemes";
import type { FacialRigState } from "../data/facialRig";

type UseExercisePlayerOptions = {
  autoPlay?: boolean;
  loop?: boolean;
  defaultSpeed?: number;
  onStepChange?: (stepIndex: number, stepId: string) => void;
  onComplete?: () => void;
};

export function useExercisePlayer({
  autoPlay = true,
  loop = true,
  defaultSpeed = 1,
  onStepChange,
  onComplete,
}: UseExercisePlayerOptions = {}) {
  const [isPlaying, setIsPlaying] = useState(autoPlay);
  const [loopMode, setLoopMode] = useState(loop);
  const [stepMode, setStepMode] = useState(false);
  const [speed, setSpeed] = useState(defaultSpeed);
  const [stepIndex, setStepIndex] = useState(0);
  const [stepElapsed, setStepElapsed] = useState(0);
  const lastTimeRef = useRef<number | null>(null);
  const didCompleteRef = useRef(false);

  const currentStep = speechExerciseSteps[stepIndex];
  const countdown = Math.max(
    0,
    Math.ceil(currentStep.durationSeconds - stepElapsed),
  );

  const goToStep = useCallback((index: number) => {
    setStepIndex(index);
    setStepElapsed(0);
    lastTimeRef.current = null;
    didCompleteRef.current = false;
  }, []);

  const restart = useCallback(() => {
    setStepIndex(0);
    setStepElapsed(0);
    setIsPlaying(true);
    lastTimeRef.current = null;
    didCompleteRef.current = false;
  }, []);

  const complete = useCallback(() => {
    if (didCompleteRef.current) return;
    didCompleteRef.current = true;
    setIsPlaying(false);
    onComplete?.();
  }, [onComplete]);

  useEffect(() => {
    onStepChange?.(stepIndex, currentStep.id);
  }, [currentStep.id, onStepChange, stepIndex]);

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

          const isLastStep = stepIndex === speechExerciseSteps.length - 1;
          if (isLastStep && !loopMode) {
            complete();
            return currentStep.durationSeconds;
          }

          setStepIndex((index) => (index + 1) % speechExerciseSteps.length);
          return 0;
        });
      } else {
        lastTimeRef.current = null;
      }

      frame = requestAnimationFrame(tick);
    };

    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [
    complete,
    currentStep.durationSeconds,
    isPlaying,
    loopMode,
    speed,
    stepIndex,
    stepMode,
  ]);

  const morphTargets = useMemo<SpeechMorphTargets>(() => {
    const target = {
      ...neutralSpeechMorphTargets,
      ...currentStep.morphTargets,
    };
    const progress = currentStep.durationSeconds === 0
      ? 1
      : Math.min(1, stepElapsed / currentStep.durationSeconds);
    const ease = 0.5 - Math.cos(progress * Math.PI) / 2;
    const rhythmic = 0.65 + Math.sin(progress * Math.PI * 2) * 0.35;
    const tongueSwing = currentStep.id === "tongue-left-right"
      ? Math.sin(progress * Math.PI * 4)
      : 0;

    return {
      mouthOpen: target.mouthOpen * ease,
      smile: target.smile * ease,
      lipRound: target.lipRound * ease,
      jawLeft: target.jawLeft * Math.max(0, -tongueSwing),
      jawRight: target.jawRight * Math.max(0, tongueSwing),
      tongueOut: target.tongueOut * rhythmic,
      tongueLeft: currentStep.id === "tongue-left-right"
        ? Math.max(0, -tongueSwing)
        : target.tongueLeft * ease,
      tongueRight: currentStep.id === "tongue-left-right"
        ? Math.max(0, tongueSwing)
        : target.tongueRight * ease,
      cheekPuff: target.cheekPuff * rhythmic,
    };
  }, [currentStep, stepElapsed]);

  return {
    steps: speechExerciseSteps,
    currentStep,
    stepIndex,
    isPlaying,
    setIsPlaying,
    restart,
    goToStep,
    speed,
    setSpeed,
    stepMode,
    setStepMode,
    loopMode,
    setLoopMode,
    countdown,
    morphTargets,
  };
}

export function useOralAlternatingPlayer({
  autoPlay = false,
  loop = true,
  defaultSpeed = 1,
  onStepChange,
  onComplete,
}: UseExercisePlayerOptions = {}) {
  const [isPlaying, setIsPlaying] = useState(autoPlay);
  const [loopMode, setLoopMode] = useState(loop);
  const [stepMode, setStepMode] = useState(false);
  const [speed, setSpeed] = useState(defaultSpeed);
  const [stepIndex, setStepIndex] = useState(0);
  const [stepElapsedMs, setStepElapsedMs] = useState(0);
  const lastTimeRef = useRef<number | null>(null);
  const didCompleteRef = useRef(false);

  const currentStep = oralAlternatingSteps[stepIndex];
  const countdown = Math.max(
    0,
    Math.ceil((currentStep.durationMs - stepElapsedMs) / 1000),
  );

  const goToStep = useCallback((index: number) => {
    setStepIndex(index);
    setStepElapsedMs(0);
    lastTimeRef.current = null;
    didCompleteRef.current = false;
  }, []);

  const restart = useCallback(() => {
    setStepIndex(0);
    setStepElapsedMs(0);
    setIsPlaying(true);
    lastTimeRef.current = null;
    didCompleteRef.current = false;
  }, []);

  const complete = useCallback(() => {
    if (didCompleteRef.current) return;
    didCompleteRef.current = true;
    setIsPlaying(false);
    onComplete?.();
  }, [onComplete]);

  useEffect(() => {
    onStepChange?.(stepIndex, currentStep.id);
  }, [currentStep.id, onStepChange, stepIndex]);

  useEffect(() => {
    let frame = 0;

    const tick = (time: number) => {
      if (isPlaying) {
        if (lastTimeRef.current == null) {
          lastTimeRef.current = time;
        }
        const delta = (time - lastTimeRef.current) * speed;
        lastTimeRef.current = time;

        setStepElapsedMs((elapsed) => {
          const nextElapsed = elapsed + delta;
          if (nextElapsed < currentStep.durationMs) {
            return nextElapsed;
          }
          if (stepMode) {
            setIsPlaying(false);
            return currentStep.durationMs;
          }

          const isLastStep = stepIndex === oralAlternatingSteps.length - 1;
          if (isLastStep && !loopMode) {
            complete();
            return currentStep.durationMs;
          }

          setStepIndex((index) => (index + 1) % oralAlternatingSteps.length);
          return 0;
        });
      } else {
        lastTimeRef.current = null;
      }

      frame = requestAnimationFrame(tick);
    };

    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [
    complete,
    currentStep.durationMs,
    isPlaying,
    loopMode,
    speed,
    stepIndex,
    stepMode,
  ]);

  const morphTargets = useMemo<OralMorphTargets>(() => {
    const progress = currentStep.durationMs === 0
      ? 1
      : Math.min(1, stepElapsedMs / currentStep.durationMs);
    const ease = 0.5 - Math.cos(progress * Math.PI) / 2;
    const beat = 0.5 + Math.sin(progress * Math.PI * 6) * 0.5;
    const swing = Math.sin(progress * Math.PI * 4);
    const targets = { ...neutralOralMorphTargets };
    const applyPose = (pose: Partial<FacialRigState>, strength = 1) => {
      (Object.keys(targets) as (keyof OralMorphTargets)[]).forEach((key) => {
        const value = pose[key];
        if (value != null) {
          targets[key] = Math.max(targets[key], value * strength);
        }
      });
    };

    switch (currentStep.mouthShape) {
      case "open":
        applyPose(koreanVisemeMap["아"], ease);
        break;
      case "wideSmile":
        applyPose(koreanVisemeMap["이"], ease);
        break;
      case "round":
        applyPose(koreanVisemeMap["우"], ease);
        break;
      case "pataka":
        if (currentStep.id === "aiu") {
          const phase = Math.floor(progress * 6) % 3;
          applyPose(
            phase === 0
              ? koreanVisemeMap["아"]
              : phase === 1
                ? koreanVisemeMap["이"]
                : koreanVisemeMap["우"],
            0.9,
          );
        } else {
          const phase = Math.floor(progress * 9) % 3;
          applyPose(
            phase === 0
              ? koreanVisemeMap["ㅍ"]
              : phase === 1
                ? koreanVisemeMap["ㅌ"]
                : koreanVisemeMap["ㅋ"],
            0.92,
          );
          targets.mouthOpen = Math.max(targets.mouthOpen, 0.18 + beat * 0.22);
        }
        break;
      case "lala":
        applyPose(koreanVisemeMap["ㄹ"], 0.92);
        targets.mouthOpen = Math.max(targets.mouthOpen, 0.32);
        targets.tongueOut = 0.18 + beat * 0.18;
        targets.tongueTipUp = Math.max(targets.tongueTipUp, 0.55 + beat * 0.34);
        targets.tongueLeft = Math.max(0, -swing) * 0.25;
        targets.tongueRight = Math.max(0, swing) * 0.25;
        break;
      case "jawMove":
        targets.mouthOpen = 0.2;
        targets.jawLeft = Math.max(0, -swing);
        targets.jawRight = Math.max(0, swing);
        break;
      case "tongueMove":
        targets.mouthOpen = 0.36;
        targets.tongueOut = 0.45;
        targets.tongueLeft = Math.max(0, -swing);
        targets.tongueRight = Math.max(0, swing);
        break;
      case "neutral":
        targets.cheekPuff = currentStep.id === "relax" ? 0.05 * ease : 0;
        break;
    }

    return targets;
  }, [currentStep, stepElapsedMs]);

  return {
    steps: oralAlternatingSteps,
    currentStep,
    stepIndex,
    isPlaying,
    setIsPlaying,
    restart,
    goToStep,
    speed,
    setSpeed,
    stepMode,
    setStepMode,
    loopMode,
    setLoopMode,
    countdown,
    morphTargets,
  };
}
