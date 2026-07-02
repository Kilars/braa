class_name Difficulty
extends RefCounted
## Global difficulty mode (080, P4-1 "Choose how hard"). Pure value object; Normal = identity
## (reproduces today's tuning EXACTLY, no regression), Hard/Expert are monotonic deltas.
## All levers are MULTIPLIERS so P4-4 can apply them ON TOP of the breed-resolved values
## → effective = breed intrinsic × global mode (never a silent regression on Normal, never
## speculative on Hard/Expert until Phase 4 becomes current and the PO tunes live).

var id: String
var display_name: String
var window_scale: float          ## × SitWindow radii     (<1 tightens the timing window)
var tell_intensity_scale: float  ## × apex-tell motion    (<1 fainter tell)
var tell_speed_scale: float      ## × apex-tell speed     (>1 faster tell)
var feint_scale: float           ## × feint_chance        (>1 more distractors/feints)
var erosion_scale: float         ## × P2-4 learned-bar erosion on mistimed/wrong tap (>1 harsher)
var reward_scale: float          ## × coin mastery reward (>1 — "pain pays", P4-3/082)

func _init(p_id: String, p_name: String, p_window := 1.0, p_tell_intensity := 1.0,
		p_tell_speed := 1.0, p_feint := 1.0, p_erosion := 1.0, p_reward := 1.0) -> void:
	id = p_id
	display_name = p_name
	window_scale = p_window
	tell_intensity_scale = p_tell_intensity
	tell_speed_scale = p_tell_speed
	feint_scale = p_feint
	erosion_scale = p_erosion
	reward_scale = p_reward

## Normal mode — identity on every lever (1.0). Reproduces today's tuning EXACTLY, no silent
## regression. The dormancy guarantee: with no difficulty selector wired (default HUD), a
## fresh/legacy boot defaults to Normal and plays byte-identical to HEAD.
static func normal() -> Difficulty:
	return Difficulty.new("normal", "Normal", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

## Hard mode — monotonically harder than Normal on every lever. Window tightens, tell fades
## and speeds, feints multiply, erosion hardens, reward rises. First-pass tuning, dormant
## until Phase 4 becomes current; subject to PO refinement in live play-test.
static func hard() -> Difficulty:
	return Difficulty.new("hard", "Hard", 0.72, 0.8, 1.15, 1.6, 1.5, 1.4)

## Expert mode — monotonically harder than Hard on every lever. The peak difficulty stack.
## First-pass tuning, dormant until Phase 4 becomes current; subject to PO refinement.
static func expert() -> Difficulty:
	return Difficulty.new("expert", "Expert", 0.5, 0.62, 1.3, 2.4, 2.2, 2.0)

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
