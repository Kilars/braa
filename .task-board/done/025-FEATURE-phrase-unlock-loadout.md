# FEATURE: Phrase Unlock (economy) + Loadout Switch (TDD + UI)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, ui, economy, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Phrases exist and one (FLINK) is always loaded, but per spec they should be
COLLECTED (unlocked) and the loadout SWITCHED. Tie phrase availability to the
economy (coins/level) and let the player switch the loaded phrase.

## Current State

`phrases.ts` has `BASE_PHRASE` + effects/cooldown; main.ts hardcodes a FLINK
loadout. No unlock, no switching UI. Phrase chip shows the loaded phrase only.

## Affected Components
- Modify: `src/core/phrases.ts` (catalog with `unlockCost` and/or `unlockLevel`; `isPhraseUnlocked(phrase, profile, ownedIds)`; `availablePhrases(...)`) + test
- Modify: `src/state/save.ts` (`GameSave` gains `unlockedPhraseIds: string[]` — base always implicitly unlocked; backward-compat default `[]`)
- Modify: `src/main.ts` (track loaded phrase among unlocked; unlock spends coins; persist), `src/ui/hud.ts`/`hud.css` (chip becomes a switcher: tap cycles among unlocked phrases; show a locked/unlock affordance for the next phrase)
- Dependencies: `phrases.ts`, `economy.ts`, `save.ts`; Blocking: 012, 016, 009

## Behaviors to test (each RED first)
- `BASE_PHRASE` is always available (no unlock needed).
- `isPhraseUnlocked` false for a costed phrase not owned + insufficient level/coins; true once owned.
- `availablePhrases` returns base + owned only.
- Unlocking a phrase (spend) adds it to owned and makes it available.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Screenshot the loadout chip/switcher; VIEW it; confirm it shows the loaded phrase and a
  switch/unlock affordance, no overlap. (Note: the chip is gated by onboarding until ≥2 masteries.)

## Progress Log
- 2026-06-14 — Task created (iteration 8)

## Resolution

### Red-Green Cycles

**Cycle 1 — isPhraseUnlocked BASE always available**
RED: added test for `isPhraseUnlocked(BASE_PHRASE, baseProfile, [])` → `TypeError: isPhraseUnlocked is not a function`
GREEN: added `PHRASE_CATALOG`, `PhraseEntry`, `isPhraseUnlocked`, `availablePhrases` to `phrases.ts` (also imported `Profile`). Inline `FLINK_PHRASE` + `SUPER_PHRASE` defined in catalog.

**Cycle 2 — costed phrase unavailable until owned**
Tests passed immediately from cycle 1 implementation — logic was correct on first write.

**Cycle 3 — availablePhrases = base + owned**
Tests passed immediately from cycle 1 implementation.

**Cycle 4 — GameSave gains unlockedPhraseIds backward-compat**
RED: added backward-compat test → `expected undefined to deeply equal []`
GREEN: added `unlockedPhraseIds: string[]` to `GameSave` interface; added `unlockedPhraseIds: parsed.unlockedPhraseIds ?? []` to `deserialize`. Updated all `GameSave` literals in `save.test.ts` and `storage.test.ts` to include the new field.

### Wiring (non-TDD integration)
- `main.ts`: removed inline `FLINK_PHRASE`; loads `unlockedPhraseIds` from save; persists it; added `cyclePhrase()`, `unlockNextPhrase()`, `nextLockedEntry()` helpers; passes `onCyclePhrase`, `onUnlockNextPhrase`, `getLoadoutState` to HUD.
- `hud.ts`: `HudCallbacks` extended with new phrase callbacks; chip rebuilt with sub-elements `#hud-loadout-word` + `#hud-loadout-unlock`; chip tap cycles among available phrases; unlock button spends coins.
- `hud.css`: chip becomes `display:flex` + `pointer-events:auto`; added `#hud-loadout-word`, `#hud-loadout-unlock` with affordable/too-expensive/just-unlocked states; `can-cycle` class adds `›` suffix.

### Chip Behavior
- Shows the loaded phrase word (e.g. "BRA") in the green pill.
- Tapping the chip cycles to the next available phrase (wraps).
- When only one phrase is available (no owned costed phrases), `can-cycle` is absent and no cycle arrow is shown.
- Sub-badge shows "+FLINK 🪙50" (next locked phrase + cost); yellow when affordable, muted when not.
- Tapping the sub-badge spends coins and unlocks the phrase; chip updates immediately.
- On cooldown: pill darkens using the existing gradient sweep.
- Chip is hidden (`hud-gated`) until ≥2 masteries — onboarding gate unchanged.

### Screenshot Result
Real capture via playwright-firefox. Full-page screenshot at `/tmp/bra-loadout-full.png` shows:
- Bottom-left: green pill "BRA | +FLINK 🪙50" — no overlap with any other element.
- Top-right: stats (🪙108 Lv 2) — separate, no collision.
- Bottom-center: BRA tap button — separate from chip.
- The chip is visible (not gated) because the seeded save has 2 masteries in `roster[0].masteredTrickIds`.

## Acceptance Criteria
- [x] Unlock/availability logic written test-first; base always available; costed phrases gate on owned
- [x] `GameSave` gains `unlockedPhraseIds` (backward-compat default); owned persists
- [x] Player can switch the loaded phrase among unlocked ones; unlocking spends coins
- [x] Chip/switcher renders without overlap (respecting onboarding gate)
- [x] Screenshot reviewed (real capture — `/tmp/bra-loadout-full.png`, `/tmp/bra-loadout.png`)
- [x] Pure `phrases.ts` no DOM imports
- [x] `bun run test` green (243 tests, 20 files); `bun run typecheck` clean (0 errors); `bun run build` succeeds
