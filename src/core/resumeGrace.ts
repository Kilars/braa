/**
 * Mobile resume grace (specs.md §Mistakes → Mobile grace).
 *
 * Taps in the brief moment right after the app returns to the foreground are
 * ignored, so a notification dismiss, lock-screen wake, or fat-finger never lands
 * as a false mark + confuse. The policy is a pure function of time so it can be
 * unit-tested; the `visibilitychange` wiring that stamps `resumedAt` is thin DOM glue.
 */

/** Taps within this window (ms) after the app returns to the foreground are ignored. */
export const RESUME_GRACE_MS = 400;

/**
 * True if `now` falls inside the resume-grace window started at `resumedAt`.
 * Half-open: a tap exactly `graceMs` after resume is allowed. A never-resumed
 * sentinel (`resumedAt = -Infinity`) is always outside the window.
 */
export function isWithinResumeGrace(now: number, resumedAt: number, graceMs = RESUME_GRACE_MS): boolean {
  return now - resumedAt < graceMs;
}
