# CONTENT: More Marker Phrases (TDD)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: content, core, tdd
**Estimated Effort**: Simple

## Context & Motivation

The phrase catalog has base "bra" + flink + super. Add a couple more collectible
Norwegian marker words to deepen the collection axis.

## Affected Components
- Modify: `src/core/phrases.ts` (add 2 phrases to `PHRASE_CATALOG`, e.g. `dyktig` ("dyktig"), `kjempebra` ("kjempebra") with sensible `unlockCost`/`unlockLevel` + window/reward bonus + cooldown that fit the existing trade-off shape) + test
- Dependencies: `phrases.ts` (012/025); Blocking: 025

## Behaviors to test (each RED first)
- The two new phrases exist in `PHRASE_CATALOG` with positive `unlockCost` and valid bonus/cooldown fields.
- They follow the trade-off pattern (stronger bonus ↔ higher cost/cooldown/level) consistent with flink/super — assert the ordering is monotonic where intended.
- `isPhraseUnlocked`/`availablePhrases`/`isReady`/`applyPhraseToAttempt` work for them (no special-casing).
- Costs respect the §7 balance intent (don't let coin cost clear before the level gate).

## Visual Review
- Not required (content/logic only) — but confirm `bun run build`/`e2e` still pass since the loadout chip cycles through unlocked phrases.

## Progress Log
- 2026-06-14 — Task created (iteration 17)

## Resolution
Added 2 phrases to `PHRASE_CATALOG` in `src/core/phrases.ts` via genuine red-green TDD (25 new tests added to `phrases.test.ts`).

### `dyktig`
- `windowBonusMs`: 200
- `rewardBonus`: 0.15
- `cooldownMs`: 10000
- `unlockCost`: 175
- `unlockLevel`: 2

### `kjempebra`
- `windowBonusMs`: 350
- `rewardBonus`: 0.3
- `cooldownMs`: 18000
- `unlockCost`: 450
- `unlockLevel`: 4

Catalog order: bra → flink → dyktig → super → kjempebra. All four dimensions (windowBonusMs, rewardBonus, cooldownMs, unlockCost) are strictly monotonically increasing. No special-casing in any phrase function — all existing functions (`isPhraseUnlocked`, `availablePhrases`, `isReady`, `applyPhraseToAttempt`) work generically via the catalog.

### Verification results
- `bun run typecheck`: 0 errors
- `bun run test`: 409 passed (was 384, +25 new) — 24 test files, all green
- `bun run build`: built in 13.99s, dist OK
- `bun run e2e`: E2E SMOKE PASS

## Acceptance Criteria
- [x] 2 new phrases added with valid fields + balanced costs (test-first)
- [x] Existing phrase fns work for them unchanged (tested)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
