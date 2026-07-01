class_name DogDirector
extends RefCounted
## Drives the loaded dog's AnimationPlayer for Phase 1 (024b). It keeps the dog
## alive on its idle clip (P1-2) and, on a sit-capable dog (the licensed Labrador,
## ADR-0002), plays the build→hold sit whose apex — the single source of truth —
## feeds SitWindow (024a). On the CC0 placeholder, which ships no Sitt clip, it
## stays in idle and reports has_sit() == false; it never fakes a sit (P1-1 "no
## placeholder stand-in", and the 024b asset gate). Clip names are resolved by
## DogClips, so the director is the same code for both dogs.

var clips: DogClips
var _ap: AnimationPlayer

## Crossfade between clips so pose changes ease instead of snapping. P1-6/034 needs the
## joyful hop to blend cleanly out of the seated pose and back again (no pose pop); a short
## uniform blend is the standard Godot idiom and also softens the idle↔sit transitions
## without touching the apex (which is timing-driven, not blend-driven). Visual Review gates.
const BLEND_TIME := 0.2

func _init(animation_player: AnimationPlayer) -> void:
	_ap = animation_player
	if _ap != null:
		_ap.playback_default_blend_time = BLEND_TIME
	var names := _ap.get_animation_list() if _ap != null else PackedStringArray()
	clips = DogClips.resolve(names)

## Whether this dog can perform a real sit (vs. the idle-only CC0 placeholder).
func has_sit() -> bool:
	return clips.has_sit()

## Whether this dog has an authored positive reaction to play on a successful mark
## (024f). False on the CC0 placeholder — play_reaction then stays a no-op.
func has_reaction() -> bool:
	return clips.has_reaction()

## Whether this dog has a walk clip for the ambient wander (050, P2-8). False → play_walk no-ops
## and main leaves the dog put (never a faked gait). Both shipped dogs carry one.
func has_walk() -> bool:
	return clips.has_walk()

## Loop the ambient idle so the dog reads as alive at rest (P1-2). No-op if the
## dog exposes no idle clip.
func play_idle() -> void:
	if _ap == null or clips.idle == "":
		return
	_set_loop(clips.idle, Animation.LOOP_LINEAR)
	_ap.play(clips.idle)

## Loop the walk clip so the legs step while main glides the dog ROOT across the grass patch
## (050, P2-8 ambient wander). The clip is in-place (licensed `Walk_F_IP`) so it animates only the
## gait, never the root — main owns the translation. A no-op on a dog with no walk clip (never a
## faked gait); main then leaves the dog put.
func play_walk() -> void:
	if _ap == null or not has_walk():
		return
	_set_loop(clips.walk, Animation.LOOP_LINEAR)
	_ap.play(clips.walk)

## Play the build-into-the-sit, then hold the seated loop (P1-3). Requires a
## sit-capable dog; a no-op (stays idle) otherwise — never a faked sit.
func play_sit() -> void:
	if _ap == null or not has_sit():
		return
	_set_loop(clips.sit_loop, Animation.LOOP_LINEAR)
	_ap.play(clips.sit_start)
	_ap.queue(clips.sit_loop)

## Begin a sit then ABORT it (048, P2-8 feint): play the real `Sitting_start` build-in and
## fall STRAIGHT back to idle, WITHOUT queueing the seated loop — so the dip never reaches a
## held apex. No scoring window opens for a feint (main keeps the session closed), so a tap
## during it is DEAD → gentle erosion (P2-4). Honest reuse of the licensed build-in clip, no
## new asset and no faked pose. A no-op on a dog that can't sit (the CC0 placeholder) — it has
## no build-in to play, so it can never feint (never a faked dip; the 024b asset gate holds).
func play_feint() -> void:
	if _ap == null or not has_sit():
		return
	_set_loop(clips.sit_start, Animation.LOOP_NONE)  # the dip plays once, never loops a hold
	_ap.play(clips.sit_start)
	if clips.idle != "":
		_ap.queue(clips.idle)  # stand straight back up — never reach the seated hold

## The scoring window for this dog's sit: apex = end of `Sitting_start` (single
## source of truth). Returns null when the dog can't sit.
func sit_window() -> SitWindow:
	if _ap == null or not has_sit():
		return null
	var start_len := _ap.get_animation(clips.sit_start).length
	var loop_len := _ap.get_animation(clips.sit_loop).length
	# The scoring bands' canonical home is SitWindow (029); the apex stays the end
	# of `Sitting_start`. Pass the defaults explicitly so difficulty can override later.
	return SitWindow.from_sit_clips(start_len, loop_len,
		SitWindow.DEFAULT_PERFECT_RADIUS, SitWindow.DEFAULT_OK_RADIUS)

## Play the dog's positive reaction ONCE on a successful mark (024f, P1-6), then fall
## back to its resting pose (the seated hold if sitting, else idle) so it doesn't freeze
## on the celebration. A no-op on a dog with no reaction clip (the CC0 placeholder) —
## the gameplay gate (MarkPayoff.reacts, keyed off a successful mark) already keeps it
## from firing on a miss, and here we never fake a reaction the asset can't perform.
func play_reaction() -> void:
	if _ap == null or not has_reaction():
		return
	_set_loop(clips.reaction, Animation.LOOP_NONE)
	_ap.play(clips.reaction)
	if clips.sit_loop != "":
		_ap.queue(clips.sit_loop)
	elif clips.idle != "":
		_ap.queue(clips.idle)

## Stand the dog back up out of the seated hold with its AUTHORED stand-up clip (`Sitting_end`)
## — the missing third beat of the sit cycle (build-in → hold → STAND-UP), so the exit eases
## through the real animation instead of snapping straight from the seated loop to idle on the
## blend alone (059). Then settle into the ambient idle. Falls back to a plain idle when the dog
## ships no stand-up clip (the CC0 placeholder), so the dog always ends up alive at rest, never
## frozen mid-sit and never faking a stand-up it can't perform (the 024b asset gate holds).
## Honest reuse of the licensed `Sitting_end` — no new asset.
func play_sit_end() -> void:
	if _ap == null:
		return
	if clips.sit_end == "":
		play_idle()  # no authored stand-up — settle straight to idle rather than freeze
		return
	_set_loop(clips.sit_end, Animation.LOOP_NONE)  # the stand-up plays once, never loops
	_ap.play(clips.sit_end)
	if clips.idle != "":
		_ap.queue(clips.idle)  # settle into the ambient idle after standing

## True while the authored stand-up is the clip currently playing (059). main holds the ambient
## roam IN PLACE during it so the stand-up reads before the dog ambles off, without touching the
## SitLoop cadence (the next offer stays on its own clock — this only gates which clip shows).
func is_standing_up() -> bool:
	return _ap != null and clips.sit_end != "" and _ap.current_animation == clips.sit_end

func _set_loop(clip: String, mode: Animation.LoopMode) -> void:
	if _ap.has_animation(clip):
		_ap.get_animation(clip).loop_mode = mode
