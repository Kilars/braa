# 080 — FEATURE: difficulty mode model + persisted global setting (dormant)

**Type:** FEATURE (game-logic TDD) · **Phase:** 4 — Difficulty · **Label:** `work-ahead` (PROVISIONAL —
Phase 3 is still the current, un-signed-off phase) · **Source:** `.docs/specs/phase4.md` **P4-1** ("Choose
how hard … a single global setting applied to all training") · **Priority:** foundation for the whole
Phase-4 difficulty slice (081/082 build on it).

## Why this is work-ahead (and how it stays dormant)

Phase 3 is **exhausted**: all PO directives (077/078/079) shipped, the construction audit is CLEAN, and
every open flag is busted — so Phase 3 is blocked **purely** on owner breed-assets + the human PO sign-off.
Per the spec's **Work-ahead exception** (`index.md`), the loop may build the **next** phase's buildable
stories *provisionally*. Hard guardrails, all satisfied here:

- **Dormant in the live build.** The mode defaults to **Normal**, and **Normal reproduces today's tuning
  EXACTLY** (every modifier = 1.0 identity — the same discipline `BreedPersonality` uses: "1.0 reproduces
  today's fixed feel EXACTLY, no silent regression"). No difficulty selector is wired into the default HUD;
  the mode is only reachable via a **debug seam** (`?bra_difficulty=`, off by default, exactly like the
  existing `?bra_force_tell` / `?bra_trick` / `?bra_breed` seams). So the father's Phase-3 play-test is
  **byte-identical**.
- **Independent of the blocked item.** Depends on nothing owner-gated — no new breed models, no voice. It
  composes on `BreedPersonality` (already shipped, Labrador + chocolate) and the existing scoring/loop
  constants.
- **Never advances the phase / never writes the sign-off list.** This is subordinate; the PO still signs
  Phase 3, and any reopened current-phase work preempts it.

## What it addresses

P4-1: a single global **difficulty** setting (Normal / Hard / Expert) that later stories (P4-2 the read,
P4-3 the reward, P4-4 the breed-stack) read. This task builds only the **model + the persisted setting +
the dormant seam** — no lever changes yet (that is 081), so on its own it changes **no** behavior.

## Technical approach

### 1. Pure `Difficulty` model (TDD, new `scripts/difficulty.gd`) — mirrors `BreedPersonality`

A pure value object keyed to a mode, carrying a **multiplier bundle**. Every modifier is a scalar so P4-4
can compose it as `effective = breed_intrinsic × difficulty` (see 081). **Normal = all identity.**

```gdscript
class_name Difficulty
extends RefCounted
## Global difficulty (P4-1). Pure value object; Normal = identity (reproduces today's tuning EXACTLY,
## no regression), Hard/Expert are monotonic deltas. All levers are MULTIPLIERS so 081 (P4-2) can
## apply them ON TOP of the breed-resolved values → effective = breed intrinsic × global mode (P4-4).

var id: String
var display_name: String
var window_scale: float          ## × SitWindow radii     (<1 tightens the timing window)
var tell_intensity_scale: float  ## × apex-tell motion    (<1 fainter tell)
var tell_speed_scale: float      ## × apex-tell speed     (>1 faster tell)
var feint_scale: float           ## × feint_chance        (>1 more distractors/feints)
var erosion_scale: float         ## × P2-4 learned-bar erosion on a mistimed/wrong tap (>1 harsher)
var reward_scale: float          ## × coin mastery reward (>1 — "pain pays", P4-3/082)

static func normal() -> Difficulty:  # identity — today's feel, unchanged
    return Difficulty.new("normal", "Normal", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
static func hard() -> Difficulty:
    return Difficulty.new("hard", "Hard", 0.72, 0.8, 1.15, 1.6, 1.5, 1.4)
static func expert() -> Difficulty:
    return Difficulty.new("expert", "Expert", 0.5, 0.62, 1.3, 2.4, 2.2, 2.0)

static func catalog() -> Array: return [normal(), hard(), expert()]
static func is_known(id: String) -> bool: ...        # true iff a shipped mode
static func by_id(id: String) -> Difficulty: ...      # unknown → normal() (never a dead resolve)
```
(Exact Hard/Expert numbers are a first pass — they land dormant, so they are tuned later against a real
play-test when Phase 4 becomes current. The **contract** is: Normal identity; Hard and Expert monotonically
harder than Normal on every lever.)

### 2. Persist the global setting in the ONE save blob (TDD — extend `TrickStore`)

Difficulty rides the SAME `user://` blob as tricks + coins + roster (never a second save file). Default
`"normal"`; legacy/corrupt/wrong-version degrades to `"normal"` — a broken save never boots into a mode the
player didn't pick.

**Before** (`scripts/trick_store.gd`):
```gdscript
static func encode(tricks: Dictionary, coins: int = 0, roster: Dictionary = {}) -> String:
    return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins, "roster": roster})
```
**After** — `difficulty` rides the blob, defaulting so every pre-080 caller is unchanged:
```gdscript
static func encode(tricks: Dictionary, coins: int = 0, roster: Dictionary = {},
        difficulty: String = "normal") -> String:
    return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins,
        "roster": roster, "difficulty": difficulty})
```
Add `decode_difficulty(text) -> String` + `load_difficulty()` mirroring `decode_coins`/`load_coins`: a
missing/corrupt/legacy/unknown mode → `"normal"` (validate against `Difficulty.is_known`, else `"normal"`).
Extend the `save(...)` signature the same way (default `"normal"`).

### 3. Dormant boot seam in `main.gd` (pure glue) — `?bra_difficulty=`

`_resolve_difficulty()` returns the query override (`?bra_difficulty=hard|expert|normal`) when present, else
the persisted `load_difficulty()`, else `"normal"`. Store `_difficulty := Difficulty.by_id(...)` on boot.
Mirror the existing `_query_trick`/`_query_breed` string-sentinel readers (guard the JS eval as a String, per
the recurring web-marshal gotcha). **Do NOT** add a player-facing selector to the default HUD — that is the
Phase-4-current story; here the setting is inert unless the seam explicitly picks a non-Normal mode.

## Acceptance criteria

- [x] TDD (RED→GREEN, `tests/test_difficulty.gd`): `Difficulty.normal()` is the identity bundle (every
      modifier == 1.0); Hard and Expert are **monotonically** harder than Normal on every lever
      (window_scale ↓, tell_intensity_scale ↓, tell_speed_scale ↑, feint_scale ↑, erosion_scale ↑,
      reward_scale ↑); `is_known`/`by_id` resolve shipped modes and an unknown id → `normal()`.
- [x] TDD (`tests/test_trick_store.gd`): difficulty round-trips in the same save blob alongside
      tricks+coins+roster; a legacy (pre-080) / corrupt / unknown-mode blob decodes to `"normal"`.
- [x] `main.gd` resolves `_difficulty` on boot from the persisted setting, overridable by `?bra_difficulty=`;
      with no override and a fresh/legacy save the mode is **Normal**.
- [x] **Dormancy proven:** with default Normal, the default run is behavior-identical to HEAD — no lever
      is touched yet (that is 081), and no difficulty selector appears in the default HUD.
- [x] Placeholder check clean (no stub/placeholder in shipped `scripts/`).
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Foundation only — inert by itself. 081 (P4-2/P4-4) applies the bundle to the read levers; 082 (P4-3) applies
`reward_scale`. Keep Hard/Expert numbers as a documented first pass; they are dormant and tuned when Phase 4
becomes current. Nothing here depends on owner assets.
