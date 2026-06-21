/**
 * In-round pause clock (specs.md §Round States: "Pause/resume supported").
 *
 * Translates wall-clock `now` into "round time" that freezes while paused, so a
 * paused round resumes exactly where it left off instead of skipping ahead by the
 * paused wall-clock span. Pure and time-injected so it is fully unit-testable
 * without Babylon/DOM; the pause button + overlay wiring is thin glue in main.ts.
 *
 * Model: round time = `now - startNow - lostMs`, where `lostMs` accumulates every
 * paused span. While paused, `now` is clamped to the pause instant so elapsed
 * stops advancing.
 */

export interface PauseClock {
  /** True while the round is paused. */
  isPaused: () => boolean;
  /** Pause the round at wall-clock `now`. Idempotent: a second pause is ignored. */
  pause: (now: number) => void;
  /** Resume the round at wall-clock `now`, banking the paused span. No-op if not paused. */
  resume: (now: number) => void;
  /** Round time (ms since start) at wall-clock `now`, with paused spans subtracted out. */
  elapsed: (now: number) => number;
}

export function createPauseClock(startNow: number): PauseClock {
  let pausedAt: number | null = null;
  let lostMs = 0;
  return {
    isPaused: () => pausedAt !== null,
    pause: (now: number) => {
      if (pausedAt === null) pausedAt = now;
    },
    resume: (now: number) => {
      if (pausedAt !== null) {
        lostMs += now - pausedAt;
        pausedAt = null;
      }
    },
    // While paused, clamp `now` to the pause instant so elapsed is frozen.
    elapsed: (now: number) => (pausedAt ?? now) - startNow - lostMs,
  };
}
