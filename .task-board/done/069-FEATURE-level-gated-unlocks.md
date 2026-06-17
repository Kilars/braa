# FEATURE: Two-Step Level-Gated Unlocks (level makes available, coins buy)

**Status**: Backlog
**Created**: 2026-06-16
**Priority**: High
**Labels**: core, logic, economy, progression, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **Economy & Progression** (specs.md:158–171):

> **XP → Trainer Level.** … Rising levels **unlock tiers**, making that tier's
> breeds, tricks, and phrases **available to buy**. …
> **Coins.** … buy the specific item within an already-unlocked tier …
> The two steps are sequential: **level makes content purchasable; coins purchase
> it.** Nothing is unlocked by level alone or coins alone.

This **two-step gate is a v1 requirement** ("Coins + XP + levels (two-step
unlocks)", specs.md:386) and is **currently not enforced** — purchasing is
coin-only:

- `src/core/phrases.ts:73` `isPhraseUnlocked(phrase, _profile, ownedIds)` — the
  profile parameter is **underscored/unused**; the `unlockLevel` data on every
  `PHRASE_CATALOG` entry (specs: DYKTIG=lvl 2, SUPER=lvl 3, KJEMPEBRA=lvl 4) is
  **dead** — a level-1 player with enough coins can buy any phrase.
- `src/core/breeds.ts:69` `canAdopt(breed, coins, roster)` — checks coins only;
  no level requirement exists on `Breed`.
- `src/core/economy.ts:50` `isTierUnlocked(level, requiredLevel)` — the exact
  primitive for this gate **exists but has zero production callers** (dead code).

So the "level makes available" half of the two-step is missing. This task wires it
in (killing the dead `isTierUnlocked` and the dead `unlockLevel` data at the same
time).

## Current State

- Phrase purchase flow (`src/main.ts:227–246`): `unlockNextPhrase()` / 
  `nextLockedEntry()` find the first catalog entry where
  `!isPhraseUnlocked(...) && unlockCost > 0`, then `spend()` coins. Level is never
  consulted.
- HUD affordance (`src/ui/hud.ts:967–971`): shows `+<word> 🪙<cost>` and an
  enabled/disabled state from `coins >= cost`.
- Breed adopt (`src/main.ts:388–397`): `canAdopt(breed, profile.coins, roster)` —
  coins only.

## Desired Outcome

A phrase or breed can only be **purchased** once the player's level meets the
item's required level **and** they can afford the coin cost — the two sequential
steps. Already-owned items remain usable regardless of level (the gate is on
*purchase*, not on *use after purchase*). The affordance UI distinguishes
"locked by level" (e.g. `Lvl 3`) from "locked by coins" (cost shown, greyed when
unaffordable), so the player understands *why* something isn't buyable yet.

## Affected Components

### Files to Modify
- `src/core/phrases.ts` (+ `.test.ts`) — add a **pure** `isPhrasePurchasable(entry,
  level, ownedIds)` (or thread level into `nextPurchasableEntry`) using
  `isTierUnlocked`. **Test-first.** Keep `isPhraseUnlocked` semantics = "owned or
  base" (usable), but its purchase callers must also pass the level gate.
- `src/core/economy.ts` — none (reuse `isTierUnlocked`); confirm it's now imported.
- `src/core/breeds.ts` (+ `.test.ts`) — add `requiredLevel?: number` to `Breed`,
  populate the catalog (starter = 1; Border Collie/Bulldog/Husky/Puddel at rising
  levels), and gate `canAdopt` via `isTierUnlocked`. **Test-first.**
- `src/main.ts` — pass `profile.level` into the phrase purchase find + `canAdopt`;
  surface a level-locked vs coin-locked distinction to the HUD.
- `src/ui/hud.ts` — render the level requirement when the next item is level-locked.

### Dependencies
- **Internal**: `economy.isTierUnlocked` (wire the dead export), `economy.Profile`
  (`level`), `phrases.PHRASE_CATALOG`, `breeds.canAdopt`.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Gate purchase, not use.** Owning a phrase (in `unlockedPhraseIds`) keeps it
  loadable forever; the level check only governs whether the *next* locked item is
  **buyable now**. So leave `isPhraseUnlocked` = base-or-owned, and apply the level
  gate in the purchase/affordance path.
- **Reuse `isTierUnlocked(level, requiredLevel)`** as the single level-comparison
  primitive for both phrases and breeds — this also removes a dead export.
- **Two distinct locked states** for the UI: *level-locked* (need to reach level N)
  vs *coin-locked* (eligible by level, not enough coins). The find that drives the
  affordance returns the next entry the player is **level-eligible** to buy; if the
  very next catalog entry is beyond the player's level, the UI shows its required
  level instead of a buy affordance.

### Behaviours to test (TDD)

`phrases.test.ts`:
1. A phrase with `unlockLevel` above the profile level is **not purchasable** even
   with sufficient coins (e.g. level-1 player, DYKTIG needs level 2 → false).
2. Same phrase **becomes purchasable** once level ≥ `unlockLevel` and not owned.
3. An already-owned phrase reports unlocked/usable regardless of level
   (`isPhraseUnlocked` unchanged).
4. `nextPurchasableEntry(level, ownedIds)` returns the first not-owned,
   level-eligible, cost>0 entry (skips level-locked ones), `null` when none.

`breeds.test.ts`:
5. `canAdopt` returns false when `level < breed.requiredLevel` even with enough
   coins; true when both level and coins suffice; still false when already owned.

### Implementation Steps

1. **TDD phrases** — add `isPhrasePurchasable` / `nextPurchasableEntry` using
   `isTierUnlocked` (behaviours 1–4), red→green.
2. **TDD breeds** — add `requiredLevel` to `Breed` + catalog, gate `canAdopt`
   (behaviour 5). Update the existing `canAdopt` signature to take `level`.
3. **Wire `main.ts`** — `unlockNextPhrase`/`nextLockedEntry` use the level-aware
   find; `getAdoptableBreeds`/`onAdoptBreed` pass `profile.level` to `canAdopt`.
4. **HUD** — when the next phrase is level-locked, show `Lvl N` (not a coin price);
   greyed when coin-locked, as today.
5. Update `032`-style docs only if needed; record the chosen `requiredLevel` /
   `unlockLevel` ladder in `.docs/tech-decisions.md` (tuning is placeholder).

### Risks & Considerations

- **Risk: breaking `canAdopt`'s signature** ripples to call sites. Mitigation:
  only two call sites (`main.ts:389, 396`); update both.
- **Risk: a player softlocks with nothing buyable.** Mitigation: base "bra" is
  always usable and mastered-trick re-practice (see task 070) guarantees a coin
  floor; level rises from active mastery, so the next tier always becomes reachable.
- **Risk: over-gating early game** hurts onboarding. Mitigation: keep level-1
  entries (BASE, FLINK) buyable from the start; only later phrases/breeds gate.

## Before / After Examples

### Example 1: purchasable check (tested)

**Before** (`src/core/phrases.ts:73`):
```ts
export function isPhraseUnlocked(
  phrase: Phrase,
  _profile: Profile,            // ← unused; level never checked
  ownedIds: string[],
): boolean {
  const entry = PHRASE_CATALOG.find(e => e.phrase.id === phrase.id);
  if (!entry) return false;
  if (entry.unlockCost === 0 && entry.unlockLevel <= 1) return true; // base
  return ownedIds.includes(phrase.id);
}
```

**After** (add a purchase-gate helper; `isPhraseUnlocked` keeps "owned/base"):
```ts
import { isTierUnlocked } from './economy';

/** The next phrase the player is LEVEL-eligible to buy (not owned, cost>0,
 *  level ≥ unlockLevel). null when none. Coin affordability is checked separately
 *  at the call site so the UI can distinguish level-locked from coin-locked. */
export function nextPurchasableEntry(level: number, ownedIds: string[]): PhraseEntry | null {
  return PHRASE_CATALOG.find(
    e => e.unlockCost > 0
      && !ownedIds.includes(e.phrase.id)
      && isTierUnlocked(level, e.unlockLevel),
  ) ?? null;
}
```

### Example 2: breed adopt gate (tested)

**Before** (`src/core/breeds.ts:69`):
```ts
export function canAdopt(breed: Breed, coins: number, roster: Dog[]): boolean {
  const owned = roster.some(d => d.breedId === breed.id);
  if (owned) return false;
  const cost = breed.adoptCost ?? 0;
  return coins >= cost;
}
```

**After**:
```ts
export function canAdopt(breed: Breed, coins: number, level: number, roster: Dog[]): boolean {
  const owned = roster.some(d => d.breedId === breed.id);
  if (owned) return false;
  if (!isTierUnlocked(level, breed.requiredLevel ?? 1)) return false; // level gate
  return coins >= (breed.adoptCost ?? 0);                              // coin gate
}
```

## Code References

- `src/core/phrases.ts:60–92` — catalog (`unlockLevel`), `isPhraseUnlocked`,
  `availablePhrases`.
- `src/core/economy.ts:50–52` — `isTierUnlocked` (dead export to wire in).
- `src/core/breeds.ts:62–74` — catalog + `canAdopt`.
- `src/main.ts:227–246, 388–397` — phrase purchase + breed adopt call sites.
- `src/ui/hud.ts:967–971` — phrase unlock affordance render.
- `.docs/specs.md:158–171, 386` — two-step unlock, v1 requirement.

## Progress Log

- 2026-06-16 — Task created (scan round 5; verified `_profile` unused,
  `isTierUnlocked` has zero production callers, `canAdopt` is coin-only).
- 2026-06-17 — Implemented (TDD, 24 new tests). phrases.ts: `isPhrasePurchasable`
  + `nextPurchasableEntry` (both via `isTierUnlocked`). breeds.ts: `Breed.requiredLevel`,
  catalog ladder (Labrador 1 / Bulldog 2 / Border Collie 3 / Puddel 4 / Husky 5),
  `canAdopt` now 4-arg with level gate. main.ts: purchase path uses
  `nextPurchasableEntry` (level-locked phrase never auto-bought), both `canAdopt`
  call sites pass `profile.level`, `nextLockedIsLevelGated` surfaced to HUD.
  hud.ts: chip shows `Lvl N` when level-locked vs `+word 🪙cost` (greyed when
  unaffordable). Ladder recorded in tech-decisions §10. Verify green: 532 tests
  (508 baseline + 24). Visual: training HUD verified clean on 390×844 portrait;
  coin-locked affordance DOM confirmed (`+flink 🪙50`, `too-expensive`, disabled).
  The live `Lvl N` chip state requires mid-game progression (own a lvl-1 phrase
  while still level 1) that is impractical to script for a one-word label swap on
  the already-styled `#hud-loadout-unlock` element; that branch is covered by the
  unit tests for `nextLockedIsLevelGated`.

## Acceptance Criteria

- [x] Phrases: a not-owned phrase whose `unlockLevel` exceeds the player's level is
      **not purchasable even with enough coins**, and becomes purchasable once the
      level is reached — covered **test-first** in `phrases.test.ts` (incl. owned
      phrases staying usable, `nextPurchasableEntry` skipping level-locked entries).
- [x] Breeds: `Breed` gains `requiredLevel`, the catalog is populated, and
      `canAdopt` enforces level **and** coins — covered **test-first** in
      `breeds.test.ts`.
- [x] `economy.isTierUnlocked` is now imported/used in production (no longer dead);
      both phrase and breed gates use it.
- [x] `main.ts` purchase/adopt paths pass `profile.level`; the HUD shows a level
      requirement (`Lvl N`) for level-locked items vs the coin price for
      coin-locked ones.
- [x] The chosen `unlockLevel` / `requiredLevel` ladder is recorded in
      `.docs/tech-decisions.md` (placeholder tuning).
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green
      (report the verify summary line).

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
