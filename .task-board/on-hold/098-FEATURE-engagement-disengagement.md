# FEATURE: Engagement meter + wrong-behavior / walk-away beats

**Status**: On-hold (pure model + HUD meter DELIVERED; dog-behavior beats + walk-away
blocked on 079) · **Priority**: Medium · **Depends on**: 079 (imported dog anims)
**Created**: 2026-06-19 · **Partially delivered**: 2026-06-19 (iteration 12)

## What
Give the dog personality when training goes badly (specs.md → Mistakes →
*Wrong-behavior beats & disengagement*). An **engagement meter** drains on
sloppy/false marks or slow rewards and refills on good timing; the dog's offered
wrong-behaviors escalate with it.

## Scope
- **Pure first (TDD):** `engagement(prev, event)` reducer (mark quality / false-mark /
  reward latency → 0..1) + `disengageBeat(level)` mapping the meter to a beat
  (`itch → flop → bark → walk-off`). No Babylon in the pure layer.
- **Wire:** drive the existing distractor/`misbehaving` visual states from the chosen
  beat using the real Labrador clips (`scratch ear`, `dig`, `bark`, `lie`, `trot`+`turn 180`).
- **Walk-away state:** at empty meter the dog trots to frame edge, back-turned; player
  taps to **call back** (costs tempo/combo); auto-returns after a beat.

## Out of scope
Per-bone retarget (epic phase 2). `pissing`/`defecation` = optional rare gag only.

## Done when
Pure reducers TDD-covered; meter visibly reflects play; walk-away + call-back works;
`bun run verify` + e2e green; Visual Review of the beats.

---

## Delivered (iteration 12, 2026-06-19) — the unblocked slice

The **"Pure first" layer is complete and TDD-covered**, and the meter is now
**visibly wired into live play** (the dog-behavior expression awaits 079's real
clips — see Remaining). Gate green: typecheck 0 · 662 tests · build clean · e2e PASS.

- **`src/core/engagement.ts` (pure, 13 tests):**
  - `engagement(prev, event)` — clamped 0..1 reducer. Events: `{kind:'mark', result}`
    (PERFECT +0.15 / OK +0.08 / MISS −0.06 / FALSE_MARK −0.2) and
    `{kind:'reward', latencyMs}` (snappy ≤800ms → +0.05, slow ≥2400ms → −0.15,
    linear between). Both event kinds covered; reward-latency is available but only
    mark-quality is wired live this iteration (see Remaining).
  - `disengageBeat(level)` → `engaged → itch → flop → bark → walk-off` (thresholds
    0.75 / 0.5 / 0.25 / 0; monotonic, spec escalation order).
- **Live wiring (`main.ts`):** a runtime `engagementMeter` (starts full each round,
  not persisted — a transient session feel like `combo`), updated on every mark,
  threaded through `toViewModel(...)` → HUD. Dev hook `window.__setEngagement(0..1)`
  for screenshots.
- **HUD mood meter (`hud.ts` + `hud.css`):** a top-right pill stacked under coins/level
  in a shared `#hud-stats-cluster`; fill width = meter, colour escalates with the beat
  (green→yellow-green→amber→orange→red), red-tinted empty track + gentle pulse at
  walk-off. Revealed at the economy stage (with stats). `role="meter"` + aria values;
  reduced-motion handled. **Visual Review: PASS** after two rounds — fixed a mid-screen
  float (cluster wrapper), an invisible track (lightened groove), an empty walk-off with
  no colour (red track tint), and aligned the cluster to the HUD's floating-inset chrome
  pattern (stats pill went from flush-edge/square to inset/rounded — see tech-decisions).
- **`viewModel.ts`:** `engagement` + derived `engagementBeat` fields (3 tests).

## Remaining (still blocked on 079 — real Labrador clips)
- Drive the dog's **distractor/`misbehaving` visual states** from `disengageBeat()`
  using the real clips (`scratch ear`/`dig`/`bark`/`lie`/`trot`+`turn 180`).
- **Walk-away + call-back**: trot to frame edge, back-turned; tap to call back
  (costs tempo/combo); auto-return. Needs the trot/turn clips + scene work.
- Wire the **reward-latency** event live (the pure fn already supports it).
- Visual Review of the on-dog beats once the clips render.

## Discrepancy repaired (pre-existing, unrelated to this task)
`src/render/dogModelLoader.test.ts` (untracked, from the on-hold 078 work) imported
`importedPoseTransforms` — a symbol never implemented in `dogModelLoader.ts` — plus an
orphaned `NEUTRAL`/`DogPose` fixture used by no test. This broke `tsc` (TS2305) and
blocked the gate. Removed the dead import + fixture (no behaviour change; the planned
pose-transform test belongs to on-hold 078/079). Noted so the real impl can re-add it.
