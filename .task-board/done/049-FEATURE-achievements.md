# FEATURE: Achievements (TDD + panel)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, ui, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Add lightweight achievements for goals/retention — derivable from existing save
state where possible, shown in a panel.

## Affected Components
- Create: `src/core/achievements.ts` + test
- Modify: `src/state/save.ts` (`GameSave` gains `bestCombo: number`, default 0 — for the combo achievement; backward-compat) + test; `src/main.ts` (track bestCombo = max(bestCombo, combo) on each mark + persist; compute unlocked achievements for the panel), `src/ui/hud.ts`/`hud.css` (an Achievements panel — reachable from the ⚙ settings panel or its own "🏆" button on select)
- Dependencies: `roster.ts`, `tricks.ts`, `economy.ts`, `prestige.ts`, `save.ts`; Blocking: 021,026,030,038

## Interface (signatures — bodies test-first)

```ts
export interface Achievement { id: string; name: string; description: string; }
export const ACHIEVEMENTS: Achievement[];
// State shape this reads (a subset of GameSave + derived):
export interface AchState { roster: Dog[]; coins: number; prestigePoints: number; bestCombo: number; }
export function unlockedAchievements(s: AchState): string[]; // ids satisfied
```

Suggested achievements (derive from existing state — no new tracking except bestCombo):
- `first-mark` — any dog has ≥1 mastered trick
- `full-repertoire` — some dog mastered all STARTER_TRICKS
- `collector` — roster length ≥ 2 (adopted a dog)
- `combo-10` — `bestCombo ≥ 10`
- `graduate` — `prestigePoints ≥ 1`
- `wealthy` — `coins ≥ 500`

## Behaviors to test (each RED first)
- `unlockedAchievements` returns [] for a fresh state.
- Each achievement flips on at its exact condition (test the boundary for combo-10, collector, etc.).
- It's monotonic-ish per condition (achieved stays achieved while the condition holds).
- `GameSave.bestCombo` backward-compat default 0.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Seed a save satisfying a couple of achievements; open the achievements panel; screenshot /tmp/bra-achievements.png; VIEW it; confirm locked/unlocked render clearly, no overlap.

## Progress Log
- 2026-06-14 — Task created (iteration 17)

## Resolution

**Completed 2026-06-14 (iteration 49)**

### What was done

**TDD cycles (7 achievement + 2 save backward-compat):**
- Cycle 1: fresh state → []
- Cycle 2: first-mark boundary (0 vs 1 mastered tricks)
- Cycle 3: full-repertoire boundary (partial vs all STARTER_TRICKS)
- Cycle 4: collector boundary (1 vs 2 dogs)
- Cycle 5: combo-10 boundary (9 vs 10, and >10)
- Cycle 6: graduate boundary (0 vs 1 prestigePoints)
- Cycle 7: wealthy boundary (499 vs 500 coins)
- Cycle 8: GameSave.bestCombo backward-compat default 0
- Cycle 9: GameSave.bestCombo round-trip

**Files created/modified:**
- `src/core/achievements.ts` — pure; ACHIEVEMENTS array (6 achievements), unlockedAchievements(s)
- `src/core/achievements.test.ts` — 16 tests covering all boundary conditions
- `src/state/save.ts` — added `bestCombo: number`; `deserialize` defaults to 0
- `src/state/save.test.ts` — added bestCombo to all GameSave literals + new backward-compat + round-trip tests
- `src/state/storage.test.ts` — added bestCombo to all GameSave literals
- `src/app/gameHelpers.ts` — buildGameSave accepts optional bestCombo, defaults 0
- `src/main.ts` — bestCombo declared before try block; restored from save; tracked via Math.max(bestCombo, combo) after each mark; included in persist(); passed to getAchievementsState callback
- `src/ui/hud.ts` — added getAchievementsState to HudCallbacks; Achievements button in settings panel body; achievements panel (role=dialog, ✕ close); refreshAchievementsPanel; open/close wiring (settings panel closes when achievements opens)
- `src/ui/hud.css` — achievements panel, achievement-row (unlocked=gold ✓, locked=muted ○), settings-row--achievements, reduced-motion

**Screenshot /tmp/bra-achievements.png:** 5/6 unlocked (First Mark ✓, Collector ✓, Combo Master ✓, Graduate ✓, Wealthy ✓); Full Repertoire locked (dog had 2/3 starter tricks). Panel renders clearly with gold ✓ for unlocked, muted ○ for locked. No overlap with other panels.

**Verification:**
- `bun run typecheck`: 0 errors
- `bun run test`: 384 tests, all green (was 368 before, +16)
- `bun run build`: success (dist/ produced)
- `bun run e2e`: E2E SMOKE PASS

## Acceptance Criteria
- [x] `achievements.ts` written test-first; each condition's boundary tested
- [x] `GameSave.bestCombo` persists (backward-compat); main.ts tracks max combo
- [x] An achievements panel shows locked/unlocked; reachable + no overlap
- [x] Screenshot reviewed (real)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
