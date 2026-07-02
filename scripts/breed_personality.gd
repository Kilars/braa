class_name BreedPersonality
extends RefCounted
## Per-breed temperament → the difficulty levers (075, P3-3 "Training has no breed-personality
## dimension yet"). Pure value object + unit-testable (test_breed_personality.gd) — no engine state.
##
## A breed is a TEMPERAMENT, not a paint job: the four traits below drive the levers that already
## exist as tunable constants, so the felt training experience differs per dog. Multipliers are
## around 1.0 — 1.0 reproduces today's fixed feel EXACTLY (no silent regression), so the Labrador
## (breed #1) is a deliberate baseline and later breeds are deltas from it ("deep kits, not skins").
##
## The resolved-lever accessors below are the ONLY thing callers touch — they compose each trait
## with the existing canonical constant so the arithmetic never scatters across main.gd:
##   learn_speed      × TrickProgress.PERFECT_GAIN / OK_GAIN        (fills the learned bar faster)
##   distractibility  × SitLoop.FEINT_CHANCE                        (more/fewer feints between offers)
##   window_stability × SitWindow.DEFAULT_PERFECT_RADIUS / OK_RADIUS (tighter/looser timing window)
##   energy           ÷ SitLoop.MIN/MAX_INTER_SIT_GAP               (offers come quicker/slower)

var id: String
var display_name: String
var learn_speed: float       ## × TrickProgress gains  (>1 learns faster)
var distractibility: float   ## × SitLoop.feint_chance (>1 feints more)
var window_stability: float  ## × SitWindow radii      (>1 = more forgiving timing)
var energy: float            ## × inverse of inter-sit gap (>1 = quicker offers)

func _init(p_id: String, p_name: String, p_learn := 1.0, p_distract := 1.0,
		p_window := 1.0, p_energy := 1.0) -> void:
	id = p_id
	display_name = p_name
	learn_speed = p_learn
	distractibility = p_distract
	window_stability = p_window
	energy = p_energy

## The Labrador — breed #1. A famously trainable, eager, food-motivated retriever: learns a touch
## fast, steady focus (few feints), forgiving timing, medium-high energy. Small deliberate deltas so
## the felt experience stays inside the PO-signed Phase-2 band (additive, not a shake-up).
static func labrador() -> BreedPersonality:
	return BreedPersonality.new("labrador", "Labrador", 1.15, 0.9, 1.1, 1.0)

## Resolved levers (callers use these, not the raw multipliers) — each composes a trait with the
## canonical constant that owns the tuning, so the multiplier meaning stays in one place.
func perfect_gain() -> float: return TrickProgress.PERFECT_GAIN * learn_speed
func ok_gain() -> float:      return TrickProgress.OK_GAIN * learn_speed
func feint_chance() -> float: return clampf(SitLoop.FEINT_CHANCE * distractibility, 0.0, 1.0)
func perfect_radius() -> float: return SitWindow.DEFAULT_PERFECT_RADIUS * window_stability
func ok_radius() -> float:      return SitWindow.DEFAULT_OK_RADIUS * window_stability
func min_gap() -> float: return SitLoop.MIN_INTER_SIT_GAP / energy
func max_gap() -> float: return SitLoop.MAX_INTER_SIT_GAP / energy
