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
var _coat_tint: Color        ## multiplied over the coat albedo atlas (076) — see coat_tint()

func _init(p_id: String, p_name: String, p_learn := 1.0, p_distract := 1.0,
		p_window := 1.0, p_energy := 1.0, p_tint := Color(1, 1, 1)) -> void:
	id = p_id
	display_name = p_name
	learn_speed = p_learn
	distractibility = p_distract
	window_stability = p_window
	energy = p_energy
	_coat_tint = p_tint

## The Labrador — breed #1. A famously trainable, eager, food-motivated retriever: learns a touch
## fast, steady focus (few feints), forgiving timing, medium-high energy. Small deliberate deltas so
## the felt experience stays inside the PO-signed Phase-2 band (additive, not a shake-up).
static func labrador() -> BreedPersonality:
	return BreedPersonality.new("labrador", "Labrador", 1.15, 0.9, 1.1, 1.0)

## The Chocolate Labrador — breed #2 (076, BUST-074). The SAME licensed rig, recolored at runtime by
## multiplying its one coat atlas by coat_tint() (≈#AA7D51) — a genuine second breed with NO new owner
## model. Temperament-wise a warmer, busier retriever than the yellow Lab: the field-bred chocolate line
## reads as a touch more distractible and higher-energy, still eminently trainable (learn_speed just under
## the yellow Lab's) with slightly less forgiving timing. Distinct on every axis so it FEELS like its own
## dog, not a palette swap.
static func chocolate_labrador() -> BreedPersonality:
	# Coat tint tuned against the REAL render (076 Visual Review): the bust's computed ~#AA7D51 came out
	# a light, reddish milk-chocolate under the bright scene sun — darkened toward a deeper coffee brown
	# (~#805E42) so it reads unmistakably as a Chocolate Lab, not a fox-red / muddy-yellow lab.
	# Display name is Norwegian AND short (076/138/157 localization; PO father-pass-26): the English
	# "Chocolate Labrador" was the one English string left in the otherwise 100%-Norwegian «Raser» menu,
	# and it elided to «Chocolate…» under the «Adopter 30» badge. The breed-row name budget is only ~132 px
	# at NAME_SIZE 26 (Nunito Bold) once the wide «Adopter 30» badge is subtracted — measured in-engine, so
	# «Brun labrador» (155 px) and even the PO's «Sjokoladelab» (145 px) still elide. «Brun lab» (96 px) —
	# "brown lab", the everyday Norwegian short form, matching the brown coat swatch beside it and pairing
	# cleanly with «Labrador» one row up — renders COMPLETE. The id stays "chocolate_labrador" (display-only).
	return BreedPersonality.new("chocolate_labrador", "Brun lab",
		1.1, 1.1, 1.0, 1.1, Color(0.50, 0.37, 0.26))

## Resolved levers (callers use these, not the raw multipliers) — each composes a trait with the
## canonical constant that owns the tuning, so the multiplier meaning stays in one place.
func perfect_gain() -> float: return TrickProgress.PERFECT_GAIN * learn_speed
func ok_gain() -> float:      return TrickProgress.OK_GAIN * learn_speed
func feint_chance() -> float: return clampf(SitLoop.FEINT_CHANCE * distractibility, 0.0, 1.0)
func perfect_radius() -> float: return SitWindow.DEFAULT_PERFECT_RADIUS * window_stability
func ok_radius() -> float:      return SitWindow.DEFAULT_OK_RADIUS * window_stability
func min_gap() -> float: return SitLoop.MIN_INTER_SIT_GAP / energy
func max_gap() -> float: return SitLoop.MAX_INTER_SIT_GAP / energy

## The breed's coat colour, multiplied over the baked albedo atlas by CoatTint (076). The yellow
## Labrador is the identity Color(1,1,1) — its atlas IS the coat colour, so it's left untouched; the
## chocolate Labrador multiplies the atlas into the warm-brown chocolate range. A paint job layered on
## top of a real temperament, not a substitute for one.
func coat_tint() -> Color: return _coat_tint

## The honest coat-colour chip the adopt/select menu shows (079) — NOT a faked breed image, just the
## real coat colour as a swatch. A tinted breed shows its tint directly; the yellow Labrador's tint is
## the identity (its coat IS the atlas, so there's no tint to show), so it falls back to the atlas's
## representative sandy-yellow. So the two breeds read as clearly different, honest coat colours.
const LAB_SWATCH := Color(0.86, 0.72, 0.47)  ## the yellow Lab's atlas reads as this warm sandy tan
func swatch_color() -> Color:
	return LAB_SWATCH if _coat_tint.is_equal_approx(Color(1, 1, 1)) else _coat_tint

# ---- the catalog the roster + adopt-select menu read (079) ----------------------------------------
## The shipped breeds, in roster order (starter first). The ONLY place the breed list is enumerated —
## is_known / by_id / the menu all read this, so a new breed is a one-line add here.
static func catalog() -> Array:
	return [labrador(), chocolate_labrador()]

## True iff `id` names a shipped breed (never an unshipped / owner-gated / ghost id). The roster admits
## only known ids; the store degrades an unknown saved id away.
static func is_known(id: String) -> bool:
	for b in catalog():
		if (b as BreedPersonality).id == id:
			return true
	return false

## Resolve a breed id to its personality. An unknown id falls back to the starter Labrador — never a
## dog-less resolve, so a corrupt/legacy active id still boots a real dog.
static func by_id(id: String) -> BreedPersonality:
	for b in catalog():
		if (b as BreedPersonality).id == id:
			return b
	return labrador()

## Repoint an existing TrickProgress's gains to this breed's learn_speed (079, live breed switch), so a
## more-trainable breed fills its learned bar faster the moment the player switches to it.
func apply_gains_to(progress: TrickProgress) -> void:
	progress.set_gains(perfect_gain(), ok_gain())
