# 075 — FEATURE: BreedPersonality — temperament drives the difficulty levers (P3-3)

**Type:** FEATURE (game-logic, TDD) · **Phase:** 3 (current) · **Source:** PO Review 2026-07-02
`po-review.md` **Improvement 4** (P3-3 "Training has no breed-personality dimension yet") +
**BUST-068** (economy/personality spine is buildable **without the owner**, keyed to the Labrador
as breed #1) · **Priority:** P2 for this phase — the foundation that makes breeds "deep kits, not
skins." Buildable now; **zero dependency** on additional breed models.

## What it addresses

Every session trains identically today — learn speed, distractibility, window stability and energy
are the same fixed feel regardless of "which dog." P3-3 requires **personality to drive the
difficulty levers** so a breed is a temperament, not a paint job. The levers already exist and are
already tunable; they are just hard-coded constants. This task introduces a `BreedPersonality` data
model that supplies those values **per breed**, wired to the existing systems, keyed to the
**Labrador as breed #1** so the single starter breed has a *defined* temperament and the levers are
proven before any second breed (see 074 chocolate-Lab bust) lands.

The four levers from BUST-068, each mapped to an existing knob:

| Personality trait   | Existing lever                                          | Effect |
|---------------------|---------------------------------------------------------|--------|
| **learn_speed**     | `TrickProgress.PERFECT_GAIN` / `OK_GAIN`                | fills the learned bar faster/slower |
| **distractibility** | `SitLoop.feint_chance`                                  | more/fewer feints between offers |
| **window_stability**| `SitWindow.perfect_radius` / `ok_radius` (+ `late_bias`)| tighter/looser timing window |
| **energy**          | `SitLoop.MIN_INTER_SIT_GAP` / `MAX_INTER_SIT_GAP`       | offers come quicker/slower |

## Technical approach (TDD — pure data model + wiring)

New pure class `scripts/breed_personality.gd` (`class_name BreedPersonality`, `extends RefCounted`)
— a value object holding the four traits as **multipliers around 1.0** (so 1.0 = today's baseline
and the Labrador can be tuned deliberately), plus a `name`/`id`. It exposes the *resolved* lever
values so callers don't scatter the arithmetic.

**New** (`scripts/breed_personality.gd`):
```gdscript
class_name BreedPersonality
extends RefCounted
## Per-breed temperament → the difficulty levers (P3-3). Pure + unit-testable.
## Multipliers are around 1.0: 1.0 reproduces today's fixed feel, so the Labrador (#1)
## is a deliberate baseline and later breeds are deltas from it — "deep kits, not skins".

var id: String
var display_name: String
var learn_speed: float       ## × TrickProgress gains  (>1 learns faster)
var distractibility: float   ## × SitLoop.feint_chance (>1 feints more)
var window_stability: float  ## × SitWindow radii      (>1 = more forgiving timing)
var energy: float            ## × inverse of inter-sit gap (>1 = quicker offers)

func _init(p_id: String, p_name: String, p_learn := 1.0, p_distract := 1.0,
		p_window := 1.0, p_energy := 1.0) -> void:
	id = p_id; display_name = p_name
	learn_speed = p_learn; distractibility = p_distract
	window_stability = p_window; energy = p_energy

## The Labrador — breed #1. A famously trainable, eager, food-motivated retriever:
## learns a touch fast, steady focus (few feints), forgiving timing, medium-high energy.
static func labrador() -> BreedPersonality:
	return BreedPersonality.new("labrador", "Labrador", 1.15, 0.9, 1.1, 1.0)

## Resolved levers (callers use these, not raw multipliers):
func perfect_gain() -> float: return TrickProgress.PERFECT_GAIN * learn_speed
func ok_gain() -> float:      return TrickProgress.OK_GAIN * learn_speed
func feint_chance() -> float: return clampf(SitLoop.FEINT_CHANCE * distractibility, 0.0, 1.0)
func perfect_radius() -> float: return SitWindow.DEFAULT_PERFECT_RADIUS * window_stability
func ok_radius() -> float:      return SitWindow.DEFAULT_OK_RADIUS * window_stability
func min_gap() -> float: return SitLoop.MIN_INTER_SIT_GAP / energy
func max_gap() -> float: return SitLoop.MAX_INTER_SIT_GAP / energy
```

**Wiring** — thread the active breed's resolved values into the existing systems instead of the
bare constants. Keep it **additive and non-regressing**: the Labrador multipliers are chosen so the
felt experience stays in the PO-signed Phase-2 band (small, deliberate deltas, not a shake-up).

- `TrickProgress.apply()` currently uses `PERFECT_GAIN`/`OK_GAIN` directly. Add an optional
  per-instance gain override (constructor params defaulting to the constants) so `main.gd` can build
  each trick's progress with the breed's `perfect_gain()`/`ok_gain()`. Do **not** change the
  constants themselves (other call sites + the mastery checkpoint math depend on them).

  **Before:**
  ```gdscript
  const PERFECT_GAIN := 0.20
  const OK_GAIN := 0.08
  func apply(tier: int) -> float:
      ...  # uses PERFECT_GAIN / OK_GAIN
  ```
  **After:**
  ```gdscript
  const PERFECT_GAIN := 0.20
  const OK_GAIN := 0.08
  var _perfect_gain := PERFECT_GAIN
  var _ok_gain := OK_GAIN
  func _init(p_perfect := PERFECT_GAIN, p_ok := OK_GAIN) -> void:
      _perfect_gain = p_perfect; _ok_gain = p_ok
  func apply(tier: int) -> float:
      ...  # uses _perfect_gain / _ok_gain
  ```

- `SitLoop`: `main.gd` already sets `_loop.feint_chance`; set it from `personality.feint_chance()`.
  Set the inter-sit gap bounds from `min_gap()`/`max_gap()` (add settable `min_gap`/`max_gap` vars on
  `SitLoop` defaulting to the current `MIN/MAX_INTER_SIT_GAP` if not already present, and have
  `_draw_next_gap()` read them).
- `SitWindow`: build the per-sit window with `personality.perfect_radius()`/`ok_radius()` (compose
  with 073's `late_bias`).
- `main.gd`: hold a single `var _breed := BreedPersonality.labrador()` and feed it into the above at
  construction. One breed for now — the multi-breed selector wires in once 074/roster land.

### TDD (follow `.claude/skills/tdd/SKILL.md`)

Write FIRST in a new `tests/test_breed_personality.gd` (+ extend `test_trick_progress.gd` /
`test_sit_loop.gd` for the override wiring). Behaviors to lock:

```gdscript
func test_neutral_personality_reproduces_baseline() -> void:
	# All-1.0 multipliers resolve to exactly today's constants (no silent regression).
	var p := BreedPersonality.new("x", "X")   # defaults 1.0
	assert_eq(p.perfect_gain(), TrickProgress.PERFECT_GAIN)
	assert_eq(p.feint_chance(), SitLoop.FEINT_CHANCE)
	assert_eq(p.perfect_radius(), SitWindow.DEFAULT_PERFECT_RADIUS)

func test_labrador_has_defined_temperament() -> void:
	# Breed #1 is a deliberate temperament, not the neutral default.
	var lab := BreedPersonality.labrador()
	assert_true(lab.learn_speed > 1.0, "the Labrador learns a touch fast")
	assert_true(lab.feint_chance() < SitLoop.FEINT_CHANCE, "steady focus → fewer feints than baseline")

func test_higher_learn_speed_fills_bar_faster() -> void:
	var fast := TrickProgress.new(0.20 * 1.5, 0.08 * 1.5)
	var base := TrickProgress.new()
	fast.apply(SitWindow.Tier.PERFECT); base.apply(SitWindow.Tier.PERFECT)
	assert_true(fast.value > base.value, "a higher learn_speed fills the learned bar faster")

func test_more_energy_shortens_offer_gap() -> void:
	var lab := BreedPersonality.new("l", "L", 1.0, 1.0, 1.0, 2.0)  # double energy
	assert_true(lab.max_gap() < SitLoop.MAX_INTER_SIT_GAP, "more energy → quicker offers")
```

Watch each go RED (class/overrides absent) → GREEN. Keep every existing `test_trick_progress.gd`
and `test_sit_loop.gd` assertion green: the constructor defaults must reproduce the current
behavior exactly (that is the anti-regression contract).

## Acceptance criteria

- [ ] TDD: `tests/test_breed_personality.gd` written first (RED → GREEN) covering: neutral
      personality == baseline constants; Labrador has a defined (non-neutral) temperament; higher
      learn_speed fills the bar faster; more energy shortens the gap.
- [ ] `BreedPersonality` (pure `RefCounted`) exposes resolved levers (`perfect_gain`/`ok_gain`/
      `feint_chance`/`perfect_radius`/`ok_radius`/`min_gap`/`max_gap`) and a `labrador()` breed #1.
- [ ] `TrickProgress` takes optional per-instance gain overrides **defaulting to the current
      constants** (no existing call site or test regresses); `SitLoop` gap bounds + feint chance and
      `SitWindow` radii are driven from the active breed in `main.gd`.
- [ ] `main.gd` holds one active `BreedPersonality` (Labrador) feeding all four levers; the felt
      experience stays in the PO-signed Phase-2 band (additive, small deltas — no shake-up).
- [ ] Placeholder check clean on the diff; `nix develop -c bash verify.sh` green
      (import·boot·test·export).

## Notes

Pure logic + wiring — no new asset, no Visual Review (the *feel* shift is subtle and additive; the
owner judges temperament on his next play-test). Ships with **one** breed (Labrador), so nothing
multi-breed is exposed in the default run — the multi-breed selector/adopt UI stays owner-gated
(P3-1/P3-2 appearance + D1/D2/D4) and wires in only once 074 (chocolate recolor) and/or an owner
model + roster (Change-5) land. This is the **spine** the roster and additional breeds hang off.
