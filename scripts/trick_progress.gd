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

## Apply a scored tap. Returns the SIGNED delta actually applied after clamping, so main can
## drive feedback: delta > 0 → the bar filled; delta < 0 → a setback (confused beat + the bar
## visibly drops); see just_mastered() for the one-shot celebratory beat.
func apply(tier: int) -> float:
	var before := value
	match tier:
		SitWindow.Tier.PERFECT: value += PERFECT_GAIN
		SitWindow.Tier.OK:      value += OK_GAIN
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
