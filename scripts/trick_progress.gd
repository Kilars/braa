class_name TrickProgress
extends RefCounted
## Per-trick learned progress (045, P2-4 "feel the dog learning"). One instance = one
## trick's learned bar in [0, 1]. Pure + unit-testable (test_trick_progress.gd); main.gd
## feeds it the scored SitWindow.Tier on every BRA tap and reads `value` for the on-screen
## bar. Keyed per trick by construction (one instance per trick) so the selector (P2-1) and
## persistence (P2-5) drop in later — today there is exactly one trick, Sitt, so main holds
## a single instance.
##
## The rules (P2-4, as amended by the 2026-06-29 PO directive on negative learning):
##   - A well-timed BRA fills the bar; PERFECT fills more than OK.
##   - A mistimed tap (MISS) or a tap with no real apex (DEAD — a feint/ambient moment,
##     P2-8) ERODES it. DEAD is gentler than MISS (a no-window tap vs. a real mistime).
##   - Good play always NETS FORWARD: PERFECT_GAIN > both erosions, so a single bad tap
##     can never wipe out a clean mark. The bar floors at 0; a bad tap can't end the game.
##   - 100% latches mastery with a celebratory beat (main plays the joyful reaction) and is
##     a SAFE CHECKPOINT: once mastered, erosion can't drop below MASTERY (re-practice can't
##     un-master), and mastered tricks stay re-practiceable.

## Tuning, homed here (no scattered literals — cf. 029). Early game is deliberately GENTLE;
## harsher erosion is a Phase-4 difficulty knob (P4-2). The net-forward invariant the tests
## pin: PERFECT_GAIN > max(MISS_EROSION, DEAD_EROSION).
const PERFECT_GAIN := 0.20
const OK_GAIN := 0.08
const MISS_EROSION := 0.10  ## a real apex, mistimed
const DEAD_EROSION := 0.05  ## a tap with no open window (feint / ambient) — gentler
const MASTERY := 1.0
const FLOOR := 0.0

var value: float = 0.0      ## learned fraction in [0, 1]
var mastered: bool = false  ## latches true at value >= MASTERY; never un-latches (safe checkpoint)

## Per-instance gains, defaulting to the canonical constants so every existing call site behaves
## EXACTLY as before (the anti-regression contract). The breed-personality model (075, P3-3) builds
## a trick's progress with the active breed's learn_speed-scaled gains (perfect_gain()/ok_gain()) so
## a more trainable dog fills its learned bar faster. The constants stay the baseline — the mastery
## checkpoint math and other call sites depend on them — only the applied gain is overridable.
var _perfect_gain := PERFECT_GAIN
var _ok_gain := OK_GAIN

func _init(p_perfect := PERFECT_GAIN, p_ok := OK_GAIN) -> void:
	_perfect_gain = p_perfect
	_ok_gain = p_ok

## Repoint the applied per-instance gains (079, live breed switch). When the player switches the active
## breed at runtime, its learn_speed re-scales the fill applied on the NEXT tap without rebuilding the
## model — so the felt fill speed matches the chosen dog. The canonical constants stay the baseline
## (the mastery checkpoint math keys off them); only the applied gain changes.
func set_gains(p_perfect: float, p_ok: float) -> void:
	_perfect_gain = p_perfect
	_ok_gain = p_ok

## Apply a scored tap. Returns the SIGNED delta actually applied after clamping, so main can
## drive feedback: delta > 0 → the bar filled; delta < 0 → a setback (confused beat + the bar
## visibly drops); see just_mastered() for the one-shot celebratory beat.
func apply(tier: int) -> float:
	var before := value
	match tier:
		SitWindow.Tier.PERFECT: value += _perfect_gain
		SitWindow.Tier.OK:      value += _ok_gain
		SitWindow.Tier.MISS:    value -= MISS_EROSION
		SitWindow.Tier.DEAD:    value -= DEAD_EROSION
	# Mastery is a safe checkpoint: once mastered, the floor rises to MASTERY so re-practice
	# can never drop a mastered trick below 100%.
	var low := MASTERY if mastered else FLOOR
	value = clampf(value, low, MASTERY)
	if value >= MASTERY:
		mastered = true
	return value - before

## True only on the tap that FIRST reaches mastery (drives the one-shot celebratory beat).
## `applied_delta` is the value apply() returned for that same tap: a positive delta whose
## pre-tap value was below MASTERY means this tap is the one that crossed.
func just_mastered(applied_delta: float) -> bool:
	return mastered and applied_delta > 0.0 and (value - applied_delta) < MASTERY

## Persistence (049, P2-5): the model owns its own serializable shape so the save store
## (TrickStore) stays dumb about the rules (mastery latch, floor). to_dict() + restore() are
## a pair — restore(to_dict()) is the identity.
func to_dict() -> Dictionary:
	return {"value": value, "mastered": mastered}

## Restore from a saved entry (049, P2-5). Clamps value into [FLOOR, MASTERY] and re-latches
## mastery so a returning player's SAFE CHECKPOINT survives a reload: once `mastered` is set,
## apply()'s floor keeps re-practice from dropping below MASTERY. Missing / out-of-range /
## garbage keys default to a clean clamped zero so a partial save never crashes.
func restore(d: Dictionary) -> void:
	value = clampf(float(d.get("value", 0.0)), FLOOR, MASTERY)
	mastered = bool(d.get("mastered", false))
