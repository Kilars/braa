# FEATURE: Wire reward-latency into the live engagement meter

**Status**: Backlog · **Priority**: Medium · **Type**: FEATURE (completes a shipped v1 mechanic)
**Created**: 2026-06-19 (iteration 13 scan) · **Depends on**: none

## What
The engagement meter (task 098) implements **two** event kinds in its pure model, but
only one is fed from the live loop. `engagement(prev, { kind:'mark', result })` drives
the HUD mood meter today; `engagement(prev, { kind:'reward', latencyMs })` — the
**"slow rewards drain it"** half of the spec — is fully built and unit-tested in
`src/core/engagement.ts` but **never fired** in `main.ts`. This task wires it live so the
mood meter responds to *how promptly the player rewards* the dog, not just mark quality.

> specs.md §Mistakes → *Wrong-behavior beats & disengagement*: *"good timing keeps the
> dog eager; sloppy/false marks **or slow rewards** drain it…"*

## ⚠️ Discrepancy with 098's notes (recorded per the read-only-spec rule)
On-hold task 098 lists *"Wire the reward-latency event live"* under **"Remaining (still
blocked on 079 — real Labrador clips)."** That bundling is **over-broad**: the
reward-latency feed needs only timing data already in the loop — the active `Attempt`'s
apex (`attempt.peak` / window `start`) and the tap instant — **no Labrador clips**. The
HUD mood meter is a DOM element (not dog-rendered), so it can reflect the reward-latency
event immediately. Only the *on-dog* disengage beats / walk-away remain 079-gated. This
task carves the reward-latency feed out of that bundle; it does **not** touch the
079-gated on-dog work. (Do not edit specs.md; this note lives here + will be reflected in
tech-decisions §"Engagement Meter" on completion.)

## Why now
- It completes a **shipped-but-partial** v1 spec mechanic with a small, low-risk change —
  the pure reducer + its 13 tests already exist (`REWARD_SNAPPY_MS`, `REWARD_SLOW_MS`,
  `rewardLatencyDelta`); this is pure wiring + one integration helper.
- It is genuinely unblocked (corrects the 098 deferral), and "progressive — builds on
  what exists" is a selection criterion.
- Keeps the slate off the saturated quality/refactor domain.

## Technical Approach

`onBraTap` in `main.ts` already has everything needed at the mark site: the active
`attempt` (with `peak`/`start`) and `now`. On a **successful** mark (PERFECT/OK — i.e.
the player *did* reward a real behavior), compute how long after the apex the reward
landed and feed the reward event.

### 1. Pure helper (TDD) — `src/core/engagement.ts`
Add a small pure function that maps a successful mark's tap-vs-apex gap to a latency,
clamped at 0 (a tap *before* apex is "instant", not negative):

```ts
// NEW (pure)
/** ms from the apex to the reward tap; 0 if the tap pre-empted the apex. */
export function rewardLatencyMs(tapTime: number, apexTime: number): number {
  return Math.max(0, tapTime - apexTime);
}
```
(`rewardLatencyDelta` already turns this into the meter delta; keep it internal as-is.)

### 2. Live wiring — `src/main.ts` `onBraTap`
```ts
// BEFORE (~line 372)
engagementMeter = engagement(engagementMeter, { kind: 'mark', result });
```
```ts
// AFTER
engagementMeter = engagement(engagementMeter, { kind: 'mark', result });
// "Slow rewards drain it" (spec §Mistakes): on a real reward (PERFECT/OK), how
// promptly the player marked the apex nudges engagement too. Needs only timing —
// no dog clips (see task 100 note re: 098's over-broad 079 deferral).
if ((result === 'PERFECT' || result === 'OK') && attempt) {
  engagementMeter = engagement(engagementMeter, {
    kind: 'reward',
    latencyMs: rewardLatencyMs(now, attempt.peak),
  });
}
```

Notes:
- Only fire on PERFECT/OK: a MISS/FALSE_MARK is not a reward, and its drain is already
  applied by the `mark` event — firing reward-latency there would double-count.
- `attempt` is the resolved attempt from `resolvePhraseMark(...)`; guard for `null`.
- No new persisted state — engagement stays transient (resets to `ENGAGEMENT_FULL` each
  round), consistent with 098.

## TDD behaviors (write the failing test first)
- `rewardLatencyMs`: tap after apex → positive gap; tap before apex → `0` (clamped);
  tap exactly at apex → `0`.
- Composition guard: a snappy PERFECT (small latency) yields a **net** engagement gain
  ≥ the mark-only delta; a deliberately slow OK (latency ≥ `REWARD_SLOW_MS`) yields less
  than the mark-only delta (the latency drain bites). Assert via the public
  `engagement(...)` reducer, not internals.

## Out of scope
- All **on-dog** disengage beats, walk-away/call-back — those stay 079-gated in task 098.
- Persisting engagement (intentionally transient).
- Any retuning of the latency constants (they are documented placeholders).

## Acceptance criteria
- [ ] `rewardLatencyMs` added to `src/core/engagement.ts`, written **test-first** (`tdd`
      skill: red → green → refactor).
- [ ] `main.ts` fires the `{ kind:'reward', latencyMs }` event on PERFECT/OK marks only,
      using the active attempt's apex; MISS/FALSE_MARK do **not** fire it.
- [ ] A test proves slow-but-correct marks net less engagement than snappy ones, through
      the public reducer.
- [ ] The HUD mood meter visibly responds to reward latency (a `__setEngagement`-free
      check: drive a slow vs. fast successful mark and observe the meter differ). Note:
      this is logic-verifiable; no Visual Review screenshot required beyond confirming
      the meter still renders.
- [ ] tech-decisions.md §"Engagement Meter + Disengage Beats" updated: reward-latency is
      now wired live; note that it required no 079 dependency (corrects 098's bundling).
- [ ] Gate green: `bun run typecheck` · `bun run test` · `bun run build` (no warnings) ·
      `bun run e2e`.
