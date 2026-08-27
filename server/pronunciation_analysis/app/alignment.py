"""Dependency-free CTC Viterbi alignment for unit and integration tests."""

from __future__ import annotations

import math


def ctc_viterbi(log_probabilities: list[list[float]], tokens: list[int], blank: int = 0) -> list[tuple[int, int]]:
    if not log_probabilities or not tokens:
        return []
    states: list[int] = [blank]
    for token in tokens:
        states.extend((token, blank))
    negative = -math.inf
    previous = [negative] * len(states)
    previous[0] = log_probabilities[0][blank]
    if len(states) > 1:
        previous[1] = log_probabilities[0][states[1]]
    paths: list[list[int]] = [[0] * len(states)]
    for frame in range(1, len(log_probabilities)):
        current = [negative] * len(states)
        back = [0] * len(states)
        for state, token in enumerate(states):
            candidates = [(previous[state], state)]
            if state > 0:
                candidates.append((previous[state - 1], state - 1))
            if state > 1 and token != blank and token != states[state - 2]:
                candidates.append((previous[state - 2], state - 2))
            best_score, best_state = max(candidates)
            current[state] = best_score + log_probabilities[frame][token]
            back[state] = best_state
        previous = current
        paths.append(back)
    state = max(range(max(1, len(states) - 2), len(states)), key=previous.__getitem__)
    state_path = [state]
    for frame in range(len(paths) - 1, 0, -1):
        state = paths[frame][state]
        state_path.append(state)
    state_path.reverse()
    spans = []
    for token_index in range(len(tokens)):
        target_state = token_index * 2 + 1
        frames = [index for index, state in enumerate(state_path) if state == target_state]
        spans.append((min(frames), max(frames) + 1) if frames else (-1, -1))
    return spans
