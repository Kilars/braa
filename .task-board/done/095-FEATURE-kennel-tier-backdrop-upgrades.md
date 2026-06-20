# FEATURE: Kennel level visibly upgrades the training-ground backdrop

**Status**: ✅ Done (2026-06-18)
**Created**: 2026-06-17

> **Outcome:** Pure `backdropTier.ts` (`kennelTier(ids)→0-3`, `backdropTierConfig`)
> TDD'd (19 tests); `backdrop.ts` builds tier props (bushes / agility cones / a
> cream jump set / fence line) once and `applyBackdropTier` shows/hides + tints
> the ground green per tier; `scene.ts` exposes `setKennelUpgrades(ids)` and
> `main.ts` calls it on bootstrap + every kennel purchase (live, no rebuild).
> Added a `__setKennelUpgrades` dev/screenshot hook. Visual Review caught and
> fixed real bugs (props behind camera, black materials, tier-2 regression, cone
> dominance). 632 tests, verify + e2e green. Tier→visual mapping in tech-decisions §2c.

**Priority**: High (v1 spec gap — §Kennel; visual, non-gated, unsaturated domain)
**Labels**: feature, render, kennel, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

specs.md §Kennel states plainly:

> "Kennel level also visibly upgrades the on-screen training-ground backdrop."

and §Visual Presentation:

> "The backdrop is a simple training ground/park that visibly **upgrades** as the kennel grows."

This is currently **not implemented**. `src/render/backdrop.ts` builds a single
static backdrop (sky gradient + ground gradient + vignette + key light) and
`src/render/scene.ts` exposes **no** way to change it after creation
(`grep -niE "kennel|tier|upgrade" backdrop.ts scene.ts` → nothing). Buying all
three kennel upgrades (`treats-pouch` → `clicker-pro` → `training-dummy`,
`core/kennel.ts:10-13`) changes payout multipliers and idle income but produces
**zero** visual change to the scene. The kennel's promised on-screen reward —
"your training ground levels up" — is missing.

This is a **v1 spec gap**, not polish: the spec names the backdrop upgrade as a
kennel feature. It is also **non-gated** (purely procedural Babylon geometry/
materials — no purchased asset, unlike the owner-gated dog-mesh epic 077-085)
and sits in the **visual/rendering domain**, which has had no task in the last
15 done items.

## Desired Outcome

The training-ground backdrop visibly improves in **4 readable tiers** keyed to
the number of owned kennel upgrades (0 → 1 → 2 → 3): the more the player has
invested in the kennel, the lusher / more built-up the park looks. Buying an
upgrade updates the scene **live** (no reload). The mapping from owned-upgrade
set → visual tier is a **pure, tested** function; the actual mesh/material
changes are covered by **Visual Review**.

Concretely, each tier should add a clearly-visible, Pokémon-GO-clean increment,
e.g.:
- **Tier 0 (no upgrades):** current bare ground + sky.
- **Tier 1:** richer/greener ground gradient + a couple of simple park props
  (e.g. low bushes / a tree silhouette at the edges, well outside the dog frame).
- **Tier 2:** add agility props (e.g. a cone pair / a low jump bar) + brighter fill.
- **Tier 3:** fullest dressing (fence line / more greenery), warmest lighting.

Exact prop choices are an implementation call (document in tech-decisions);
**props must never intrude on the centered dog framing (D12)** or hurt state
legibility, and must respect `prefers-reduced-motion` (props are static, so this
is mostly N/A, but no new motion cues).

## Affected Components

### Files to Create / Modify
- `src/render/backdropTier.ts` (NEW) + `backdropTier.test.ts` (NEW) — pure
  tier-resolution + per-tier config (no Babylon import; plain data in/out).
- `src/render/backdrop.ts` — accept a tier and build the tier's props/colours;
  expose a way to re-apply a new tier to an existing scene.
- `src/render/scene.ts` — pass the initial tier through; add `setKennelTier(n)`
  (or `setKennelUpgrades(ids)`) to the returned scene handle.
- `src/main.ts` — compute the tier from the owned-upgrade ids on startup and
  call the new handle method whenever a kennel upgrade is purchased
  (next to the existing `kennelMultiplier(kennelUpgradeIds)` call sites).
- `.docs/tech-decisions.md` — record the tier→visual mapping decision.

## Technical Approach

The **tier-resolution + config is functional → test-first (TDD)** per
[`.claude/skills/tdd`](../../.claude/skills/tdd/SKILL.md): one failing test →
minimal impl → repeat. The Babylon mesh/material wiring is render glue, exempt
from unit tests and covered by **Visual Review**.

### Behaviours to test (TDD) — `backdropTier.ts`
1. `kennelTier([])` → `0` (no upgrades).
2. `kennelTier(['treats-pouch'])` → `1`; two owned → `2`; all three → `3`.
3. Tier is driven by **count of valid owned upgrades**, clamped to `[0,3]`;
   unknown ids are ignored (so a stale save can't push tier out of range).
4. `backdropTierConfig(tier)` returns a config object that **monotonically
   increases** a documented "lushness" scalar with tier (e.g. greater ground
   greenness and prop count for higher tiers) and is defined for tiers 0-3.

### Before
```ts
// src/render/scene.ts — setupBackdrop called once, no later control
setupBackdrop(scene, ground as unknown as { material: StandardMaterial | null }, light);
return { updateDog, setBreed, notifyMark, notifyMastery, dispose };

// src/render/backdrop.ts
export function setupBackdrop(scene, groundMesh, hemiLight): void { /* static */ }
```

### After
```ts
// src/render/backdropTier.ts  (pure, fully tested)
export function kennelTier(ownedUpgradeIds: string[]): 0 | 1 | 2 | 3 {
  const valid = ownedUpgradeIds.filter(isKnownUpgrade).length;
  return Math.min(3, Math.max(0, valid)) as 0 | 1 | 2 | 3;
}
export function backdropTierConfig(tier: 0 | 1 | 2 | 3): BackdropTierConfig { /* lushness ramp */ }

// src/render/backdrop.ts — build for a tier + allow re-applying
export function setupBackdrop(scene, groundMesh, hemiLight, tier: 0|1|2|3 = 0): void { ... }
export function applyBackdropTier(scene, tier: 0|1|2|3): void { /* swap props/colours live */ }

// src/render/scene.ts — handle gains live control
setupBackdrop(scene, ground as ..., light, kennelTier(initialUpgradeIds));
return {
  ...,
  setKennelUpgrades(ids: string[]): void { applyBackdropTier(scene, kennelTier(ids)); },
};

// src/main.ts — recompute on purchase
sceneHandle.setKennelUpgrades(kennelUpgradeIds); // after a successful kennel buy + on bootstrap
```

## Risks & Considerations
- **Framing (D12):** props must stay at the scene edges, never overlapping the
  centered dog or its contact shadow; verify on a phone-portrait viewport.
- **Legibility:** added greenery/props must not reduce contrast for the dog's
  state tints (idle/offering/distractor/confused/reward) — Visual Review checks this.
- **Live update:** purchasing an upgrade must not require a scene rebuild; reuse
  the existing scene/meshes and only add/recolour. Avoid per-frame allocation.
- **Save compatibility:** tier is derived from existing `kennelUpgradeIds`; no
  save-schema change. Unknown ids are ignored (clamp), so old/foreign saves are safe.
- **Mobile perf:** keep prop polycount tiny (low-segment primitives), no new
  textures beyond what's needed; this is a mobile-only game.

## Acceptance Criteria
- [x] Failing tests written first for `kennelTier` (0/1/2/3 + clamp + unknown-id ignore) and `backdropTierConfig` (defined 0-3, monotonic lushness) — TDD red → green.
- [x] Owned-upgrade set maps to exactly 4 tiers (0-3); the backdrop visibly differs between each adjacent tier.
- [x] Buying a kennel upgrade updates the backdrop **live** (no reload); bootstrap restores the correct tier from the saved upgrade ids.
- [x] Dog stays centered and fully framed at every tier (D12); state tints remain legible; no new motion that ignores `prefers-reduced-motion`.
- [x] **Visual Review (blocking):** captured phone-portrait (390×844 @2×) screenshots at all four tiers and reviewed (main agent + an independent review subagent). First pass FAILED — props were placed at negative-z (behind the camera) so nothing showed, and rendered black (no emissive under `disableLighting`). Fixed: props moved to positive-z behind the dog, made lit+matte. Second pass found two blocking issues (tier-2 not a visual superset of tier-1; cones too dominant) — fixed by keeping front bushes closer than the deeper cones, shrinking + softening the cones, and warming the jump set to cream. Final review: clean monotonic upgrade (tier 0 bare → 1 bushes → 2 +cones+jump → 3 +fence line), dog centered/framed/unoccluded at every tier, legibility intact. SHIP.
- [x] Tier→visual mapping decision recorded in `.docs/tech-decisions.md`.
- [x] `bun run verify` green (typecheck + tests + build, no warnings); `bun run e2e` green.
