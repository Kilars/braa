class_name SitLoop
extends RefCounted
## The Phase-1 round loop (027, specs2.md P1-9): keeps the single mark REPEATING —
## idle → sit → markable window → back to idle → next sit, indefinitely. Before this,
## main.gd played the sit exactly once on load and then stalled (the session never
## closed, the dog never stood, no second sit ever came round).
##
## SitLoop is deliberately pure: it owns only the loop's state and timers and returns an
## Intent each frame. It touches no Node and holds no AnimationPlayer, so it is unit-
## tested headless exactly like SitWindow / SitSession. main.gd advances it from _process
## and acts on the Intent — START_SIT → play the sit + open the scoring window + build the
## tell; END_SIT → close the session + stand back down to the ambient idle.
##
## On a dog that cannot sit (the CC0 placeholder, no Sitt clip) the loop parks in IDLE
## forever and never emits START_SIT — the scene simply idles as it does today, never a
## faked sit (P1-1 / 024b). It lights up the moment the sit-capable Labrador ships (025).

enum State { IDLE, SITTING }
enum Intent { NONE, START_SIT, END_SIT }

const DEFAULT_INTER_SIT_GAP := 1.2  ## seconds idle between sits — a calm beat, not frantic
const DEFAULT_SIT_HOLD := 0.5       ## seconds to hold the seated pose past the window close

var inter_sit_gap: float  ## idle seconds before the next sit begins
var sit_hold: float       ## seconds the dog holds the seat past the markable window
var _state: int = State.IDLE
var _idle_elapsed: float = 0.0  ## seconds accumulated in the current idle gap

func _init(p_inter_sit_gap := DEFAULT_INTER_SIT_GAP, p_sit_hold := DEFAULT_SIT_HOLD) -> void:
	inter_sit_gap = p_inter_sit_gap
	sit_hold = p_sit_hold

func state() -> int:
	return _state

func is_sitting() -> bool:
	return _state == State.SITTING

## Advance the loop one frame and return the Intent main.gd should act on.
##   delta           — frame delta seconds.
##   has_sit         — can the loaded dog sit? false (CC0) keeps the loop IDLE forever.
##   session_elapsed — seconds into the current sit (only meaningful while SITTING).
##   sit_end         — the markable window's end (seated-span end) for the open sit.
func tick(delta: float, has_sit: bool, session_elapsed: float, sit_end: float) -> int:
	match _state:
		State.IDLE:
			# Never start a sit the dog can't perform — park in idle (P1-1, no faked sit).
			if not has_sit:
				return Intent.NONE
			_idle_elapsed += delta
			if _idle_elapsed >= inter_sit_gap:
				_idle_elapsed = 0.0
				_state = State.SITTING
				return Intent.START_SIT
			return Intent.NONE
		State.SITTING:
			# Hold the seated pose a beat past the markable window, then stand back up.
			if session_elapsed >= sit_end + sit_hold:
				_state = State.IDLE
				_idle_elapsed = 0.0
				return Intent.END_SIT
			return Intent.NONE
	return Intent.NONE
