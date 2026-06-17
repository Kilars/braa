import { MarkResult, classifyMark } from './mark';
import { SessionState, newSession, applyMark } from './session';
import { TimelineEvent, attemptAt } from './scheduler';

export interface RoundState {
  timeline: TimelineEvent[];
  session: SessionState;
  lastResult: MarkResult | null;
}

export const createRound = (timeline: TimelineEvent[]): RoundState => ({
  timeline,
  session: newSession(),
  lastResult: null,
});

export function markAt(state: RoundState, now: number): RoundState {
  const result = classifyMark(now, attemptAt(state.timeline, now));
  return { ...state, session: applyMark(state.session, result, now), lastResult: result };
}

export const isMastered = (s: RoundState): boolean => s.session.mastered;

/**
 * Swap in a fresh timeline (e.g. when a placeholder segment is exhausted) while
 * PRESERVING the learned-bar / session progress and last result. Progress must
 * never reset just because the behavior timeline looped.
 */
export const replaceTimeline = (state: RoundState, timeline: TimelineEvent[]): RoundState => ({
  ...state,
  timeline,
});
