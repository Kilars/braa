# FEATURE: Adopt panel distinguishes level-locked from coin-locked breeds

**Status**: Done
**Created**: 2026-06-17
**Priority**: High
**Labels**: economy, progression, ui, two-step-unlock, legibility, tdd
**Estimated Effort**: Small

## Context & Motivation

The economy is a **two-step unlock**: *level makes content purchasable; coins
purchase it* (specs.md:158–171). For this to read as designed, the player must be
able to **tell which gate is blocking them** — "I need to level up" vs "I need to
save coins". The phrase loadout already does this: `getLoadoutState()` computes a
`nextLockedIsLevelGated` flag (`main.ts:451–458`) and the HUD shows "Lvl N" for a
level-blocked phrase.

The **adopt (breed) panel does not.** `canAdopt(breed, coins, level, roster)`
(`breeds.ts:76`) folds the level gate (`isTierUnlocked`, line 79) and the coin gate
into one boolean; `getAdoptableBreeds()` (`main.ts:403–407`) maps it to a single
`affordable`; and the panel (`hud.ts:658–685`) renders every locked breed
identically — disabled "Adopt" button, `too-expensive` class, aria-label
"*not enough coins*". So a level-1 player eyeing a level-3 breed is told "can't
afford" and will grind coins **pointlessly**, never learning they must level up.
This directly undermines the two-step model (task 069) and the no-soft-lock
guarantee's legibility.

This is a v1 economy/progression correctness gap, not dog-visual polish.

## Current State

- `src/core/breeds.ts:76–80` — `canAdopt` returns one bool: `isTierUnlocked(level, requiredLevel)` AND coins ≥ cost AND not owned.
- `src/main.ts:403–407` — `getAdoptableBreeds()` returns `{ breed, affordable }`.
- `src/ui/hud.ts:658–685` — adopt rows: `affordable ? 'affordable' : 'too-expensive'`, button disabled when `!affordable`, aria-label always "not enough coins" when locked.
- `src/main.ts:451–458` — the phrase precedent to mirror (`nextLockedIsLevelGated`).
- `src/core/breeds.ts:13,22,33,44,55,66` — each breed has `requiredLevel`.

## Desired Outcome

A breed locked **by level** is shown distinctly from one locked **by coins**:
a level badge (e.g. "Lvl 3") and a level-specific aria-label, instead of the
coin-shortage styling. A breed unlocked by level but unaffordable still reads as the
coin case. An adoptable breed is unchanged.

## Affected Components

### Files to Modify
- `src/core/breeds.ts` (+ `.test.ts`) — add a pure predicate so callers can ask the
  *level* question separately, e.g. `isBreedLevelLocked(breed, level)` (or reuse
  `isTierUnlocked(level, breed.requiredLevel ?? 1)` directly). **Test-first.**
- `src/main.ts` — `getAdoptableBreeds()` returns `{ breed, affordable, levelGated }`.
- `src/ui/hud.ts` — adopt row renders the level-gated case distinctly (badge +
  aria-label + class); update the `getAdoptableBreeds` callback type.
- `.docs/tech-decisions.md` — note the adopt panel now mirrors the phrase
  level-gate legibility pattern.

### Dependencies
- **Internal**: `isTierUnlocked` (economy.ts), already imported by breeds.ts.
  Composes with tasks 069 (level-gating) and 071 (panel shell). Independent order.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **`levelGated` is "blocked by level regardless of coins".** Compute it as
  `!isTierUnlocked(level, breed.requiredLevel ?? 1)` — purely the level question,
  mirroring `nextLockedIsLevelGated` for phrases. A level-gated breed is *never*
  `affordable`; the UI shows the level badge and **suppresses** the coin-shortage
  label (the coin amount is moot until the level unlocks).
- **Keep `canAdopt` as the single source of truth for actual adoptability** (it must
  still gate the purchase in `onAdoptBreed`); `levelGated` is an *explanatory* flag
  layered on top, not a replacement.

### Behaviours to test (TDD, `breeds.test.ts`)
1. A breed with `requiredLevel: 3` is level-locked at level 1 and level 2, and not
   level-locked at level 3+ (`isBreedLevelLocked` / `isTierUnlocked` boundary).
2. A breed with `requiredLevel: 1` is never level-locked (default path).
3. Cross-check with `canAdopt`: when level-locked, `canAdopt` is `false` even with
   ample coins (regression guard that level dominates coins).
4. A breed unlocked by level but with insufficient coins is **not** level-locked
   (it's the coin case) — `isBreedLevelLocked` false, `canAdopt` false.

### Implementation Steps
1. **TDD `breeds.ts`** — add `isBreedLevelLocked(breed, level)` (behaviours 1–4),
   red→green. (If you instead inline `isTierUnlocked`, still add the boundary tests.)
2. **`main.ts`**: `getAdoptableBreeds()` →
   `{ breed, affordable: canAdopt(...), levelGated: isBreedLevelLocked(breed, profile.level) }`.
3. **`hud.ts`**: when `levelGated`, render a "Lvl N" badge, set class
   `level-locked` (style minimally — reuse existing locked styling), and aria-label
   `` `${breed.name} — reach level ${breed.requiredLevel} to unlock` ``; else keep
   the existing affordable / not-enough-coins branches. Update the callback's return
   type.
4. **Doc**: one line in tech-decisions noting adopt now mirrors phrase legibility.
5. **Visual check**: at low level, the level-gated breeds show "Lvl N"; after
   leveling past the gate they flip to the coin/affordable case.

## Before / After Examples

### Example 1: the flag (tested + wired)
**Before** (`src/main.ts:403–407`):
```ts
getAdoptableBreeds() {
  return adoptableBreeds(roster).map(breed => ({
    breed,
    affordable: canAdopt(breed, profile.coins, profile.level, roster),
  }));
},
```
**After**:
```ts
getAdoptableBreeds() {
  return adoptableBreeds(roster).map(breed => ({
    breed,
    affordable: canAdopt(breed, profile.coins, profile.level, roster),
    levelGated: isBreedLevelLocked(breed, profile.level),  // blocked by level, not coins
  }));
},
```

### Example 2: distinct rendering
**Before** (`src/ui/hud.ts:658–685`, condensed):
```ts
for (const { breed, affordable } of breeds) {
  rowEl.className = 'adopt-breed-row' + (affordable ? ' affordable' : ' too-expensive');
  // costEl always "🪙 N"; button disabled when !affordable; aria "not enough coins"
}
```
**After**:
```ts
for (const { breed, affordable, levelGated } of breeds) {
  rowEl.className = 'adopt-breed-row'
    + (affordable ? ' affordable' : levelGated ? ' level-locked' : ' too-expensive');
  costEl.textContent = levelGated ? `Lvl ${breed.requiredLevel}` : `🪙 ${breed.adoptCost ?? 0}`;
  adoptBtn.disabled = !affordable;
  adoptBtn.setAttribute('aria-label',
    affordable      ? `Adopt ${breed.name} for ${breed.adoptCost ?? 0} coins`
    : levelGated    ? `${breed.name} — reach level ${breed.requiredLevel} to unlock`
    :                 `${breed.name} — not enough coins`);
}
```

## Risks & Considerations
- **Risk:** `requiredLevel` is optional (`?? 1`). Use the same default everywhere so
  level-1 breeds never read as level-gated.
- **Risk:** double source of truth. Keep `canAdopt` authoritative for the purchase;
  `levelGated` is display-only. The `onAdoptBreed` guard stays unchanged.
- **Out of scope:** changing breed `requiredLevel` values or unlock tiers (tuning).

## Code References
- `src/core/breeds.ts:76–80` — `canAdopt` (level + coin fold).
- `src/main.ts:403–407` — `getAdoptableBreeds`.
- `src/main.ts:451–458` — phrase `nextLockedIsLevelGated` precedent.
- `src/ui/hud.ts:658–685` — adopt row render.
- `.docs/specs.md:158–171` — two-step unlock; level vs coins.

## Progress Log
- 2026-06-17 — Task created (scan round 6). Verified `canAdopt` folds level+coin
  into one bool and `getAdoptableBreeds`/HUD expose only `affordable`, so level-locked
  and coin-locked breeds render identically ("not enough coins"). Phrase system
  already solves the symmetric case via `nextLockedIsLevelGated`.
- 2026-06-17 — Implemented (TDD, vertical slices):
  - `breeds.ts`: added `isBreedLevelLocked(breed, level) = !isTierUnlocked(level, breed.requiredLevel ?? 1)`.
    Test-first: 6 new tests in `breeds.test.ts` (below-gate locked at L1/L2, at/above-gate
    unlocked at L3+, `requiredLevel:1` never locked, missing-`requiredLevel` default,
    level-dominates-coins guard, coin-case-is-not-level-locked). RED → GREEN confirmed.
  - `main.ts`: `getAdoptableBreeds()` now returns `levelGated: isBreedLevelLocked(breed, profile.level)`
    alongside `affordable`. `onAdoptBreed` purchase guard (`canAdopt`) untouched.
  - `hud.ts`: callback type gains `levelGated: boolean`; adopt row renders the level case
    distinctly — `level-locked` class, `Lvl ${requiredLevel}` badge (not a coin price), and
    aria-label `"<name> — reach level N to unlock"`. Coin-case and affordable branches unchanged.
  - `hud.css`: `.adopt-breed-row.level-locked` — readable name + amber (`#dea04c`) "Lvl N"
    badge; ADOPT button shares the disabled styling.
  - `.docs/tech-decisions.md`: §10 gains a "Gate legibility" note (adopt mirrors phrase loadout).
  - **Visual Review** (390×844): screenshot `/tmp/072-adopt-panel2.png` shows all four
    higher-level breeds at a fresh L1 save with amber "Lvl 2/3/4/5" badges, readable names,
    disabled ADOPT buttons. Reported amber = `rgb(222,160,76)`, buttons `disabled`. Confirmed
    by an independent review agent (PASS). `.level-locked` class verified applied on the rows.
  - Verify: `bun run verify` ✓ typecheck + tests + build (549 tests); `bun run e2e` PASS.

## Acceptance Criteria

- [x] `breeds.ts` gains a tested, **test-first** way to ask the level question alone
      (`isBreedLevelLocked` or equivalent), covering the `requiredLevel` boundary,
      the default (`requiredLevel: 1`) path, and the level-dominates-coins guard.
- [x] `getAdoptableBreeds()` returns a `levelGated` flag alongside `affordable`.
- [x] The adopt panel renders level-locked breeds distinctly from coin-locked ones:
      a "Lvl N" badge and a level-specific aria-label, not the coin-shortage label.
- [x] An affordable breed and a coin-locked-but-level-unlocked breed are unchanged
      from today; only the level-locked case gains the new affordance.
- [x] Adopt purchase guard (`canAdopt` in `onAdoptBreed`) is unchanged and still
      blocks level-gated adoption.
- [x] Legibility change noted in `.docs/tech-decisions.md`. Visual Review confirms
      the badge on a phone-portrait viewport.
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green
      (`bun run verify` ✓ typecheck + tests + build (549 tests); `bun run e2e` PASS).

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
