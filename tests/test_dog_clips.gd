extends "res://tests/test_case.gd"
## TDD for clip resolution (024b). The sit director must be dog-agnostic across the
## CC0 placeholder (assets/models/dog.glb — no Sitt) and the licensed Labrador
## (ADR-0002 shared clip library — real Sitting_* clips). The logic is pure
## name-list matching; one test also binds to the REAL committed dog so "idle
## resolves" can't read a hollow green against an empty/stale list.

# The committed CC0 dog's actual clip leaves (verified from the glb).
const CC0 := ["AnimalArmature|Idle", "AnimalArmature|Walk", "AnimalArmature|Run",
	"AnimalArmature|Jump", "AnimalArmature|Idle_Eating", "AnimalArmature|Death"]

# The licensed Labrador's relevant clip leaves AS GODOT IMPORTS THEM (verified from the
# imported dog_licensed.glb): the glTF importer renames `Sitting_loop_1/2` to `Sitting_1/2`
# (strips "loop"), so the resolver must match the hold loop by exclusion, not "loop". Note
# the decoy `Crouch_Idle_loop_1`: it has "idle" and "loop" but is NOT a sit.
const LAB := ["Arm_Labrador|Idle_1", "Arm_Labrador|Idle_2",
	"Arm_Labrador|Crouch_Idle_loop_1",
	"Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_1",
	"Arm_Labrador|Sitting_2", "Arm_Labrador|Sitting_end",
	"Arm_Labrador|Walk_F_IP"]

func test_cc0_resolves_plain_idle_and_has_no_sit() -> void:
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_eq(c.idle, "AnimalArmature|Idle", "the exact 'Idle' leaf is the idle clip")
	assert_false(c.has_sit(), "the CC0 placeholder ships no Sitt clip")
	assert_eq(c.sit_start, "", "no sit start on the CC0 dog")

func test_labrador_resolves_idle_and_sit_clips() -> void:
	var c := DogClips.resolve(PackedStringArray(LAB))
	assert_eq(c.idle, "Arm_Labrador|Idle_1", "first Idle-prefixed leaf when no exact 'Idle'")
	assert_true(c.has_sit(), "the Labrador has a real Sitt")
	assert_eq(c.sit_start, "Arm_Labrador|Sitting_start", "sit build-in clip")
	assert_eq(c.sit_loop, "Arm_Labrador|Sitting_1", "first sit hold-loop clip (Godot strips 'loop')")
	assert_eq(c.sit_end, "Arm_Labrador|Sitting_end", "sit stand-up clip")

func test_crouch_idle_is_not_mistaken_for_idle_or_sit() -> void:
	var c := DogClips.resolve(PackedStringArray(LAB))
	assert_ne(c.idle, "Arm_Labrador|Crouch_Idle_loop_1", "crouch-idle is not the idle clip")
	assert_ne(c.sit_loop, "Arm_Labrador|Crouch_Idle_loop_1", "crouch-idle is not the sit loop")

func test_empty_list_resolves_to_nothing() -> void:
	var c := DogClips.resolve(PackedStringArray([]))
	assert_eq(c.idle, "", "no idle from an empty clip set")
	assert_false(c.has_sit(), "no sit from an empty clip set")
	assert_false(c.has_reaction(), "no reaction from an empty clip set")

func test_reaction_resolves_a_positive_clip_when_present() -> void:
	# 024f: the happy reaction on a successful mark is clip-driven too, so the director
	# stays dog-agnostic. Illustrative clip set (NOT the verified LAB list): a dog whose
	# pack carries a positive-reaction clip must resolve it so play_reaction has a clip.
	var names := ["Arm_Labrador|Idle_1", "Arm_Labrador|Tail_wag",
		"Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_loop_1"]
	var c := DogClips.resolve(PackedStringArray(names))
	assert_eq(c.reaction, "Arm_Labrador|Tail_wag", "the positive-reaction clip resolves")
	assert_true(c.has_reaction(), "a dog with a reaction clip can react on a mark")

func test_cc0_has_no_positive_reaction_clip() -> void:
	# The CC0 placeholder ships only locomotion + idle — no authored celebration — so it
	# can't react and stays idle; the real reaction ships with the licensed Labrador, the
	# same asset gate as the Sitt (024b). Generic Jump/Walk must NOT be read as a reaction.
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_false(c.has_reaction(), "the CC0 dog has no positive-reaction clip")
	assert_eq(c.reaction, "", "no reaction clip resolved on the CC0 dog (Jump is not a reaction)")

func test_reaction_prefers_a_joyful_bounce_over_a_lone_bark() -> void:
	# 034 / P1-6: on the licensed pack the only reaction-vocab leaf used to be `Bark`, so a
	# successful mark fired a lone bark (no read of joy). A joyful in-place hop must outrank
	# it. Uses the REAL licensed leaf names (Step 0): `Jump_Place_IP` is the complete in-place
	# bounce; `Bark` is the standing bark. The hop must win.
	var names := ["Arm_Labrador|Idle_1", "Arm_Labrador|Bark",
		"Arm_Labrador|Jump_Place_IP", "Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_1"]
	var c := DogClips.resolve(PackedStringArray(names))
	assert_eq(c.reaction, "Arm_Labrador|Jump_Place_IP", "the joyful hop outranks the lone Bark")
	assert_ne(c.reaction, "Arm_Labrador|Bark", "a successful mark is no longer a lone bark")
	assert_true(c.has_reaction(), "the licensed dog still has a reaction")

func test_cc0_generic_jump_is_never_a_reaction() -> void:
	# 034 / P1-6: the joyful terms ("jump_place"/"jumpair") must stay specific enough that the
	# CC0 placeholder's bare `Jump` is NOT mistaken for a celebration (else the 024f asset gate
	# breaks and the idle-only dog fakes a hop). A list whose only jump-ish leaf is a bare
	# `Jump` must resolve no reaction.
	var names := ["AnimalArmature|Idle", "AnimalArmature|Walk", "AnimalArmature|Jump"]
	var c := DogClips.resolve(PackedStringArray(names))
	assert_eq(c.reaction, "", "a bare generic Jump is not a joyful reaction")
	assert_false(c.has_reaction(), "the idle-only dog still can't react (asset gate holds)")

func test_walk_resolves_the_locomotion_clip() -> void:
	# 050 / P2-8 locomotion: the ambient wander rides a REAL walk clip (no faked gait). The
	# licensed Labrador ships `Walk_F_IP` — an IN-PLACE walk (root motion stripped), exactly
	# what we want since main drives the root translation itself and the clip just moves the legs.
	var c := DogClips.resolve(PackedStringArray(LAB))
	assert_eq(c.walk, "Arm_Labrador|Walk_F_IP", "the in-place walk clip resolves for locomotion")
	assert_true(c.has_walk(), "the Labrador can amble (has a walk clip)")

func test_cc0_also_has_a_walk_clip() -> void:
	# The CC0 fallback ships a plain `Walk` too, so the local verify/export build can still show
	# the dog roaming (the licensed dog isn't in public CI).
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_eq(c.walk, "AnimalArmature|Walk", "the CC0 dog's plain Walk resolves")
	assert_true(c.has_walk(), "even the CC0 fallback can amble")

func test_a_dog_with_no_walk_clip_cannot_amble() -> void:
	# Honest gate (mirrors has_sit / has_reaction): a dog with no walk clip resolves none, so
	# main skips the wander rather than faking a glide-while-standing (CLAUDE.md "no faked gait").
	var c := DogClips.resolve(PackedStringArray(
		["Arm|Idle_1", "Arm|Sitting_start", "Arm|Sitting_1"]))
	assert_eq(c.walk, "", "no walk clip resolves to nothing")
	assert_false(c.has_walk(), "a dog with no walk clip can't amble (skip, never fake)")

# The licensed Labrador's LIE-DOWN (Ligg, P2-2) clip leaves AS GODOT IMPORTS THEM: exactly like
# Sitting, the glTF importer strips "loop" from `Lie_loop_1/2` -> `Lie_1/2`, so the hold loop must
# resolve by EXCLUSION, not the literal "loop". The decoys `Lie_belly_*` (Legg deg, the SETTLE trick,
# task 067) and `Lie_Sleep_*` (a sleep pose) share the "lie" stem but are a DIFFERENT trick — Ligg
# must never resolve to them. Verified against the committed manifest (dog_licensed.clips.txt).
const LAB_LIE := ["Arm_Labrador|Idle_1",
	"Arm_Labrador|Sitting_start", "Arm_Labrador|Sitting_1", "Arm_Labrador|Sitting_end",
	"Arm_Labrador|Lie_start", "Arm_Labrador|Lie_1", "Arm_Labrador|Lie_2", "Arm_Labrador|Lie_end",
	"Arm_Labrador|Lie_belly_start", "Arm_Labrador|Lie_belly_1", "Arm_Labrador|Lie_belly_end",
	"Arm_Labrador|Lie_belly_sleep_start", "Arm_Labrador|Lie_belly_sleep", "Arm_Labrador|Lie_belly_sleep_end",
	"Arm_Labrador|Lie_Sleep_start", "Arm_Labrador|Lie_Sleep_loop", "Arm_Labrador|Lie_Sleep_end"]

func test_labrador_resolves_ligg_lie_clips() -> void:
	# BUST-064 / P2-2: Ligg (lie down) clips are PRESENT in the licensed asset (per the manifest),
	# just unwired. The resolver must find the plain lie build/hold/stand triple, distinct from Sitt.
	var c := DogClips.resolve(PackedStringArray(LAB_LIE))
	assert_true(c.has_lie(), "the Labrador has a real Ligg (lie down)")
	assert_eq(c.lie_start, "Arm_Labrador|Lie_start", "Ligg build-in clip")
	assert_eq(c.lie_loop, "Arm_Labrador|Lie_1", "first Ligg hold-loop clip (Godot strips 'loop')")
	assert_eq(c.lie_end, "Arm_Labrador|Lie_end", "Ligg stand-up clip")

func test_ligg_is_not_the_belly_settle_or_sleep_pose() -> void:
	# P2-2: Ligg (plain lie) must read distinct from Legg deg (Lie_belly_*, task 067) and never
	# resolve to the sleep pose. The "lie" stem is shared, so the resolver excludes belly + sleep.
	var c := DogClips.resolve(PackedStringArray(LAB_LIE))
	assert_ne(c.lie_start, "Arm_Labrador|Lie_belly_start", "Ligg is not the belly-settle (Legg deg)")
	assert_ne(c.lie_loop, "Arm_Labrador|Lie_belly_1", "Ligg hold is not the belly hold")
	assert_ne(c.lie_start, "Arm_Labrador|Lie_Sleep_start", "Ligg is not the sleep pose")
	assert_ne(c.lie_loop, "Arm_Labrador|Lie_Sleep_loop", "Ligg hold is not the sleep pose")

func test_cc0_has_no_ligg() -> void:
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_false(c.has_lie(), "the CC0 placeholder ships no lie-down clip")
	assert_eq(c.lie_start, "", "no Ligg build-in on the CC0 dog")

func test_generic_trick_accessors_map_ids_to_clip_bundles() -> void:
	# The director + main drive a NAMED trick via a generic (start, loop, end) bundle so adding a
	# trick is a clip-name swap, not a new code path: "sitt" -> Sitting_*, "ligg" -> Lie_*.
	var c := DogClips.resolve(PackedStringArray(LAB_LIE))
	assert_true(c.has_trick("sitt"), "sitt is a known, resolved trick")
	assert_true(c.has_trick("ligg"), "ligg is a known, resolved trick")
	assert_eq(c.trick_start("sitt"), c.sit_start, "sitt bundle start == sit_start")
	assert_eq(c.trick_loop("sitt"), c.sit_loop, "sitt bundle loop == sit_loop")
	assert_eq(c.trick_end("sitt"), c.sit_end, "sitt bundle end == sit_end")
	assert_eq(c.trick_start("ligg"), c.lie_start, "ligg bundle start == lie_start")
	assert_eq(c.trick_loop("ligg"), c.lie_loop, "ligg bundle loop == lie_loop")
	assert_eq(c.trick_end("ligg"), c.lie_end, "ligg bundle end == lie_end")
	assert_false(c.has_trick("nope"), "an unknown trick id resolves to nothing")
	assert_eq(c.trick_start("nope"), "", "an unknown trick id has no start clip")

func test_licensed_dog_if_present_resolves_ligg() -> void:
	# BUST-064: binds to the REAL imported licensed Labrador — proves Ligg is genuinely IN the asset
	# (behavior != inventory: the running game wires only Sitt, but the glb holds Lie_*). Gitignored
	# asset, so absent in public CI: skip cleanly there (the assert_true dodges the 0-assertion gate)
	# and verify for real in local dev.
	var p := "res://assets/models/dog_licensed.glb"
	if not ResourceLoader.exists(p):
		assert_true(true, "licensed dog absent (e.g. public CI) — skipped")
		return
	var packed := load(p) as PackedScene
	assert_true(packed != null, "the licensed dog glb must load as a PackedScene")
	if packed == null:
		return
	var dog := packed.instantiate()
	var ap := DogClips.find_animation_player(dog)
	assert_true(ap != null, "the licensed dog must have an AnimationPlayer")
	if ap != null:
		var c := DogClips.resolve(ap.get_animation_list())
		assert_true(c.has_lie(), "the licensed Labrador must resolve a real Ligg (lie down) — it's in the manifest")
		assert_true(ap.has_animation(c.lie_start), "resolved lie_start must be a real clip on the dog")
		assert_true(ap.has_animation(c.lie_loop), "resolved lie_loop must be a real clip on the dog")
		assert_true(c.has_trick("ligg"), "ligg is drivable via the generic trick accessor")
	dog.free()

# Legg deg (settle on belly, P2-2/P2-3, task 067): the licensed asset already holds the belly-settle
# `Lie_belly_start / Lie_belly_loop_1|2 / Lie_belly_end` clips (manifest) — unwired until BUST-064.
# Like Sitting/Lie, the glTF importer strips "loop" (`Lie_belly_loop_1` -> `Lie_belly_1`), so the hold
# resolves by EXCLUSION. Legg deg must read distinct from Ligg (plain lie) and NEVER resolve to the
# belly-SLEEP decoys (`Lie_belly_sleep_*`) or the plain sleep pose (`Lie_Sleep_*`).
func test_labrador_resolves_legg_deg_belly_clips() -> void:
	var c := DogClips.resolve(PackedStringArray(LAB_LIE))
	assert_true(c.has_legg_deg(), "the Labrador has a real Legg deg (belly settle)")
	assert_eq(c.legg_start, "Arm_Labrador|Lie_belly_start", "Legg deg build-in clip")
	assert_eq(c.legg_loop, "Arm_Labrador|Lie_belly_1", "first Legg deg hold-loop clip (Godot strips 'loop')")
	assert_eq(c.legg_end, "Arm_Labrador|Lie_belly_end", "Legg deg stand-up clip")

func test_legg_deg_is_distinct_from_ligg_and_never_the_sleep_pose() -> void:
	# P2-3: Legg deg (belly settle) must read distinct from Ligg (plain lie) and must never resolve to
	# the belly-sleep or plain-sleep decoys — all four share the "lie" stem.
	var c := DogClips.resolve(PackedStringArray(LAB_LIE))
	assert_ne(c.legg_start, c.lie_start, "Legg deg build-in is not the plain-lie (Ligg) build-in")
	assert_ne(c.legg_loop, c.lie_loop, "Legg deg hold is not the plain-lie (Ligg) hold")
	assert_ne(c.legg_start, "Arm_Labrador|Lie_belly_sleep_start", "Legg deg is not the belly-sleep pose")
	assert_ne(c.legg_loop, "Arm_Labrador|Lie_belly_sleep", "Legg deg hold is not the belly-sleep pose")
	assert_ne(c.legg_start, "Arm_Labrador|Lie_Sleep_start", "Legg deg is not the plain sleep pose")
	# And the reverse guard: Ligg must never grab a belly clip now that both are present.
	assert_false(c.lie_start.contains("belly"), "Ligg still excludes the belly-settle clips")

func test_cc0_has_no_legg_deg() -> void:
	var c := DogClips.resolve(PackedStringArray(CC0))
	assert_false(c.has_legg_deg(), "the CC0 placeholder ships no belly-settle clip")
	assert_eq(c.legg_start, "", "no Legg deg build-in on the CC0 dog")

func test_generic_trick_accessors_include_legg_deg() -> void:
	# Adding Legg deg is a clip-name swap through the generic bundle, not a new code path:
	# "legg_deg" -> Lie_belly_*, driven by the same play_trick / trick_window family.
	var c := DogClips.resolve(PackedStringArray(LAB_LIE))
	assert_true(c.has_trick("legg_deg"), "legg_deg is a known, resolved trick")
	assert_eq(c.trick_start("legg_deg"), c.legg_start, "legg_deg bundle start == legg_start")
	assert_eq(c.trick_loop("legg_deg"), c.legg_loop, "legg_deg bundle loop == legg_loop")
	assert_eq(c.trick_end("legg_deg"), c.legg_end, "legg_deg bundle end == legg_end")

func test_licensed_dog_if_present_resolves_legg_deg() -> void:
	# BUST-064: binds to the REAL imported licensed Labrador — proves Legg deg's belly clips are
	# genuinely IN the asset (behavior != inventory). Gitignored asset, absent in public CI: skip
	# cleanly there (the assert_true dodges the 0-assertion gate) and verify for real in local dev.
	var p := "res://assets/models/dog_licensed.glb"
	if not ResourceLoader.exists(p):
		assert_true(true, "licensed dog absent (e.g. public CI) — skipped")
		return
	var packed := load(p) as PackedScene
	assert_true(packed != null, "the licensed dog glb must load as a PackedScene")
	if packed == null:
		return
	var dog := packed.instantiate()
	var ap := DogClips.find_animation_player(dog)
	assert_true(ap != null, "the licensed dog must have an AnimationPlayer")
	if ap != null:
		var c := DogClips.resolve(ap.get_animation_list())
		assert_true(c.has_legg_deg(), "the licensed Labrador must resolve a real Legg deg — it's in the manifest")
		assert_true(ap.has_animation(c.legg_start), "resolved legg_start must be a real clip on the dog")
		assert_true(ap.has_animation(c.legg_loop), "resolved legg_loop must be a real clip on the dog")
		assert_true(c.has_trick("legg_deg"), "legg_deg is drivable via the generic trick accessor")
		assert_ne(c.legg_start, c.lie_start, "Legg deg and Ligg resolve to different build-in clips on the real asset")
	dog.free()

func test_committed_dog_exposes_a_real_idle_clip() -> void:
	# Binds to the REAL committed asset (mirrors test_smoke): after --import the dog
	# must yield an AnimationPlayer whose resolved idle is an actual clip on it.
	var packed := load("res://assets/models/dog.glb") as PackedScene
	assert_true(packed != null, "the committed dog glb must load as a PackedScene")
	if packed == null:
		return
	var dog := packed.instantiate()
	var ap := DogClips.find_animation_player(dog)
	assert_true(ap != null, "the committed dog must have an AnimationPlayer")
	if ap != null:
		var c := DogClips.resolve(ap.get_animation_list())
		assert_ne(c.idle, "", "the committed dog must expose an idle clip")
		assert_true(ap.has_animation(c.idle), "the resolved idle must be a real clip on the dog")
		# The committed dog is the CC0 placeholder, which has no Sitt (the gate
		# behind 024b). Pins the discrepancy so a future asset swap is deliberate.
		assert_false(c.has_sit(), "the committed CC0 dog has no Sitt clip (see task 024b)")
		# Same gate for the payoff reaction (024f): no authored celebration on CC0, so
		# the live dog can't react until the licensed Labrador ships (025).
		assert_false(c.has_reaction(), "the committed CC0 dog has no reaction clip (see 024f)")
	dog.free()

func test_licensed_dog_if_present_resolves_a_real_sit() -> void:
	# Binds to the REAL imported licensed Labrador against Godot's ACTUAL clip names — the
	# guard that would have caught the importer renaming Sitting_loop_1 -> Sitting_1. The
	# asset is gitignored, so it's absent in public CI: skip cleanly there (the assert_true
	# keeps this from tripping the 0-assertion gate), and verify for real in local dev. (025)
	var p := "res://assets/models/dog_licensed.glb"
	if not ResourceLoader.exists(p):
		assert_true(true, "licensed dog absent (e.g. public CI) — skipped")
		return
	var packed := load(p) as PackedScene
	assert_true(packed != null, "the licensed dog glb must load as a PackedScene")
	if packed == null:
		return
	var dog := packed.instantiate()
	var ap := DogClips.find_animation_player(dog)
	assert_true(ap != null, "the licensed dog must have an AnimationPlayer")
	if ap != null:
		var c := DogClips.resolve(ap.get_animation_list())
		assert_true(c.has_sit(), "the licensed Labrador must resolve a real Sitt (start + hold loop)")
		assert_true(ap.has_animation(c.sit_start), "resolved sit_start must be a real clip on the dog")
		assert_true(ap.has_animation(c.sit_loop), "resolved sit_loop must be a real clip on the dog")
		# 034 / P1-6: the joyful reaction must resolve to the real in-place hop on the asset
		# (Step 0 confirmed `Jump_Place_IP` exists), NOT the lone Bark.
		assert_true(c.has_reaction(), "the licensed Labrador must resolve a positive reaction")
		assert_eq(c.reaction, "Arm_Labrador|Jump_Place_IP", "reaction is the joyful in-place hop, not Bark")
		assert_true(ap.has_animation(c.reaction), "resolved reaction must be a real clip on the dog")
	dog.free()
