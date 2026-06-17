import { Attempt } from './mark';

export interface SchedulerConfig {
  attemptInterval: number; // ms between correct attempts
  activeSpan: number;      // ms the behavior is visibly held
  windowWidth: number;     // ms scoring window (<= activeSpan)
  peakRadius: number;      // ms PERFECT band half-width
  distractorRate: number;  // 0..1 chance of a distractor between attempts
}

export interface TimelineEvent {
  kind: 'attempt' | 'distractor';
  activeStart: number;
  activeEnd: number;
  attempt?: Attempt;       // present when kind === 'attempt'
}

export function buildTimeline(
  cfg: SchedulerConfig,
  rng: () => number,
  count: number,
): TimelineEvent[] {
  const events: TimelineEvent[] = [];
  let cursor = 0;

  for (let i = 0; i < count; i++) {
    // Optionally insert a distractor before the next correct attempt
    // (skip before the first attempt — distractors fill the gap between attempts)
    if (i > 0 && rng() < cfg.distractorRate) {
      // The distractor occupies a slot of activeSpan length in the idle gap
      // between the previous activeEnd and the upcoming activeStart.
      // Place it starting at cursor - attemptInterval + activeSpan (the idle gap start).
      const idleGapStart = cursor - cfg.attemptInterval + cfg.activeSpan;
      const distractorStart = idleGapStart;
      const distractorEnd = distractorStart + cfg.activeSpan;
      events.push({
        kind: 'distractor',
        activeStart: distractorStart,
        activeEnd: distractorEnd,
      });
    }

    const activeStart = cursor;
    const activeEnd = activeStart + cfg.activeSpan;

    // Center the scoring window within the active span
    const windowOffset = (cfg.activeSpan - cfg.windowWidth) / 2;
    const start = activeStart + windowOffset;
    const end = start + cfg.windowWidth;
    const peak = (start + end) / 2;

    events.push({
      kind: 'attempt',
      activeStart,
      activeEnd,
      attempt: { start, end, peak, peakRadius: cfg.peakRadius },
    });

    cursor += cfg.attemptInterval;
  }

  return events;
}

export function distractorActiveAt(timeline: TimelineEvent[], now: number): boolean {
  for (const event of timeline) {
    if (event.kind === 'distractor' && now >= event.activeStart && now <= event.activeEnd) {
      return true;
    }
  }
  return false;
}

export function attemptAt(timeline: TimelineEvent[], now: number): Attempt | null {
  for (const event of timeline) {
    if (event.kind === 'attempt' && now >= event.activeStart && now <= event.activeEnd) {
      return event.attempt ?? null;
    }
  }
  return null;
}

/**
 * Untraining inversion: the markable window is the CALM gap — a period when
 * neither an attempt nor a distractor is active. The bad-habit (distractor)
 * window is NOT markable (returns null), same for normal attempt windows.
 *
 * Calm gaps are derived from the sorted event boundaries:
 *   [0, firstEventStart), [event1End, event2Start), ... for all sorted events.
 * Only gaps longer than a minimum threshold (100 ms) are considered markable.
 */
export function untrainAttemptAt(timeline: TimelineEvent[], now: number): Attempt | null {
  if (timeline.length === 0) return null;

  // During a distractor or attempt window → not markable
  if (distractorActiveAt(timeline, now)) return null;
  if (attemptAt(timeline, now) !== null) return null;

  // Find the calm gap containing `now`
  // Collect all event spans, sorted by start
  const spans = timeline
    .map(ev => ({ start: ev.activeStart, end: ev.activeEnd }))
    .sort((a, b) => a.start - b.start);

  // Find the gap boundaries around `now`
  // The gap starts at the end of the last event before `now` (or 0),
  // and ends at the start of the next event after `now` (or Infinity).
  let gapStart = 0;
  let gapEnd = Infinity;

  for (const span of spans) {
    if (span.end <= now) {
      // This event ended before now — it might define the left boundary of the gap
      if (span.end > gapStart) gapStart = span.end;
    } else if (span.start > now) {
      // This event starts after now — it defines the right boundary
      if (span.start < gapEnd) gapEnd = span.start;
      break; // spans are sorted, no need to continue
    }
  }

  // Must be a finite gap of at least 100 ms to be meaningful
  if (gapEnd === Infinity || gapEnd - gapStart < 100) return null;

  // Derive an Attempt that covers the calm gap
  const peak = (gapStart + gapEnd) / 2;
  const peakRadius = Math.min(80, (gapEnd - gapStart) / 4);
  return { start: gapStart, end: gapEnd, peak, peakRadius };
}
