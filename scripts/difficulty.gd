class_name Difficulty
extends RefCounted
## Global difficulty mode (080, P4-1 "Choose how hard"). Pure value object; Normal = identity
## (reproduces today's tuning EXACTLY, no regression), Hard/Expert are monotonic deltas.
## All levers are MULTIPLIERS so P4-4 can apply them ON TOP of the breed-resolved values
## → effective = breed intrinsic × global mode (never a silent regression on Normal, never
## speculative on Hard/Expert until Phase 4 becomes current and the PO tunes live).
##
## NOTE on tell timing: there is NO independent tell_speed_scale lever. The tell's speed /
## narrowness follows the difficulty-tightened window ramp (ApexTell.ramp = window.ok_radius,
## one source of truth). Adding a separate speed multiplier would decouple the tell from the
## scoring window and break ApexTell's invariant — "faster/narrower tell" falls out for free
## when window_scale shrinks ok_radius. Only the tell's INTENSITY (damping) needs wiring.

## Small positive floor for scale_tell_intensity(): a non-zero tell never collapses to zero
## information, honouring ADR X-5 (reduced motion dampened but NEVER removed).
const TELL_FLOOR := 0.15

var id: String
var display_name: String
var window_scale: float          ## × SitWindow radii          (<1 tightens the timing window)
var tell_intensity_scale: float  ## × apex-tell motion/damping (<1 fainter tell)
var feint_scale: float           ## × feint_chance             (>1 more distractors/feints)
var erosion_scale: float         ## × P2-4 learned-bar erosion on mistimed/wrong tap (>1 harsher)
var reward_scale: float          ## × coin mastery reward      (>1 — "pain pays", P4-3/082)

func _init(p_id: String, p_name: String, p_window := 1.0, p_tell_intensity := 1.0,
		p_feint := 1.0, p_erosion := 1.0, p_reward := 1.0) -> void:
	id = p_id
	display_name = p_name
	window_scale = p_window
	tell_intensity_scale = p_tell_intensity
	feint_scale = p_feint
	erosion_scale = p_erosion
	reward_scale = p_reward

## Normal mode — identity on every lever (1.0). Reproduces today's tuning EXACTLY, no silent
## regression. The dormancy guarantee: with no difficulty selector wired (default HUD), a
## fresh/legacy boot defaults to Normal and plays byte-identical to HEAD.
static func normal() -> Difficulty:
	return Difficulty.new("normal", "Normal", 1.0, 1.0, 1.0, 1.0, 1.0)

## Hard mode — monotonically harder than Normal on every lever. Window tightens, tell fades,
## feints multiply, erosion hardens, reward rises. First-pass tuning, dormant until Phase 4
## becomes current; subject to PO refinement in live play-test.
static func hard() -> Difficulty:
	return Difficulty.new("hard", "Hard", 0.72, 0.8, 1.6, 1.5, 1.4)

## Expert mode — monotonically harder than Hard on every lever. The peak difficulty stack.
## First-pass tuning, dormant until Phase 4 becomes current; subject to PO refinement.
static func expert() -> Difficulty:
	return Difficulty.new("expert", "Ekspert", 0.5, 0.62, 2.4, 2.2, 2.0)

## The shipped difficulty modes, in order: Normal, Hard, Expert. The ONLY place the mode
## list is enumerated — is_known, by_id, and any future UI read this.
static func catalog() -> Array:
	return [normal(), hard(), expert()]

## True iff `id` names a shipped mode (never an unshipped / ghost / typo id).
static func is_known(id: String) -> bool:
	for d in catalog():
		if (d as Difficulty).id == id:
			return true
	return false

## Resolve a mode id to its Difficulty bundle. An unknown id falls back to Normal — never a
## dead resolve, so a corrupt/legacy mode id still boots the safe default (identity).
static func by_id(id: String) -> Difficulty:
	for d in catalog():
		if (d as Difficulty).id == id:
			return d
	return normal()

# ---- Composition accessors (081, P4-2/P4-4): effective = breed_intrinsic × difficulty.<scale>
# Pure arithmetic on the model — the same discipline as BreedPersonality's resolved levers.
# Normal = identity on all four (dormancy: effective == breed value, byte-identical default play).

## Scale a SitWindow radius by this difficulty's window_scale.
## Normal is identity (× 1.0). Hard/Expert tighten the window (< 1.0).
func scale_radius(breed_radius: float) -> float:
	return breed_radius * window_scale

## Scale a feint chance by this difficulty's feint_scale, clamped to [0, 1].
## Normal is identity (× 1.0). Hard/Expert raise the feint rate (> 1.0), capped at 1.0.
func scale_feint(breed_feint: float) -> float:
	return clampf(breed_feint * feint_scale, 0.0, 1.0)

## Scale a base erosion amount by this difficulty's erosion_scale.
## Normal is identity (× 1.0). Hard/Expert harden the bar drain (> 1.0).
func scale_erosion(base: float) -> float:
	return base * erosion_scale

## Scale a tell motion/damping value by this difficulty's tell_intensity_scale, clamped to
## [TELL_FLOOR, 1.0]. Normal is identity (× 1.0). Hard/Expert fade the tell (< 1.0).
## The floor ensures a non-zero tell never collapses to zero information (ADR X-5: reduced
## motion is dampened but NEVER removed). The tell's TIMING (faster/narrower) falls out for
## free from the tightened window (ok_radius already scaled) — no independent speed lever.
func scale_tell_intensity(motion: float) -> float:
	return clampf(motion * tell_intensity_scale, TELL_FLOOR, 1.0)

## Mastery coin payout for this difficulty mode (P4-3, 082): base × reward_scale, rounded to a whole coin.
## Normal is identity (× 1.0) — the dormancy guarantee, byte-identical default economy.
## Hard/Expert pay strictly more ("pain pays").
func mastery_reward(base: int) -> int:
	return int(round(base * reward_scale))
