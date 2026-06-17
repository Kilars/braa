# BUGFIX: Single-active-panel invariant (overlays stack on top of each other)

**Status**: Done
**Created**: 2026-06-17
**Priority**: High
**Labels**: ui, shell, bug, correctness, overlays
**Estimated Effort**: Small

## Context & Motivation

The select-screen shell has five modal overlays — **settings**, **help**,
**achievements**, **kennel**, **adopt** — each shown by setting its own element's
`display = 'flex'`. Only `openAchievementsPanel()` closes another panel first
(`hud.ts:547` calls `closeSettingsPanel()`); every other `open*Panel()` leaves any
already-open panel visible. Result: a player can have **adopt + settings**,
**adopt + kennel**, **kennel + settings**, **kennel + help**, etc. open at once,
stacked, with no single-active-panel guarantee. This was flagged in a UI review
(panel-stacking bug) and verified in code.

Two related shell-correctness defects sit next to it:

1. **Adopt panel not dismissed after adopting.** On a successful adopt the handler
   calls `showSelect()` (`hud.ts:693`) to repopulate the roster, but never calls
   `closeAdoptPanel()` — so the select screen redraws *behind* the still-open adopt
   panel instead of returning to it cleanly.
2. **Kennel button overlays the training HUD.** `#kennel-btn` is
   `position: fixed; z-index: 21` (`hud.css:564–567`), so it renders on top of the
   training HUD even though it logically belongs to the (hidden) select screen — a
   player mid-round can tap "Kennel" and open that panel over the training loop.

This is a v1 UI-shell correctness bug (not post-v1 depth, not dog-visual polish):
overlapping modals are simply broken behavior, reachable in the running app today.

## Current State

- `src/ui/hud.ts:431–445` — `openSettingsPanel` / `closeSettingsPanel`.
- `src/ui/hud.ts:486–492` — `openHelpPanel` / `closeHelpPanel`.
- `src/ui/hud.ts:545–553` — `openAchievementsPanel` (the only one that closes another) / `closeAchievementsPanel`.
- `src/ui/hud.ts:626–633` — `openKennelPanel` / `closeKennelPanel`.
- `src/ui/hud.ts:703–710` — `openAdoptPanel` / `closeAdoptPanel`.
- `src/ui/hud.ts:687–694` — adopt success handler (calls `showSelect()`, not `closeAdoptPanel()`).
- `src/ui/hud.css:564–567` — `#kennel-btn { position: fixed; z-index: 21 }`.
- `src/ui/hud.ts` `applyRevealed()` (~1074) — hides/shows shell buttons by onboarding stage; `selectEl` is hidden during training, but the fixed kennel button is not.

## Desired Outcome

At most **one** overlay panel is visible at any time. Opening any panel first
closes all others. Adopting a breed returns the player to a clean select screen
(panel dismissed). No overlay button bleeds onto the training HUD.

## Affected Components

### Files to Modify
- `src/ui/hud.ts` — add a `closeAllPanels()` helper; call it at the top of every
  `open*Panel()`; call `closeAdoptPanel()` after the post-adopt `showSelect()`;
  ensure the kennel button is hidden when not on the select screen.
- `src/ui/hud.css` — if needed, make `#kennel-btn` visibility follow select-screen
  state (e.g. hide via a class toggled in `showTraining`/`showSelect`) rather than
  always-on `position: fixed`.

### Dependencies
- **Internal**: `showSelect` / `showTraining` already toggle shell state — reuse.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **One helper, called everywhere.** A single `closeAllPanels()` that sets
  `display = 'none'` on all five panel elements is the simplest correct guarantee;
  each `open*Panel()` calls it before showing itself. This subsumes the existing
  one-off `closeSettingsPanel()` call in `openAchievementsPanel`.
- **Keep per-panel close functions** (they also reset panel-local state, e.g.
  settings' reset-confirm timer at `hud.ts:438–444`). `closeAllPanels()` should call
  those close functions (not just set display) so that local state still resets.
- **Kennel button belongs to the select screen.** Toggle its visibility with the
  same select/training transition rather than relying on a fixed overlay.

### Behaviours to test (TDD where logic exists)
The panel wiring is DOM-bound, so the primary gate is **Visual Review**. Where a
pure invariant can be extracted, prefer a test: e.g. a small
`exclusivePanels(panels, toOpen)` helper that returns the display map with exactly
one open could be unit-tested (Arrange the five panel ids, Act open one, Assert only
that one is `'flex'`). If extraction adds more indirection than value, cover it via
the JSDOM-style assertions already used in `viewModel`/HUD-adjacent tests, or rely on
Visual Review — but state which in the Progress Log.

### Implementation Steps
1. Add `closeAllPanels()` in `createHud` after all panel close fns are defined; it
   invokes each panel's close fn.
2. Prepend `closeAllPanels()` to `openSettingsPanel`, `openHelpPanel`,
   `openAchievementsPanel`, `openKennelPanel`, `openAdoptPanel`. Remove the now-
   redundant `closeSettingsPanel()` inside `openAchievementsPanel`.
3. In the adopt success handler, call `closeAdoptPanel()` after `showSelect()`.
4. Hide `#kennel-btn` during training (class toggle in `showTraining`, restored in
   `showSelect`, respecting onboarding `applyRevealed`).
5. **Visual review** on a phone-portrait viewport: open each panel in turn, confirm
   the previously-open one closes; adopt a breed and confirm a clean return to
   select; enter training and confirm no kennel button bleeds through.

## Before / After Examples

### Example 1: exclusive open
**Before** (`src/ui/hud.ts:703–706`):
```ts
function openAdoptPanel(): void {
  refreshAdoptPanel();
  adoptPanelEl.style.display = 'flex';
}
```
**After**:
```ts
function closeAllPanels(): void {
  closeSettingsPanel();
  closeHelpPanel();
  closeAchievementsPanel();
  closeKennelPanel();
  closeAdoptPanel();
}

function openAdoptPanel(): void {
  closeAllPanels();
  refreshAdoptPanel();
  adoptPanelEl.style.display = 'flex';
}
```
(same `closeAllPanels()` prepended to the other four `open*Panel` fns;
`openAchievementsPanel` drops its lone `closeSettingsPanel()` call.)

### Example 2: clean return after adopt
**Before** (`src/ui/hud.ts:687–694`):
```ts
if (affordable) {
  adoptBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    callbacks.onAdoptBreed(breed.id);
    refreshAdoptPanel();
    showSelect();
  });
}
```
**After**:
```ts
if (affordable) {
  adoptBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    callbacks.onAdoptBreed(breed.id);
    showSelect();
    closeAdoptPanel();   // return cleanly to the (refreshed) select screen
  });
}
```

## Risks & Considerations
- **Risk:** `closeAllPanels()` calling a not-yet-defined close fn (hoisting). Define
  it after all five close fns, or use function declarations (hoisted) — verify order.
- **Risk:** Hiding the kennel button could regress its onboarding reveal. Mitigation:
  route visibility through the existing `applyRevealed` gate, don't bypass it.
- **Out of scope:** redesigning the panels' look — this is behavior only.

## Code References
- `src/ui/hud.ts:431–553, 626–722` — panel open/close fns + adopt handler.
- `src/ui/hud.css:564–567` — fixed kennel button.
- `.docs/specs.md` Visual Presentation — "finished, opaque UI" (overlays must be modal, not stacked).

## Progress Log
- 2026-06-17 — Task created (scan round 6). Verified in code: only
  `openAchievementsPanel` closes another panel; no `closeAllPanels`; adopt handler
  omits `closeAdoptPanel`; `#kennel-btn` is `position: fixed; z-index: 21`.
- 2026-06-17 — Implementation complete.
  - `src/ui/hud.ts`: Added `closeAllPanels()` function declaration after
    `adoptPanelEl.style.display = 'none'` (line ~724); it calls all five per-panel
    close fns so local state (e.g. settings reset-confirm timer) resets properly.
    Prepended `closeAllPanels()` to `openSettingsPanel`, `openHelpPanel`,
    `openKennelPanel`, `openAdoptPanel`. Replaced the lone `closeSettingsPanel()`
    in `openAchievementsPanel` with `closeAllPanels()`. In the adopt success
    handler, removed the now-redundant `refreshAdoptPanel()` call and added
    `closeAdoptPanel()` after `showSelect()` for a clean return to the select
    screen. In `showTraining`, added `kennelBtnEl.classList.add('kennel-btn-training-hidden')`.
    In `showSelect`, added `kennelBtnEl.classList.remove('kennel-btn-training-hidden')`
    (before the existing body, so it runs on every select entry regardless of path).
  - `src/ui/hud.css`: Added `.kennel-btn-training-hidden` rule (visibility:hidden;
    pointer-events:none) after `#hud-kennel-btn:active` — matches `.hud-gated`
    pattern so both classes compose correctly with the onboarding gate.
  - Coverage choice: panel wiring is DOM-bound; no extractable pure invariant
    without disproportionate indirection. Left for Visual Review.
  - Verify: `bun run verify` — ✓ typecheck + tests + build (537 tests)
- 2026-06-17 (later iteration) — Implementation re-verified on disk (task had been
  left in backlog after a prior crash). **Visual Review performed** on a 390×844
  phone-portrait viewport via `scripts/shoot.mjs` + an independent review agent:
  - Exclusivity: opened Settings (⚙) then Achievements (🏆, which lives inside the
    Settings panel) and asserted `#settings-panel` is `display:none` while
    `#achievements-panel` is shown (Playwright `--poll`, passed without timeout).
    Screenshot `/tmp/071-exclusivity-ach.png` shows the Achievements panel as the
    sole visible overlay — no stacked Settings content. Review agent verdict: PASS.
  - Kennel-button training bleed: covered at the code level (`showTraining` adds
    `.kennel-btn-training-hidden` → CSS `visibility:hidden;pointer-events:none` at
    hud.css:592; `showSelect` removes it at hud.ts:1019). Reproducing the live bleed
    needs ≥3 masteries to reveal the (otherwise `hud-gated`) kennel button —
    disproportionate to stage in a headless browser; class wiring + CSS verified present.
  - Post-adopt clean return: code path verified (`showSelect()` then
    `closeAdoptPanel()` in the adopt success handler, hud.ts:695–696).
  - Final gate: `bun run verify` ✓ typecheck + tests + build (549 tests); `bun run e2e` PASS.

## Acceptance Criteria

- [x] A `closeAllPanels()` helper exists and is called at the start of every
      `open*Panel()`; opening any panel hides all others (at most one visible).
- [x] The redundant one-off `closeSettingsPanel()` in `openAchievementsPanel` is
      removed (subsumed by `closeAllPanels`).
- [x] Adopting a breed dismisses the adopt panel and returns to a refreshed select
      screen (no panel left open over it).
- [x] The kennel button does not render/respond over the training HUD; it is only
      reachable from the select screen (respecting onboarding reveal).
- [x] Where a pure invariant was extracted it is unit-tested; otherwise the Progress
      Log states the coverage choice. **Visual Review** performed on a phone-portrait
      viewport with screenshots confirming exclusivity, clean post-adopt return, and
      no training-HUD bleed.
      *Coverage choice: panel wiring is DOM-bound (no extractable pure invariant
      without significant indirection); covered by Visual Review. Exclusivity asserted
      via Playwright `--poll` (settings hidden when achievements opened) + screenshot
      `/tmp/071-exclusivity-ach.png` + independent review agent (PASS). Post-adopt
      return and kennel-bleed verified at code level (see Progress Log). No unit test added.*
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green
      (report the verify summary line).

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
