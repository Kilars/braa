import { MarkResult, NORMAL_DELTAS } from './mark';

export const CONFUSE_MS = 3000;

export interface SessionState {
  learned: number;
  confusedUntil: number | null;
  mastered: boolean;
}

export const newSession = (): SessionState => ({
  learned: 0,
  confusedUntil: null,
  mastered: false,
});

export function applyMark(
  state: SessionState,
  result: MarkResult,
  now: number,
  deltas: Record<MarkResult, number> = NORMAL_DELTAS,
): SessionState {
  const learned = Math.max(0, Math.min(100, state.learned + deltas[result]));
  const confusedUntil =
    result === 'FALSE_MARK' ? now + CONFUSE_MS : state.confusedUntil;
  return { learned, confusedUntil, mastered: learned >= 100 };
}

export const isConfused = (s: SessionState, now: number): boolean =>
  s.confusedUntil !== null && now < s.confusedUntil;
