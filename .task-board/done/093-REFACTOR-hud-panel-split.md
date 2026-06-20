# REFACTOR: Split the `hud.ts` god-module — extract the five overlay panels

**Status**: Done (2026-06-17)
**Created**: 2026-06-17
**Priority**: High
**Labels**: refactor, readability, ui, visual-review
**Estimated Effort**: Large

## Context & Motivation

`src/ui/hud.ts` is a **1148-line single `createHud()` closure** (planning-board's
top quality candidate). Inside it, five independent overlay panels — **adopt**,
**kennel**, **settings**, **help**, **achievements** — are each built inline with
flat `document.createElement` chains that share one giant scope. The panels are
logically separable but physically entangled, which makes the module the hardest
to read and change in the codebase. Splitting them into `src/ui/panels/*` modules
is the highest-value readability refactor available, and the app is feature-complete
so it can absorb a structural pass.

This is a **pure refactor**: zero behaviour change, zero DOM/CSS change. Every
element keeps its exact id/class/parent so `hud.css` still applies and the panels
look and behave **byte-for-byte identical**.

## Current State

- `createHud(callbacks)` (src/ui/hud.ts) constructs the loading overlay, the select
  screen, the training HUD, **and** all five panels inline, then returns one update
  API. Panels reference shared closure state and a cross-panel exclusivity rule
  (only one panel open at a time — task 071) and a11y wiring (focus rings, dialog
  roles, task 035).
- `hud.css` styles everything by id/class. **These selectors are the contract** the
  refactor must preserve.

## Desired Outcome

`createHud()` shrinks to orchestration: it wires the buttons/state and delegates
each panel's DOM construction to a `createXxxPanel(...)` factory in
`src/ui/panels/`. Each factory returns `{ el, open(), close(), update(...) }` (and
whatever refs the HUD needs), takes the relevant callbacks/deps as params, and
appends with the **same ids/classes/parents** as today. A single open-panel
coordinator preserves the one-at-a-time exclusivity.

## Affected Components

### Files to Create
- `src/ui/panels/adoptPanel.ts`
- `src/ui/panels/kennelPanel.ts`
- `src/ui/panels/settingsPanel.ts`
- `src/ui/panels/helpPanel.ts`
- `src/ui/panels/achievementsPanel.ts`
- `src/ui/panels/panelManager.ts` (or equivalent) — owns mutual-exclusivity:
  opening one closes the others (preserves task 071 behaviour).

### Files to Modify
- `src/ui/hud.ts` — delegate panel construction to the factories; keep the public
  `createHud` return type identical so `main.ts` call-sites are unchanged.

## Technical Approach

### Architecture Decisions
- **Preserve the public contract.** `createHud(callbacks)`'s return shape stays
  identical; `main.ts` is untouched. This is an internal decomposition only.
- **Preserve the DOM contract.** Same tag/id/class/parent for every node →
  `hud.css` unchanged. Do **not** restyle or "improve" anything this task.
- **Incremental + verifiable.** Extract one panel, run `bun run verify` + a
  screenshot, confirm identical, then the next. Never extract all five blind.
- **Exclusivity via a coordinator**, not cross-panel references — the manager holds
  the list of panels and closes the others on open (task 071 invariant).

### Before → After (shape)

```ts
// BEFORE (hud.ts, inline):
const adoptPanelEl = document.createElement('div');
adoptPanelEl.id = 'adopt-panel'; /* ...dozens of lines... */
document.body.appendChild(adoptPanelEl);

// AFTER (panels/adoptPanel.ts):
export function createAdoptPanel(cb: AdoptPanelCallbacks): PanelHandle {
  const el = document.createElement('div');
  el.id = 'adopt-panel'; /* identical construction, same ids/classes */
  document.body.appendChild(el);
  return { el, open, close, update };
}
// AFTER (hud.ts):
const adoptPanel = createAdoptPanel({ onAdopt: callbacks.onAdopt, /* ... */ });
```

### Behaviours to test (where pure)
- Pure helpers exposed during extraction (e.g. an `isAnyPanelOpen` / panel-list
  coordinator, or list-row formatting helpers) → unit-test them per
  `.claude/skills/tdd/SKILL.md`. DOM construction itself is **Visual Review**, not
  unit-tested.

### Implementation Steps
1. Define a shared `PanelHandle` type (`{ el, open, close, update }`).
2. Extract panels **one at a time**, in this order (simplest first): help →
   achievements → settings → kennel → adopt. After each: `bun run verify` +
   screenshot the open panel + diff against baseline.
3. Introduce the open-panel coordinator; route every `open*()` through it; confirm
   task 071 exclusivity still holds (opening adopt closes settings, etc.).
4. Final pass: `createHud` reads as orchestration; no panel DOM left inline.

## Visual Review (blocking)
Run `bun run dev` (reuse the one server) and `node scripts/shoot-hud.mjs` (or
`scripts/shoot.mjs`) on a **phone-portrait** viewport. Capture each of the five
panels **open**, plus the select screen and the training HUD. Each must be
pixel-identical to the pre-refactor baseline (capture baselines first). Spawn a
review agent to actually view the screenshots and confirm no layout/spacing/focus
regression. Findings are blocking.

## Risks & Considerations
- **CSS breakage** if any id/class/parent changes — the single biggest risk. Keep
  them identical; screenshots are the guard.
- **Exclusivity / focus regressions** (tasks 071, 035) — verify one-at-a-time open
  and close-button focus rings survive.
- **Event-listener leaks / double-append** — each panel appends to `document.body`
  exactly once, as today.

## Acceptance Criteria
- [x] Five panels live in `src/ui/panels/*`; `createHud` delegates to them and no
      panel DOM construction remains inline in `hud.ts`.
- [x] `createHud`'s public return contract is unchanged; `main.ts` is untouched.
- [x] Mutual exclusivity (task 071) and close-button focus rings (task 035) still
      work; verified.
- [x] All five panels + select + training HUD are **pixel-identical** to baseline
      (real before/after screenshots on phone-portrait, reviewed by an agent).
- [x] Any pure helper extracted is TDD-covered; `bun run verify` green +
      `bun run e2e` PASS.
- [x] `hud.ts` line count materially reduced; record before/after LOC in the task.

## Resolution (2026-06-17)

Extracted all five overlay panels from the `createHud()` god-closure into
`src/ui/panels/*` factories, each returning a `PanelHandle`
(`{ el, open(), close(), update? }`). A new **panel manager** owns
one-open-at-a-time exclusivity (task 071) and was built **test-first** (TDD, 4
tests) as DOM-agnostic pure logic over `{ open, close }` handles.

### Files created
- `src/ui/panels/panelManager.ts` + `panelManager.test.ts` — `PanelHandle` type
  and `createPanelManager()` (register / open-exclusive / closeAll). TDD.
- `src/ui/panels/adoptPanel.ts` — `createAdoptPanel(deps)`; on adopt → `onAdopted()`
  (HUD's `showSelect`) then self-close.
- `src/ui/panels/kennelPanel.ts` — `createKennelPanel(deps)`; exposes `update` so
  the HUD's public `refreshKennelPanel` delegates to it.
- `src/ui/panels/settingsPanel.ts` — `createSettingsPanel(deps)`; keeps the
  two-tap reset-confirm timer as panel-local state; `onOpenAchievements` routes
  through the manager.
- `src/ui/panels/helpPanel.ts` — `createHelpPanel()` (static content).
- `src/ui/panels/achievementsPanel.ts` — `createAchievementsPanel(deps)`.

### hud.ts
- `createHud` now orchestrates: builds the panel manager, creates the five panels
  **in the original append order** (adopt → kennel → settings → help →
  achievements, kept between the select screen and the training HUD so
  `document.body` child order — and thus `hud.css`/stacking — is unchanged), wires
  the select-screen trigger buttons through `panelManager.open(...)`, and removed
  the old inline panel DOM + `closeAllPanels`. Public return shape unchanged;
  `main.ts` untouched. Dropped now-unused `kennel` imports.
- **LOC: 1148 → 640** (−508). Panel factories total ~622 LOC across 5 modules.

### Verification
- **DOM contract proof:** captured `document.body` child order + each panel's
  `outerHTML` BEFORE and AFTER via Playwright (dispatchEvent-open so onboarding
  gates don't hide triggers). Body order identical; all five panels + select
  **byte-for-byte identical**; training HUD differed only in the live
  `data-tell` / tell-ring opacity (time-varying animation, not structure).
- **Pixel proof:** phone-portrait (390×844) screenshots of every panel — 6/7
  **MD5-identical**; training differs only by the animated tell-cue glow frame.
- **Visual Review agent:** viewed all 7 before/after pairs → **PASS, no regression.**
- **Gate:** `bun run verify` green (typecheck 0 · **600 tests** · build no warnings)
  + `bun run e2e` (smoke + full-loop) **PASS** — full-loop proves listener wiring
  (tap→mastery→50-coin payout→return-to-select) survived the extraction.

Verification harness scripts were temporary scaffolding and removed after use.
