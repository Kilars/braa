class_name SitLoop
extends RefCounted
## The round loop (027, P1-9): keeps the single mark REPEATING — idle → sit → markable
## window → back to idle → next sit, indefinitely. Before this, main.gd played the sit once
## on load and then stalled (the session never closed, the dog never stood, no second sit).
##
## 048 (P2-8 "a dog with a mind of its own") kills the metronome the loop used to be:
##   - The idle gap between offers is now drawn FRESH each cycle from [MIN, MAX] — there is no
##     fixed beat to game.
##   - Some offers are FEINTS: the dog starts a sit then aborts it. A feint opens NO markable
##     window (the loop reports FEINTING, not SITTING), so main keeps the session closed and a
##     tap during it is a wrong-moment DEAD → gentle erosion (P2-4). Only a real, completed
##     Sitt has a markable apex.
##
## Determinism comes from an INJECTED, seeded RandomNumberGenerator (a seeded Godot RNG is
## fully deterministic), so the varying cadence and feint coin-flips are unit-testable headless
## exactly like SitWindow / SitSession; production constructs one with a random seed. SitLoop
## touches no Node and holds no AnimationPlayer — main.gd advances it from _process and acts on
## the Intent (START_SIT/END_SIT for a real sit; START_FEINT/END_FEINT for a dip-and-abort).
##
## On a dog that cannot sit (the CC0 placeholder, no Sitt clip) the loop parks in IDLE forever
## and emits NEITHER a sit NOR a feint — the feint reuses the real sit build-in, so a sit-less
## dog can never fake one (P1-1 / 024b). It lights up the moment the sit-capable Labrador ships.

enum State { IDLE, SITTING, FEINTING }
enum Intent { NONE, START_SIT, END_SIT, START_FEINT, END_FEINT }

const MIN_INTER_SIT_GAP := 0.8   ## shortest idle beat before the next offer
const MAX_INTER_SIT_GAP := 2.0   ## longest — the spread is what kills the metronome
const DEFAULT_SIT_HOLD := 0.5    ## seconds to hold the seated pose past the window close
const FEINT_CHANCE := 0.35       ## fraction of offers that abort (a feint) instead of completing
const FEINT_HOLD := 0.45         ## seconds the aborted dip is held before standing back up

var sit_hold: float            ## seconds the dog holds the seat past the markable window
var _rng: RandomNumberGenerator
var _state: int = State.IDLE
var _idle_elapsed: float = 0.0   ## seconds accumulated in the current idle gap
var _feint_elapsed: float = 0.0  ## seconds accumulated in the current feint dip
var _next_gap: float = 0.0       ## this cycle's idle gap, drawn fresh from [MIN, MAX] each idle

## rng: inject a seeded RandomNumberGenerator for deterministic tests; null (production) builds
## one with a random seed. p_sit_hold: seconds to hold the seat past the markable window.
func _init(rng: RandomNumberGenerator = null, p_sit_hold := DEFAULT_SIT_HOLD) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()
	sit_hold = p_sit_hold
	_draw_next_gap()

## Draw this idle cycle's gap fresh from [MIN, MAX] — the spread is what removes the metronome.
func _draw_next_gap() -> void:
	_next_gap = _rng.randf_range(MIN_INTER_SIT_GAP, MAX_INTER_SIT_GAP)

## Park the loop back in IDLE and draw a fresh gap (066, P2-1). main calls this when the player picks
## a different trick mid-offer: it closes the open sit on the OLD trick, then resets here so the next
## offer comes round fresh as the newly-chosen trick. Without it the loop would stay SITTING while the
## session is closed — its SITTING branch waits on session_elapsed (now frozen), so it would never
## come round again and the game would stall. Idempotent from any state.
func reset_to_idle() -> void:
	_state = State.IDLE
	_idle_elapsed = 0.0
	_feint_elapsed = 0.0
	_draw_next_gap()

func state() -> int:
	return _state

func is_sitting() -> bool:
	return _state == State.SITTING

## True while a feint dip is playing (no markable window is open — P2-8).
func is_feinting() -> bool:
	return _state == State.FEINTING

## The gap (seconds) the loop is currently waiting out before the next offer — drawn fresh each
## idle cycle. Exposed so tests can pin the variable-cadence contract through the public surface.
func next_gap() -> float:
	return _next_gap

## Advance the loop one frame and return the Intent main.gd should act on.
##   delta           — frame delta seconds.
##   has_sit         — can the loaded dog sit? false (CC0) keeps the loop IDLE forever.
##   session_elapsed — seconds into the current sit (only meaningful while SITTING).
##   sit_end         — the markable window's end (seated-span end) for the open sit.
func tick(delta: float, has_sit: bool, session_elapsed: float, sit_end: float) -> int:
	match _state:
		State.IDLE:
			# Never offer anything the dog can't perform — park in idle (P1-1, no faked sit
			# or feint; the feint reuses the real sit build-in, so a sit-less dog has none).
			if not has_sit:
				return Intent.NONE
			_idle_elapsed += delta
			if _idle_elapsed >= _next_gap:
				_idle_elapsed = 0.0
				# Coin-flip this offer: a feint dips-and-aborts (no window), a real offer sits.
				if _rng.randf() < FEINT_CHANCE:
					_state = State.FEINTING
					_feint_elapsed = 0.0
					return Intent.START_FEINT
				_state = State.SITTING
				return Intent.START_SIT
			return Intent.NONE
		State.SITTING:
			# Hold the seated pose a beat past the markable window, then stand back up and draw
			# a fresh gap so the next offer comes round on a new, non-metronome beat.
			if session_elapsed >= sit_end + sit_hold:
				_state = State.IDLE
				_idle_elapsed = 0.0
				_draw_next_gap()
				return Intent.END_SIT
			return Intent.NONE
		State.FEINTING:
			# Hold the aborted dip briefly, then stand straight back up — no seated apex ever
			# (a feint opens no scoring window). Draw a fresh gap for the next cycle.
			_feint_elapsed += delta
			if _feint_elapsed >= FEINT_HOLD:
				_state = State.IDLE
				_idle_elapsed = 0.0
				_draw_next_gap()
				return Intent.END_FEINT
			return Intent.NONE
	return Intent.NONE
