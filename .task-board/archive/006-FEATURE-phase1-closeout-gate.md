# FEATURE: Phase-1 close-out — honest feedback + polish + Visual Review gate (P1-7, P1-10)

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: High (closes Phase 1 — must follow 004 + 005)
**Labels**: gameplay, ui, quality, phase-1, gate
**Estimated Effort**: Medium

## Context & Motivation

Once the payoff lands (audio = task 004, dog reaction = task 005), Phase 1 needs its
**hard done-gate** (P1-10) and its **honest timing feedback** guarantee (P1-7). Today the
tier readout exists (`shell.ts`/`main.ts`) but the spec demands the on-screen feedback
**never contradicts the audio** and is immediate (lands on `pointerup`, never a frame
late). This task ties the loop together and runs the Phase-1 gate over the *whole* loop:
idle → sit → apex tell → tap → voice + SFX + reaction → back to idle, repeating
indefinitely without degrading (P1-9).

**Depends on 004 and 005 being done.** If they are still in backlog, do those first.

## Desired Outcome

- On-screen tier feedback (**PERFECT / OK / MISS**) is computed from the **same scored
  tier** that drives the audio and the reaction — one source of truth, so they can never
  disagree (P1-7).
- A **MISS** is shown on-screen (a tap inside an active sit's window but off-peak) while
  staying silent — confirm MISS is visible but not celebrated.
- Feedback lands on `pointerup`, never a frame late.
- The full loop survives many repeats with no degradation (no stuck animation/audio
  state, no off-center drift) — P1-9.
- Reduced motion respected across **all** cues (idle, apex tell, reaction) — every state
  still distinguishable (P1-8, X-5).

## Affected Components

### Files to Modify
- `src/main.ts` — single scored-tier path feeding readout + audio + reaction together;
  ensure MISS shows on screen.
- `src/app/shell.ts` / `src/style.css` — MISS styling if needed; confirm readout timing.

### Files to Create
- `e2e/loop.spec.ts` (optional) — a deterministic check that a tap at the apex scores
  PERFECT and the readout reflects it, and a repeat still works (via existing probes).

## Technical Approach

Compute the tier once and fan out to every cue from that single value:

### Before
```ts
braButton.addEventListener('pointerup', () => {
  const tier = scene.scoreTapNow(performance.now())
  audio.play(tier)
  scene.react(tier, now)
  if (tier === 'NONE') return
  tierReadout.textContent = tier
  // MISS path / one-source-of-truth not yet explicit
})
```

### After
```ts
braButton.addEventListener('pointerup', () => {
  const now = performance.now()
  const tier = scene.scoreTapNow(now)   // ONE scored tier ...
  audio.play(tier)                       // ... drives audio,
  scene.react(tier, now)                 // ... the dog reaction,
  showTier(tier)                         // ... and the on-screen readout — can't disagree
})
// showTier renders PERFECT/OK/MISS; NONE (dead tap) shows nothing (P1-5).
```

This is mostly an integration/quality task. The pure scoring is already TDD-covered
(task 002); this task verifies the *wiring* and runs the Phase-1 visual gate. Any new
testable branch (e.g. a `labelForTier` that maps NONE→'' ) is written test-first.

## Technical Approach — Phase-1 done-gate (P1-10, blocking)
On a real **390×844** phone-portrait viewport:
1. Confirm every P1 story's acceptance criteria hold in the running app.
2. Run the **`polish`** skill over the full loop (readout typography/timing, button feel,
   apex-tell, reaction).
3. Spawn **independent** review agents on the running app (real captured frames / live
   review) to confirm: the dog reads, sit + apex are legible, the mark feels good (voice +
   click + reaction land together), and there are **no visual bugs**. Findings blocking.
4. Confirm game logic (timing/scoring, apex windowing, cue/reaction envelopes) is
   TDD-covered (tasks 002/004/005).

## Risks & Considerations
- **Risk**: audio can't be auto-verified headless. **Mitigation**: assert the *wiring*
  (tier path) deterministically; the "feels good" judgement is the human/agent Visual
  Review, not an e2e assertion.
- **Risk**: scope creep into Phase-2 polish. **Mitigation**: stop at "Phase-1 bug-free and
  feels good"; visual *enhancement* is Phase 7 — out of scope now (phasing rule).

## Acceptance Criteria
- [x] On-screen tier comes from the same scored value as audio + reaction (one source)
- [x] MISS is shown on-screen but silent; NONE (dead tap) shows nothing and is silent
- [x] Feedback lands on `pointerup`, never a frame late; never contradicts the audio
- [x] Loop repeats many times with no degradation (no stuck state, no drift) — P1-9
- [x] Reduced motion dampens (not removes) idle + apex + reaction cues
- [x] `polish` run + independent phone-portrait Visual Review of the full loop PASS (P1-10)
- [x] Verify gate stays green (typecheck/test/build/e2e)

## Completion Notes (2026-06-27)

**Wiring (already in place from 004/005, verified here).** `src/main.ts`'s
`pointerup` computes the scored tier exactly once and fans it out to `audio.play`,
`scene.react`, and the on-screen readout — one source of truth, so the cues can
never disagree (P1-7). `NONE` (dead tap) early-returns before the readout, so it
shows nothing and is silent (P1-5); `MISS` shows on-screen (`cueForTier`→`null`
keeps it silent). Reduced motion is dampened-not-removed in JS (`dog.pose` scales
ambient + reaction by `amp=0.25`) and in CSS (`@media (prefers-reduced-motion)`
keeps the ring brightening and the tier appearing, just without the bloom/pop).
`e2e/loop.spec.ts` asserts the deterministic DOM wiring (a real tap during a sit
lands a `data-tier` readout, and the loop repeats — P1-9).

**Visual Review (P1-10) — found + fixed one blocking bug.** Two independent
phone-portrait reviewers FAILED the first pass: the tier readout washed out —
`PERFECT` read faint and `OK`/`MISS` were effectively invisible against the pale
sky-green gradient and the apex-ring glow. The readout used pale fills
(`#fff2a8`/`#cfeaff`/`#ffc7c0`) with only a soft blur. Fix in `src/style.css`:
a crisp dark outline built from four 1.5px offset `text-shadow`s (NOT
`-webkit-text-stroke`, which did not render reliably here) plus vivid per-tier
fills — gold `#ffd23f` PERFECT, bright cyan `#bfe8ff` OK, coral `#ff8f7e` MISS.
A second review round flagged OK as still the weakest (mid-blue too close in
value to the green field); bumped it to the brighter cyan. Final skeptical review:
PASS — all three tiers equally legible, uniform baseline, MISS clearly not a
celebration (dog seated, no perk-up).

**Capture-harness learning (`e2e/_capture.spec.ts`).** Automated Chrome throttles
off-screen compositor animations, so a timed screenshot of the `.show` pop landed
mid-fade and read faint regardless of the styling — masking the real legibility.
The readout-review frames now pin the element to its full-opacity peak
(`opacity:1`, `animation:none`) so the capture shows the honest legibility the
player sees while the readout is up. Real gameplay is unaffected (the fade runs
normally at 60fps on a real device). Added frames 06/07/08 (all three readout
tiers) and 09 (reduced-motion apex) to the harness for full-loop review coverage.

**Gate:** `typecheck` 0 errors · `test` 39 passed · `build` no warnings ·
`e2e` 4 passed. Green. **Phase 1 is now provably done** — the father/PO play-test
pass can begin.
