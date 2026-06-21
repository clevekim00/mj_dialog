import { useCallback, useEffect, useRef, useState } from "react";
import { OralExerciseStep } from "../data/oralAlternatingSteps";

type UsePronunciationAudioOptions = {
  step: OralExerciseStep;
  enabled: boolean;
};

export function usePronunciationAudio({
  step,
  enabled,
}: UsePronunciationAudioOptions) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [muted, setMuted] = useState(false);
  const [hasUserInteracted, setHasUserInteracted] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  const markUserInteracted = useCallback(() => {
    setHasUserInteracted(true);
    setNotice(null);
  }, []);

  const stopCurrentAudio = useCallback(() => {
    audioRef.current?.pause();
    audioRef.current = null;
    if ("speechSynthesis" in window) {
      window.speechSynthesis.cancel();
    }
  }, []);

  const speak = useCallback(async () => {
    if (!step.pronunciation || muted || !enabled) {
      return;
    }
    if (!hasUserInteracted) {
      setNotice("브라우저 정책상 먼저 재생 버튼을 누르면 발음 소리가 재생됩니다.");
      return;
    }

    stopCurrentAudio();
    setNotice(null);

    if (step.audioSrc) {
      try {
        const audio = new Audio(step.audioSrc);
        audioRef.current = audio;
        await audio.play();
        return;
      } catch {
        setNotice("오디오 파일을 재생할 수 없어 음성 합성으로 대체합니다.");
      }
    }

    if ("speechSynthesis" in window) {
      const utterance = new SpeechSynthesisUtterance(step.pronunciation);
      utterance.lang = "ko-KR";
      utterance.rate = 0.82;
      utterance.pitch = 1.02;
      window.speechSynthesis.speak(utterance);
      return;
    }

    setNotice("이 브라우저에서는 발음 오디오를 사용할 수 없습니다.");
  }, [enabled, hasUserInteracted, muted, step, stopCurrentAudio]);

  useEffect(() => {
    void speak();
    return stopCurrentAudio;
  }, [speak, stopCurrentAudio]);

  return {
    muted,
    setMuted,
    notice,
    markUserInteracted,
    replay: speak,
  };
}
