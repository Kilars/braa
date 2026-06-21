# FEATURE: Disengagement — dog walks off & you call it back (procedural dog)

**Status**: DONE (2026-06-21, iteration 20)
**Created**: 2026-06-20 (iteration 18 scan)
**Priority**: High
**Labels**: gameplay, logic, render, ui, gap:engagement, epic:engagement
**Estimated Effort**: Medium-Large

## Context & Motivation

specs.md §"Wrong-behavior beats & disengagement" specifies a graded escalation as
the **engagement meter** drains: *off-task → sass → **Disengage (meter empty):
trots to the frame edge and sits back-turned — you can't earn until you call it
back (tap), costing tempo/combo. The dog returns and re-engages once you're
rewarding well.*"

Task 098 shipped the **pure engagement model** (`engagement(prev,event)` reducer,
`disengageBeat(level)` → `engaged→itch→flop→bark→walk-off`) and a HUD **mood
meter** — but the beat only **tints a HUD bar**. The dog never disengages and
there is no **call-back** interaction, so the meter has **no gameplay teeth**. The
remainder was deferred in 098 as "079-gated" (needed the licensed Labrador clips).

**That deferral is now over-broad.** The licensed dog is DEV-only (flag OFF,
packaging-gated — task 080); the **procedural dog is what ships**. The walk-off +
call-back can be expressed **procedurally** on the shipping dog (translate toward
the frame edge, sit back-turned; a tap calls it back) exactly like the existing
procedural `distractor` "turned-away" state. This closes the **single biggest
remaining non-owner-gated v1 *gameplay* gap** and gives the engagement system real
stakes. (Render is a warm domain, but the saturation filter's own exception
applies: this is a genuine remaining v1 gameplay gap, not polish, and the bulk is
TDD-able logic + a thin render expression.)

## Current State

- `src/core/engagement.ts` — `engagement()` reducer + `disengageBeat(level)`
  (`engaged|itch|flop|bark|walk-off`). Fully tested. **No consumer acts on
  `walk-off`.**
- `src/main.ts` — feeds mark-quality + reward-latency events into the meter
  (`__setEngagement` dev hook); passes `engagement`/`engagementBeat` to the view
  model. Does **not** gate scoring or change dog state on `walk-off`.
- `src/render/dogState.ts` — `DogVisual = idle|offering|confused|happy|distractor|
  misbehaving`. **No `disengaged` state.**
- `src/render/dogPose.ts` — pure per-state pose channels (root/head/tail), already
  reduced-motion-aware; `distractor` already turns the dog away.
- `src/render/dogMesh.ts` / `scene.ts` — apply the pose; `distractor` shows a
  grey turned-away dog, proving the turned-away framing is achievable procedurally.

## Desired Outcome

- When the meter empties (`disengageBeat === 'walk-off'`), the **dog disengages**:
  translates toward the frame edge and sits **back-turned**, visibly "done with
  you", distinct from `distractor` and `idle`.
- While disengaged, **no marks score** (taps are not false-marks either — they are
  the **call-back**): a tap **calls the dog back**, which restores engagement above
  the walk-off threshold and **costs tempo/combo** (combo breaks), then the dog
  trots back and re-engages.
- Graded mild beats stay funny (the existing `itch/flop/bark` HUD escalation is the
  warning; the dog optionally nods to them via small pose deltas — keep minimal).
- `prefers-reduced-motion`: the walk-off reads via **pose + position + tint**, with
  motion dampened not removed (D13).

## Affected Components

### Files to Create
- `src/core/disengage.ts` — **pure** logic (TDD): `isDisengaged(beat)`,
  `callBackEngagement(prev)` (the engagement level a call-back restores to, above
  the walk-off threshold), and `canScoreMark(beat)` (false while disengaged).
- `src/core/disengage.test.ts` — its tests.

### Files to Modify
- `src/render/dogState.ts` — add `'disengaged'` to `DogVisual` + selection when
  the beat is `walk-off`.
- `src/render/dogPose.ts` (+ `.test.ts`) — a `disengaged` pose: lateral translate
  toward the frame edge + back-turned yaw + seated; reduced-motion variant.
- `src/main.ts` — on `walk-off`, set the dog state to `disengaged` and route the
  next tap to **call-back** (consume it, restore engagement, break combo) instead
  of mark scoring; resume normal play after re-engage.
- `src/ui/hud.ts` — a faint "tap to call back" affordance while disengaged
  (mirrors the existing swipe hint pattern).
- `.docs/tech-decisions.md` — record the procedural-disengage model + call-back
  rules (and that this completes the 098 remainder without the licensed clips).

### Dependencies
- **Internal**: 098 engagement model (DONE). None blocking. **Not** 079-gated.
- **External**: none.

## Technical Approach

### Implementation Steps (TDD for the pure core — `tdd` skill)
1. `src/core/disengage.ts` pure functions, one test → impl → repeat:
   - `canScoreMark('walk-off') === false`; true for the other beats.
   - `isDisengaged` only for `walk-off`.
   - `callBackEngagement(0)` returns a level whose `disengageBeat` is **not**
     `walk-off` (re-engaged), and never exceeds 1.
2. `dogPose` `disengaged` channels (TDD via the existing pose tests): back-turned
   yaw + edge offset + seated; reduced-motion dampened.
3. `main.ts` wiring + `dogState` `'disengaged'`; tap-routing branch (Visual Review).
4. HUD call-back affordance (Visual Review).

### Before / After

**Before** (`src/main.ts`, walk-off only tints the meter):
```ts
const beat = disengageBeat(engagement);      // 'walk-off' at empty
viewModel.engagementBeat = beat;             // HUD colour only — dog plays on
// onBraTap: always classifies a mark (or false mark)
```

**After**:
```ts
const beat = disengageBeat(engagement);
if (isDisengaged(beat)) dogVisualState = 'disengaged';   // dog trots off, back-turned

// onBraTap:
if (isDisengaged(disengageBeat(engagement))) {
  engagement = callBackEngagement(engagement);            // tap = call back
  combo = 0;                                              // costs tempo/combo
  return;                                                 // not a scored mark / not a false mark
}
```

```ts
// src/core/disengage.ts (pure, tested)
import { disengageBeat, type DisengageBeat } from './engagement';
export const isDisengaged = (b: DisengageBeat) => b === 'walk-off';
export const canScoreMark = (b: DisengageBeat) => b !== 'walk-off';
export function callBackEngagement(_prev: number): number {
  return 0.5; // re-engages above the walk-off threshold; clamp 0..1
}
```

### Risks & Considerations
- **Risk**: the call-back tap colliding with the false-mark path. **Mitigation**:
  branch call-back **before** mark classification in `onBraTap`.
- **Risk**: walk-off pose breaks centering/contact-shadow. **Mitigation**: reuse
  the `distractor` turned-away framing; keep the dog fully in-frame at the edge.
- **Risk**: meter oscillates (walk-off → call-back → instantly walk-off).
  **Mitigation**: `callBackEngagement` restores comfortably above threshold; test it.

## Acceptance Criteria

- [ ] Pure `disengage.ts` (`isDisengaged`, `canScoreMark`, `callBackEngagement`)
      added **test-first** via `tdd` — behavior tested through the public functions.
- [ ] At empty meter the dog enters a **distinct `disengaged`** state (edge +
      back-turned + seated), tellable apart from `idle` and `distractor` at a glance.
- [ ] While disengaged, taps **call the dog back** (restore engagement, break
      combo) and do **not** score or false-mark; play resumes after re-engage.
- [ ] `prefers-reduced-motion`: disengage reads via pose+position+tint, motion
      dampened not removed (D13).
- [ ] **Visual Review (blocking)**: real phone-portrait screenshots of the
      disengaged + call-back states, reviewed by an independent agent. No fabricated
      screenshots (use `node scripts/shoot-hud.mjs`).
- [ ] Decision recorded in `.docs/tech-decisions.md` (completes the 098 remainder).
      **specs.md untouched.**
- [ ] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Next Steps**: Ready for implementation; the flagship of this round. Move to
`in-progress/` when starting; give it a dedicated, screenshot-heavy pass.

---

## COMPLETION (2026-06-21, iteration 20)

**Done — all acceptance criteria met. Full gate green: typecheck 0 · 805 tests
(781 → 805) · build no-warn · e2e (smoke + full-loop) PASS.**

Closes the 098 remainder **procedurally** on the shipping dog (no licensed clips — the
"079-gated" deferral was over-broad, exactly as the task argued).

### What shipped
- **Pure logic (TDD):** `src/core/disengage.ts` + `.test.ts` (7 tests) — `isDisengaged`,
  `canScoreMark`, `callBackEngagement` (→ 0.5 = `itch`, above walk-off AND bark → no
  oscillation, tested through `disengageBeat`).
- **State (TDD):** `dogState.ts` `'disengaged'` + `opts.disengaged`; precedence
  `happy > disengaged > confused > offering > distractor > idle` (5 new dogState tests).
- **Pose (TDD):** `dogPose.ts` `disengaged` — back-turned `bodyYaw = −π/2` (rump to
  camera; −90° not 180° because the ArcRotateCamera at `alpha=−π/2` would otherwise show
  the same flank), seated `crouchY=−0.34`, head-down, reduced-motion-safe (6 new tests).
- **View model (TDD):** `viewModel.ts` `disengaged` flag (3 new tests).
- **Render glue:** `scene.ts` cool-blue tint `(0.34,0.41,0.6)` (distinct from distractor
  grey), `scale 0.82`, edge offset `x=0.6`; `dogAnimationMap.ts` `disengaged` clip pref.
- **Tap routing:** `main.ts` `onBraTapCommit` branches the **call-back** before mark
  classification (restore engagement, break combo, soft ack, return — never scores).
- **HUD:** `#hud-callback-hint` blue pill ("Hunden gikk — trykk for å kalle den tilbake")
  while disengaged; first-run coach suppressed so prompts never contradict (3 hud tests).
- **Decision recorded** in `.docs/tech-decisions.md` ("On-dog walk-off + call-back"),
  engagement section flipped PARTIAL → COMPLETE. **specs.md untouched.**

### Visual Review (blocking) — real phone-portrait screenshots
`scripts/shoot-disengage.mjs` (engaged / walk-off / called-back / walk-off-reduced),
verified in a real browser: walk-off → dog disengaged + hint shown → a real BRA tap
calls it back (state returns to play, meter 0 → 0.5/itch, hint gone, combo broken).
- Round 1 (independent agent): **FAIL** — dog read as idle recolored (180° yaw = same
  flank, barely seated, centered, grey-not-blue). Fixed.
- Round 2 (fresh independent agent): **PASS WITH NITS** — back-turned/seated/off-to-side/
  blue all read; only nit: uniform-crouch "sit" reads as a low crouch (the primitive dog
  has no per-leg control for a haunches-down sit) — non-blocking.
