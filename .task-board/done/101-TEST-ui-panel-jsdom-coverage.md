# TEST: jsdom harness + unit tests for the UI panel factories

**Status**: Backlog · **Priority**: Medium · **Type**: TEST (coverage gap)
**Created**: 2026-06-19 (iteration 13 scan) · **Depends on**: none

## What
The five overlay panels extracted in task 093 — `adoptPanel`, `kennelPanel`,
`settingsPanel`, `helpPanel`, `achievementsPanel` (`src/ui/panels/*`) — are real
DOM-building factories with branching logic (level-gated vs coin-gated badges, affordable
vs locked styling, list rendering, open/close/update) and have **zero unit tests**. Only
`panelManager.ts` (pure exclusivity logic) is covered. The Vitest environment is
`node`-only (`vite.config.ts` → `test.environment: "node"`), so panel DOM cannot be
exercised today. This task adds a **jsdom** test environment for the UI layer and
covers the panel factories' observable behavior.

## Why now
- These factories carry user-facing correctness (e.g. `adoptPanel`'s `levelGated` vs
  affordability rendering — tech-decisions §10 "Gate legibility") with **no regression
  net**; 093's refactor was validated by screenshots only.
- The `tests` domain is unsaturated this round (1 of the last 15 done); this is genuine
  coverage value, not churn.
- It unblocks confident future panel edits and is a prerequisite for testing any future
  DOM-bearing UI logic.

## Technical Approach

### 1. Enable jsdom for UI tests only — `vite.config.ts`
Keep the fast node default for the pure core; opt the UI layer into jsdom via Vitest
`environmentMatchGlobs` (or a `// @vitest-environment jsdom` docblock per UI test file).

```ts
// BEFORE (vite.config.ts)
test: {
  environment: "node",
  include: ["src/**/*.test.ts"],
  reporters: ["dot"],
},
```
```ts
// AFTER
test: {
  environment: "node",
  environmentMatchGlobs: [["src/ui/**", "jsdom"]],
  include: ["src/**/*.test.ts"],
  reporters: ["dot"],
},
```
Add `jsdom` as a dev dependency (`bun add -d jsdom`). Confirm the existing node-env
tests are unaffected (they don't touch `src/ui/**`).

### 2. Cover each panel factory's observable behavior (TDD-style, behavior-first)
Test through the public factory + `PanelHandle` (`{ el, open, close, update? }`), not
internals. Representative behaviors:

```ts
// EXAMPLE — adoptPanel.test.ts (src/ui/panels/)
// @vitest-environment jsdom
it('renders a level-gated breed with a "Lvl N" badge, not a coin price', () => {
  const handle = createAdoptPanel({ /* breeds incl. one above the player's level */ });
  handle.update?.(/* profile at a low level */);
  const card = handle.el.querySelector('[data-breed="husky"]')!;
  expect(card.textContent).toMatch(/Lvl 5/);
  expect(card.classList.contains('level-locked')).toBe(true);
});

it('open() shows the panel and close() hides it', () => {
  const handle = createAdoptPanel({ /* … */ });
  handle.open();
  expect(handle.el.classList.contains('open')).toBe(true); // or hidden attr, per impl
  handle.close();
  expect(handle.el.classList.contains('open')).toBe(false);
});
```

Cover, at minimum, one meaningful branch per panel:
- **adoptPanel** — level-gated badge vs affordable vs coin-short styling.
- **kennelPanel** — owned vs affordable vs locked upgrade rows + multiplier display.
- **settingsPanel** — mute toggle reflects state; reset wiring invokes the callback.
- **helpPanel** — open/close + key content present.
- **achievementsPanel** — unlocked vs locked rendering from the achievements list.

Match the **actual** factory signatures and class/attr names by reading each
`src/ui/panels/*.ts` first — the snippets above are illustrative.

## Out of scope
- Testing `hud.ts` orchestration end-to-end (large; a follow-up if valuable).
- Any behavior change to the panels — this is **characterization** of current behavior;
  if a test surfaces a real bug, file it separately rather than fixing inline.
- Visual styling assertions beyond class/attribute presence (Visual Review owns pixels).

## Acceptance criteria
- [ ] `jsdom` added as a dev dependency; `vite.config.ts` runs `src/ui/**` tests under
      jsdom while the rest stay on node.
- [ ] Existing 662 tests still pass under the split config (no env regressions).
- [ ] Each of the five panel factories has at least one behavior test covering a real
      branch (gated/affordable/locked, open/close, or list rendering), written
      behavior-first through the public `PanelHandle`.
- [ ] Tests assert observable DOM/behavior, not private implementation, so they survive
      refactors (per CLAUDE.md TDD guidance).
- [ ] Gate green: `bun run typecheck` · `bun run test` · `bun run build` (no warnings) ·
      `bun run e2e`.
