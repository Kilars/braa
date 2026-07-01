class_name DogClips
extends RefCounted
## Resolves a dog's idle / sit clip names from its AnimationPlayer clip list so the
## sit director (024b) is dog-agnostic. The CC0 placeholder
## (assets/models/dog.glb) ships no Sitt clip; the licensed Labrador (ADR-0002
## shared clip library) has real `Sitting_start / loop / end`. Matching is by the
## clip's leaf name — the segment after the last '|' — so it survives both the
## `AnimalArmature|...|Idle` and `Arm_Labrador|Sitting_start` naming schemes, and
## "sitting" (not the looser "sit") guards against decoys like `Crouch_Idle_loop`.

## Stable trick ids — the keys the director / main / save-store address a trick by (065, BUST-064).
## Kept here so the resolver, the director, and main.gd all name a trick the same way.
const TRICK_SITT := "sitt"
const TRICK_LIGG := "ligg"

var idle: String       ## the ambient idle clip (P1-2); "" if the dog has none
var sit_start: String  ## build-into-the-sit clip; the apex is its end. "" if none
var sit_loop: String   ## fully-seated hold loop. "" if none
var sit_end: String    ## stand-back-up clip. "" if none
## Ligg (lie down, P2-2 / 065): the licensed asset already holds these `Lie_*` clips (manifest
## dog_licensed.clips.txt) — unwired until BUST-064 routed them here. Resolved distinct from Sitt and
## from the belly-settle (Legg deg, `Lie_belly_*`, task 067) / sleep (`Lie_Sleep_*`) poses. "" if none.
var lie_start: String  ## build-into-the-lie clip; the apex (fully down) is its end. "" if none
var lie_loop: String   ## fully-down hold loop. "" if none
var lie_end: String    ## stand-back-up-from-lie clip. "" if none
var reaction: String   ## positive reaction on a mark (024f, P1-6); "" if the dog has none
var walk: String       ## locomotion clip for the ambient wander (050, P2-8); "" if the dog has none

## Leaf substrings that name a POSITIVE reaction, in priority order. A joyful in-place
## bounce reads as celebration at phone size, so the licensed pack's hop clips rank ahead
## of a bare Bark (P1-6, task 034 — a lone bark on an already-open mouth didn't read as
## joy). Terms stay reaction-SPECIFIC — "jump_place" matches the licensed `Jump_Place_IP`
## (a complete root-stripped in-place hop) and "jumpair" its airborne variants, but NEVER
## a bare "jump"/"walk"/"run" — so the CC0 placeholder, which ships only generic
## locomotion, resolves no reaction and stays idle rather than faking a celebration (the
## 024f asset gate still holds). Verified against the real `dog_licensed.glb` clip list.
const REACTION_VOCAB := [
	"jump_place", "jumpair", "wag", "happy", "excit", "greet", "celebrat", "perk", "bark",
]

func _init() -> void:
	idle = ""
	sit_start = ""
	sit_loop = ""
	sit_end = ""
	lie_start = ""
	lie_loop = ""
	lie_end = ""
	reaction = ""
	walk = ""

static func resolve(names: PackedStringArray) -> DogClips:
	var c := DogClips.new()
	c.idle = _pick_idle(names)
	c.sit_start = _pick(names, "sitting", "start")
	c.sit_loop = _pick_sit_loop(names)
	c.sit_end = _pick(names, "sitting", "end")
	c.lie_start = _pick_lie(names, "start")
	c.lie_loop = _pick_lie_loop(names)
	c.lie_end = _pick_lie(names, "end")
	c.reaction = _pick_reaction(names)
	c.walk = _pick_walk(names)
	return c

## True when this dog can actually perform a sit (build + hold both present). The
## CC0 placeholder returns false — the director then stays in idle and never fakes
## a sit (P1-1 "no placeholder stand-in", and the 024b asset gate).
func has_sit() -> bool:
	return sit_start != "" and sit_loop != ""

## True when this dog can perform Ligg (lie down) — build + hold both present (065, P2-2). The CC0
## placeholder returns false, so the director never fakes a lie-down it can't perform (the asset gate
## the licensed Labrador does hold: its `Lie_*` clips are in the manifest).
func has_lie() -> bool:
	return lie_start != "" and lie_loop != ""

## Generic trick accessors (065, BUST-064): the director + main drive a NAMED trick via a
## (start, loop, end) bundle so adding a trick is a clip-name swap, not a new code path. Unknown ids
## resolve to "" / has_trick()==false, so an unwired trick degrades honestly (never fakes a pose).
func trick_start(id: String) -> String:
	match id:
		TRICK_SITT: return sit_start
		TRICK_LIGG: return lie_start
	return ""

func trick_loop(id: String) -> String:
	match id:
		TRICK_SITT: return sit_loop
		TRICK_LIGG: return lie_loop
	return ""

func trick_end(id: String) -> String:
	match id:
		TRICK_SITT: return sit_end
		TRICK_LIGG: return lie_end
	return ""

## True when the named trick's build + hold clips both resolved on this dog (mirrors has_sit/has_lie).
func has_trick(id: String) -> bool:
	return trick_start(id) != "" and trick_loop(id) != ""

## True when this dog has an authored positive-reaction clip (024f). False on the CC0
## placeholder — the director then skips the reaction (stays in its resting pose) and
## never fakes a celebration; the real reaction ships with the licensed Labrador (025).
func has_reaction() -> bool:
	return reaction != ""

## True when this dog has a walk clip for the ambient wander (050, P2-8). When false, main skips
## the wander rather than gliding a standing dog — never a faked gait (CLAUDE.md). Both shipped
## dogs carry one: the CC0 `Walk` and the licensed `Walk_F_IP` (an in-place walk, root motion
## stripped — exactly right since main drives the root translation itself).
func has_walk() -> bool:
	return walk != ""

## Depth-first search for the dog's AnimationPlayer inside a loaded glb subtree. The one
## home for the recursive find that the scene loader (main.gd) and the clip tests share,
## so a change to how the player is located lives in a single place. Returns null if none.
static func find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for child in n.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null

static func _leaf(name: String) -> String:
	var parts := name.split("|")
	return parts[parts.size() - 1]

## Idle = the leaf that is exactly "idle" if present (the CC0 dog's "Idle"), else
## the first leaf that *starts with* "idle" (the Labrador's "Idle_1"). The
## starts-with rule rejects decoys like "Crouch_Idle_loop_1".
static func _pick_idle(names: PackedStringArray) -> String:
	var fallback := ""
	for n in names:
		var leaf := _leaf(n).to_lower()
		if leaf == "idle":
			return n
		if fallback == "" and leaf.begins_with("idle"):
			fallback = n
	return fallback

## The fully-seated hold loop: the first "sitting" clip that is neither the build-in
## (start) nor the stand-up (end). Matched by EXCLUSION, not the literal "loop" substring,
## because Godot's glTF importer renames `Sitting_loop_1/2` to `Sitting_1/2` — the held
## loop must still resolve so has_sit() is true on the imported Labrador. The "sitting"
## guard still rejects decoys like `Crouch_Idle_loop_1`. (025)
static func _pick_sit_loop(names: PackedStringArray) -> String:
	for n in names:
		var leaf := _leaf(n).to_lower()
		if leaf.contains("sitting") and not leaf.contains("start") and not leaf.contains("end"):
			return n
	return ""

## Ligg (lie down, 065/P2-2): the first `Lie_*` clip whose leaf carries substring `b` (start / end)
## but is NEITHER the belly-settle (`Lie_belly_*` = Legg deg, task 067) NOR the sleep pose
## (`Lie_Sleep_*`) — those share the "lie" stem but are a different trick, so Ligg must exclude them.
## Skips (continues past) a belly/sleep match rather than returning it, so a later plain-lie clip
## still resolves regardless of clip order.
static func _pick_lie(names: PackedStringArray, b: String) -> String:
	for n in names:
		var leaf := _leaf(n).to_lower()
		if leaf.contains("lie") and leaf.contains(b) \
			and not leaf.contains("belly") and not leaf.contains("sleep"):
			return n
	return ""

## The fully-down Ligg hold loop: the first plain-lie clip that is neither the build-in (start) nor
## the stand-up (end), matched by EXCLUSION — the glTF importer strips "loop" from `Lie_loop_1/2` to
## `Lie_1/2` (same as Sitting), so "loop" can't be matched literally. Excludes belly/sleep decoys.
static func _pick_lie_loop(names: PackedStringArray) -> String:
	for n in names:
		var leaf := _leaf(n).to_lower()
		if leaf.contains("lie") and not leaf.contains("start") and not leaf.contains("end") \
			and not leaf.contains("belly") and not leaf.contains("sleep"):
			return n
	return ""

## First clip whose leaf contains both substrings (case-insensitive).
static func _pick(names: PackedStringArray, a: String, b: String) -> String:
	for n in names:
		var leaf := _leaf(n).to_lower()
		if leaf.contains(a) and leaf.contains(b):
			return n
	return ""

## The positive-reaction clip: the first clip matching the highest-priority reaction
## term present (vocab order, not clip order, so the choice is stable regardless of how
## the pack lists its clips). "" when none match — the CC0 dog, which never reacts.
static func _pick_reaction(names: PackedStringArray) -> String:
	for term in REACTION_VOCAB:
		for n in names:
			if _leaf(n).to_lower().contains(term):
				return n
	return ""

## The locomotion clip for the ambient wander (050, P2-8): the first leaf containing "walk".
## Matches both the CC0 `Walk` and the licensed in-place `Walk_F_IP`. "" when the dog ships no
## walk clip — main then skips the wander rather than faking a gait.
static func _pick_walk(names: PackedStringArray) -> String:
	for n in names:
		if _leaf(n).to_lower().contains("walk"):
			return n
	return ""
