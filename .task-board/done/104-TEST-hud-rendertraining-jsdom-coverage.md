# TEST: jsdom coverage for `hud.ts` `renderTraining` display logic

**Status**: Backlog
**Created**: 2026-06-20 (iteration 17 scan)
**Priority**: Medium
**Labels**: test, ui, quality
**Estimated Effort**: Simple

## Context & Motivation

`src/ui/hud.ts` (~752 lines) is the largest untested logic-bearing file in the project.
Task 093 split the five overlay panels out into `src/ui/panels/*` (each now covered by
the jsdom tests added in task 101), and task 101 stood up the jsdom test harness for
`src/ui/**` (tech-decisions §3e). But the **`createHud` orchestration itself — in
particular `renderTraining` — still has zero direct tests.**

`renderTraining` contains exactly the kind of **display logic** that regresses silently:
- phrase **cooldown percentage** → the `--cooldown-pct` CSS var sweep,
- **combo** visibility threshold + multiplier text,
- **engagement** percentage rounding + beat class,
- phrase **readiness** gating (ready vs cooling),
- the **level-gate vs coin-gate** affordance branching on purchasable items.

These are pure-ish view transforms over a `TrainingViewModel`, perfect for
characterization tests through the public HUD surface. Adding them is **purely additive**
(no refactor, low risk) and directly answers the scan's standing "unit tests for
`hud.ts` orchestration" carry-forward item (PLANNING-BOARD).

## Current State

- `src/ui/hud.ts` — `createHud(...)` returns a handle; `renderTraining(vm)` mutates the
  training DOM. No `hud.test.ts` exists.
- `src/ui/viewModel.ts` — has tests (`viewModel.test.ts`); produces the `TrainingViewModel`
  that `renderTraining` consumes. Use it to build realistic inputs.
- `src/ui/panels/*.test.ts` — the established pattern: drive the public `PanelHandle`,
  assert **observable DOM** (classes, text, attributes), not internals — so tests survive
  refactors. Mirror this for the HUD.
- `vite.config.ts` — `test.environmentMatchGlobs: [["src/ui/**","jsdom"]]` already routes
  `src/ui/**` tests to jsdom; add the per-file `// @vitest-environment jsdom` docblock.

## Desired Outcome

A new `src/ui/hud.test.ts` (jsdom) that drives `createHud` through its **public** surface
and asserts the observable DOM produced by `renderTraining` for representative view
models — characterization of current behavior, asserting DOM not internals.

## Affected Components

### Files to Create
- `src/ui/hud.test.ts`

### Files to Modify
- None expected. If `createHud` is genuinely impossible to instantiate in jsdom without a
  tiny, behavior-preserving seam (e.g. an injectable document root), make the **minimal**
  such change and note it — but prefer testing as-is first.

### Dependencies
- **External**: `jsdom` (already a dev dep).
- **Internal**: `src/ui/viewModel.ts` (to build inputs), the panel tests (as the pattern).
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Test through the public interface only.** Call `createHud`, render a training view
  model, and assert on the resulting DOM (`querySelector` + class/text/attr/CSS-var
  checks). Do not reach into closures or private functions — keep tests refactor-proof,
  matching the panel-test convention (CLAUDE.md "test behavior through public interfaces").
- **TDD ordering** via the `tdd` skill: write one failing assertion at a time against the
  real behavior (characterization), confirm red→green, then add the next concern. These
  are tests for existing behavior, so "red" means the test is wrong, not the code — fix
  the test until it captures the true current output, then move on.

### Implementation Steps

1. **Harness**: instantiate `createHud` in jsdom with stub callbacks; grab the training
   container.
2. **Slices (one concern per test)**:
   - cooldown sweep: a cooling phrase sets `--cooldown-pct` between 0 and 1; a ready
     phrase reads ready.
   - combo: below threshold hidden / at threshold visible with the right multiplier text.
   - engagement: percentage rounding + the expected beat class for a sample meter value.
   - unlock affordance: a level-locked entry shows the "Lvl N" treatment vs a coin-priced
     one (mirror `adoptPanel`/`kennelPanel` gate-legibility tests).
3. **Edge cases**: empty/at-boundary view models (0% and 100% cooldown, combo exactly at
   threshold, engagement 0 and 1).

### Risks & Considerations

- **Risk**: `createHud` touches browser-only APIs not in jsdom (e.g. canvas, audio).
  **Mitigation**: stub via the existing panel-test approach; if a hard dependency blocks
  instantiation, add a minimal injectable seam (note it) rather than testing internals.
- **Risk**: over-coupling tests to exact markup. **Mitigation**: assert semantic
  outputs (CSS var value ranges, presence of a class, text content), not full HTML.

## Before / After Examples

### Example: cooldown-percentage characterization (new test)

**Before** (`src/ui/hud.ts`): logic exists, untested.
```ts
// inside renderTraining(vm):
chip.style.setProperty('--cooldown-pct', String(vm.phrase.cooldownPct));
chip.classList.toggle('is-ready', vm.phrase.ready);
```

**After** (`src/ui/hud.test.ts`, new):
```ts
// @vitest-environment jsdom
it('sweeps --cooldown-pct and marks ready when off cooldown', () => {
  const hud = createHud(/* stub deps */);
  hud.renderTraining(vmWith({ phrase: { cooldownPct: 0.5, ready: false } }));
  const chip = document.querySelector('.loadout-chip') as HTMLElement;
  expect(chip.style.getPropertyValue('--cooldown-pct')).toBe('0.5');
  expect(chip.classList.contains('is-ready')).toBe(false);
});
```
(Exact selectors/var names to be confirmed against `hud.ts` during implementation.)

## Code References

- `src/ui/panels/adoptPanel.test.ts`, `src/ui/panels/kennelPanel.test.ts` — the
  jsdom-through-public-handle pattern + gate-legibility assertions to mirror.
- `src/ui/viewModel.test.ts` — how the training view model is built for tests.

## Resolution

Added `src/ui/hud.test.ts` — 15 jsdom characterization tests driving `createHud`
through its public surface and asserting the observable DOM `renderTraining` produces.
**No seam was added to `hud.ts`** — `createHud` instantiates cleanly under jsdom as-is;
the only test-side stub needed is `vi.spyOn(performance, 'now')` (the one browser timing
call inside `renderTraining`'s cooldown branch) plus a full stub `HudCallbacks`. Tests
assert semantic outputs (CSS var values, classes, `data-*` attrs, text), never internals.

Groups (one concern per test):
- **Phrase cooldown sweep (4)**: cooling phrase sets `--cooldown-pct` to the remaining
  fraction as a one-decimal percent string + `on-cooldown` class; a ready phrase clears
  it; boundaries — exactly-at-cooldown reads `0%`/ready, just-used reads `100.0%`.
- **Combo indicator (3)**: hidden below threshold (combo 1, no `visible`/`data-combo`);
  visible at the threshold (2) with `x2` text + `data-combo`; above (5) shows `x5`.
- **Engagement meter (4)**: `Math.round(engagement*100)` drives fill width +
  `aria-valuenow` (0.426→43%); `data-beat` mirrors the passed beat; boundaries 0
  (empty/walk-off) and 1 (full/engaged).
- **Unlock affordance (4)**: level-gated entry → `Lvl N` badge, `too-expensive`,
  disabled; coin-priced affordable → `+word 🪙cost`, `affordable`, enabled; coin-priced
  unaffordable → `too-expensive` + disabled; no next phrase → button hidden.

Characterization note: the actual `--cooldown-pct` value is a `"NN.N%"` percent string
(not the `0.5` fraction the task example sketched) — captured as the true current output.

Verification:
- `bun run typecheck` → 0 errors.
- `bunx vitest run src/ui/hud.test.ts` → **15 passed (15)**, 1 file passed.

## Progress Log

- 2026-06-20 — Task created (iteration 17 scan). Answers the standing "unit tests for
  hud.ts orchestration" carry-forward (PLANNING-BOARD). Additive, low risk.
- 2026-06-20 — Implemented test-first (tdd skill, vertical slices). Added
  `src/ui/hud.test.ts` with 15 jsdom characterization tests across cooldown / combo /
  engagement / unlock-affordance, including the required boundary cases. No `hud.ts`
  change (no seam needed — `createHud` runs under jsdom as-is; only `performance.now`
  stubbed in tests). Typecheck 0 errors; `vitest run src/ui/hud.test.ts` 15/15 green.

## Acceptance Criteria

- [ ] New `src/ui/hud.test.ts` runs under jsdom (per-file docblock) and is green.
- [ ] Written **test-first** via the `tdd` skill — one concern per test, asserting
      observable DOM through the public HUD surface (not internals).
- [ ] Covers: phrase cooldown sweep + ready state, combo visibility/multiplier text,
      engagement percentage + beat class, and level-gate vs coin-gate affordance.
- [ ] Includes boundary cases (0%/100% cooldown, combo at threshold, engagement 0 and 1).
- [ ] No behavior change to `hud.ts` (or only a minimal, documented injectable seam if
      strictly required to instantiate it in jsdom).
- [ ] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting.
