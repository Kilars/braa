/**
 * Centralized numeric tunables — the single home for the game's balance knobs.
 *
 * Mirrors the audited constant table in tech-decisions.md §8. A tuner edits the
 * values here; domain modules import them by name (and may thinly re-export a
 * name that is imported widely, to keep call-sites stable).
 *
 * INVARIANT: this module imports NOTHING from `src/core/*` (or anywhere in the
 * app) — it sits at the bottom of the dependency graph so there can be no import
 * cycles. Exports are primitive numbers plus a few small constant tables
 * (`Record`/`as const` objects) whose key types are written inline so this file
 * stays import-free.
 */

// ── Difficulty: NORMAL mode (src/core/difficulty.ts) ─────────────────────────
export const NORMAL_WINDOW_WIDTH_MS = 400;  // scoring window (tap here → OK/PERFECT)
export const NORMAL_PEAK_RADIUS_MS = 80;    // half-width of the PERFECT sub-band
export const NORMAL_DISTRACTOR_RATE = 0.2;  // distractor probability between attempts
export const NORMAL_TELL_INTENSITY = 1;     // apex pulse strength (1 = clearest)
export const NORMAL_REWARD_MULT = 1;        // mastery payout scalar

// ── Difficulty: HARD mode (src/core/difficulty.ts) ───────────────────────────
export const HARD_WINDOW_WIDTH_MS = 280;    // tighter than NORMAL 400
export const HARD_PEAK_RADIUS_MS = 50;      // tighter than NORMAL 80
export const HARD_DISTRACTOR_RATE = 0.45;   // higher than NORMAL 0.2
export const HARD_TELL_INTENSITY = 0.6;     // fainter than NORMAL 1
export const HARD_REWARD_MULT = 1.3;        // higher than NORMAL 1
export const HARD_FALSE_MARK_DELTA = -8;    // harsher than NORMAL -4

// ── Difficulty: EXPERT mode (src/core/difficulty.ts) ─────────────────────────
export const EXPERT_WINDOW_WIDTH_MS = 160;  // tighter than HARD 280
export const EXPERT_PEAK_RADIUS_MS = 25;    // tighter than HARD 50
export const EXPERT_DISTRACTOR_RATE = 0.55; // higher than HARD 0.45
export const EXPERT_TELL_INTENSITY = 0.3;   // fainter than HARD 0.6
export const EXPERT_REWARD_MULT = 2.5;      // higher than HARD 1.3
export const EXPERT_FALSE_MARK_DELTA = -10; // harsher than HARD -8

// ── Difficulty: false-mark confuse debuff (src/core/difficulty.ts) ───────────
export const CONFUSE_WINDOW_MULT = 0.6;     // window narrows ≈ −40%
export const CONFUSE_DISTRACTOR_MULT = 1.5; // distractors increase ≈ +50%

// ── Learned-bar deltas: NORMAL baseline (src/core/mark.ts) ───────────────────
// Reference deltas (spec: "PERFECT +8% OK +3% miss +0% false mark -4%"). HARD/
// EXPERT only override FALSE_MARK above. Keys written inline = `MarkResult`.
export const NORMAL_DELTAS: Record<'PERFECT' | 'OK' | 'MISS' | 'FALSE_MARK', number> = {
  PERFECT: 8,
  OK: 3,
  MISS: 0,
  FALSE_MARK: -4,
};

// ── Engagement: per-mark deltas (src/core/engagement.ts) ─────────────────────
// Good timing refills; sloppy/false marks drain. Keys written inline = `MarkResult`.
export const MARK_ENGAGEMENT_DELTA: Record<'PERFECT' | 'OK' | 'MISS' | 'FALSE_MARK', number> = {
  PERFECT: 0.15,
  OK: 0.08,
  MISS: -0.06,
  FALSE_MARK: -0.2,
};

// ── Engagement: reward-latency feed (src/core/engagement.ts) ─────────────────
export const REWARD_SNAPPY_MS = 800;     // at/under → max refill
export const REWARD_SLOW_MS = 2400;      // at/over  → max drain
export const REWARD_SNAPPY_REFILL = 0.05;
export const REWARD_SLOW_DRAIN = -0.15;

// ── Disengagement: call-back (src/core/disengage.ts) ─────────────────────────
export const CALL_BACK_ENGAGEMENT = 0.5; // level a call-back tap restores → 'itch' band

// ── Scheduler: base timing (src/app/gameHelpers.ts) ──────────────────────────
// Applied before any difficulty/breed/trick overrides spread on top.
export const BASE_SCHEDULER_TIMING = {
  attemptInterval: 2000, // 2 s between correct attempts
  activeSpan: 800,       // behavior visible for 800 ms
} as const;

// ── App-level (src/main.ts) ──────────────────────────────────────────────────
export const PANT_INTERVAL_MS = 7000;       // min ms between idle foley pants
export const TIMELINE_EVENTS = 20;          // events per segment; loops on exhaustion

// ── HUD UX timing (src/ui/hud.ts) ────────────────────────────────────────────
export const RESULT_FLASH_MS = 700;         // how long the post-mark result flash holds
